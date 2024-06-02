open Ava
open RescriptCore

external magic: 'a => 'b = "%identity"
external castAnyToUnknown: 'any => unknown = "%identity"
external castUnknownToAny: unknown => 'any = "%identity"

let unsafeGetVariantPayload = variant => (variant->Obj.magic)["_0"]

exception Test
let raiseTestException = () => raise(Test)

type errorPayload = {operation: S.operation, code: S.errorCode, path: S.Path.t}

// TODO: Get rid of the helper
let error = ({operation, code, path}: errorPayload): S.error => {
  S.Error.make(~code, ~operation, ~path)
}

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

let assertErrorResult = (t, result, errorPayload) => {
  switch result {
  | Ok(_) => t->Assert.fail("Asserted result is not Error.")
  | Error(err) => t->Assert.is(err->S.Error.message, error(errorPayload)->S.Error.message, ())
  }
}

let rec cleanUpSchema = schema => {
  let new = Dict.make()
  schema
  ->(magic: S.t<'a> => Dict.t<unknown>)
  ->Dict.toArray
  ->Array.forEach(((key, value)) => {
    switch key {
    | "i"
    | // Object ctx
    "itemsSet"
    | "definition"
    | "nestedCtxs" => ()
    | _ =>
      if typeof(value) === #function {
        ()
      } else if typeof(value) === #object && value !== %raw(`null`) {
        new->Dict.set(
          key,
          cleanUpSchema(value->(magic: unknown => S.t<'a>))->(magic: S.t<'a> => unknown),
        )
      } else {
        new->Dict.set(key, value)
      }
    }
  })
  new->(magic: Dict.t<unknown> => S.t<'a>)
}

let unsafeAssertEqualSchemas = (t, s1: S.t<'v1>, s2: S.t<'v2>, ~message=?) => {
  t->Assert.unsafeDeepEqual(s1->cleanUpSchema, s2->cleanUpSchema, ~message?, ())
}

let assertCompiledCode = (t, ~schema, ~op: [#parse | #serialize], code, ~message=?) => {
  let compiledCode = switch op {
  | #parse =>
    if schema->S.isAsyncParse {
      let _ = %raw(`undefined`)->S.parseAsyncInStepsWith(schema)
      %raw(`schema.opa.toString()`)
    } else {
      let _ = %raw(`undefined`)->S.parseAnyWith(schema)
      %raw(`schema.op.toString()`)
    }
  | #serialize => {
      try {
        let _ = %raw(`undefined`)->S.serializeToUnknownOrRaiseWith(schema)
      } catch {
      | _ => ()
      }
      %raw(`schema.os.toString()`)
    }
  }
  t->Assert.is(compiledCode, code, ~message?, ())
}

let assertCompiledCodeIsNoop = (t, ~schema, ~op: [#parse | #serialize], ~message=?) => {
  let compiledCode = switch op {
  | #parse =>
    if schema->S.isAsyncParse {
      let _ = %raw(`undefined`)->S.parseAsyncInStepsWith(schema)
      %raw(`schema.opa.toString()`)
    } else {
      let _ = %raw(`undefined`)->S.parseAnyWith(schema)
      %raw(`schema.op.toString()`)
    }
  | #serialize => {
      try {
        let _ = %raw(`undefined`)->S.serializeToUnknownOrRaiseWith(schema)
      } catch {
      | _ => ()
      }
      %raw(`schema.os.toString()`)
    }
  }
  t->Assert.truthy(compiledCode->String.startsWith("function noopOperation(i)"), ~message?, ())
}

let assertEqualSchemas: (
  Ava.ExecutionContext.t<'a>,
  S.t<'value>,
  S.t<'value>,
  ~message: string=?,
) => unit = unsafeAssertEqualSchemas
