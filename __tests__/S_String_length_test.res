open Ava

test("Successfully parses valid data", t => {
  let struct = S.string()->S.String.length(1)

  t->Assert.deepEqual("1"->S.parseWith(struct), Ok("1"), ())
})

test("Fails to parse invalid data", t => {
  let struct = S.string()->S.String.length(1)

  t->Assert.deepEqual(
    ""->S.parseWith(struct),
    Error({
      code: OperationFailed("String must be exactly 1 characters long"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
  t->Assert.deepEqual(
    "1234"->S.parseWith(struct),
    Error({
      code: OperationFailed("String must be exactly 1 characters long"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.string()->S.String.length(1)

  t->Assert.deepEqual("1"->S.serializeWith(struct), Ok(%raw(`"1"`)), ())
})

test("Fails to serialize invalid value", t => {
  let struct = S.string()->S.String.length(1)

  t->Assert.deepEqual(
    ""->S.serializeWith(struct),
    Error({
      code: OperationFailed("String must be exactly 1 characters long"),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
  t->Assert.deepEqual(
    "1234"->S.serializeWith(struct),
    Error({
      code: OperationFailed("String must be exactly 1 characters long"),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Returns custom error message", t => {
  let struct = S.string()->S.String.length(~message="Custom", 12)

  t->Assert.deepEqual(
    "123"->S.parseWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Returns refinement", t => {
  let struct = S.string()->S.String.length(4)

  t->Assert.deepEqual(
    struct->S.String.refinements,
    [{kind: Length({length: 4}), message: "String must be exactly 4 characters long"}],
    (),
  )
})
