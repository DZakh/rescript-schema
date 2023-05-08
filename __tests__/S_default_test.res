open Ava

test("Uses default value when parsing optional unknown primitive", t => {
  let value = 123.
  let any = %raw(`undefined`)

  let struct = S.float->S.default(() => value)

  t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
})

test("Successfully parses with default when provided JS undefined", t => {
  let struct = S.bool->S.default(() => false)

  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(struct), Ok(false), ())
})

test("Successfully parses with default when provided primitive", t => {
  let struct = S.bool->S.default(() => false)

  t->Assert.deepEqual(%raw(`true`)->S.parseAnyWith(struct), Ok(true), ())
})

test("Successfully parses nested option with default value", t => {
  let struct = S.option(S.bool)->S.default(() => Some(true))

  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(struct), Ok(Some(true)), ())
})

test("Fails to parse data with default", t => {
  let struct = S.bool->S.default(() => false)

  t->Assert.deepEqual(
    %raw(`"string"`)->S.parseAnyWith(struct),
    Error({
      code: UnexpectedType({expected: "Bool", received: "String"}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
