open Ppxlib
open Parsetree
open Ast_helper
open Utils

let generate_struct_signature_item ~type_declaration =
  let { ptype_name = { txt = type_name } } = type_declaration in

  let struct_name = get_generated_struct_name type_name in

  [%type: [%t Typ.constr (lid type_name) []] S.t]
  |> Val.mk (mknoloc struct_name)
  |> Sig.value

let map_signature_item mapper ({ psig_desc } as signature_item) =
  match psig_desc with
  | Psig_type (_, decls) ->
      let generated_sig_items =
        decls
        |> List.map (fun type_declaration ->
               match
                 Utils.get_attribute_by_name type_declaration.ptype_attributes
                   "struct"
               with
               | Error err -> fail type_declaration.ptype_loc err
               | Ok None -> []
               | Ok (Some _) ->
                   [ generate_struct_signature_item ~type_declaration ])
        |> List.concat
      in
      mapper#signature_item signature_item :: generated_sig_items
  | _ -> [ mapper#signature_item signature_item ]
