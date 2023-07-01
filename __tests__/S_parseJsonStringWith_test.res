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

  t->Assert.deepEqual(
    "123,"->S.parseJsonStringWith(struct),
    Error({
      code: OperationFailed("Unexpected token , in JSON at position 3"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to parse", t => {
  let struct = S.bool

  t->Assert.deepEqual(
    "123"->S.parseJsonStringWith(struct),
    Error({
      code: InvalidType({expected: "Bool", received: "Float"}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
