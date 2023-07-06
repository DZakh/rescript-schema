open Ava

module Json = Js.Json

test("Successfully parses", t => {
  let struct = S.bool

  t->Assert.deepEqual(Json.boolean(true)->S.parseWith(struct), Ok(true), ())
})

test("Successfully parses unknown", t => {
  let struct = S.unknown

  t->Assert.deepEqual(Json.boolean(true)->S.parseWith(struct), Ok(true->Obj.magic), ())
})

test("Fails to parse", t => {
  let struct = S.bool

  t->Assert.deepEqual(
    %raw("123")->S.parseWith(struct),
    Error({
      code: InvalidType({expected: struct->S.toUnknown, received: %raw("123")}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
