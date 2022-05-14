open Ava

module Common = {
  let value = None
  let any = %raw(`null`)
  let wrongAny = %raw(`123.45`)
  let jsonString = `null`
  let wrongJsonString = `123.45`
  let factory = () => S.null(S.string())

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

  test("Successfully decodes from JSON string", t => {
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

  test("Successfully encodes to JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.encodeJsonWith(struct), Ok(jsonString), ())
  })
}

test("Successfully decodes primitive", t => {
  let struct = S.null(S.bool())

  t->Assert.deepEqual(Js.Json.boolean(true)->S.decodeWith(struct), Ok(Some(true)), ())
})

test("Fails to decode JS undefined", t => {
  let struct = S.null(S.bool())

  t->Assert.deepEqual(
    %raw(`undefined`)->S.decodeWith(struct),
    Error("[ReScript Struct] Failed decoding at root. Reason: Expected Bool, got Option"),
    (),
  )
})

module MissingFieldThatMarkedAsNullable = {
  type record = {nullableField: option<string>}

  test("Fails to decode record with missing field that marked as null", t => {
    let struct = S.record1(
      ~fields=("nullableField", S.null(S.string())),
      ~constructor=nullableField => {nullableField: nullableField}->Ok,
      (),
    )

    t->Assert.deepEqual(
      %raw(`{}`)->S.decodeWith(struct),
      Error(`[ReScript Struct] Failed decoding at ["nullableField"]. Reason: Expected String, got Option`),
      (),
    )
  })
}

test("Fails to decode JS null when struct doesn't allow optional data", t => {
  let struct = S.bool()

  t->Assert.deepEqual(
    %raw(`null`)->S.decodeWith(struct),
    Error("[ReScript Struct] Failed decoding at root. Reason: Expected Bool, got Null"),
    (),
  )
})
