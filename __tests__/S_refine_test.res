open Ava

test("Refined primitive returns an error when parsed", t => {
  let struct = S.int()->S.refine(~parser=value =>
    if value < 0 {
      S.Error.raise("Should be positive")
    }
  , ())

  t->Assert.deepEqual(
    %raw(`-12`)->S.parseWith(struct),
    Error({
      code: OperationFailed("Should be positive"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

// TODO: Test serializing
