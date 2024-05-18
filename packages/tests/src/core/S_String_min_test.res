open Ava

test("Successfully parses valid data", t => {
  let schema = S.string->S.stringMin(1)

  t->Assert.deepEqual("1"->S.parseAnyWith(schema), Ok("1"), ())
  t->Assert.deepEqual("1234"->S.parseAnyWith(schema), Ok("1234"), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.string->S.stringMin(1)

  t->U.assertErrorResult(
    ""->S.parseAnyWith(schema),
    {
      code: OperationFailed("String must be 1 or more characters long"),
      operation: Parsing,
      path: S.Path.empty,
    },
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.string->S.stringMin(1)

  t->Assert.deepEqual("1"->S.serializeToUnknownWith(schema), Ok(%raw(`"1"`)), ())
  t->Assert.deepEqual("1234"->S.serializeToUnknownWith(schema), Ok(%raw(`"1234"`)), ())
})

test("Fails to serialize invalid value", t => {
  let schema = S.string->S.stringMin(1)

  t->U.assertErrorResult(
    ""->S.serializeToUnknownWith(schema),
    {
      code: OperationFailed("String must be 1 or more characters long"),
      operation: Serializing,
      path: S.Path.empty,
    },
  )
})

test("Returns custom error message", t => {
  let schema = S.string->S.stringMin(~message="Custom", 1)

  t->Assert.deepEqual(
    ""->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parsing, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.string->S.stringMin(1)

  t->Assert.deepEqual(
    schema->S.String.refinements,
    [{kind: Min({length: 1}), message: "String must be 1 or more characters long"}],
    (),
  )
})
