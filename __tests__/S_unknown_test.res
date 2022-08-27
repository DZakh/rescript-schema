open Ava

module Common = {
  let any = %raw(`"Hello world!"`)
  let factory = () => S.unknown()

  ava->test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(any), ())
  })

  ava->test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.serializeWith(struct), Ok(any), ())
  })
}
