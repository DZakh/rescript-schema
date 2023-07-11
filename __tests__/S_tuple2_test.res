open Ava

module Common = {
  let value = (123, true)
  let any = %raw(`[123, true]`)
  let invalidAny = %raw(`[123]`)
  let invalidTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.tuple2(S.int, S.bool)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse invalid value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidAny->S.parseAnyWith(struct),
      Error({
        code: InvalidTupleSize({
          expected: 2,
          received: 1,
        }),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to parse invalid type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidTypeAny->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: struct->S.toUnknown, received: invalidTypeAny}),
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
