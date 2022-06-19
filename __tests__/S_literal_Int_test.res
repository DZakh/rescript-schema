open Ava

module Common = {
  let value = 123
  let wrongValue = 444
  let any = %raw(`123`)
  let wrongAny = %raw(`444`)
  let wrongTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(Int(123))

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
      Error({
        code: UnexpectedValue({expected: "123", received: "444"}),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "Int Literal (123)", received: "String"}),
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

  test("Successfully serializes wrong value in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongValue->S.serializeWith(~mode=Unsafe, struct), Ok(any), ())
  })

  test("Fails to serialize wrong value in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongValue->S.serializeWith(struct),
      Error({
        code: UnexpectedValue({expected: "123", received: "444"}),
        operation: Serializing,
        path: [],
      }),
      (),
    )
  })
}
