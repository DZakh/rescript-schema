open Ava

module Common = {
  let value = Js.Null.empty
  let invalidValue = %raw(`123`)
  let any = %raw(`null`)
  let invalidTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(Js.Null.empty)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse invalid type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidTypeAny->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({expected: Null, received: invalidTypeAny}),
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

  test("Fails to serialize invalid value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidValue->S.serializeToUnknownWith(struct),
      Error({
        code: InvalidLiteral({expected: Null, received: invalidValue}),
        operation: Serializing,
        path: S.Path.empty,
      }),
      (),
    )
  })
}
