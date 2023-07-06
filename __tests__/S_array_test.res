open Ava

module CommonWithNested = {
  let value = ["Hello world!", ""]
  let any = %raw(`["Hello world!", ""]`)
  let invalidAny = %raw(`true`)
  let nestedInvalidAny = %raw(`["Hello world!", 1]`)
  let factory = () => S.array(S.string)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
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

  test("Fails to parse nested", t => {
    let struct = factory()

    t->Assert.deepEqual(
      nestedInvalidAny->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: S.string->S.toUnknown, received: 1->Obj.magic}),
        operation: Parsing,
        path: S.Path.fromArray(["1"]),
      }),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(struct), Ok(any), ())
  })
}

test("Successfully parses matrix", t => {
  let struct = S.array(S.array(S.string))

  t->Assert.deepEqual(
    %raw(`[["a", "b"], ["c", "d"]]`)->S.parseAnyWith(struct),
    Ok([["a", "b"], ["c", "d"]]),
    (),
  )
})

test("Fails to parse matrix", t => {
  let struct = S.array(S.array(S.string))

  Js.log(%raw(`[["a", 1], ["c", "d"]]`)->S.parseAnyWith(struct))

  t->Assert.deepEqual(
    %raw(`[["a", 1], ["c", "d"]]`)->S.parseAnyWith(struct),
    Error({
      operation: Parsing,
      code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`1`)}),
      path: S.Path.fromArray(["0", "1"]),
    }),
    (),
  )
})

test("Successfully parses array of optional items", t => {
  let struct = S.array(S.option(S.string))

  t->Assert.deepEqual(
    %raw(`["a", undefined, undefined, "b"]`)->S.parseAnyWith(struct),
    Ok([Some("a"), None, None, Some("b")]),
    (),
  )
})
