open Ava
open RescriptCore

module Common = {
  let value = None
  let any = %raw(`undefined`)
  let invalidAny = %raw(`123.45`)
  let factory = () => S.string->S.option->S.deprecate("Some warning")

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidAny->S.parseAnyWith(struct),
      Error(
        U.error({
          code: InvalidType({expected: struct->S.toUnknown, received: invalidAny}),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(struct), Ok(any), ())
  })
}

test("Successfully parses primitive", t => {
  let struct = S.bool->S.option->S.deprecate("Deprecated")

  t->Assert.deepEqual(JSON.Encode.bool(true)->S.parseAnyWith(struct), Ok(Some(true)), ())
})

test("Successfully parses undefined", t => {
  let struct = S.bool->S.option->S.deprecate("Deprecated")

  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(struct), Ok(None), ())
})

test("Fails to parse null", t => {
  let struct = S.bool->S.option->S.deprecate("Deprecated")

  t->Assert.deepEqual(
    %raw(`null`)->S.parseAnyWith(struct),
    Error(
      U.error({
        code: InvalidType({expected: struct->S.toUnknown, received: %raw(`null`)}),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Successfully parses null for deprecated nullable struct", t => {
  let struct = S.null(S.bool)->S.option->S.deprecate("Deprecated")

  t->Assert.deepEqual(%raw(`null`)->S.parseAnyWith(struct), Ok(None), ())
})
