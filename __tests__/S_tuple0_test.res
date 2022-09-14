open Ava

module Common = {
  let value = ()
  let any = %raw(`[]`)
  let wrongAny = %raw(`[true]`)
  let wrongTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.tuple0(.)

  ava->test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  ava->test("Fails to parse wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error({
        code: TupleSize({
          expected: 0,
          received: 1,
        }),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  ava->test("Fails to parse wrong type", t => {
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

  ava->test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })
}
