open Ava

test("Successfully parses valid data", t => {
  let schema = S.string->S.String.max(1)

  t->Assert.deepEqual("1"->S.parseAnyWith(schema), Ok("1"), ())
  t->Assert.deepEqual(""->S.parseAnyWith(schema), Ok(""), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.string->S.String.max(1)

  t->Assert.deepEqual(
    "1234"->S.parseAnyWith(schema),
    Error(
      U.error({
        code: OperationFailed("String must be 1 or fewer characters long"),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.string->S.String.max(1)

  t->Assert.deepEqual("1"->S.serializeToUnknownWith(schema), Ok(%raw(`"1"`)), ())
  t->Assert.deepEqual(""->S.serializeToUnknownWith(schema), Ok(%raw(`""`)), ())
})

test("Fails to serialize invalid value", t => {
  let schema = S.string->S.String.max(1)

  t->Assert.deepEqual(
    "1234"->S.serializeToUnknownWith(schema),
    Error(
      U.error({
        code: OperationFailed("String must be 1 or fewer characters long"),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Returns custom error message", t => {
  let schema = S.string->S.String.max(~message="Custom", 1)

  t->Assert.deepEqual(
    "1234"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parsing, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.string->S.String.max(1)

  t->Assert.deepEqual(
    schema->S.String.refinements,
    [{kind: Max({length: 1}), message: "String must be 1 or fewer characters long"}],
    (),
  )
})
