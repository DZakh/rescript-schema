open Ava

test("Successfully parses valid data", t => {
  let schema = S.string->S.String.url

  t->Assert.deepEqual("http://dzakh.dev"->S.parseAnyWith(schema), Ok("http://dzakh.dev"), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.string->S.String.url

  t->Assert.deepEqual(
    "cifjhdsfhsd"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Invalid url"), operation: Parsing, path: S.Path.empty})),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.string->S.String.url

  t->Assert.deepEqual(
    "http://dzakh.dev"->S.serializeToUnknownWith(schema),
    Ok(%raw(`"http://dzakh.dev"`)),
    (),
  )
})

test("Fails to serialize invalid value", t => {
  let schema = S.string->S.String.url

  t->U.assertErrorResult(
    "cifjhdsfhsd"->S.serializeToUnknownWith(schema),
    {code: OperationFailed("Invalid url"), operation: Serializing, path: S.Path.empty},
  )
})

test("Returns custom error message", t => {
  let schema = S.string->S.String.url(~message="Custom")

  t->Assert.deepEqual(
    "abc"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parsing, path: S.Path.empty})),
    (),
  )
})
