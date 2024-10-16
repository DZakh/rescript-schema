open Ava

test("Successfully parses valid data", t => {
  let schema = S.string->S.url

  t->Assert.deepEqual("http://dzakh.dev"->S.parseAnyWith(schema), Ok("http://dzakh.dev"), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.string->S.url

  t->Assert.deepEqual(
    "cifjhdsfhsd"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Invalid url"), operation: Parse, path: S.Path.empty})),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.string->S.url

  t->Assert.deepEqual(
    "http://dzakh.dev"->S.reverseConvertWith(schema),
    %raw(`"http://dzakh.dev"`),
    (),
  )
})

test("Fails to serialize invalid value", t => {
  let schema = S.string->S.url

  t->U.assertError(
    () => "cifjhdsfhsd"->S.reverseConvertWith(schema),
    {code: OperationFailed("Invalid url"), operation: SerializeToUnknown, path: S.Path.empty},
  )
})

test("Returns custom error message", t => {
  let schema = S.string->S.url(~message="Custom")

  t->Assert.deepEqual(
    "abc"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parse, path: S.Path.empty})),
    (),
  )
})
