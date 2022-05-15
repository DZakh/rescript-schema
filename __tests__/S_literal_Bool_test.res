open Ava

module Common = {
  let value = false
  let any = %raw(`false`)
  let wrongAny = %raw(`true`)
  let wrongTypeAny = %raw(`"Hello world!"`)
  let jsonString = `false`
  let wrongJsonString = `true`
  let factory = () => S.literal(Bool(false))

  test("Successfully constructs", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
  })

  test("Successfully constructs without validation. Note: Use S.parseWith instead", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongAny->S.constructWith(struct), Ok(wrongAny), ())
  })

  test("Successfully destructs", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.destructWith(struct), Ok(any), ())
  })

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Fails to parse wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error("[ReScript Struct] Failed parsing at root. Reason: Expected false, got true"),
      (),
    )
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseWith(struct),
      Error(
        "[ReScript Struct] Failed parsing at root. Reason: Expected Bool Literal (false), got String",
      ),
      (),
    )
  })

  test("Successfully parses from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(jsonString->S.parseJsonWith(struct), Ok(value), ())
  })

  test("Fails to parse from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongJsonString->S.parseJsonWith(struct),
      Error(`[ReScript Struct] Failed parsing at root. Reason: Expected false, got true`),
      (),
    )
  })

  test("Successfully serializes to JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeJsonWith(struct), Ok(jsonString), ())
  })
}
