open Ava

module Common = {
  let value = true
  let any = %raw(`true`)
  let wrongAny = %raw(`"Hello world!"`)
  let jsonString = `true`
  let wrongJsonString = `"Hello world!"`
  let factory = () => S.bool()

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
      Error("[ReScript Struct] Failed decoding at root. Reason: Expected Bool, got String"),
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
      Error(`[ReScript Struct] Failed decoding at root. Reason: Expected Bool, got String`),
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

test("Decodes bool when JSON is true", t => {
  let struct = S.bool()

  t->Assert.deepEqual(Js.Json.boolean(true)->S.decodeWith(struct), Ok(true), ())
})

test("Decodes bool when JSON is false", t => {
  let struct = S.bool()

  t->Assert.deepEqual(Js.Json.boolean(false)->S.decodeWith(struct), Ok(false), ())
})
