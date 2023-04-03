open Ava

module Common = {
  let value = ()
  let wrongValue = %raw(`123`)
  let any = %raw(`NaN`)
  let wrongTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(NaN)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseAnyWith(struct),
      Error({
        code: UnexpectedType({expected: "NaN Literal (NaN)", received: "String"}),
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
        code: UnexpectedValue({expected: "undefined", received: "123"}),
        operation: Serializing,
        path: S.Path.empty,
      }),
      (),
    )
  })
}
