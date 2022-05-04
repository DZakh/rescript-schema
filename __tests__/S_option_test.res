open Ava

module Common = {
  let value = None
  let unknown = %raw(`undefined`)
  let wrongUnknown = %raw(`123.45`)
  let jsonString = `undefined`
  let wrongJsonString = `123.45`
  let factory = () => S.option(S.string())

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
      Error("Struct decoding failed at root. Reason: Expected String, got Float"),
      (),
    )
  })

  failing("Successfully decodes from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(jsonString->S.Json.decodeStringWith(struct), Ok(value), ())
  })

  test("Fails to decode from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongJsonString->S.Json.decodeStringWith(struct),
      Error(`Struct decoding failed at root. Reason: Expected String, got Float`),
      (),
    )
  })

  test("Successfully encodes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.Json.encodeWith(struct), Ok(unknown), ())
  })

  // FIXME: It should fail with encoding error
  failing("Successfully encodes to JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.Json.encodeStringWith(struct), Ok(jsonString), ())
  })
}

test("Decodes option when provided primitive", t => {
  let struct = S.option(S.bool())

  t->Assert.deepEqual(Js.Json.boolean(true)->S.Json.decodeWith(struct), Ok(Some(true)), ())
})

test("Fails to decode JS undefined when struct doesn't allow optional data", t => {
  let struct = S.bool()

  t->Assert.deepEqual(
    %raw(`undefined`)->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Bool, got Option"),
    (),
  )
})

todo("Fails to encode undefined to JSON string")
