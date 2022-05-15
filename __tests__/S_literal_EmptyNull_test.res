open Ava

module Common = {
  let value = None
  let any = %raw(`null`)
  let wrongTypeAny = %raw(`"Hello world!"`)
  let jsonString = `null`
  let factory = () => S.literal(EmptyNull)

  test("Successfully constructs", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
  })

  test("Successfully constructs without validation. Note: Use S.parseWith instead", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongTypeAny->S.constructWith(struct), Ok(wrongTypeAny), ())
  })

  test("Successfully destructs", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.destructWith(struct), Ok(any), ())
  })

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseWith(struct),
      Error(
        "[ReScript Struct] Failed parsing at root. Reason: Expected EmptyNull Literal (null), got String",
      ),
      (),
    )
  })

  test("Successfully parses from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(jsonString->S.parseJsonWith(struct), Ok(value), ())
  })

  test("Successfully serializes to JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeJsonWith(struct), Ok(jsonString), ())
  })
}
