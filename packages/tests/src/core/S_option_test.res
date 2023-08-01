open Ava

module Common = {
  let value = None
  let any = %raw(`undefined`)
  let invalidAny = %raw(`123.45`)
  let factory = () => S.option(S.string)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidAny->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: S.string->S.toUnknown, received: invalidAny}),
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

test("Successfully parses primitive", t => {
  let struct = S.option(S.bool)

  t->Assert.deepEqual(JSON.Encode.bool(true)->S.parseAnyWith(struct), Ok(Some(true)), ())
})

test("Fails to parse JS null", t => {
  let struct = S.option(S.bool)

  t->Assert.deepEqual(
    %raw(`null`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`null`)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to parse JS undefined when struct doesn't allow optional data", t => {
  let struct = S.bool

  t->Assert.deepEqual(
    %raw(`undefined`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: struct->S.toUnknown, received: %raw(`undefined`)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
