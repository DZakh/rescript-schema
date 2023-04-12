open Ppxlib
open Parsetree
open Ast_helper
open Utils

let generate_decode_success_case num_args =
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
      |> Array.to_list |> Exp.tuple
      |> fun e -> [%expr Ok [%e e]] );
  }

let generate_decode_switch composite_decoders =
  let decode_expr =
    composite_decoders
    |> List.mapi (fun i d ->
           let ident = make_ident_expr ("v" ^ string_of_int i) in
           [%expr [%e d] [%e ident]])
    |> Exp.tuple
  in
  composite_decoders
  |> List.mapi
       (Decode_cases.generate_error_case (List.length composite_decoders))
  |> List.append
       [ generate_decode_success_case (List.length composite_decoders) ]
  |> Exp.match_ decode_expr

let generate_decoder composite_decoders =
  let match_arr_pattern =
    composite_decoders
    |> List.mapi (fun i _ -> Pat.var (mknoloc ("v" ^ string_of_int i)))
    |> Pat.array
  in
  let match_pattern = [%pat? Js.Json.JSONArray [%p match_arr_pattern]] in
  let outer_switch =
    Exp.match_ [%expr Js.Json.classify json]
      [
        Exp.case match_pattern (generate_decode_switch composite_decoders);
        Exp.case
          [%pat? Js.Json.JSONArray _]
          [%expr Spice.error "Incorrect cardinality" json];
        Exp.case [%pat? _] [%expr Spice.error "Not a tuple" json];
      ]
  in
  [%expr fun json -> [%e outer_switch]]
