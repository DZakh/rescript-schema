open Ava

module Common = {
  let value = None
  let any = %raw(`undefined`)
  let wrongAny = %raw(`123.45`)
  let factory = () => S.string()->S.deprecated(~message="Some warning", ())

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
  let struct = S.bool()->S.deprecated()

  t->Assert.deepEqual(Js.Json.boolean(true)->S.parseWith(struct), Ok(Some(true)), ())
})

ava->test("Successfully parses undefined", t => {
  let struct = S.bool()->S.deprecated()

  t->Assert.deepEqual(%raw(`undefined`)->S.parseWith(struct), Ok(None), ())
})

ava->test("Fails to parse null", t => {
  let struct = S.bool()->S.deprecated()

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

ava->test("Successfully parses null for deprecated nullable struct", t => {
  let struct = S.null(S.bool())->S.deprecated()

  t->Assert.deepEqual(%raw(`null`)->S.parseWith(struct), Ok(Some(None)), ())
})
