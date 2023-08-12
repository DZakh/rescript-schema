open Ava

test("Successfully parses valid data", t => {
  let struct = S.string->S.String.url

  t->Assert.deepEqual("http://dzakh.dev"->S.parseAnyWith(struct), Ok("http://dzakh.dev"), ())
})

test("Fails to parse invalid data", t => {
  let struct = S.string->S.String.url

  t->Assert.deepEqual(
    "cifjhdsfhsd"->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Invalid url"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.string->S.String.url

  t->Assert.deepEqual(
    "http://dzakh.dev"->S.serializeToUnknownWith(struct),
    Ok(%raw(`"http://dzakh.dev"`)),
    (),
  )
})

test("Fails to serialize invalid value", t => {
  let struct = S.string->S.String.url

  t->Assert.deepEqual(
    "cifjhdsfhsd"->S.serializeToUnknownWith(struct),
    Error({
      code: OperationFailed("Invalid url"),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Returns custom error message", t => {
  let struct = S.string->S.String.url(~message="Custom")

  t->Assert.deepEqual(
    "abc"->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
