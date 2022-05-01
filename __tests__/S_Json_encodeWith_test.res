open Ava

test("Encodes primitive", t => {
  let primitive = "ReScript is Great!"
  let struct = S.string()

  t->Assert.deepEqual(primitive->S.Json.encodeWith(struct), Ok(Js.Json.string(primitive)), ())
})
