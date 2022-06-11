open Ava

module Common = {
  let value = ()
  let wrongValue = %raw(`123`)
  let any = %raw(`undefined`)
  let wrongTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(Unit)

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(), ())
  })

  test("Successfully parses without validation in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongTypeAny->S.parseWith(~mode=Unsafe, struct), Ok(any), ())
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseWith(struct),
      Error(
        "[ReScript Struct] Failed parsing at root. Reason: Expected Unit Literal (undefined), got String",
      ),
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
      Error(`[ReScript Struct] Failed serializing at root. Reason: Expected Unit Literal (undefined), got Float`),
      (),
    )
  })
}
