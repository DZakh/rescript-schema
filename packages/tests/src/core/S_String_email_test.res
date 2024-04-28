open Ava

test("Successfully parses valid data", t => {
  let schema = S.string->S.String.email

  t->Assert.deepEqual("dzakh.dev@gmail.com"->S.parseAnyWith(schema), Ok("dzakh.dev@gmail.com"), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.string->S.String.email

  t->U.assertErrorResult("dzakh.dev"->S.parseAnyWith(schema), {
        code: OperationFailed("Invalid email address"),
        operation: Parsing,
        path: S.Path.empty,
      })
})

test("Successfully serializes valid value", t => {
  let schema = S.string->S.String.email

  t->Assert.deepEqual(
    "dzakh.dev@gmail.com"->S.serializeToUnknownWith(schema),
    Ok(%raw(`"dzakh.dev@gmail.com"`)),
    (),
  )
})

test("Fails to serialize invalid value", t => {
  let schema = S.string->S.String.email

  t->U.assertErrorResult("dzakh.dev"->S.serializeToUnknownWith(schema), {
        code: OperationFailed("Invalid email address"),
        operation: Serializing,
        path: S.Path.empty,
      })
})

test("Returns custom error message", t => {
  let schema = S.string->S.String.email(~message="Custom")

  t->Assert.deepEqual(
    "dzakh.dev"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parsing, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.string->S.String.email

  t->Assert.deepEqual(
    schema->S.String.refinements,
    [{kind: Email, message: "Invalid email address"}],
    (),
  )
})
