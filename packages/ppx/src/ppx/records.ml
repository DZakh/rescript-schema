open Ppxlib
open Parsetree
open Ast_helper
open Utils

(* TODO: Support recursive types *)
(* TODO: Move default from here *)
(* TODO: check optional *)

type parsed_decl = {
  name : string;
  (* "NAME" *)
  key : expression;
  (* v.NAME *)
  field : expression;
  struct_expr : expression;
  default : expression option;
  is_optional : bool;
}

let generate_decoder decls =
  (* Use Obj.magic to cast to uncurried function in case of uncurried mode *)
  [%expr
    S.Object.factory
      (Obj.magic (fun (s : S.Object.ctx) ->
           [%e
             Exp.record
               (decls
               |> List.map (fun decl ->
                      ( lid decl.name,
                        [%expr s.field [%e decl.key] [%e decl.struct_expr]] )))
               None]))]

let parse_decl { pld_name = { txt }; pld_loc; pld_type; pld_attributes } =
  let default =
    match get_attribute_by_name pld_attributes "struct.default" with
    | Ok (Some attribute) -> Some (get_expr_from_payload attribute)
    | Ok None -> None
    | Error s -> fail pld_loc s
  in
  let key =
    match get_attribute_by_name pld_attributes "struct.field" with
    | Ok (Some attribute) -> get_expr_from_payload attribute
    | Ok None -> Exp.constant (Pconst_string (txt, Location.none, None))
    | Error s -> fail pld_loc s
  in
  let optional_attrs = [ "ns.optional"; "res.optional" ] in
  let is_optional =
    optional_attrs
    |> List.map (fun attr -> get_attribute_by_name pld_attributes attr)
    |> List.exists (function Ok (Some _) -> true | _ -> false)
  in
  let struct_expr = Codecs.generate_struct_expr pld_type in
  let struct_expr =
    if is_optional then [%expr Obj.magic S.option [%e struct_expr]]
    else struct_expr
  in

  {
    name = txt;
    key;
    field = Exp.field [%expr v] (lid txt);
    struct_expr;
    default;
    is_optional;
  }

let generate_struct_expr decls =
  let parsed_decls = List.map parse_decl decls in
  generate_decoder parsed_decls
