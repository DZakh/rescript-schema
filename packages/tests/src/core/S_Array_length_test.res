open Ava

test("Successfully parses valid data", t => {
  let schema = S.array(S.int)->S.arrayLength(1)

  t->Assert.deepEqual([1]->S.parseAnyWith(schema), Ok([1]), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.array(S.int)->S.arrayLength(1)

  t->U.assertErrorResult(
    []->S.parseAnyWith(schema),
    {
      code: OperationFailed("Array must be exactly 1 items long"),
      operation: Parse,
      path: S.Path.empty,
    },
  )
  t->U.assertErrorResult(
    [1, 2, 3, 4]->S.parseAnyWith(schema),
    {
      code: OperationFailed("Array must be exactly 1 items long"),
      operation: Parse,
      path: S.Path.empty,
    },
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.array(S.int)->S.arrayLength(1)

  t->Assert.deepEqual([1]->S.reverseConvertWith(schema), %raw(`[1]`), ())
})

test("Fails to serialize invalid value", t => {
  let schema = S.array(S.int)->S.arrayLength(1)

  t->U.assertError(
    () => []->S.reverseConvertWith(schema),
    {
      code: OperationFailed("Array must be exactly 1 items long"),
      operation: SerializeToUnknown,
      path: S.Path.empty,
    },
  )
  t->U.assertError(
    () => [1, 2, 3, 4]->S.reverseConvertWith(schema),
    {
      code: OperationFailed("Array must be exactly 1 items long"),
      operation: SerializeToUnknown,
      path: S.Path.empty,
    },
  )
})

test("Returns custom error message", t => {
  let schema = S.array(S.int)->S.arrayLength(~message="Custom", 1)

  t->Assert.deepEqual(
    []->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parse, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.array(S.int)->S.arrayLength(1)

  t->Assert.deepEqual(
    schema->S.Array.refinements,
    [{kind: Length({length: 1}), message: "Array must be exactly 1 items long"}],
    (),
  )
})
