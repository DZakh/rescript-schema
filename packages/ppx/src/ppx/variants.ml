open Ppxlib
open Parsetree
open Ast_helper
open Utils

let parse_decl { pcd_name = { txt = name }; pcd_loc; pcd_attributes } =
  let alias =
    match get_attribute_by_name pcd_attributes "as" with
    | Ok (Some attribute) -> get_expr_from_payload attribute
    | Ok None -> Exp.constant (Pconst_string (name, Location.none, None))
    | Error s -> fail pcd_loc s
  in

  (* TODO: Support other literals besides String *)
  [%expr
    S.literalVariant (String [%e alias]) [%e Exp.construct (lid name) None]]

let generate_struct_expr constr_decls =
  let union_items = List.map parse_decl constr_decls in
  match union_items with
  | [ item ] -> item
  | _ -> [%expr S.union [%e Exp.array union_items]]
