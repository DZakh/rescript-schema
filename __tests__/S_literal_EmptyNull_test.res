open Ava

module Common = {
  let value = None
  let wrongValue = Some(%raw(`123`))
  let any = %raw(`null`)
  let wrongTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(EmptyNull)

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test(
    "Successfully parses in Unsafe mode without validation and returns literal value. Note: Use S.parseWith instead",
    t => {
      let struct = factory()

      t->Assert.deepEqual(wrongTypeAny->S.parseWith(~mode=Unsafe, struct), Ok(value), ())
    },
  )

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseWith(struct),
      Error(
        "[ReScript Struct] Failed parsing at root. Reason: Expected EmptyNull Literal (null), got String",
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
      Error(`[ReScript Struct] Failed serializing at root. Reason: Expected EmptyNull Literal (null), got Float`),
      (),
    )
  })
}
