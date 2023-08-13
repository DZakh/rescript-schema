open Ava

test("Successfully parses", t => {
  let struct = S.bool

  t->Assert.deepEqual("true"->S.parseJsonStringWith(struct), Ok(true), ())
})

test("Successfully parses unknown", t => {
  let struct = S.unknown

  t->Assert.deepEqual("true"->S.parseJsonStringWith(struct), Ok(true->Obj.magic), ())
})

test("Fails to parse JSON", t => {
  let struct = S.bool

  switch "123,"->S.parseJsonStringWith(struct) {
  | Ok(_) => t->Assert.fail("Must return Error")
  | Error({code, operation, path}) => {
      t->Assert.deepEqual(operation, Parsing, ())
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
  let struct = S.bool

  t->Assert.deepEqual(
    "123"->S.parseJsonStringWith(struct),
    Error(
      U.error({
        code: InvalidType({expected: struct->S.toUnknown, received: Obj.magic(123)}),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})
