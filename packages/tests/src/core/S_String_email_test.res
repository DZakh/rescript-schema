open Ava

test("Successfully parses valid data", t => {
  let struct = S.string->S.String.email

  t->Assert.deepEqual("dzakh.dev@gmail.com"->S.parseAnyWith(struct), Ok("dzakh.dev@gmail.com"), ())
})

test("Fails to parse invalid data", t => {
  let struct = S.string->S.String.email

  t->Assert.deepEqual(
    "dzakh.dev"->S.parseAnyWith(struct),
    Error(
      U.error({
        code: OperationFailed("Invalid email address"),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.string->S.String.email

  t->Assert.deepEqual(
    "dzakh.dev@gmail.com"->S.serializeToUnknownWith(struct),
    Ok(%raw(`"dzakh.dev@gmail.com"`)),
    (),
  )
})

test("Fails to serialize invalid value", t => {
  let struct = S.string->S.String.email

  t->Assert.deepEqual(
    "dzakh.dev"->S.serializeToUnknownWith(struct),
    Error(
      U.error({
        code: OperationFailed("Invalid email address"),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Returns custom error message", t => {
  let struct = S.string->S.String.email(~message="Custom")

  t->Assert.deepEqual(
    "dzakh.dev"->S.parseAnyWith(struct),
    Error(U.error({code: OperationFailed("Custom"), operation: Parsing, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let struct = S.string->S.String.email

  t->Assert.deepEqual(
    struct->S.String.refinements,
    [{kind: Email, message: "Invalid email address"}],
    (),
  )
})
