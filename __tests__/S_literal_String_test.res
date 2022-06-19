open Ava

module Common = {
  let value = "ReScript is Great!"
  let wrongValue = "Hello world!"
  let any = %raw(`"ReScript is Great!"`)
  let wrongAny = %raw(`"Hello world!"`)
  let wrongTypeAny = %raw(`true`)
  let factory = () => S.literal(String("ReScript is Great!"))

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Successfully parses without validation in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongAny->S.parseWith(~mode=Unsafe, struct), Ok(any), ())
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

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })

  test("Successfully serializes wrong value in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongValue->S.serializeWith(~mode=Unsafe, struct), Ok(any), ())
  })

  test("Fails to serialize wrong value in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongValue->S.serializeWith(struct),
      Error(`[ReScript Struct] Failed serializing at root. Reason: Expected "ReScript is Great!", got "Hello world!"`),
      (),
    )
  })
}
