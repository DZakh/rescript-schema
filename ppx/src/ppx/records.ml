open Ppxlib
open Parsetree
open Ast_helper
open Utils

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

let optional_attr : Ppxlib.Parsetree.attribute =
  {
    attr_name = { txt = "ns.optional"; loc = Location.none };
    attr_payload = PStr [];
    attr_loc = Location.none;
  }

let generate_dict_get { key; struct_expr; default } =
  match default with
  | Some default ->
      [%expr
        Belt.Option.getWithDefault
          (Belt.Option.map (Js.Dict.get dict [%e key]) [%e struct_expr])
          (Ok [%e default])]
  | None ->
      [%expr
        Belt.Option.getWithDefault (Js.Dict.get dict [%e key]) Js.Json.null
        |> [%e struct_expr]]

let generate_dict_gets decls =
  decls |> List.map generate_dict_get |> tuple_or_singleton Exp.tuple

let generate_error_case { key } =
  {
    pc_lhs = [%pat? Error (e : Spice.decodeError)];
    pc_guard = None;
    pc_rhs = [%expr Error { e with path = "." ^ [%e key] ^ e.path }];
  }

let generate_final_record_expr decls =
  decls
  |> List.map (fun { name; is_optional } ->
         let attrs = if is_optional then [ optional_attr ] else [] in
         (lid name, make_ident_expr ~attrs name))
  |> fun l -> [%expr Ok [%e Exp.record l None]]

let generate_success_case { name } success_expr =
  {
    pc_lhs = (mknoloc name |> Pat.var |> fun p -> [%pat? Ok [%p p]]);
    pc_guard = None;
    pc_rhs = success_expr;
  }

let rec generate_nested_switches_recurse all_decls remaining_decls =
  let current, success_expr =
    match remaining_decls with
    | [] -> failwith "Spice internal error: [] not expected"
    | [ last ] -> (last, generate_final_record_expr all_decls)
    | first :: tail -> (first, generate_nested_switches_recurse all_decls tail)
  in
  [ generate_error_case current ]
  |> List.append [ generate_success_case current success_expr ]
  |> Exp.match_ (generate_dict_get current)
  [@@ocaml.doc
    " Recursively generates an expression containing nested switches, first\n\
    \ *  decoding the first record items, then (if successful) the second, \
     etc. "]

let generate_nested_switches decls =
  generate_nested_switches_recurse decls decls

let generate_decoder decls unboxed =
  match unboxed with
  | true ->
      let { struct_expr; name } = List.hd decls in

      let record_expr = Exp.record [ (lid name, make_ident_expr "v") ] None in

      [%expr fun v -> map ([%e struct_expr] v) (fun v -> [%e record_expr])]
  | false ->
      [%expr
        fun v ->
          match Js.Json.classify v with
          | Js.Json.JSONObject dict -> [%e generate_nested_switches decls]
          | _ -> Spice.error "Not an object" v]

let parse_decl { pld_name = { txt }; pld_loc; pld_type; pld_attributes } =
  let default =
    match get_attribute_by_name pld_attributes "struct.default" with
    | Ok (Some attribute) -> Some (get_expr_from_payload attribute)
    | Ok None -> None
    | Error s -> fail pld_loc s
  in
  let key =
    match get_attribute_by_name pld_attributes "struct.key" with
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
    if is_optional then [%expr Spice.optionFromJson [%e struct_expr]]
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

let generate_struct_expr decls unboxed =
  let parsed_decls = List.map parse_decl decls in
  generate_decoder parsed_decls unboxed
