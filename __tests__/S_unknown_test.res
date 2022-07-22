open Ava

module Common = {
  let any = %raw(`"Hello world!"`)
  let factory = () => S.unknown()

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(any), ())
  })

  test("Successfully parses in Migration mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(~mode=Migration, struct), Ok(any), ())
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.serializeWith(struct), Ok(any), ())
  })
}
