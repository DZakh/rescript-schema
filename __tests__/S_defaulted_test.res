open Ava

test("Uses default value when parsing optional unknown primitive ", t => {
  let value = 123.
  let any = %raw(`undefined`)

  let struct = S.option(S.float())->S.defaulted(value)

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses with default when provided JS undefined", t => {
  let struct = S.option(S.bool())->S.defaulted(false)

  t->Assert.deepEqual(%raw(`undefined`)->S.parseWith(struct), Ok(false), ())
})

test("Successfully parses with default when provided primitive", t => {
  let struct = S.option(S.bool())->S.defaulted(false)

  t->Assert.deepEqual(%raw(`true`)->S.parseWith(struct), Ok(true), ())
})

test("Successfully parses nested option with default value", t => {
  let struct = S.option(S.option(S.bool()))->S.defaulted(Some(true))

  t->Assert.deepEqual(%raw(`undefined`)->S.parseWith(struct), Ok(Some(true)), ())
})

test("Fails to parse data with default", t => {
  let struct = S.option(S.bool())->S.defaulted(false)

  t->Assert.deepEqual(
    %raw(`"string"`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Bool", received: "String"}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

// FIXME: Add value checks for Literal
Failing.test(
  "Raises error when providing default value different from optional literal struct value",
  t => {
    let struct = S.option(S.literal(Int(123)))->S.defaulted(444)

    t->Assert.throws(
      () => {
        %raw(`undefined`)->S.parseWith(struct)
      },
      ~expectations={
        message: "[rescript-struct] Provided default value (444) is different from optional Int Literal (123)",
      },
      (),
    )
  },
)
