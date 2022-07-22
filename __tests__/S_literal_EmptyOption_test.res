open Ava

module Common = {
  let value = ()
  let wrongValue = %raw(`123`)
  let any = %raw(`undefined`)
  let wrongTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(EmptyOption)

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Successfully parses without validation in Migration mode", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongTypeAny->S.parseWith(~mode=Migration, struct), Ok(any), ())
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "EmptyOption Literal (undefined)", received: "String"}),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })

  test("Fails to serialize wrong value", t => {
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
