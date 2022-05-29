open Ava

module Common = {
  let value = None
  let any = %raw(`undefined`)
  let wrongAny = %raw(`123.45`)
  let jsonString = `undefined`
  let wrongJsonString = `123.45`
  let factory = () => S.deprecated(~message="Some warning", S.string())

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Successfully parses without validation in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongAny->S.parseWith(~mode=Unsafe, struct), Ok(wrongAny), ())
  })

  test("Fails to parse in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error("[ReScript Struct] Failed parsing at root. Reason: Expected String, got Float"),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })
}

test("Successfully parses primitive", t => {
  let struct = S.deprecated(S.bool())

  t->Assert.deepEqual(Js.Json.boolean(true)->S.parseWith(struct), Ok(Some(true)), ())
})

test("Successfully parses undefined", t => {
  let struct = S.deprecated(S.bool())

  t->Assert.deepEqual(%raw(`undefined`)->S.parseWith(struct), Ok(None), ())
})

test("Fails to parse null", t => {
  let struct = S.deprecated(S.bool())

  t->Assert.deepEqual(
    %raw(`null`)->S.parseWith(struct),
    Error(`[ReScript Struct] Failed parsing at root. Reason: Expected Bool, got Null`),
    (),
  )
})

test("Successfully parses null for deprecated nullable struct", t => {
  let struct = S.deprecated(S.null(S.bool()))

  t->Assert.deepEqual(%raw(`null`)->S.parseWith(struct), Ok(Some(None)), ())
})
