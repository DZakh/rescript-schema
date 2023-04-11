open Ppxlib
open Parsetree
open Ast_helper
open Utils

type parsed_decl = {
  name : string;
  alias : expression;
  has_attr_as : bool;
  constr_decl : Parsetree.constructor_declaration;
}

let generate_encoder_case unboxed has_attr_as
    { name; alias; constr_decl = { pcd_args; pcd_loc } } =
  match pcd_args with
  | Pcstr_tuple args ->
      let alias_name, _, delimit = get_string_from_expression alias in
      let constructor_expr =
        Exp.constant (Pconst_string (alias_name, Location.none, delimit))
      in
      let lhs_vars =
        match args with
        | [] -> None
        | [ _ ] -> Some (Pat.var (mknoloc "v0"))
        | _ ->
            args
            |> List.mapi (fun i _ ->
                   mkloc ("v" ^ string_of_int i) pcd_loc |> Pat.var)
            |> Pat.tuple
            |> fun v -> Some v
      in
      let rhs_list =
        args
        |> List.map Codecs.generate_codecs
        |> List.map (fun (encoder, _) -> Option.get encoder)
        |> List.mapi (fun i e ->
               Exp.apply ~loc:pcd_loc e
                 [ (Asttypes.Nolabel, make_ident_expr ("v" ^ string_of_int i)) ])
        |> List.append [ [%expr Js.Json.string [%e constructor_expr]] ]
      in

      {
        pc_lhs = Pat.construct (lid name) lhs_vars;
        pc_guard = None;
        pc_rhs =
          (if unboxed then List.tl rhs_list |> List.hd
          else if has_attr_as then [%expr Js.Json.string [%e constructor_expr]]
          else [%expr Js.Json.array [%e rhs_list |> Exp.array]]);
      }
  | Pcstr_record _ ->
      fail pcd_loc "This syntax is not yet implemented by rescript-struct"

let generate_decode_success_case num_args constructor_name =
  {
    pc_lhs =
      Array.init num_args (fun i ->
          mknoloc ("v" ^ string_of_int i) |> Pat.var |> fun p ->
          [%pat? Ok [%p p]])
      |> Array.to_list
      |> tuple_or_singleton Pat.tuple;
    pc_guard = None;
    pc_rhs =
      ( Array.init num_args (fun i -> make_ident_expr ("v" ^ string_of_int i))
      |> Array.to_list
      |> tuple_or_singleton Exp.tuple
      |> fun v ->
        Some v |> Exp.construct (lid constructor_name) |> fun e ->
        [%expr Ok [%e e]] );
  }

let generate_arg_decoder args constructor_name =
  let num_args = List.length args in
  args
  |> List.mapi (Decode_cases.generate_error_case num_args)
  |> List.append [ generate_decode_success_case num_args constructor_name ]
  |> Exp.match_
       (args
       |> List.map Codecs.generate_codecs
       |> List.mapi (fun i (_, decoder) ->
              Exp.apply (Option.get decoder)
                [
                  ( Asttypes.Nolabel,
                    (* +1 because index 0 is the constructor *)
                    let idx =
                      Pconst_integer (string_of_int (i + 1), None)
                      |> Exp.constant
                    in
                    [%expr Belt.Array.getExn json_arr [%e idx]] );
                ])
       |> tuple_or_singleton Exp.tuple)

let generate_decoder_case { pcd_name = { txt = name }; pcd_args; pcd_loc } =
  match pcd_args with
  | Pcstr_tuple args ->
      let arg_len =
        Pconst_integer (string_of_int (List.length args + 1), None)
        |> Exp.constant
      in
      let decoded =
        match args with
        | [] ->
            let ident = lid name in
            [%expr Ok [%e Exp.construct ident None]]
        | _ -> generate_arg_decoder args name
      in

      {
        pc_lhs =
          ( Pconst_string (name, Location.none, None) |> Pat.constant |> fun v ->
            Some v |> Pat.construct (lid "Js.Json.JSONString") );
        pc_guard = None;
        pc_rhs =
          [%expr
            if Js.Array.length tagged <> [%e arg_len] then
              Spice.error "Invalid number of arguments to variant constructor" v
            else [%e decoded]];
      }
  | Pcstr_record _ ->
      fail pcd_loc "This syntax is not yet implemented by rescript-struct"

let generate_decoder_case_attr
    { name; alias; constr_decl = { pcd_args; pcd_loc } } =
  match pcd_args with
  | Pcstr_tuple args ->
      let alias_name, _, delimit = get_string_from_expression alias in
      let decoded =
        match args with
        | [] ->
            let ident = lid name in
            [%expr Ok [%e Exp.construct ident None]]
        | _ -> generate_arg_decoder args name
      in

      let if' =
        Exp.apply (make_ident_expr "=")
          [
            ( Asttypes.Nolabel,
              Pconst_string (alias_name, Location.none, delimit) |> Exp.constant
            );
            (Asttypes.Nolabel, [%expr str]);
          ]
      in
      let then' = [%expr [%e decoded]] in

      (if', then')
  | Pcstr_record _ ->
      fail pcd_loc "This syntax is not yet implemented by rescript-struct"

let generate_unboxed_decode { pcd_name = { txt = name }; pcd_args; pcd_loc } =
  match pcd_args with
  | Pcstr_tuple args -> (
      match args with
      | [ a ] -> (
          let _, d = Codecs.generate_codecs a in
          match d with
          | Some d ->
              let constructor = Exp.construct (lid name) (Some [%expr v]) in

              Some
                [%expr
                  fun v ->
                    Belt.Result.map ([%e d] v) (fun v -> [%e constructor])]
          | None -> None)
      | _ -> fail pcd_loc "Expected exactly one type argument")
  | Pcstr_record _ ->
      fail pcd_loc "This syntax is not yet implemented by rescript-struct"

let parse_decl ({ pcd_name = { txt }; pcd_loc; pcd_attributes } as constr_decl)
    =
  let alias, has_attr_as =
    match get_attribute_by_name pcd_attributes "struct.as" with
    | Ok (Some attribute) -> (get_expression_from_payload attribute, true)
    | Ok None -> (Exp.constant (Pconst_string (txt, Location.none, None)), false)
    | Error s -> (fail pcd_loc s, false)
  in

  { name = txt; alias; has_attr_as; constr_decl }

let generate_codecs constr_decls unboxed =
  let parsed_decls = List.map parse_decl constr_decls in
  let count_has_attr =
    parsed_decls |> List.filter (fun v -> v.has_attr_as) |> List.length
  in
  let has_attr_as =
    if count_has_attr > 0 then
      if count_has_attr = List.length parsed_decls then true
      else failwith "Partial @struct.as usage is not allowed"
    else false
  in

  let encoder =
    if true then
      Some
        (parsed_decls
        |> List.map (generate_encoder_case unboxed has_attr_as)
        |> Exp.match_ [%expr v]
        |> Exp.fun_ Asttypes.Nolabel None [%pat? v])
    else None
  in

  let decoder =
    match not true with
    | true -> None
    | false ->
        if unboxed then generate_unboxed_decode (List.hd constr_decls)
        else if has_attr_as then
          let rec make_ifthenelse cases =
            match cases with
            | [] -> [%expr Spice.error "Not matched" v]
            | hd :: tl ->
                let if_, then_ = hd in
                Exp.ifthenelse if_ then_ (Some (make_ifthenelse tl))
          in

          let decoder_switch =
            List.map generate_decoder_case_attr parsed_decls |> make_ifthenelse
          in

          Some
            [%expr
              fun v ->
                match Js.Json.classify v with
                | Js.Json.JSONString str -> [%e decoder_switch]
                | _ -> Spice.error "Not a JSONString" v]
        else
          let decoder_default_case =
            {
              pc_lhs = [%pat? _];
              pc_guard = None;
              pc_rhs =
                [%expr
                  Spice.error "Invalid variant constructor"
                    (Belt.Array.getExn json_arr 0)];
            }
          in

          let decoder_switch =
            constr_decls |> List.map generate_decoder_case |> fun l ->
            l @ [ decoder_default_case ]
            |> Exp.match_ [%expr Belt.Array.getExn tagged 0]
          in

          Some
            [%expr
              fun v ->
                match Js.Json.classify v with
                | Js.Json.JSONArray [||] ->
                    Spice.error "Expected variant, found empty array" v
                | Js.Json.JSONArray json_arr ->
                    let tagged = Js.Array.map Js.Json.classify json_arr in
                    [%e decoder_switch]
                | _ -> Spice.error "Not a variant" v]
  in

  (encoder, decoder)
