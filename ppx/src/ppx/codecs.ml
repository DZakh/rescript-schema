open Ppxlib
open Parsetree
open Ast_helper
open Utils

let rec generate_constr_struct_expr { Location.txt = identifier; loc } type_args
    =
  let open Longident in
  match (identifier, type_args) with
  | Lident "string", _ -> [%expr S.string ()]
  | Lident "int", _ -> [%expr S.int ()]
  | Lident "int64", _ -> fail loc "Can't generate struct for `int64` type"
  | Lident "float", _ -> [%expr S.float ()]
  | Lident "bool", _ -> [%expr S.bool ()]
  | Lident "unit", _ -> [%expr S.unit ()]
  | Lident "unknown", _ -> [%expr S.unknown ()]
  | Ldot (Lident "S", "never"), _ -> [%expr S.never ()]
  | Lident "array", [ item_type ] ->
      [%expr S.array [%e generate_struct_expr item_type]]
  | Lident "list", [ item_type ] ->
      [%expr S.list [%e generate_struct_expr item_type]]
  | Lident "option", [ item_type ] ->
      [%expr S.option [%e generate_struct_expr item_type]]
  | Lident "null", [ item_type ] ->
      [%expr S.null [%e generate_struct_expr item_type]]
  | Lident "result", [ ok_type; error_type ] ->
      [%expr
        S.result
          [%e generate_struct_expr ok_type]
          [%e generate_struct_expr error_type]]
  | Ldot (Ldot (Lident "Js", "Dict"), "t"), [ item_type ]
  | Ldot (Lident "Dict", "t"), [ item_type ] ->
      [%expr S.dict [%e generate_struct_expr item_type]]
  | Ldot (Ldot (Lident "Js", "Json"), "t"), _ | Ldot (Lident "JSON", "t"), _ ->
      [%expr S.jsonable ()]
  | Lident s, _ -> make_ident_expr (get_generated_struct_name s)
  | Ldot (left, right), _ ->
      Exp.ident (mknoloc (Ldot (left, get_generated_struct_name right)))
  | Lapply (_, _), _ -> fail loc "Lapply syntax not handled by rescript-struct"

and generate_struct_expr { ptyp_desc; ptyp_loc; ptyp_attributes } =
  let custom_struct_expr =
    get_attribute_by_name ptyp_attributes "struct.custom"
  in
  match custom_struct_expr with
  | Ok None -> (
      match ptyp_desc with
      | Ptyp_any -> fail ptyp_loc "Can't generate struct for `any` type"
      | Ptyp_arrow (_, _, _) ->
          fail ptyp_loc "Can't generate struct for function type"
      | Ptyp_package _ -> fail ptyp_loc "Can't generate struct for module type"
      | Ptyp_tuple tuple_types ->
          let tuple_struct_exprs = List.map generate_struct_expr tuple_types in
          [%expr S.Tuple.factory [%e Exp.tuple tuple_struct_exprs]]
      | Ptyp_var s -> make_ident_expr (get_generated_struct_name s)
      | Ptyp_constr (constr, typeArgs) ->
          generate_constr_struct_expr constr typeArgs
      | _ -> fail ptyp_loc "This syntax is not yet handled by rescript-struct")
  | Ok (Some attribute) -> get_expr_from_payload attribute
  | Error s -> fail ptyp_loc s
