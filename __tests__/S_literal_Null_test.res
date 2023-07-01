open Ava

module Common = {
  let value = Js.Null.empty
  let wrongValue = %raw(`123`)
  let any = %raw(`null`)
  let wrongTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(Js.Null.empty)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({expected: Null, received: wrongTypeAny}),
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
        code: InvalidLiteral({expected: Null, received: wrongValue}),
        operation: Serializing,
        path: S.Path.empty,
      }),
      (),
    )
  })
}
