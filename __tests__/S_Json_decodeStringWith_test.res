open Ava

test("Fails to decode invalid JSON", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    `undefined`->S.decodeJsonWith(struct),
    Error(
      "[ReScript Struct] Failed decoding at root. Reason: Unexpected token u in JSON at position 0",
    ),
    (),
  )
})
