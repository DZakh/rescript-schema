open Ava

module Common = {
  let value = "ReScript is Great!"
  let any = %raw(`"ReScript is Great!"`)
  let wrongAny = %raw(`true`)
  let jsonString = `"ReScript is Great!"`
  let wrongJsonString = `true`
  let factory = () => S.string()

  test("Successfully constructs", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
  })

  test("Successfully constructs without validation. Note: Use S.decodeWith instead", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongAny->S.constructWith(struct), Ok(wrongAny), ())
  })

  test("Successfully destructs", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.destructWith(struct), Ok(any), ())
  })

  test("Successfully destructs without validation. Note: Use S.encodeWith instead", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongAny->S.destructWith(struct), Ok(wrongAny), ())
  })

  test("Successfully decodes", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.decodeWith(struct), Ok(value), ())
  })

  test("Fails to decode", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.decodeWith(struct),
      Error("Struct decoding failed at root. Reason: Expected String, got Bool"),
      (),
    )
  })

  test("Successfully decodes from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(jsonString->S.decodeJsonWith(struct), Ok(value), ())
  })

  test("Fails to decode from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongJsonString->S.decodeJsonWith(struct),
      Error(`Struct decoding failed at root. Reason: Expected String, got Bool`),
      (),
    )
  })

  test("Successfully encodes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.encodeWith(struct), Ok(any), ())
  })

  test("Successfully encodes to JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.encodeJsonWith(struct), Ok(jsonString), ())
  })
}
