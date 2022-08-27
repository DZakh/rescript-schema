open Ava

ava->test("Successfully parses valid data", t => {
  let struct = S.string()->S.String.max(1)

  t->Assert.deepEqual("1"->S.parseWith(struct), Ok("1"), ())
  t->Assert.deepEqual(""->S.parseWith(struct), Ok(""), ())
})

ava->test("Fails to parse invalid data", t => {
  let struct = S.string()->S.String.max(1)

  t->Assert.deepEqual(
    "1234"->S.parseWith(struct),
    Error({
      code: OperationFailed("String must be 1 or fewer characters long"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

ava->test("Successfully serializes valid value", t => {
  let struct = S.string()->S.String.max(1)

  t->Assert.deepEqual("1"->S.serializeWith(struct), Ok(%raw(`"1"`)), ())
  t->Assert.deepEqual(""->S.serializeWith(struct), Ok(%raw(`""`)), ())
})

ava->test("Fails to serialize invalid value", t => {
  let struct = S.string()->S.String.max(1)

  t->Assert.deepEqual(
    "1234"->S.serializeWith(struct),
    Error({
      code: OperationFailed("String must be 1 or fewer characters long"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

ava->test("Returns custom error message", t => {
  let struct = S.string()->S.String.max(~message="Custom", 1)

  t->Assert.deepEqual(
    "1234"->S.parseWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})
