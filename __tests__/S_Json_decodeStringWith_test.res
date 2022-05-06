open Ava

test("Fails to decode invalid JSON", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    `undefined`->S.decodeJsonWith(struct),
    Error("Struct decoding failed at root. Reason: Unexpected token u in JSON at position 0"),
    (),
  )
})
