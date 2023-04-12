open Ppxlib
open Parsetree
open Ast_helper
open Utils

let rec parameterize_codecs type_args decoder_func =
  let sub_decoders =
    type_args |> List.map (fun core_type -> generate_struct_expr core_type)
  in

  sub_decoders
  |> List.map (fun e -> (Asttypes.Nolabel, e))
  |> Exp.apply decoder_func

and generate_constr_codecs { Location.txt = identifier; loc } =
  let open Longident in
  match identifier with
  | Lident "string" -> [%expr Spice.stringFromJson]
  | Lident "int" -> [%expr Spice.intFromJson]
  | Lident "int64" -> [%expr Spice.int64FromJson]
  | Lident "float" -> [%expr Spice.floatFromJson]
  | Lident "bool" -> [%expr Spice.boolFromJson]
  | Lident "unit" -> [%expr Spice.unitFromJson]
  | Lident "array" -> [%expr Spice.arrayFromJson]
  | Lident "list" -> [%expr Spice.listFromJson]
  | Lident "option" -> [%expr Spice.optionFromJson]
  | Ldot (Ldot (Lident "Belt", "Result"), "t") -> [%expr Spice.resultFromJson]
  | Ldot (Ldot (Lident "Js", "Dict"), "t") -> [%expr Spice.dictFromJson]
  | Ldot (Ldot (Lident "Js", "Json"), "t") -> [%expr fun v -> Ok v]
  | Lident s -> make_ident_expr (s ^ Utils.decoder_func_suffix)
  | Ldot (left, right) ->
      Exp.ident (mknoloc (Ldot (left, right ^ Utils.decoder_func_suffix)))
  | Lapply (_, _) -> fail loc "Lapply syntax not yet handled by rescript-struct"

and generate_struct_expr { ptyp_desc; ptyp_loc; ptyp_attributes } =
  match ptyp_desc with
  | Ptyp_any -> fail ptyp_loc "Can't generate codecs for `any` type"
  | Ptyp_arrow (_, _, _) ->
      fail ptyp_loc "Can't generate codecs for function type"
  | Ptyp_package _ -> fail ptyp_loc "Can't generate codecs for module type"
  | Ptyp_tuple types ->
      let composite_codecs = List.map generate_struct_expr types in
      composite_codecs |> Tuple.generate_decoder
  | Ptyp_var s -> make_ident_expr (decoder_var_prefix ^ s)
  | Ptyp_constr (constr, typeArgs) -> (
      let custom_codec = get_attribute_by_name ptyp_attributes "struct.codec" in
      let decode =
        match custom_codec with
        | Ok None -> generate_constr_codecs constr
        | Ok (Some attribute) ->
            let expr = get_expression_from_payload attribute in
            [%expr
              let _, d = [%e expr] in
              d]
        | Error s -> fail ptyp_loc s
      in
      match List.length typeArgs = 0 with
      | true -> decode
      | false -> parameterize_codecs typeArgs decode)
  | _ -> fail ptyp_loc "This syntax is not yet handled by rescript-struct"
