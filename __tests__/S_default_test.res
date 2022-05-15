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

  t->Assert.deepEqual(Js.Json.boolean(true)->S.parseWith(struct), Ok(true), ())
})

test("Fails to parse data with default", t => {
  let struct = S.option(S.bool())->S.default(false)

  t->Assert.deepEqual(
    Js.Json.string("string")->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: Expected Bool, got String"),
    (),
  )
})
