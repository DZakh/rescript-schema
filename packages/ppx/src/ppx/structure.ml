open Ppxlib
open Parsetree
open Ast_helper
open Codecs
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

  let is_unboxed =
    match Utils.get_attribute_by_name ptype_attributes "unboxed" with
    | Ok (Some _) -> true
    | _ -> false
  in

  match (ptype_manifest, ptype_kind) with
  | None, Ptype_abstract ->
      fail ptype_loc "Can't generate struct for unspecified type"
  | Some { ptyp_desc = Ptyp_variant (row_fields, _, _) }, Ptype_abstract ->
      generate_decls type_name
        (Polyvariants.generate_struct_expr row_fields is_unboxed)
  | Some manifest, _ -> generate_decls type_name (generate_struct_expr manifest)
  | None, Ptype_variant decls ->
      generate_decls type_name (Variants.generate_struct_expr decls is_unboxed)
  | None, Ptype_record decls ->
      generate_decls type_name (Records.generate_struct_expr decls is_unboxed)
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
