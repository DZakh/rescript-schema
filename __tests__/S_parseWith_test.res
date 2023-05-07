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
    Json.number(123.)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Bool", received: "Float"}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
