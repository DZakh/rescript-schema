open Ava

test("Successfully parses valid data", t => {
  let schema = S.string->S.cuid

  t->Assert.deepEqual(
    "ckopqwooh000001la8mbi2im9"->S.parseAnyWith(schema),
    Ok("ckopqwooh000001la8mbi2im9"),
    (),
  )
})

test("Fails to parse invalid data", t => {
  let schema = S.string->S.cuid

  t->Assert.deepEqual(
    "cifjhdsfhsd-invalid-cuid"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Invalid CUID"), operation: Parse, path: S.Path.empty})),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.string->S.cuid

  t->Assert.deepEqual(
    "ckopqwooh000001la8mbi2im9"->S.reverseConvertWith(schema),
    %raw(`"ckopqwooh000001la8mbi2im9"`),
    (),
  )
})

test("Fails to serialize invalid value", t => {
  let schema = S.string->S.cuid

  t->U.assertRaised(
    () => "cifjhdsfhsd-invalid-cuid"->S.reverseConvertWith(schema),
    {code: OperationFailed("Invalid CUID"), operation: ReverseConvert, path: S.Path.empty},
  )
})

test("Returns custom error message", t => {
  let schema = S.string->S.cuid(~message="Custom")

  t->Assert.deepEqual(
    "cifjhdsfhsd-invalid-cuid"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parse, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.string->S.cuid

  t->Assert.deepEqual(schema->S.String.refinements, [{kind: Cuid, message: "Invalid CUID"}], ())
})
