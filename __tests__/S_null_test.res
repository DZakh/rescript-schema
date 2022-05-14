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

  test("Successfully constructs without validation. Note: Use S.parseWith instead", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongAny->S.constructWith(struct), Ok(wrongAny), ())
  })

  test("Successfully destructs", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.destructWith(struct), Ok(any), ())
  })

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error("[ReScript Struct] Failed parsing at root. Reason: Expected String, got Float"),
      (),
    )
  })

  test("Successfully parses from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(jsonString->S.parseJsonWith(struct), Ok(value), ())
  })

  test("Fails to parse from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongJsonString->S.parseJsonWith(struct),
      Error(`[ReScript Struct] Failed parsing at root. Reason: Expected String, got Float`),
      (),
    )
  })

  test("Successfully serializes to JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeJsonWith(struct), Ok(jsonString), ())
  })
}

test("Successfully parses primitive", t => {
  let struct = S.null(S.bool())

  t->Assert.deepEqual(Js.Json.boolean(true)->S.parseWith(struct), Ok(Some(true)), ())
})

test("Fails to parse JS undefined", t => {
  let struct = S.null(S.bool())

  t->Assert.deepEqual(
    %raw(`undefined`)->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: Expected Bool, got Option"),
    (),
  )
})

module MissingFieldThatMarkedAsNullable = {
  type record = {nullableField: option<string>}

  test("Fails to parse record with missing field that marked as null", t => {
    let struct = S.record1(
      ~fields=("nullableField", S.null(S.string())),
      ~constructor=nullableField => {nullableField: nullableField}->Ok,
      (),
    )

    t->Assert.deepEqual(
      %raw(`{}`)->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at ["nullableField"]. Reason: Expected String, got Option`),
      (),
    )
  })
}

test("Fails to parse JS null when struct doesn't allow optional data", t => {
  let struct = S.bool()

  t->Assert.deepEqual(
    %raw(`null`)->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: Expected Bool, got Null"),
    (),
  )
})

test("Successfully parses null and serializes it back for deprecated nullable struct", t => {
  let struct = S.deprecated(S.null(S.bool()))

  t->Assert.deepEqual(
    %raw(`null`)->S.parseWith(struct)->Belt.Result.map(S.destructWith(_, struct)),
    Ok(Ok(%raw(`null`))),
    (),
  )
})

test("Successfully parses null and serializes it back for optional nullable struct", t => {
  let struct = S.option(S.null(S.bool()))

  t->Assert.deepEqual(
    %raw(`null`)->S.parseWith(struct)->Belt.Result.map(S.destructWith(_, struct)),
    Ok(Ok(%raw(`null`))),
    (),
  )
})
