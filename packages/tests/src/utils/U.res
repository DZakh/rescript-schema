open Ava
open RescriptCore

external magic: 'a => 'b = "%identity"
external castAnyToUnknown: 'any => unknown = "%identity"
external castUnknownToAny: unknown => 'any = "%identity"

%%private(
  @val @scope("JSON")
  external unsafeStringify: 'a => string = "stringify"
)

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
  | Ok(any) => t->Assert.fail("Asserted result is not Error. Recieved: " ++ any->unsafeStringify)
  | Error(err) => t->Assert.is(err->S.Error.message, error(errorPayload)->S.Error.message, ())
  }
}

let getCompiledCodeString = (schema, ~op: [#Parse | #Serialize | #Assert | #SerializeJson]) => {
  (
    switch op {
    | #Parse =>
      if schema->S.isAsync {
        let fn = schema->S.compile(~input=Any, ~output=Output, ~mode=Async, ~typeValidation=true)
        fn->magic
      } else {
        let fn = schema->S.compile(~input=Any, ~output=Output, ~mode=Sync, ~typeValidation=true)
        fn->magic
      }
    | #Assert =>
      let fn = schema->S.compile(~input=Any, ~output=Assert, ~mode=Sync, ~typeValidation=true)
      fn->magic
    | #Serialize => {
        let fn =
          schema
          ->S.reverse
          ->S.compile(~input=Any, ~output=Output, ~mode=Sync, ~typeValidation=false)
        fn->magic
      }
    | #SerializeJson => {
        let fn =
          schema
          ->S.reverse
          ->S.compile(~input=Any, ~output=Json, ~mode=Sync, ~typeValidation=false)
        fn->magic
      }
    }
  )["toString"]()
}

let rec cleanUpSchema = schema => {
  let new = Dict.make()
  schema
  ->(magic: S.t<'a> => Dict.t<unknown>)
  ->Dict.toArray
  ->Array.forEach(((key, value)) => {
    switch key {
    | "i" | "c" => ()
    // tagged
    | "definition" => ()
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

let assertCompiledCode = (t, ~schema, ~op, code, ~message=?) => {
  t->Assert.is(schema->getCompiledCodeString(~op), code, ~message?, ())
}

let assertCompiledCodeIsNoop = (t, ~schema, ~op, ~message=?) => {
  t->assertCompiledCode(~schema, ~op, "function noopOperation(i) {\n  return i;\n}", ~message?)
}

let assertEqualSchemas: (
  Ava.ExecutionContext.t<'a>,
  S.t<'value>,
  S.t<'value>,
  ~message: string=?,
) => unit = unsafeAssertEqualSchemas

let assertReverseParsesBack = (t, schema: S.t<'value>, value: 'value) => {
  t->Assert.unsafeDeepEqual(
    value
    ->S.reverseConvertWith(schema)
    ->S.parseAnyWith(schema)
    ->S.unwrap,
    value,
    (),
  )
}
