open Ava

module Common = {
  let value = "ReScript is Great!"
  let any = %raw(`"ReScript is Great!"`)
  let wrongAny = %raw(`true`)
  let factory = () => S.string()

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseAnyWith(struct),
      Error({
        code: UnexpectedType({expected: "String", received: "Bool"}),
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
}
