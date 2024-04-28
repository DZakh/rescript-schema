open Ava

test("Successfully parses valid data", t => {
  let schema = S.array(S.int)->S.Array.min(1)

  t->Assert.deepEqual([1]->S.parseAnyWith(schema), Ok([1]), ())
  t->Assert.deepEqual([1, 2, 3, 4]->S.parseAnyWith(schema), Ok([1, 2, 3, 4]), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.array(S.int)->S.Array.min(1)

  t->U.assertErrorResult([]->S.parseAnyWith(schema), {
        code: OperationFailed("Array must be 1 or more items long"),
        operation: Parsing,
        path: S.Path.empty,
      })
})

test("Successfully serializes valid value", t => {
  let schema = S.array(S.int)->S.Array.min(1)

  t->Assert.deepEqual([1]->S.serializeToUnknownWith(schema), Ok(%raw(`[1]`)), ())
  t->Assert.deepEqual([1, 2, 3, 4]->S.serializeToUnknownWith(schema), Ok(%raw(`[1,2,3,4]`)), ())
})

test("Fails to serialize invalid value", t => {
  let schema = S.array(S.int)->S.Array.min(1)

  t->U.assertErrorResult([]->S.serializeToUnknownWith(schema), {
        code: OperationFailed("Array must be 1 or more items long"),
        operation: Serializing,
        path: S.Path.empty,
      })
})

test("Returns custom error message", t => {
  let schema = S.array(S.int)->S.Array.min(~message="Custom", 1)

  t->Assert.deepEqual(
    []->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parsing, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.array(S.int)->S.Array.min(1)

  t->Assert.deepEqual(
    schema->S.Array.refinements,
    [{kind: Min({length: 1}), message: "Array must be 1 or more items long"}],
    (),
  )
})
