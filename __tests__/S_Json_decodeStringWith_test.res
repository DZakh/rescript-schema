open Ava

test("Decodes int", t => {
  let struct = S.int()

  t->Assert.deepEqual(`123`->S.Json.decodeStringWith(struct), Ok(123), ())
})

test("Fails to decode int", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    `"string"`->S.Json.decodeStringWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Int, got String"),
    (),
  )
})

test("Fails to decode invalid JSON", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    `undefined`->S.Json.decodeStringWith(struct),
    Error("Struct decoding failed at root. Reason: Unexpected token u in JSON at position 0"),
    (),
  )
})
