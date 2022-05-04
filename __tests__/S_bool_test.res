open Ava

module Common = {
  let value = true
  let unknown = %raw(`true`)
  let wrongUnknown = %raw(`"Hello world!"`)
  let jsonString = `true`
  let wrongJsonString = `"Hello world!"`
  let factory = () => S.bool()

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
      Error("Struct decoding failed at root. Reason: Expected Bool, got String"),
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
      Error(`Struct decoding failed at root. Reason: Expected Bool, got String`),
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

test("Decodes bool when JSON is true", t => {
  let struct = S.bool()

  t->Assert.deepEqual(Js.Json.boolean(true)->S.Json.decodeWith(struct), Ok(true), ())
})

test("Decodes bool when JSON is false", t => {
  let struct = S.bool()

  t->Assert.deepEqual(Js.Json.boolean(false)->S.Json.decodeWith(struct), Ok(false), ())
})
