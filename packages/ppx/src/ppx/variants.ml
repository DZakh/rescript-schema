open Ppxlib
open Parsetree
open Ast_helper
open Utils

let parse_decl { pcd_name = { txt = name } } =
  [%expr S.literal [%e Exp.construct (lid name) None]]

let generate_struct_expr constr_decls =
  let union_items = List.map parse_decl constr_decls in
  match union_items with
  | [ item ] -> item
  | _ -> [%expr S.union [%e Exp.array union_items]]
