open Ppxlib
open Parsetree
open Ast_helper
open Utils

let generate_struct_signature_item ~type_declaration =
  let { ptype_name = { txt = type_name } } = type_declaration in

  let struct_name = get_generated_struct_name type_name in

  [%type: [%t Typ.var type_name] S.t]
  |> Val.mk (mknoloc struct_name)
  |> Sig.value

let map_signature_item mapper ({ psig_desc } as signature_item) =
  match psig_desc with
  | Psig_type (_, decls) ->
      let generated_sig_items =
        decls
        |> List.map (fun type_declaration ->
               generate_struct_signature_item ~type_declaration)
      in
      mapper#signature_item signature_item :: generated_sig_items
  | _ -> [ mapper#signature_item signature_item ]
