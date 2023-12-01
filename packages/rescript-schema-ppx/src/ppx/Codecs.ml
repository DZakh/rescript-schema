open Ppxlib
open Parsetree
open Ast_helper
open Util

let rec generate_constr_schema_expr {Location.txt = identifier; loc} type_args =
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
    [%expr S.array [%e generateSchemaExpression item_type]]
  | Lident "list", [item_type] ->
    [%expr S.list [%e generateSchemaExpression item_type]]
  | Lident "option", [item_type] ->
    [%expr S.option [%e generateSchemaExpression item_type]]
  | Lident "null", [item_type] ->
    [%expr S.null [%e generateSchemaExpression item_type]]
  | Ldot (Ldot (Lident "Js", "Dict"), "t"), [item_type]
  | Ldot (Lident "Dict", "t"), [item_type] ->
    [%expr S.dict [%e generateSchemaExpression item_type]]
  | Lident s, _ -> makeIdentExpr (generateSchemaName s)
  | Ldot (left, right), _ ->
    Exp.ident (mknoloc (Ldot (left, generateSchemaName right)))
  | Lapply (_, _), _ ->
    fail loc "Lapply syntax not handled by rescript-schema-ppx"

and generateSchemaExpression {ptyp_desc; ptyp_loc; ptyp_attributes} =
  let custom_schema_expr = getAttributeByName ptyp_attributes "schema" in
  match custom_schema_expr with
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
                              [%e generateSchemaExpression tuple_type]]))]))]
    | Ptyp_var s -> makeIdentExpr (generateSchemaName s)
    | Ptyp_constr (constr, typeArgs) ->
      generate_constr_schema_expr constr typeArgs
    | _ -> fail ptyp_loc "This syntax is not yet handled by rescript-schema-ppx"
    )
  | Ok (Some attribute) -> getExpressionFromPayload attribute
  | Error s -> fail ptyp_loc s
