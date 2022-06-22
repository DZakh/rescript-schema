open Ava

test("Successfully parses valid data", t => {
  let struct = S.string()->S.String.url()

  t->Assert.deepEqual("http://dzakh.dev"->S.parseWith(struct), Ok("http://dzakh.dev"), ())
})

test("Fails to parse invalid data", t => {
  let struct = S.string()->S.String.url()

  t->Assert.deepEqual(
    "cifjhdsfhsd"->S.parseWith(struct),
    Error({
      code: OperationFailed("Invalid url"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.string()->S.String.url()

  t->Assert.deepEqual(
    "http://dzakh.dev"->S.serializeWith(struct),
    Ok(%raw(`"http://dzakh.dev"`)),
    (),
  )
})

test("Fails to serialize invalid value", t => {
  let struct = S.string()->S.String.url()

  t->Assert.deepEqual(
    "cifjhdsfhsd"->S.serializeWith(struct),
    Error({
      code: OperationFailed("Invalid url"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})
