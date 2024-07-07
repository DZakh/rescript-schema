open Ava

test("Successfully parses", t => {
  let schema = S.bool

  t->Assert.deepEqual("true"->S.parseJsonStringWith(schema), Ok(true), ())
})

test("Successfully parses unknown", t => {
  let schema = S.unknown

  t->Assert.deepEqual("true"->S.parseJsonStringWith(schema), Ok(true->Obj.magic), ())
})

test("Fails to parse JSON", t => {
  let schema = S.bool

  switch "123,"->S.parseJsonStringWith(schema) {
  | Ok(_) => t->Assert.fail("Must return Error")
  | Error({code, operation, path}) => {
      t->Assert.deepEqual(operation, Parse, ())
      t->Assert.deepEqual(path, S.Path.empty, ())
      switch code {
      // For some reason when running tests with wallaby I get another error message
      | OperationFailed("Unexpected token , in JSON at position 3")
      | OperationFailed("Unexpected non-whitespace character after JSON at position 3") => ()
      | _ => t->Assert.fail("Code must be OperationFailed")
      }
    }
  }
})

test("Fails to parse", t => {
  let schema = S.bool

  t->U.assertErrorResult(
    "123"->S.parseJsonStringWith(schema),
    {
      code: InvalidType({expected: schema->S.toUnknown, received: Obj.magic(123)}),
      operation: Parse,
      path: S.Path.empty,
    },
  )
})
