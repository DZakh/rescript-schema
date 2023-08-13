open Ava
open RescriptCore

let nullableStruct = innerStruct => {
  S.custom("Nullable", s => {
    parser: unknown => {
      if unknown === %raw(`undefined`) || unknown === %raw(`null`) {
        None
      } else {
        switch unknown->S.parseAnyWith(innerStruct) {
        | Ok(value) => Some(value)
        | Error(error) => s.failWithError(error)
        }
      }
    },
    serializer: value => {
      switch value {
      | Some(innerValue) =>
        switch innerValue->S.serializeToUnknownWith(innerStruct) {
        | Ok(value) => value
        | Error(error) => s.failWithError(error)
        }
      | None => %raw(`null`)
      }
    },
  })
}

test("Correctly parses custom struct", t => {
  let struct = nullableStruct(S.string)

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(struct), Ok(Some("Hello world!")), ())
  t->Assert.deepEqual(%raw(`null`)->S.parseAnyWith(struct), Ok(None), ())
  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(struct), Ok(None), ())
  t->Assert.deepEqual(
    123->S.parseAnyWith(struct),
    Error(
      U.error({
        code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`123`)}),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Correctly serializes custom struct", t => {
  let struct = nullableStruct(S.string)

  t->Assert.deepEqual(
    Some("Hello world!")->S.serializeToUnknownWith(struct),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
  t->Assert.deepEqual(None->S.serializeToUnknownWith(struct), Ok(%raw(`null`)), ())
})

test("Fails to serialize with user error", t => {
  let struct = S.custom("Test", s => {
    serializer: _ => s.fail("User error"),
  })

  t->Assert.deepEqual(
    None->S.serializeToUnknownWith(struct),
    Error(
      U.error({code: OperationFailed("User error"), operation: Serializing, path: S.Path.empty}),
    ),
    (),
  )
})

test("Fails to serialize with serializer is missing", t => {
  let struct = S.custom("Test", _ => {
    parser: _ => (),
  })

  t->Assert.deepEqual(
    ()->S.serializeToUnknownWith(struct),
    Error(
      U.error({
        code: InvalidOperation({description: "The S.custom serializer is missing"}),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

asyncTest("Parses with asyncParser", async t => {
  let struct = S.custom("Test", _ => {
    asyncParser: _ => () => Promise.resolve(),
  })

  t->Assert.deepEqual(await %raw(`undefined`)->S.parseAnyAsyncWith(struct), Ok(), ())
})
