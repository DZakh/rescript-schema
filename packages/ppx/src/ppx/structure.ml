open Ppxlib
open Parsetree
open Ast_helper
open Utils

let generate_decls type_name struct_expr =
  let struct_name_pat =
    Pat.var (mknoloc (get_generated_struct_name type_name))
  in
  [
    Vb.mk struct_name_pat
      (Exp.constraint_ struct_expr
         [%type: [%t Typ.constr (lid type_name) []] S.t]);
  ]

let map_type_decl decl =
  let {
    ptype_attributes;
    ptype_name = { txt = type_name };
    ptype_manifest;
    ptype_loc;
    ptype_kind;
  } =
    decl
  in

  match
    (get_attribute_by_name ptype_attributes "struct", ptype_manifest, ptype_kind)
  with
  | Ok None, _, _ -> []
  | Error err, _, _ -> fail ptype_loc err
  | Ok _, None, Ptype_abstract ->
      fail ptype_loc "Can't generate struct for unspecified type"
  | Ok _, Some { ptyp_desc = Ptyp_variant (row_fields, _, _) }, Ptype_abstract
    ->
      generate_decls type_name (Polyvariants.generate_struct_expr row_fields)
  | Ok _, Some manifest, _ ->
      generate_decls type_name (Codecs.generate_struct_expr manifest)
  | Ok _, None, Ptype_variant decls ->
      generate_decls type_name (Variants.generate_struct_expr decls)
  | Ok _, None, Ptype_record decls ->
      generate_decls type_name (Records.generate_struct_expr decls)
  | _ -> fail ptype_loc "This type is not handled by rescript-struct"

let map_structure_item mapper ({ pstr_desc } as structure_item) =
  match pstr_desc with
  | Pstr_type (rec_flag, decls) -> (
      let value_bindings = decls |> List.map map_type_decl |> List.concat in
      [ mapper#structure_item structure_item ]
      @
      match List.length value_bindings > 0 with
      | true -> [ Str.value rec_flag value_bindings ]
      | false -> [])
  | _ -> [ mapper#structure_item structure_item ]
