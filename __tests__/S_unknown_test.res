open Ava

module Common = {
  let any = %raw(`"Hello world!"`)
  let factory = () => S.unknown()

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(any), ())
  })

  test("Successfully parses in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(~mode=Unsafe, struct), Ok(any), ())
  })

  test("Successfully serializes in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.serializeWith(~mode=Safe, struct), Ok(any), ())
  })

  test("Successfully serializes in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.serializeWith(~mode=Unsafe, struct), Ok(any), ())
  })
}
