open Ava

// TODO: Add more tests

test("Fails to parse invalid JSON", t => {
  let struct = S.json(S.unknown())

  t->Assert.deepEqual(
    `undefined`->S.parseWith(struct),
    Error(
      "[ReScript Struct] Failed parsing at root. Reason: Unexpected token u in JSON at position 0",
    ),
    (),
  )
})
