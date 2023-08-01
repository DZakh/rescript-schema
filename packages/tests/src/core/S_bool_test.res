open Ava

module Common = {
  let value = true
  let any = %raw(`true`)
  let invalidAny = %raw(`"Hello world!"`)
  let factory = () => S.bool

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse ", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidAny->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: struct->S.toUnknown, received: invalidAny}),
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

test("Parses bool when JSON is true", t => {
  let struct = S.bool

  t->Assert.deepEqual(JSON.Encode.bool(true)->S.parseAnyWith(struct), Ok(true), ())
})

test("Parses bool when JSON is false", t => {
  let struct = S.bool

  t->Assert.deepEqual(JSON.Encode.bool(false)->S.parseAnyWith(struct), Ok(false), ())
})
