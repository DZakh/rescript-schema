open Ava

module CommonWithNested = {
  let value = ["Hello world!", ""]
  let any = %raw(`["Hello world!", ""]`)
  let wrongAny = %raw(`true`)
  let nestedWrongAny = %raw(`["Hello world!", 1]`)
  let factory = () => S.array(S.string())

  ava->test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  ava->test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "Array", received: "Bool"}),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  ava->test("Fails to parse nested", t => {
    let struct = factory()

    t->Assert.deepEqual(
      nestedWrongAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "String", received: "Float"}),
        operation: Parsing,
        path: ["1"],
      }),
      (),
    )
  })

  ava->test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })
}

ava->test("Successfully parses array of optional items", t => {
  let struct = S.array(S.option(S.string()))

  t->Assert.deepEqual(
    %raw(`["a", undefined, undefined, "b"]`)->S.parseWith(struct),
    Ok([Some("a"), None, None, Some("b")]),
    (),
  )
})
