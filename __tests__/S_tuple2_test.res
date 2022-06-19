open Ava

module Common = {
  let value = (123, true)
  let any = %raw(`[123, true]`)
  let wrongAny = %raw(`[123]`)
  let wrongTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.tuple2(. S.int(), S.bool())

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Fails to parse wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error(
        "[ReScript Struct] Failed parsing at root. Reason: Expected Tuple with 2 items, but received 1",
      ),
      (),
    )
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseWith(struct),
      Error("[ReScript Struct] Failed parsing at root. Reason: Expected Tuple, got String"),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })
}
