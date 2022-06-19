open Ava

module Common = {
  let value = ()
  let any = %raw(`123`)
  let wrongTypeAny = %raw(`"Hello"`)
  let factory = () => S.literalUnit(Int(123))

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(), ())
  })

  test("Successfully parses without validation in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongTypeAny->S.parseWith(~mode=Unsafe, struct), Ok(value), ())
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "Int Literal (123)", received: "String"}),
        path: [],
        operation: Parsing,
      }),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })
}
