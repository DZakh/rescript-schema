open Ava

test("Successfully parses valid data", t => {
  let schema = S.string->S.String.length(1)

  t->Assert.deepEqual("1"->S.parseAnyWith(schema), Ok("1"), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.string->S.String.length(1)

  t->Assert.deepEqual(
    ""->S.parseAnyWith(schema),
    Error(
      U.error({
        code: OperationFailed("String must be exactly 1 characters long"),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
  t->Assert.deepEqual(
    "1234"->S.parseAnyWith(schema),
    Error(
      U.error({
        code: OperationFailed("String must be exactly 1 characters long"),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.string->S.String.length(1)

  t->Assert.deepEqual("1"->S.serializeToUnknownWith(schema), Ok(%raw(`"1"`)), ())
})

test("Fails to serialize invalid value", t => {
  let schema = S.string->S.String.length(1)

  t->Assert.deepEqual(
    ""->S.serializeToUnknownWith(schema),
    Error(
      U.error({
        code: OperationFailed("String must be exactly 1 characters long"),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
  t->Assert.deepEqual(
    "1234"->S.serializeToUnknownWith(schema),
    Error(
      U.error({
        code: OperationFailed("String must be exactly 1 characters long"),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Returns custom error message", t => {
  let schema = S.string->S.String.length(~message="Custom", 12)

  t->Assert.deepEqual(
    "123"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parsing, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.string->S.String.length(4)

  t->Assert.deepEqual(
    schema->S.String.refinements,
    [{kind: Length({length: 4}), message: "String must be exactly 4 characters long"}],
    (),
  )
})
