open Ava

module Common = {
  let value = None
  let any = %raw(`undefined`)
  let wrongAny = %raw(`123.45`)
  let factory = () => S.option(S.string())

  ava->test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  ava->test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "String", received: "Float"}),
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

ava->test("Successfully parses primitive", t => {
  let struct = S.option(S.bool())

  t->Assert.deepEqual(Js.Json.boolean(true)->S.parseWith(struct), Ok(Some(true)), ())
})

ava->test("Fails to parse JS null", t => {
  let struct = S.option(S.bool())

  t->Assert.deepEqual(
    %raw(`null`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Bool", received: "Null"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

ava->test("Fails to parse JS undefined when struct doesn't allow optional data", t => {
  let struct = S.bool()

  t->Assert.deepEqual(
    %raw(`undefined`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Bool", received: "Option"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})
