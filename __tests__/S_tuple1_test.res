open Ava

module Common = {
  let value = 123
  let any = %raw(`[123]`)
  let wrongAny = %raw(`[123, true]`)
  let wrongTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.tuple1(. S.int())

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Fails to parse wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error({
        code: OperationFailed("Expected Tuple with 1 items, but received 2"),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "Tuple", received: "String"}),
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
