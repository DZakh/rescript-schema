open Ava

test("Successfully parses valid data", t => {
  let schema = S.int->S.port

  t->Assert.deepEqual(8080->S.parseAnyWith(schema), Ok(8080), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.int->S.port

  t->Assert.deepEqual(
    65536->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Invalid port"), operation: Parse, path: S.Path.empty})),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.int->S.port

  t->Assert.deepEqual(8080->S.reverseConvertWith(schema), %raw(`8080`), ())
})

test("Fails to serialize invalid value", t => {
  let schema = S.int->S.port

  t->U.assertError(
    () => -80->S.reverseConvertWith(schema),
    {code: OperationFailed("Invalid port"), operation: SerializeToUnknown, path: S.Path.empty},
  )
})

test("Returns custom error message", t => {
  let schema = S.int->S.port(~message="Custom")

  t->Assert.deepEqual(
    400000->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parse, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.int->S.port

  t->Assert.deepEqual(schema->S.Int.refinements, [{kind: Port, message: "Invalid port"}], ())
})
