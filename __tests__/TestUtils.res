open Ava

external magic: 'a => 'b = "%identity"
external castAnyToUnknown: 'any => unknown = "%identity"
external castUnknownToAny: unknown => 'any = "%identity"

let rec cleanUpStruct = struct => {
  let new = Js.Dict.empty()
  struct
  ->(magic: S.t<'a> => Js.Dict.t<unknown>)
  ->Js.Dict.entries
  ->Js.Array2.forEach(((key, value)) => {
    switch key {
    | "sb" | "pb" | "i" => ()
    | _ =>
      if Js.typeof(value) === "object" && value !== %raw(`null`) {
        new->Js.Dict.set(
          key,
          cleanUpStruct(value->(magic: unknown => S.t<'a>))->(magic: S.t<'a> => unknown),
        )
      } else {
        new->Js.Dict.set(key, value)
      }
    }
  })
  new->(magic: Js.Dict.t<unknown> => S.t<'a>)
}

let unsafeAssertEqualStructs = {
  (t, s1: S.t<'v1>, s2: S.t<'v2>, ~message=?, ()) => {
    t->Assert.unsafeDeepEqual(s1->cleanUpStruct, s2->cleanUpStruct, ~message?, ())
  }
}

let assertEqualStructs: (
  Ava.ExecutionContext.t<'a>,
  RescriptStruct.S.t<'value>,
  RescriptStruct.S.t<'value>,
  ~message: string=?,
  unit,
) => unit = unsafeAssertEqualStructs
