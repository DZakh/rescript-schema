open Ppxlib
open Parsetree
open Ast_helper
open Utils

let rec generate_constr_schema_expr { Location.txt = identifier; loc } type_args
    =
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
  | Lident "array", [ item_type ] ->
      [%expr S.array [%e generate_schema_expr item_type]]
  | Lident "list", [ item_type ] ->
      [%expr S.list [%e generate_schema_expr item_type]]
  | Lident "option", [ item_type ] ->
      [%expr S.option [%e generate_schema_expr item_type]]
  | Lident "null", [ item_type ] ->
      [%expr S.null [%e generate_schema_expr item_type]]
  | Ldot (Ldot (Lident "Js", "Dict"), "t"), [ item_type ]
  | Ldot (Lident "Dict", "t"), [ item_type ] ->
      [%expr S.dict [%e generate_schema_expr item_type]]
  | Lident s, _ -> make_ident_expr (get_generated_schema_name s)
  | Ldot (left, right), _ ->
      Exp.ident (mknoloc (Ldot (left, get_generated_schema_name right)))
  | Lapply (_, _), _ -> fail loc "Lapply syntax not handled by rescript-schema"

and generate_schema_expr { ptyp_desc; ptyp_loc; ptyp_attributes } =
  let custom_schema_expr = get_attribute_by_name ptyp_attributes "schema" in
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
                                  [%e generate_schema_expr tuple_type]]))]))]
      | Ptyp_var s -> make_ident_expr (get_generated_schema_name s)
      | Ptyp_constr (constr, typeArgs) ->
          generate_constr_schema_expr constr typeArgs
      | _ -> fail ptyp_loc "This syntax is not yet handled by rescript-schema")
  | Ok (Some attribute) -> get_expr_from_payload attribute
  | Error s -> fail ptyp_loc s
