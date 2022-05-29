open Ava

module Common = {
  let value = 123.
  let any = %raw(`123`)
  let wrongAny = %raw(`"Hello world!"`)
  let jsonString = `123`
  let wrongJsonString = `"Hello world!"`
  let factory = () => S.float()

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Successfully parses without validation in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongAny->S.parseWith(~mode=Unsafe, struct), Ok(wrongAny), ())
  })

  test("Fails to parse in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error("[ReScript Struct] Failed parsing at root. Reason: Expected Float, got String"),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })
}

test("Successfully parses number with a fractional part", t => {
  let struct = S.float()

  t->Assert.deepEqual(%raw(`123.123`)->S.parseWith(struct), Ok(123.123), ())
})
