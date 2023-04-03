open Ava

test("Successfully parses valid data", t => {
  let struct = S.int()->S.Int.min(1)

  t->Assert.deepEqual(1->S.parseAnyWith(struct), Ok(1), ())
  t->Assert.deepEqual(1234->S.parseAnyWith(struct), Ok(1234), ())
})

test("Fails to parse invalid data", t => {
  let struct = S.int()->S.Int.min(1)

  t->Assert.deepEqual(
    0->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Number must be greater than or equal to 1"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.int()->S.Int.min(1)

  t->Assert.deepEqual(1->S.serializeToUnknownWith(struct), Ok(%raw(`1`)), ())
  t->Assert.deepEqual(1234->S.serializeToUnknownWith(struct), Ok(%raw(`1234`)), ())
})

test("Fails to serialize invalid value", t => {
  let struct = S.int()->S.Int.min(1)

  t->Assert.deepEqual(
    0->S.serializeToUnknownWith(struct),
    Error({
      code: OperationFailed("Number must be greater than or equal to 1"),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Returns custom error message", t => {
  let struct = S.int()->S.Int.min(~message="Custom", 1)

  t->Assert.deepEqual(
    0->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Returns refinement", t => {
  let struct = S.int()->S.Int.min(1)

  t->Assert.deepEqual(
    struct->S.Int.refinements,
    [{kind: Min({value: 1}), message: "Number must be greater than or equal to 1"}],
    (),
  )
})
