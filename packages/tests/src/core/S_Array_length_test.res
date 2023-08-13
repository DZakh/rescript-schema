open Ava

test("Successfully parses valid data", t => {
  let struct = S.array(S.int)->S.Array.length(1)

  t->Assert.deepEqual([1]->S.parseAnyWith(struct), Ok([1]), ())
})

test("Fails to parse invalid data", t => {
  let struct = S.array(S.int)->S.Array.length(1)

  t->Assert.deepEqual(
    []->S.parseAnyWith(struct),
    Error(
      U.error({
        code: OperationFailed("Array must be exactly 1 items long"),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
  t->Assert.deepEqual(
    [1, 2, 3, 4]->S.parseAnyWith(struct),
    Error(
      U.error({
        code: OperationFailed("Array must be exactly 1 items long"),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.array(S.int)->S.Array.length(1)

  t->Assert.deepEqual([1]->S.serializeToUnknownWith(struct), Ok(%raw(`[1]`)), ())
})

test("Fails to serialize invalid value", t => {
  let struct = S.array(S.int)->S.Array.length(1)

  t->Assert.deepEqual(
    []->S.serializeToUnknownWith(struct),
    Error(
      U.error({
        code: OperationFailed("Array must be exactly 1 items long"),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
  t->Assert.deepEqual(
    [1, 2, 3, 4]->S.serializeToUnknownWith(struct),
    Error(
      U.error({
        code: OperationFailed("Array must be exactly 1 items long"),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Returns custom error message", t => {
  let struct = S.array(S.int)->S.Array.length(~message="Custom", 1)

  t->Assert.deepEqual(
    []->S.parseAnyWith(struct),
    Error(U.error({code: OperationFailed("Custom"), operation: Parsing, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let struct = S.array(S.int)->S.Array.length(1)

  t->Assert.deepEqual(
    struct->S.Array.refinements,
    [{kind: Length({length: 1}), message: "Array must be exactly 1 items long"}],
    (),
  )
})
