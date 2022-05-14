open Ava

test("Fails to parse invalid JSON", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    `undefined`->S.parseJsonWith(struct),
    Error(
      "[ReScript Struct] Failed parsing at root. Reason: Unexpected token u in JSON at position 0",
    ),
    (),
  )
})
