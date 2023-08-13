open Ava

test("Successfully refines on parsing", t => {
  let struct = S.int->S.refine(s => value =>
    if value < 0 {
      s.fail("Should be positive")
    })

  t->Assert.deepEqual(%raw(`12`)->S.parseAnyWith(struct), Ok(12), ())
  t->Assert.deepEqual(
    %raw(`-12`)->S.parseAnyWith(struct),
    Error(
      U.error({
        code: OperationFailed("Should be positive"),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Fails with custom path", t => {
  let struct = S.int->S.refine(s => value =>
    if value < 0 {
      s.fail(~path=S.Path.fromArray(["data", "myInt"]), "Should be positive")
    })

  t->Assert.deepEqual(
    %raw(`-12`)->S.parseAnyWith(struct),
    Error(
      U.error({
        code: OperationFailed("Should be positive"),
        operation: Parsing,
        path: S.Path.fromArray(["data", "myInt"]),
      }),
    ),
    (),
  )
})

test("Successfully refines on serializing", t => {
  let struct = S.int->S.refine(s => value =>
    if value < 0 {
      s.fail("Should be positive")
    })

  t->Assert.deepEqual(12->S.serializeToUnknownWith(struct), Ok(%raw("12")), ())
  t->Assert.deepEqual(
    -12->S.serializeToUnknownWith(struct),
    Error(
      U.error({
        code: OperationFailed("Should be positive"),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})
