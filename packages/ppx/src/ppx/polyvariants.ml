open Parsetree
open Ast_helper
open Utils

let parse_decl { prf_desc } =
  let name =
    match prf_desc with
    | Rtag ({ txt }, _, _) -> txt
    | _ -> failwith "cannot get polymorphic variant constructor"
  in

  [%expr S.literal [%e Exp.variant name None]]

let generate_struct_expr row_fields =
  let union_items = List.map parse_decl row_fields in
  match union_items with
  | [ item ] -> item
  | _ -> [%expr S.union [%e Exp.array union_items]]
