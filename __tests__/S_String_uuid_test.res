open Ava

ava->test("Successfully parses valid data", t => {
  let struct = S.string()->S.String.uuid()

  t->Assert.deepEqual(
    "123e4567-e89b-12d3-a456-426614174000"->S.parseWith(struct),
    Ok("123e4567-e89b-12d3-a456-426614174000"),
    (),
  )
})

ava->test("Fails to parse invalid data", t => {
  let struct = S.string()->S.String.uuid()

  t->Assert.deepEqual(
    "123e4567"->S.parseWith(struct),
    Error({
      code: OperationFailed("Invalid UUID"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

ava->test("Successfully serializes valid value", t => {
  let struct = S.string()->S.String.uuid()

  t->Assert.deepEqual(
    "123e4567-e89b-12d3-a456-426614174000"->S.serializeWith(struct),
    Ok(%raw(`"123e4567-e89b-12d3-a456-426614174000"`)),
    (),
  )
})

ava->test("Fails to serialize invalid value", t => {
  let struct = S.string()->S.String.uuid()

  t->Assert.deepEqual(
    "123e4567"->S.serializeWith(struct),
    Error({
      code: OperationFailed("Invalid UUID"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

ava->test("Returns custom error message", t => {
  let struct = S.string()->S.String.uuid(~message="Custom", ())

  t->Assert.deepEqual(
    "abc"->S.parseWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})
