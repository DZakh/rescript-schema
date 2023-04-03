open Ava

module Common = {
  let value = None
  let any = %raw(`undefined`)
  let wrongAny = %raw(`123.45`)
  let factory = () => S.option(S.string())

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseAnyWith(struct),
      Error({
        code: UnexpectedType({expected: "String", received: "Float"}),
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
  let struct = S.option(S.bool())

  t->Assert.deepEqual(Js.Json.boolean(true)->S.parseAnyWith(struct), Ok(Some(true)), ())
})

test("Fails to parse JS null", t => {
  let struct = S.option(S.bool())

  t->Assert.deepEqual(
    %raw(`null`)->S.parseAnyWith(struct),
    Error({
      code: UnexpectedType({expected: "Bool", received: "Null"}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to parse JS undefined when struct doesn't allow optional data", t => {
  let struct = S.bool()

  t->Assert.deepEqual(
    %raw(`undefined`)->S.parseAnyWith(struct),
    Error({
      code: UnexpectedType({expected: "Bool", received: "Option"}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
