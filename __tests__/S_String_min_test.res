open Ava

test("Successfully parses valid data", t => {
  let struct = S.string()->S.String.min(1)

  t->Assert.deepEqual("1"->S.parseWith(struct), Ok("1"), ())
  t->Assert.deepEqual("1234"->S.parseWith(struct), Ok("1234"), ())
})

test("Fails to parse invalid data", t => {
  let struct = S.string()->S.String.min(1)

  t->Assert.deepEqual(
    ""->S.parseWith(struct),
    Error({
      code: OperationFailed("String must be 1 or more characters long"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.string()->S.String.min(1)

  t->Assert.deepEqual("1"->S.serializeWith(struct), Ok(%raw(`"1"`)), ())
  t->Assert.deepEqual("1234"->S.serializeWith(struct), Ok(%raw(`"1234"`)), ())
})

test("Fails to serialize invalid value", t => {
  let struct = S.string()->S.String.min(1)

  t->Assert.deepEqual(
    ""->S.serializeWith(struct),
    Error({
      code: OperationFailed("String must be 1 or more characters long"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Returns custom error message", t => {
  let struct = S.string()->S.String.min(~message="Custom", 1)

  t->Assert.deepEqual(
    ""->S.parseWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})
