open Parsetree
open Ast_helper
open Utils

(* TODO: Support Polyvariant args *)
(* TODO: Support @tag *)
(* Polyvariants arguments are wrapped inside a Tuple, meaning that if there's only
   one arg it's the coreType, but if there's more than one arg it's a tuple of one tuple with those args.
   This function abstract this particuliarity from polyvariants (It's different from Variants). *)

(*
   let get_args_from_polyvars ~loc coreTypes =
     match coreTypes with
     | [] -> []
     | [ coreType ] -> (
         match coreType.ptyp_desc with
         (* If it's a tuple, return the args *)
         | Ptyp_tuple coreTypes -> coreTypes
         (* If it's any other coreType, return it *)
         | _ -> [ coreType ])
     | _ ->
         fail loc
           "This error shoudn't happen, means that the AST of your polyvariant is \
            wrong" *)

let parse_decl { prf_desc; prf_loc; prf_attributes } =
  let name =
    match prf_desc with
    | Rtag ({ txt }, _, _) -> txt
    | _ -> failwith "cannot get polymorphic variant constructor"
  in

  let alias =
    match get_attribute_by_name prf_attributes "struct.as" with
    | Ok (Some attribute) -> get_expr_from_payload attribute
    | Ok None -> Exp.constant (Pconst_string (name, Location.none, None))
    | Error s -> fail prf_loc s
  in

  (* TODO: Support other literals besides String *)
  [%expr S.literalVariant (String [%e alias]) [%e Exp.variant name None]]

let generate_struct_expr row_fields =
  let union_items = List.map parse_decl row_fields in
  match union_items with
  | [ item ] -> item
  | _ -> [%expr S.union [%e Exp.array union_items]]
