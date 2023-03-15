open Ava

test("Successfully parses valid data", t => {
  let struct = S.string()->S.String.cuid()

  t->Assert.deepEqual(
    "ckopqwooh000001la8mbi2im9"->S.parseWith(struct),
    Ok("ckopqwooh000001la8mbi2im9"),
    (),
  )
})

test("Fails to parse invalid data", t => {
  let struct = S.string()->S.String.cuid()

  t->Assert.deepEqual(
    "cifjhdsfhsd-invalid-cuid"->S.parseWith(struct),
    Error({
      code: OperationFailed("Invalid CUID"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.string()->S.String.cuid()

  t->Assert.deepEqual(
    "ckopqwooh000001la8mbi2im9"->S.serializeWith(struct),
    Ok(%raw(`"ckopqwooh000001la8mbi2im9"`)),
    (),
  )
})

test("Fails to serialize invalid value", t => {
  let struct = S.string()->S.String.cuid()

  t->Assert.deepEqual(
    "cifjhdsfhsd-invalid-cuid"->S.serializeWith(struct),
    Error({
      code: OperationFailed("Invalid CUID"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Returns custom error message", t => {
  let struct = S.string()->S.String.cuid(~message="Custom", ())

  t->Assert.deepEqual(
    "cifjhdsfhsd-invalid-cuid"->S.parseWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Returns refinement", t => {
  let struct = S.string()->S.String.cuid()

  t->Assert.deepEqual(struct->S.String.refinements, [{kind: Cuid, message: "Invalid CUID"}], ())
})
