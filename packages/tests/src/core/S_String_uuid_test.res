open Ava

test("Successfully parses valid data", t => {
  let schema = S.string->S.uuid

  t->Assert.deepEqual(
    "123e4567-e89b-12d3-a456-426614174000"->S.parseAnyWith(schema),
    Ok("123e4567-e89b-12d3-a456-426614174000"),
    (),
  )
})

test("Successfully parses uuid V7", t => {
  let schema = S.string->S.uuid

  t->Assert.deepEqual(
    "019122ba-bb79-75ef-9a97-190f1effbb54"->S.parseAnyWith(schema),
    Ok("019122ba-bb79-75ef-9a97-190f1effbb54"),
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
    "123e4567-e89b-12d3-a456-426614174000"->S.reverseConvertWith(schema),
    %raw(`"123e4567-e89b-12d3-a456-426614174000"`),
    (),
  )
})

test("Fails to serialize invalid value", t => {
  let schema = S.string->S.uuid

  t->U.assertError(
    () => "123e4567"->S.reverseConvertWith(schema),
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
