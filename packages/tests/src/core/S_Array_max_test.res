open Ava

test("Successfully parses valid data", t => {
  let schema = S.array(S.int)->S.arrayMaxLength(1)

  t->Assert.deepEqual([1]->S.parseAnyWith(schema), Ok([1]), ())
  t->Assert.deepEqual([]->S.parseAnyWith(schema), Ok([]), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.array(S.int)->S.arrayMaxLength(1)

  t->U.assertErrorResult(
    [1, 2, 3, 4]->S.parseAnyWith(schema),
    {
      code: OperationFailed("Array must be 1 or fewer items long"),
      operation: Parse,
      path: S.Path.empty,
    },
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.array(S.int)->S.arrayMaxLength(1)

  t->Assert.deepEqual([1]->S.serializeToUnknownWith(schema), Ok(%raw(`[1]`)), ())
  t->Assert.deepEqual([]->S.serializeToUnknownWith(schema), Ok(%raw(`[]`)), ())
})

test("Fails to serialize invalid value", t => {
  let schema = S.array(S.int)->S.arrayMaxLength(1)

  t->U.assertErrorResult(
    [1, 2, 3, 4]->S.serializeToUnknownWith(schema),
    {
      code: OperationFailed("Array must be 1 or fewer items long"),
      operation: SerializeToUnknown,
      path: S.Path.empty,
    },
  )
})

test("Returns custom error message", t => {
  let schema = S.array(S.int)->S.arrayMaxLength(~message="Custom", 1)

  t->Assert.deepEqual(
    [1, 2]->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parse, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.array(S.int)->S.arrayMaxLength(1)

  t->Assert.deepEqual(
    schema->S.Array.refinements,
    [{kind: Max({length: 1}), message: "Array must be 1 or fewer items long"}],
    (),
  )
})
