open Ava

module Common = {
  let value = None
  let any = %raw(`null`)
  let invalidAny = %raw(`123.45`)
  let factory = () => S.null(S.string)

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
  let struct = S.null(S.bool)

  t->Assert.deepEqual(JSON.Encode.bool(true)->S.parseAnyWith(struct), Ok(Some(true)), ())
})

test("Fails to parse JS undefined", t => {
  let struct = S.null(S.bool)

  t->Assert.deepEqual(
    %raw(`undefined`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`undefined`)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to parse object with missing field that marked as null", t => {
  let struct = S.object(s => s.field("nullableField", S.null(S.string)))

  t->Assert.deepEqual(
    %raw(`{}`)->S.parseAnyWith(struct),
    Error({
      // FIXME: It should be S.null(S.string) here
      code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`undefined`)}),
      operation: Parsing,
      path: S.Path.fromArray(["nullableField"]),
    }),
    (),
  )
})

test("Fails to parse JS null when struct doesn't allow optional data", t => {
  let struct = S.bool

  t->Assert.deepEqual(
    %raw(`null`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: struct->S.toUnknown, received: %raw(`null`)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully parses null and serializes it back for deprecated nullable struct", t => {
  let struct = S.null(S.bool)->S.deprecate("Deprecated")

  t->Assert.deepEqual(
    %raw(`null`)->S.parseAnyWith(struct)->Result.map(S.serializeToUnknownWith(_, struct)),
    Ok(Ok(%raw(`null`))),
    (),
  )
})

test("Successfully parses null and serializes it back for optional nullable struct", t => {
  let struct = S.option(S.null(S.bool))

  t->Assert.deepEqual(
    %raw(`null`)->S.parseAnyWith(struct)->Result.map(S.serializeToUnknownWith(_, struct)),
    Ok(Ok(%raw(`null`))),
    (),
  )
})
