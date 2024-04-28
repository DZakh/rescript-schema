open Ava
open RescriptCore

module Common = {
  let value = None
  let any = %raw(`undefined`)
  let invalidAny = %raw(`123.45`)
  let factory = () => S.string->S.option->S.deprecate("Some warning")

  test("Successfully parses", t => {
    let schema = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(schema), Ok(value), ())
  })

  test("Fails to parse", t => {
    let schema = factory()

    t->U.assertErrorResult(invalidAny->S.parseAnyWith(schema), {
          code: InvalidType({expected: schema->S.toUnknown, received: invalidAny}),
          operation: Parsing,
          path: S.Path.empty,
        })
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(schema), Ok(any), ())
  })
}

test("Successfully parses primitive", t => {
  let schema = S.bool->S.option->S.deprecate("Deprecated")

  t->Assert.deepEqual(JSON.Encode.bool(true)->S.parseAnyWith(schema), Ok(Some(true)), ())
})

test("Successfully parses undefined", t => {
  let schema = S.bool->S.option->S.deprecate("Deprecated")

  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(schema), Ok(None), ())
})

test("Fails to parse null", t => {
  let schema = S.bool->S.option->S.deprecate("Deprecated")

  t->U.assertErrorResult(%raw(`null`)->S.parseAnyWith(schema), {
        code: InvalidType({expected: schema->S.toUnknown, received: %raw(`null`)}),
        operation: Parsing,
        path: S.Path.empty,
      })
})

test("Successfully parses null for deprecated nullable schema", t => {
  let schema = S.null(S.bool)->S.option->S.deprecate("Deprecated")

  t->Assert.deepEqual(%raw(`null`)->S.parseAnyWith(schema), Ok(None), ())
})
