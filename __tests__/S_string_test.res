open Ava

module Common = {
  let value = "ReScript is Great!"
  let unknown = %raw(`"ReScript is Great!"`)
  let wrongUnknown = %raw(`true`)
  let jsonString = `"ReScript is Great!"`
  let wrongJsonString = `true`
  let factory = () => S.string()

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
      Error("Struct decoding failed at root. Reason: Expected String, got Bool"),
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
      Error(`Struct decoding failed at root. Reason: Expected String, got Bool`),
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
