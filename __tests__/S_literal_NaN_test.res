open Ava

module Common = {
  let value = ()
  let wrongValue = %raw(`123`)
  let any = %raw(`NaN`)
  let wrongTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(NaN)

  ava->test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  ava->test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "NaN Literal (NaN)", received: "String"}),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  ava->test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })

  ava->test("Fails to serialize wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongValue->S.serializeWith(struct),
      Error({
        code: UnexpectedValue({expected: "undefined", received: "123"}),
        operation: Serializing,
        path: [],
      }),
      (),
    )
  })
}
