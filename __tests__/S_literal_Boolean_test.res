open Ava

module Common = {
  let value = false
  let wrongValue = %raw(`true`)
  let any = %raw(`false`)
  let wrongAny = %raw(`true`)
  let wrongTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(false)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({expected: Boolean(false), received: true->Obj.magic}),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({expected: Boolean(false), received: wrongTypeAny}),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(struct), Ok(any), ())
  })

  test("Fails to serialize wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongValue->S.serializeToUnknownWith(struct),
      Error({
        code: InvalidLiteral({expected: Boolean(false), received: wrongValue}),
        operation: Serializing,
        path: S.Path.empty,
      }),
      (),
    )
  })
}
