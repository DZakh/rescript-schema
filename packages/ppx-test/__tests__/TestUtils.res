open Ava

module Stdlib = {
  module Dict = {
    @val
    external copy: (@as(json`{}`) _, Js.Dict.t<'a>) => Js.Dict.t<'a> = "Object.assign"

    let omit = (dict: Js.Dict.t<'a>, fields: array<string>): Js.Dict.t<'a> => {
      let dict = dict->copy
      fields->Js.Array2.forEach(field => {
        Js.Dict.unsafeDeleteKey(dict, field)
      })
      dict
    }
  }
}

external magic: 'a => 'b = "%identity"

let assertEqualStructs = {
  let cleanUpTransformationFactories = (struct: S.t<'v>): S.t<'v> => {
    struct->Obj.magic->Stdlib.Dict.omit(["pf", "sf"])->Obj.magic
  }
  (t, s1, s2, ~message=?, ()) => {
    t->Assert.deepEqual(
      s1->cleanUpTransformationFactories,
      s2->cleanUpTransformationFactories,
      ~message?,
      (),
    )
  }
}
