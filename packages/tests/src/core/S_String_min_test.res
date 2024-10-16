open Ava

test("Successfully parses valid data", t => {
  let schema = S.string->S.stringMinLength(1)

  t->Assert.deepEqual("1"->S.parseAnyWith(schema), Ok("1"), ())
  t->Assert.deepEqual("1234"->S.parseAnyWith(schema), Ok("1234"), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.string->S.stringMinLength(1)

  t->U.assertErrorResult(
    () => ""->S.parseAnyWith(schema),
    {
      code: OperationFailed("String must be 1 or more characters long"),
      operation: Parse,
      path: S.Path.empty,
    },
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.string->S.stringMinLength(1)

  t->Assert.deepEqual("1"->S.reverseConvertWith(schema), %raw(`"1"`), ())
  t->Assert.deepEqual("1234"->S.reverseConvertWith(schema), %raw(`"1234"`), ())
})

test("Fails to serialize invalid value", t => {
  let schema = S.string->S.stringMinLength(1)

  t->U.assertRaised(
    () => ""->S.reverseConvertWith(schema),
    {
      code: OperationFailed("String must be 1 or more characters long"),
      operation: ReverseConvert,
      path: S.Path.empty,
    },
  )
})

test("Returns custom error message", t => {
  let schema = S.string->S.stringMinLength(~message="Custom", 1)

  t->Assert.deepEqual(
    ""->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parse, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.string->S.stringMinLength(1)

  t->Assert.deepEqual(
    schema->S.String.refinements,
    [{kind: Min({length: 1}), message: "String must be 1 or more characters long"}],
    (),
  )
})
