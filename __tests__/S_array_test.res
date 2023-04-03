open Ava

module CommonWithNested = {
  let value = ["Hello world!", ""]
  let any = %raw(`["Hello world!", ""]`)
  let wrongAny = %raw(`true`)
  let nestedWrongAny = %raw(`["Hello world!", 1]`)
  let factory = () => S.array(S.string())

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseAnyWith(struct),
      Error({
        code: UnexpectedType({expected: "Array", received: "Bool"}),
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
        code: UnexpectedType({expected: "String", received: "Float"}),
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

test("Successfully parses array of optional items", t => {
  let struct = S.array(S.option(S.string()))

  t->Assert.deepEqual(
    %raw(`["a", undefined, undefined, "b"]`)->S.parseAnyWith(struct),
    Ok([Some("a"), None, None, Some("b")]),
    (),
  )
})
