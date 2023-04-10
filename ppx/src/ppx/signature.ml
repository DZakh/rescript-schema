open Ppxlib
open Parsetree
open Utils

let rec add_encoder_params param_names result_type =
  match param_names with
  | [] -> result_type
  | hd :: tl ->
      [%type: ([%t Ast_helper.Typ.var hd] -> Js.Json.t) -> [%t result_type]]
      |> add_encoder_params tl

let make_result_type value_type =
  [%type: ([%t value_type], Spice.decodeError) Belt.Result.t]

let rec add_decoder_params param_names result_type =
  match param_names with
  | [] -> result_type
  | hd :: tl ->
      let decoder_param =
        [%type: Js.Json.t -> [%t make_result_type (Ast_helper.Typ.var hd)]]
      in
      [%type: [%t decoder_param] -> [%t result_type]] |> add_decoder_params tl

let generate_sig_decls { do_encode; do_decode } type_name param_names =
  let encoder_pat = type_name ^ Utils.encoder_func_suffix in
  let decoder_pat = type_name ^ Utils.decoder_func_suffix in
  let value_type =
    param_names
    |> List.map Ast_helper.Typ.var
    |> Ast_helper.Typ.constr (lid type_name)
  in

  let decls = [] in

  let decls =
    match do_encode with
    | true ->
        decls
        @ [
            [%type: [%t value_type] -> Js.Json.t]
            |> add_encoder_params (List.rev param_names)
            |> Ast_helper.Val.mk (mknoloc encoder_pat)
            |> Ast_helper.Sig.value;
          ]
    | false -> decls
  in
  let decls =
    match do_decode with
    | true ->
        decls
        @ [
            [%type: Js.Json.t -> [%t make_result_type value_type]]
            |> add_decoder_params (List.rev param_names)
            |> Ast_helper.Val.mk (mknoloc decoder_pat)
            |> Ast_helper.Sig.value;
          ]
    | false -> decls
  in

  decls

let map_type_decl decl =
  let {
    ptype_attributes;
    ptype_name = { txt = type_name };
    ptype_params;
    ptype_loc;
  } =
    decl
  in

  match get_generator_settings_from_attributes ptype_attributes with
  | Error s -> fail ptype_loc s
  | Ok None -> []
  | Ok (Some generator_settings) ->
      generate_sig_decls generator_settings type_name
        (get_param_names ptype_params)

let map_signature_item mapper ({ psig_desc } as signature_item) =
  match psig_desc with
  | Psig_type (_, decls) ->
      let generated_sig_items =
        decls |> List.map map_type_decl |> List.concat
      in
      mapper#signature_item signature_item :: generated_sig_items
  | _ -> [ mapper#signature_item signature_item ]
