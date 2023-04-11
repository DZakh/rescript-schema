open Ppxlib
open Parsetree
open Ast_helper
open Utils

let rec parameterize_codecs type_args encoder_func decoder_func =
  let sub_encoders, sub_decoders =
    type_args
    |> List.map (fun core_type -> generate_codecs core_type)
    |> List.split
  in
  ( (match encoder_func with
    | None -> None
    | Some encoder_func ->
        sub_encoders
        |> List.map (fun e -> (Asttypes.Nolabel, Option.get e))
        |> Exp.apply encoder_func |> Option.some),
    match decoder_func with
    | None -> None
    | Some decoder_func ->
        sub_decoders
        |> List.map (fun e -> (Asttypes.Nolabel, Option.get e))
        |> Exp.apply decoder_func |> Option.some )

and generate_constr_codecs { Location.txt = identifier; loc } =
  let open Longident in
  match identifier with
  | Lident "string" ->
      ( (if true then Some [%expr Spice.stringToJson] else None),
        if true then Some [%expr Spice.stringFromJson] else None )
  | Lident "int" ->
      ( (if true then Some [%expr Spice.intToJson] else None),
        if true then Some [%expr Spice.intFromJson] else None )
  | Lident "int64" ->
      ( (if true then Some [%expr Spice.int64ToJson] else None),
        if true then Some [%expr Spice.int64FromJson] else None )
  | Lident "float" ->
      ( (if true then Some [%expr Spice.floatToJson] else None),
        if true then Some [%expr Spice.floatFromJson] else None )
  | Lident "bool" ->
      ( (if true then Some [%expr Spice.boolToJson] else None),
        if true then Some [%expr Spice.boolFromJson] else None )
  | Lident "unit" ->
      ( (if true then Some [%expr Spice.unitToJson] else None),
        if true then Some [%expr Spice.unitFromJson] else None )
  | Lident "array" ->
      ( (if true then Some [%expr Spice.arrayToJson] else None),
        if true then Some [%expr Spice.arrayFromJson] else None )
  | Lident "list" ->
      ( (if true then Some [%expr Spice.listToJson] else None),
        if true then Some [%expr Spice.listFromJson] else None )
  | Lident "option" ->
      ( (if true then Some [%expr Spice.optionToJson] else None),
        if true then Some [%expr Spice.optionFromJson] else None )
  | Ldot (Ldot (Lident "Belt", "Result"), "t") ->
      ( (if true then Some [%expr Spice.resultToJson] else None),
        if true then Some [%expr Spice.resultFromJson] else None )
  | Ldot (Ldot (Lident "Js", "Dict"), "t") ->
      ( (if true then Some [%expr Spice.dictToJson] else None),
        if true then Some [%expr Spice.dictFromJson] else None )
  | Ldot (Ldot (Lident "Js", "Json"), "t") ->
      ( (if true then Some [%expr fun v -> v] else None),
        if true then Some [%expr fun v -> Ok v] else None )
  | Lident s ->
      ( (if true then Some (make_ident_expr (s ^ Utils.encoder_func_suffix))
        else None),
        if true then Some (make_ident_expr (s ^ Utils.decoder_func_suffix))
        else None )
  | Ldot (left, right) ->
      ( (if true then
         Some
           (Exp.ident
              (mknoloc (Ldot (left, right ^ Utils.encoder_func_suffix))))
        else None),
        if true then
          Some
            (Exp.ident
               (mknoloc (Ldot (left, right ^ Utils.decoder_func_suffix))))
        else None )
  | Lapply (_, _) -> fail loc "Lapply syntax not yet handled by rescript-struct"

and generate_codecs { ptyp_desc; ptyp_loc; ptyp_attributes } =
  match ptyp_desc with
  | Ptyp_any -> fail ptyp_loc "Can't generate codecs for `any` type"
  | Ptyp_arrow (_, _, _) ->
      fail ptyp_loc "Can't generate codecs for function type"
  | Ptyp_package _ -> fail ptyp_loc "Can't generate codecs for module type"
  | Ptyp_tuple types ->
      let composite_codecs = List.map generate_codecs types in
      ( (if true then
         Some
           (composite_codecs
           |> List.map (fun (e, _) -> Option.get e)
           |> Tuple.generate_encoder)
        else None),
        if true then
          Some
            (composite_codecs
            |> List.map (fun (_, d) -> Option.get d)
            |> Tuple.generate_decoder)
        else None )
  | Ptyp_var s ->
      ( (if true then Some (make_ident_expr (encoder_var_prefix ^ s)) else None),
        if true then Some (make_ident_expr (decoder_var_prefix ^ s)) else None
      )
  | Ptyp_constr (constr, typeArgs) -> (
      let custom_codec = get_attribute_by_name ptyp_attributes "struct.codec" in
      let encode, decode =
        match custom_codec with
        | Ok None -> generate_constr_codecs constr
        | Ok (Some attribute) ->
            let expr = get_expression_from_payload attribute in
            ( (if true then
               Some
                 [%expr
                   let e, _ = [%e expr] in
                   e]
              else None),
              if true then
                Some
                  [%expr
                    let _, d = [%e expr] in
                    d]
              else None )
        | Error s -> fail ptyp_loc s
      in
      match List.length typeArgs = 0 with
      | true -> (encode, decode)
      | false -> parameterize_codecs typeArgs encode decode)
  | _ -> fail ptyp_loc "This syntax is not yet handled by rescript-struct"
