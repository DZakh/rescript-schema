open Ava

test("Refined primitive returns an error when parsed in a Safe mode", t => {
  let struct = S.int()->S.refine(~constructor=value =>
    switch value >= 0 {
    | true => None
    | false => Some("Should be positive")
    }
  , ())

  t->Assert.deepEqual(
    %raw(`-12`)->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: Should be positive"),
    (),
  )
})

test("Refined primitive doesn't return an error when parsed in an Unsafe mode", t => {
  let struct = S.int()->S.refine(~constructor=value =>
    switch value >= 0 {
    | true => None
    | false => Some("Should be positive")
    }
  , ())

  t->Assert.deepEqual(%raw(`-12`)->S.parseWith(~mode=Unsafe, struct), Ok(-12), ())
})

// TODO: Test serializing
// TODO: Check that both constructors provided
