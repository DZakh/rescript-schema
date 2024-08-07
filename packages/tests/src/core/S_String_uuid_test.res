open Ava

test("Successfully parses valid data", t => {
  let schema = S.string->S.uuid

  t->Assert.deepEqual(
    "123e4567-e89b-12d3-a456-426614174000"->S.parseAnyWith(schema),
    Ok("123e4567-e89b-12d3-a456-426614174000"),
    (),
  )
})

test("Fails to parse invalid data", t => {
  let schema = S.string->S.uuid

  t->Assert.deepEqual(
    "123e4567"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Invalid UUID"), operation: Parse, path: S.Path.empty})),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.string->S.uuid

  t->Assert.deepEqual(
    "123e4567-e89b-12d3-a456-426614174000"->S.serializeToUnknownWith(schema),
    Ok(%raw(`"123e4567-e89b-12d3-a456-426614174000"`)),
    (),
  )
})

test("Fails to serialize invalid value", t => {
  let schema = S.string->S.uuid

  t->U.assertErrorResult(
    "123e4567"->S.serializeToUnknownWith(schema),
    {code: OperationFailed("Invalid UUID"), operation: SerializeToUnknown, path: S.Path.empty},
  )
})

test("Returns custom error message", t => {
  let schema = S.string->S.uuid(~message="Custom")

  t->Assert.deepEqual(
    "abc"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parse, path: S.Path.empty})),
    (),
  )
})
