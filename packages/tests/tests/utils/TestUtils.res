open Ava
open RescriptCore

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

let unsafeAssertEqualStructs = (t, s1: S.t<'v1>, s2: S.t<'v2>, ~message=?, ()) => {
  t->Assert.unsafeDeepEqual(s1->cleanUpStruct, s2->cleanUpStruct, ~message?, ())
}

let assertCompiledCode = (t, ~struct, ~op: [#parse | #serialize], code, ~message=?, ()) => {
  let compiledCode = switch op {
  | #parse =>
    if struct->S.isAsyncParse {
      %raw(`struct.a.toString()`)
    } else {
      %raw(`struct.p.toString()`)
    }
  | #serialize => {
      let _ = %raw(`undefined`)->S.serializeToUnknownWith(struct)
      %raw(`struct.s.toString()`)
    }
  }
  t->Assert.is(compiledCode, code, ~message?, ())
}

let assertCompiledCodeIsNoop = (t, ~struct, ~op: [#parse | #serialize], ~message=?, ()) => {
  let compiledCode = switch op {
  | #parse =>
    if struct->S.isAsyncParse {
      %raw(`struct.a.toString()`)
    } else {
      %raw(`struct.p.toString()`)
    }
  | #serialize => {
      let _ = %raw(`undefined`)->S.serializeToUnknownWith(struct)
      %raw(`struct.s.toString()`)
    }
  }
  t->Assert.truthy(compiledCode->String.startsWith("function noopOperation(i)"), ~message?, ())
}

let assertEqualStructs: (
  Ava.ExecutionContext.t<'a>,
  S.t<'value>,
  S.t<'value>,
  ~message: string=?,
  unit,
) => unit = unsafeAssertEqualStructs
