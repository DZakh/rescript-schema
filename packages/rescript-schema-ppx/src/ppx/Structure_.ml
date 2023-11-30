open Ppxlib
open Parsetree
open Ast_helper
open Util

let generate_decls type_name schema_expr =
  let schema_name_pat =
    Pat.var (mknoloc (get_generated_schema_name type_name))
  in
  [
    Vb.mk schema_name_pat
      (Exp.constraint_ schema_expr
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
    (get_attribute_by_name ptype_attributes "schema", ptype_manifest, ptype_kind)
  with
  | Ok None, _, _ -> []
  | Error err, _, _ -> fail ptype_loc err
  | Ok _, None, Ptype_abstract ->
      fail ptype_loc "Can't generate schema for unspecified type"
  | Ok _, Some { ptyp_desc = Ptyp_variant (row_fields, _, _) }, Ptype_abstract
    ->
      generate_decls type_name (Polyvariants_.generate_schema_expr row_fields)
  | Ok _, Some manifest, _ ->
      generate_decls type_name (Codecs_.generate_schema_expr manifest)
  | Ok _, None, Ptype_variant decls ->
      generate_decls type_name (Variants_.generate_schema_expr decls)
  | Ok _, None, Ptype_record decls ->
      generate_decls type_name (Records_.generate_schema_expr decls)
  | _ -> fail ptype_loc "This type is not handled by rescript-schema"

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
