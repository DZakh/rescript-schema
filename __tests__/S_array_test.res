open Ava

module CommonWithNested = {
  let value = ["Hello world!", ""]
  let any = %raw(`["Hello world!", ""]`)
  let wrongAny = %raw(`true`)
  let nestedWrongAny = %raw(`["Hello world!", 1]`)
  let factory = () => S.array(S.string)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: "Array", received: "Bool"}),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to parse nested", t => {
    let struct = factory()

    t->Assert.deepEqual(
      nestedWrongAny->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: "String", received: "Float"}),
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
      code: InvalidType({expected: "String", received: "Float"}),
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
