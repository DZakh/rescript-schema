open Ppxlib

class mapper =
  object (self)
    inherit Ast_traverse.map

    method! signature sign =
      sign |> List.map (Signature.map_signature_item self) |> List.concat

    method! structure strt =
      strt |> List.map (Structure.map_structure_item self) |> List.concat
  end

let signature_mapper = (new mapper)#signature

let structure_mapper = (new mapper)#structure;;

Ppxlib.Driver.register_transformation ~preprocess_impl:structure_mapper
  ~preprocess_intf:signature_mapper "struct"
