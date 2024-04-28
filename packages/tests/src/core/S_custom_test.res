open Ava
open RescriptCore

let nullableSchema = innerSchema => {
  S.custom("Nullable", s => {
    parser: unknown => {
      if unknown === %raw(`undefined`) || unknown === %raw(`null`) {
        None
      } else {
        switch unknown->S.parseAnyWith(innerSchema) {
        | Ok(value) => Some(value)
        | Error(error) => s.failWithError(error)
        }
      }
    },
    serializer: value => {
      switch value {
      | Some(innerValue) =>
        switch innerValue->S.serializeToUnknownWith(innerSchema) {
        | Ok(value) => value
        | Error(error) => s.failWithError(error)
        }
      | None => %raw(`null`)
      }
    },
  })
}

test("Correctly parses custom schema", t => {
  let schema = nullableSchema(S.string)

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(schema), Ok(Some("Hello world!")), ())
  t->Assert.deepEqual(%raw(`null`)->S.parseAnyWith(schema), Ok(None), ())
  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(schema), Ok(None), ())
  t->U.assertErrorResult(123->S.parseAnyWith(schema), {
        code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`123`)}),
        operation: Parsing,
        path: S.Path.empty,
      })
})

test("Correctly serializes custom schema", t => {
  let schema = nullableSchema(S.string)

  t->Assert.deepEqual(
    Some("Hello world!")->S.serializeToUnknownWith(schema),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
  t->Assert.deepEqual(None->S.serializeToUnknownWith(schema), Ok(%raw(`null`)), ())
})

test("Fails to serialize with user error", t => {
  let schema = S.custom("Test", s => {
    serializer: _ => s.fail("User error"),
  })

  t->U.assertErrorResult(None->S.serializeToUnknownWith(schema), {code: OperationFailed("User error"), operation: Serializing, path: S.Path.empty})
})

test("Fails to serialize with serializer is missing", t => {
  let schema = S.custom("Test", _ => {
    parser: _ => (),
  })

  t->U.assertErrorResult(()->S.serializeToUnknownWith(schema), {
        code: InvalidOperation({description: "The S.custom serializer is missing"}),
        operation: Serializing,
        path: S.Path.empty,
      })
})

asyncTest("Parses with asyncParser", async t => {
  let schema = S.custom("Test", _ => {
    asyncParser: _ => () => Promise.resolve(),
  })

  t->Assert.deepEqual(await %raw(`undefined`)->S.parseAnyAsyncWith(schema), Ok(), ())
})
