open Ava

module Common = {
  let value = "ReScript is Great!"
  let any = %raw(`"ReScript is Great!"`)
  let wrongAny = %raw(`true`)
  let factory = () => S.string()

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Successfully parses without validation in Migration mode", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongAny->S.parseWith(~mode=Migration, struct), Ok(wrongAny), ())
  })

  test("Fails to parse in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "String", received: "Bool"}),
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
}
