open Ava

test("Successfully parses valid data", t => {
  let struct = S.int->S.Int.port

  t->Assert.deepEqual(8080->S.parseAnyWith(struct), Ok(8080), ())
})

test("Fails to parse invalid data", t => {
  let struct = S.int->S.Int.port

  t->Assert.deepEqual(
    65536->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Invalid port"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.int->S.Int.port

  t->Assert.deepEqual(8080->S.serializeToUnknownWith(struct), Ok(%raw(`8080`)), ())
})

test("Fails to serialize invalid value", t => {
  let struct = S.int->S.Int.port

  t->Assert.deepEqual(
    -80->S.serializeToUnknownWith(struct),
    Error({
      code: OperationFailed("Invalid port"),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Returns custom error message", t => {
  let struct = S.int->S.Int.port(~message="Custom")

  t->Assert.deepEqual(
    400000->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Returns refinement", t => {
  let struct = S.int->S.Int.port

  t->Assert.deepEqual(struct->S.Int.refinements, [{kind: Port, message: "Invalid port"}], ())
})
