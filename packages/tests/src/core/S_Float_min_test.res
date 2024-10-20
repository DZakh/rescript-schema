open Ava

test("Successfully parses valid data", t => {
  let schema = S.float->S.floatMin(1.)

  t->Assert.deepEqual(1.->S.parseAnyWith(schema), Ok(1.), ())
  t->Assert.deepEqual(1234.->S.parseAnyWith(schema), Ok(1234.), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.float->S.floatMin(1.)

  t->U.assertErrorResult(
    () => 0->S.parseAnyWith(schema),
    {
      code: OperationFailed("Number must be greater than or equal to 1"),
      operation: Parse,
      path: S.Path.empty,
    },
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.float->S.floatMin(1.)

  t->Assert.deepEqual(1.->S.reverseConvertOrThrow(schema), %raw(`1`), ())
  t->Assert.deepEqual(1234.->S.reverseConvertOrThrow(schema), %raw(`1234`), ())
})

test("Fails to serialize invalid value", t => {
  let schema = S.float->S.floatMin(1.)

  t->U.assertRaised(
    () => 0.->S.reverseConvertOrThrow(schema),
    {
      code: OperationFailed("Number must be greater than or equal to 1"),
      operation: ReverseConvert,
      path: S.Path.empty,
    },
  )
})

test("Returns custom error message", t => {
  let schema = S.float->S.floatMin(~message="Custom", 1.)

  t->Assert.deepEqual(
    0.->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parse, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.float->S.floatMin(1.)

  t->Assert.deepEqual(
    schema->S.Float.refinements,
    [{kind: Min({value: 1.}), message: "Number must be greater than or equal to 1"}],
    (),
  )
})
