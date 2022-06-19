open Ava

module CommonWithNested = {
  let value = ["Hello world!", ""]
  let any = %raw(`["Hello world!", ""]`)
  let wrongAny = %raw(`true`)
  let nestedWrongAny = %raw(`["Hello world!", 1]`)
  let factory = () => S.array(S.string())

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Successfully parses without validation in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(nestedWrongAny->S.parseWith(~mode=Unsafe, struct), Ok(nestedWrongAny), ())
  })

  test("Fails to parse in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error("[ReScript Struct] Failed parsing at root. Reason: Expected Array, got Bool"),
      (),
    )
  })

  test("Fails to parse nested in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(
      nestedWrongAny->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at [1]. Reason: Expected String, got Float`),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })
}

test("Successfully parses array of optional items", t => {
  let struct = S.array(S.option(S.string()))

  t->Assert.deepEqual(
    %raw(`["a", undefined, undefined, "b"]`)->S.parseWith(struct),
    Ok([Some("a"), None, None, Some("b")]),
    (),
  )
})
