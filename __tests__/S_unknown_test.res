open Ava

module Common = {
  let any = %raw(`"Hello world!"`)
  let factory = () => S.unknown()

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(any), ())
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.serializeWith(struct), Ok(any), ())
  })
}
