open Ppxlib
open Parsetree
open Ast_helper

let loc = !default_loc
let fail loc message =
  Location.raise_errorf ~loc "[rescript-schema-ppx] %s" message
let longident_parse = Longident.parse [@@ocaml.warning "-3"]
let mkloc txt loc = {Location.txt; loc}
let mknoloc txt = mkloc txt Location.none
let lid ?(loc = Location.none) s = mkloc (Longident.parse s) loc
let makeIdentExpr ?attrs s = Exp.ident ?attrs (mknoloc (longident_parse s))

let getAttributeByName attributes name =
  let filtered =
    attributes |> List.filter (fun {attr_name = {Location.txt}} -> txt = name)
  in
  match filtered with
  | [] -> Ok None
  | [attribute] -> Ok (Some attribute)
  | _ -> Error ("Too many occurrences of \"" ^ name ^ "\" attribute")

let getExpressionFromPayload {attr_name = {loc}; attr_payload = payload} =
  match payload with
  | PStr [{pstr_desc}] -> (
    match pstr_desc with
    | Pstr_eval (expr, _) -> expr
    | _ -> fail loc "Expected expression as attribute payload")
  | _ -> fail loc "Expected expression as attribute payload"

let generateSchemaName type_name =
  match type_name with
  | "t" -> "schema"
  | _ -> type_name ^ "Schema"
