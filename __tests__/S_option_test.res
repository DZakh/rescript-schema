open Ava

module Common = {
  let value = None
  let any = %raw(`undefined`)
  let wrongAny = %raw(`123.45`)
  let jsonString = `undefined`
  let wrongJsonString = `123.45`
  let factory = () => S.option(S.string())

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
      Error("[ReScript Struct] Failed decoding at root. Reason: Expected String, got Float"),
      (),
    )
  })

  failing("Successfully decodes from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(jsonString->S.decodeJsonWith(struct), Ok(value), ())
  })

  test("Fails to decode from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongJsonString->S.decodeJsonWith(struct),
      Error(`[ReScript Struct] Failed decoding at root. Reason: Expected String, got Float`),
      (),
    )
  })

  test("Successfully encodes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.encodeWith(struct), Ok(any), ())
  })

  // FIXME: It should fail with encoding error
  failing("Successfully encodes to JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.encodeJsonWith(struct), Ok(jsonString), ())
  })
}

test("Successfully decodes primitive", t => {
  let struct = S.option(S.bool())

  t->Assert.deepEqual(Js.Json.boolean(true)->S.decodeWith(struct), Ok(Some(true)), ())
})

test("Fails to decode JS null", t => {
  let struct = S.option(S.bool())

  t->Assert.deepEqual(
    %raw(`null`)->S.decodeWith(struct),
    Error("[ReScript Struct] Failed decoding at root. Reason: Expected Bool, got Null"),
    (),
  )
})

test("Fails to decode JS undefined when struct doesn't allow optional data", t => {
  let struct = S.bool()

  t->Assert.deepEqual(
    %raw(`undefined`)->S.decodeWith(struct),
    Error("[ReScript Struct] Failed decoding at root. Reason: Expected Bool, got Option"),
    (),
  )
})

todo("Fails to encode undefined to JSON string")
