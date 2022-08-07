open Ava

test("Refined primitive returns an error when parsed in a Safe mode", t => {
  let struct = S.int()->S.refine(~parser=value =>
    switch value >= 0 {
    | true => None
    | false => Some("Should be positive")
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

test("Refined primitive returns an error when parsed in a Migration mode", t => {
  let struct = S.int()->S.refine(~parser=value =>
    switch value >= 0 {
    | true => None
    | false => Some("Should be positive")
    }
  , ())

  t->Assert.deepEqual(
    %raw(`-12`)->S.parseWith(~mode=Migration, struct),
    Error({
      code: OperationFailed("Should be positive"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

// TODO: Test serializing
