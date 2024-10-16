open Ava

test("Successfully parses valid data", t => {
  let schema = S.string->S.email

  t->Assert.deepEqual("dzakh.dev@gmail.com"->S.parseAnyWith(schema), Ok("dzakh.dev@gmail.com"), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.string->S.email

  t->U.assertErrorResult(
    () => "dzakh.dev"->S.parseAnyWith(schema),
    {
      code: OperationFailed("Invalid email address"),
      operation: Parse,
      path: S.Path.empty,
    },
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.string->S.email

  t->Assert.deepEqual(
    "dzakh.dev@gmail.com"->S.reverseConvertWith(schema),
    %raw(`"dzakh.dev@gmail.com"`),
    (),
  )
})

test("Fails to serialize invalid value", t => {
  let schema = S.string->S.email

  t->U.assertRaised(
    () => "dzakh.dev"->S.reverseConvertWith(schema),
    {
      code: OperationFailed("Invalid email address"),
      operation: SerializeToUnknown,
      path: S.Path.empty,
    },
  )
})

test("Returns custom error message", t => {
  let schema = S.string->S.email(~message="Custom")

  t->Assert.deepEqual(
    "dzakh.dev"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parse, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.string->S.email

  t->Assert.deepEqual(
    schema->S.String.refinements,
    [{kind: Email, message: "Invalid email address"}],
    (),
  )
})
