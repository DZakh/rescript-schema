open Ava

ava->test("Successfully parses valid data", t => {
  let struct = S.string()->S.String.email()

  t->Assert.deepEqual("dzakh.dev@gmail.com"->S.parseWith(struct), Ok("dzakh.dev@gmail.com"), ())
})

ava->test("Fails to parse invalid data", t => {
  let struct = S.string()->S.String.email()

  t->Assert.deepEqual(
    "dzakh.dev"->S.parseWith(struct),
    Error({
      code: OperationFailed("Invalid email address"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

ava->test("Successfully serializes valid value", t => {
  let struct = S.string()->S.String.email()

  t->Assert.deepEqual(
    "dzakh.dev@gmail.com"->S.serializeWith(struct),
    Ok(%raw(`"dzakh.dev@gmail.com"`)),
    (),
  )
})

ava->test("Fails to serialize invalid value", t => {
  let struct = S.string()->S.String.email()

  t->Assert.deepEqual(
    "dzakh.dev"->S.serializeWith(struct),
    Error({
      code: OperationFailed("Invalid email address"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

ava->test("Returns custom error message", t => {
  let struct = S.string()->S.String.email(~message="Custom", ())

  t->Assert.deepEqual(
    "dzakh.dev"->S.parseWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})
