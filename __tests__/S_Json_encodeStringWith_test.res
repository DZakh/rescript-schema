open Ava

test("Encodes primitive", t => {
  let struct = S.string()

  t->Assert.deepEqual(
    "ReScript is Great!"->S.Json.encodeStringWith(struct),
    Ok(`"ReScript is Great!"`),
    (),
  )
})
