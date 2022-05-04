open Ava

module Common = {
  let value = 123
  let unknown = %raw(`123`)
  let wrongUnknown = %raw(`123.45`)
  let jsonString = `123`
  let wrongJsonString = `123.45`
  let factory = () => S.int()

  test("Successfully constructs", t => {
    let struct = factory()

    t->Assert.deepEqual(unknown->S.constructWith(struct), Ok(value), ())
  })

  test("Successfully constructs without validation. Note: Use S.Json.decodeWith instead", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongUnknown->S.constructWith(struct), Ok(wrongUnknown), ())
  })

  test("Successfully destructs", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.destructWith(struct), Ok(unknown), ())
  })

  test("Successfully destructs without validation. Note: Use S.Json.encodeWith instead", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongUnknown->S.destructWith(struct), Ok(wrongUnknown), ())
  })

  test("Successfully decodes", t => {
    let struct = factory()

    t->Assert.deepEqual(unknown->S.Json.decodeWith(struct), Ok(value), ())
  })

  test("Fails to decode", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongUnknown->S.Json.decodeWith(struct),
      Error("Struct decoding failed at root. Reason: Expected Int, got Float"),
      (),
    )
  })

  test("Successfully decodes from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(jsonString->S.Json.decodeStringWith(struct), Ok(value), ())
  })

  test("Fails to decode from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongJsonString->S.Json.decodeStringWith(struct),
      Error(`Struct decoding failed at root. Reason: Expected Int, got Float`),
      (),
    )
  })

  test("Successfully encodes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.Json.encodeWith(struct), Ok(unknown), ())
  })

  test("Successfully encodes to JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.Json.encodeStringWith(struct), Ok(jsonString), ())
  })
}

test("Fails to decode int when JSON is a number bigger than +2^31", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    Js.Json.number(2147483648.)->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Int, got Float"),
    (),
  )
  t->Assert.deepEqual(Js.Json.number(2147483647.)->S.Json.decodeWith(struct), Ok(2147483647), ())
})

test("Fails to decode int when JSON is a number lower than -2^31", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    Js.Json.number(-2147483648.)->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Int, got Float"),
    (),
  )
  t->Assert.deepEqual(Js.Json.number(-2147483647.)->S.Json.decodeWith(struct), Ok(-2147483647), ())
})
