open Ppxlib
open Parsetree
open Ast_helper
open Util

let rec generateConstrSchemaExpression {Location.txt = identifier; loc}
    type_args =
  let open Longident in
  match (identifier, type_args) with
  | Lident "string", _ -> [%expr S.string]
  | Lident "int", _ -> [%expr S.int]
  | Lident "int64", _ -> fail loc "Can't generate schema for `int64` type"
  | Lident "float", _ -> [%expr S.float]
  | Lident "bool", _ -> [%expr S.bool]
  | Lident "unit", _ -> [%expr S.unit]
  | Lident "unknown", _ -> [%expr S.unknown]
  | Ldot (Lident "S", "never"), _ -> [%expr S.never]
  | Ldot (Ldot (Lident "Js", "Json"), "t"), _ | Ldot (Lident "JSON", "t"), _ ->
    [%expr S.json]
  | Lident "array", [item_type] ->
    [%expr S.array [%e generateCoreTypeSchemaExpression item_type]]
  | Lident "list", [item_type] ->
    [%expr S.list [%e generateCoreTypeSchemaExpression item_type]]
  | Lident "option", [item_type] ->
    [%expr S.option [%e generateCoreTypeSchemaExpression item_type]]
  | Lident "null", [item_type] ->
    [%expr S.null [%e generateCoreTypeSchemaExpression item_type]]
  | Ldot (Ldot (Lident "Js", "Dict"), "t"), [item_type]
  | Ldot (Lident "Dict", "t"), [item_type] ->
    [%expr S.dict [%e generateCoreTypeSchemaExpression item_type]]
  | Lident s, _ -> makeIdentExpr (generateSchemaName s)
  | Ldot (left, right), _ ->
    Exp.ident (mknoloc (Ldot (left, generateSchemaName right)))
  | Lapply (_, _), _ -> fail loc "Unsupported lapply syntax"

and generatePolyvariantSchemaExpression row_fields =
  let union_items =
    row_fields
    |> List.map (fun {prf_desc} ->
           let name =
             match prf_desc with
             | Rtag ({txt}, _, _) -> txt
             | _ -> failwith "Unsupported polymorphic variant constructor"
           in

           [%expr S.literal [%e Exp.variant name None]])
  in
  match union_items with
  | [item] -> item
  | _ -> [%expr S.union [%e Exp.array union_items]]

and generateVariantSchemaExpression constr_decls =
  let union_items =
    constr_decls
    |> List.map (fun {pcd_name = {txt = name; loc}; pcd_args} ->
           match pcd_args with
           | Pcstr_tuple [] ->
             [%expr S.literal [%e Exp.construct (lid name) None]]
           | _ -> fail loc "Variants with payload not supported yet")
  in
  match union_items with
  | [item] -> item
  | _ -> [%expr S.union [%e Exp.array union_items]]

and generateObjectSchema fields =
  let field_expressions =
    fields
    |> List.map (fun field ->
           let runtime_field_name_expression =
             Exp.constant
               (Pconst_string (field.runtime_name, Location.none, None))
           in

           let schema_expr = generateCoreTypeSchemaExpression field.core_type in
           let schema_expr =
             if field.is_optional then
               [%expr Obj.magic S.option [%e schema_expr]]
             else schema_expr
           in

           ( lid field.runtime_name,
             [%expr s.field [%e runtime_field_name_expression] [%e schema_expr]]
           ))
  in
  (* Use Obj.magic to cast to uncurried function in case of uncurried mode *)
  [%expr
    S.Object.factory
      (Obj.magic (fun (s : S.Object.ctx) ->
           [%e
             Exp.extension
               ( mkloc "obj" Location.none,
                 PStr [Str.eval (Exp.record field_expressions None)] )]))]

and generateCoreTypeSchemaExpression {ptyp_desc; ptyp_loc; ptyp_attributes} =
  let customSchemaExpression = getAttributeByName ptyp_attributes "schema" in
  match customSchemaExpression with
  | Ok None -> (
    match ptyp_desc with
    | Ptyp_any -> fail ptyp_loc "Can't generate schema for `any` type"
    | Ptyp_arrow (_, _, _) ->
      fail ptyp_loc "Can't generate schema for function type"
    | Ptyp_package _ -> fail ptyp_loc "Can't generate schema for module type"
    | Ptyp_tuple tuple_types ->
      [%expr
        S.tuple
          (Obj.magic (fun (s : S.Tuple.ctx) ->
               [%e
                 Exp.tuple
                   (tuple_types
                   |> List.mapi (fun idx tuple_type ->
                          [%expr
                            s.item
                              [%e Exp.constant (Const.int idx)]
                              [%e generateCoreTypeSchemaExpression tuple_type]])
                   )]))]
    | Ptyp_var s -> makeIdentExpr (generateSchemaName s)
    | Ptyp_constr (constr, typeArgs) ->
      generateConstrSchemaExpression constr typeArgs
    | Ptyp_variant (row_fields, _, _) ->
      generatePolyvariantSchemaExpression row_fields
    | Ptyp_object (object_fields, Closed) ->
      object_fields |> List.map parseObjectField |> generateObjectSchema
    | _ -> fail ptyp_loc "Unsupported type")
  | Ok (Some attribute) -> getExpressionFromPayload attribute
  | Error s -> fail ptyp_loc s

let generateTypeDeclarationSchemaExpression type_declaration =
  match type_declaration with
  | {ptype_loc; ptype_kind = Ptype_abstract; ptype_manifest = None} ->
    fail ptype_loc "Can't generate schema for abstract type"
  | {ptype_manifest = Some manifest; _} ->
    generateCoreTypeSchemaExpression manifest
  | {ptype_kind = Ptype_variant decls; _} ->
    generateVariantSchemaExpression decls
  | {ptype_kind = Ptype_record label_declarations; _} ->
    label_declarations |> List.map parseLabelDeclaration |> generateObjectSchema
  | {ptype_loc; _} -> fail ptype_loc "Unsupported type declaration"

let generateSchemaValueBinding type_name schema_expr =
  let schema_name_pat = Pat.var (mknoloc (generateSchemaName type_name)) in
  Vb.mk schema_name_pat
    (Exp.constraint_ schema_expr [%type: [%t Typ.constr (lid type_name) []] S.t])

let mapTypeDeclaration type_declaration =
  let {ptype_attributes; ptype_name = {txt = type_name}; ptype_loc} =
    type_declaration
  in
  match getAttributeByName ptype_attributes "schema" with
  | Ok None -> []
  | Error err -> fail ptype_loc err
  | Ok _ ->
    [
      generateSchemaValueBinding type_name
        (generateTypeDeclarationSchemaExpression type_declaration);
    ]

let mapStructureItem mapper ({pstr_desc} as structure_item) =
  match pstr_desc with
  | Pstr_type (rec_flag, decls) -> (
    let value_bindings = decls |> List.map mapTypeDeclaration |> List.concat in
    [mapper#structure_item structure_item]
    @
    match List.length value_bindings > 0 with
    | true -> [Str.value rec_flag value_bindings]
    | false -> [])
  | _ -> [mapper#structure_item structure_item]
