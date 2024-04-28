open Ava

module Common = {
  let value = (123, true)
  let any = %raw(`[123, true]`)
  let invalidAny = %raw(`[123]`)
  let invalidTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.tuple2(S.int, S.bool)

  test("Successfully parses", t => {
    let schema = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(schema), Ok(value), ())
  })

  test("Fails to parse invalid value", t => {
    let schema = factory()

    t->U.assertErrorResult(invalidAny->S.parseAnyWith(schema), {
          code: InvalidTupleSize({
            expected: 2,
            received: 1,
          }),
          operation: Parsing,
          path: S.Path.empty,
        })
  })

  test("Fails to parse invalid type", t => {
    let schema = factory()

    t->U.assertErrorResult(invalidTypeAny->S.parseAnyWith(schema), {
          code: InvalidType({expected: schema->S.toUnknown, received: invalidTypeAny}),
          operation: Parsing,
          path: S.Path.empty,
        })
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(schema), Ok(any), ())
  })
}
