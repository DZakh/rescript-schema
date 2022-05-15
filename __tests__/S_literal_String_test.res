open Ava

module Common = {
  let value = "ReScript is Great!"
  let any = %raw(`"ReScript is Great!"`)
  let wrongAny = %raw(`"Hello world!"`)
  let wrongTypeAny = %raw(`true`)
  let jsonString = `"ReScript is Great!"`
  let wrongJsonString = `"Hello world!"`
  let factory = () => S.literal(String("ReScript is Great!"))

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

  test("Fails to parse wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at root. Reason: Expected "ReScript is Great!", got "Hello world!"`),
      (),
    )
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at root. Reason: Expected String Literal ("ReScript is Great!"), got Bool`),
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
      Error(`[ReScript Struct] Failed parsing at root. Reason: Expected "ReScript is Great!", got "Hello world!"`),
      (),
    )
  })

  test("Successfully serializes to JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeJsonWith(struct), Ok(jsonString), ())
  })
}
