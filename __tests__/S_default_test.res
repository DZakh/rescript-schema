open Ava

test("Using default value when constructing optional unknown primitive", t => {
  let value = 123.
  let any = %raw(`undefined`)

  let struct = S.option(S.float())->S.default(value)

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
})

test("Parses data with default when provided JS undefined", t => {
  let struct = S.option(S.bool())->S.default(false)

  t->Assert.deepEqual(%raw(`undefined`)->S.parseWith(struct), Ok(false), ())
})

test("Parses data with default when provided primitive", t => {
  let struct = S.option(S.bool())->S.default(false)

  t->Assert.deepEqual(%raw(`true`)->S.parseWith(struct), Ok(true), ())
})

test("Fails to parse data with default", t => {
  let struct = S.option(S.bool())->S.default(false)

  t->Assert.deepEqual(
    %raw(`"string"`)->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: Expected Bool, got String"),
    (),
  )
})

// FIXME: Add value checks for Literal
failing(
  "Raises error when providing default value different from optional literal struct value",
  t => {
    let struct = S.option(S.literal(Int(123)))->S.default(444)

    t->Assert.throws(() => {
      %raw(`undefined`)->S.parseWith(struct)->ignore
    }, ~expectations=ThrowsException.make(
      ~name="RescriptStructError",
      ~message="Provided default value (444) is different from optional Int Literal (123)",
      (),
    ), ())
  },
)
