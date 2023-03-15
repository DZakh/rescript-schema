open Ava

test("Successfully parses valid data", t => {
  let struct = S.string()->S.String.email()

  t->Assert.deepEqual("dzakh.dev@gmail.com"->S.parseWith(struct), Ok("dzakh.dev@gmail.com"), ())
})

test("Fails to parse invalid data", t => {
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

test("Successfully serializes valid value", t => {
  let struct = S.string()->S.String.email()

  t->Assert.deepEqual(
    "dzakh.dev@gmail.com"->S.serializeWith(struct),
    Ok(%raw(`"dzakh.dev@gmail.com"`)),
    (),
  )
})

test("Fails to serialize invalid value", t => {
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

test("Returns custom error message", t => {
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

test("Returns refinement", t => {
  let struct = S.string()->S.String.email()

  t->Assert.deepEqual(
    struct->S.String.refinements,
    [{kind: Email, message: "Invalid email address"}],
    (),
  )
})
