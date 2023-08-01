open Ava

external magic: 'a => 'b = "%identity"
external castAnyToUnknown: 'any => unknown = "%identity"
external castUnknownToAny: unknown => 'any = "%identity"

exception Test
let raiseTestException = () => raise(Test)

let assertThrowsTestException = {
  (t, fn, ~message=?, ()) => {
    try {
      let _ = fn()
      t->Assert.fail("Didn't throw")
    } catch {
    | Test => t->Assert.pass(~message?, ())
    | _ => t->Assert.fail("Thrown another exception")
    }
  }
}

let rec cleanUpStruct = struct => {
  let new = Dict.make()
  struct
  ->(magic: S.t<'a> => Dict.t<unknown>)
  ->Dict.toArray
  ->Array.forEach(((key, value)) => {
    switch key {
    | "sb" | "pb" | "i" => ()
    | _ =>
      if typeof(value) === #object && value !== %raw(`null`) {
        new->Dict.set(
          key,
          cleanUpStruct(value->(magic: unknown => S.t<'a>))->(magic: S.t<'a> => unknown),
        )
      } else {
        new->Dict.set(key, value)
      }
    }
  })
  new->(magic: Dict.t<unknown> => S.t<'a>)
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
