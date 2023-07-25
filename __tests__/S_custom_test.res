open Ava

let nullableStruct = innerStruct =>
  S.custom(
    ~name="Nullable",
    ~parser=unknown => {
      if unknown === %raw(`undefined`) || unknown === %raw(`null`) {
        None
      } else {
        switch unknown->S.parseAnyWith(innerStruct) {
        | Ok(value) => Some(value)
        | Error(error) => S.advancedFail(error)
        }
      }
    },
    ~serializer=value => {
      switch value {
      | Some(innerValue) =>
        switch innerValue->S.serializeToUnknownWith(innerStruct) {
        | Ok(value) => value
        | Error(error) => S.advancedFail(error)
        }
      | None => %raw(`null`)
      }
    },
    (),
  )

test("Correctly parses custom struct", t => {
  let struct = nullableStruct(S.string)

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(struct), Ok(Some("Hello world!")), ())
  t->Assert.deepEqual(%raw(`null`)->S.parseAnyWith(struct), Ok(None), ())
  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(struct), Ok(None), ())
  t->Assert.deepEqual(
    123->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`123`)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
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
  let struct = S.custom(
    ~name="Test",
    ~serializer=_ => {
      S.fail("User error")
    },
    (),
  )

  t->Assert.deepEqual(
    None->S.serializeToUnknownWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to serialize with serializer is missing", t => {
  let struct = S.custom(~name="Test", ~parser=_ => (), ())

  t->Assert.deepEqual(
    ()->S.serializeToUnknownWith(struct),
    Error({
      code: MissingOperation({description: "The S.custom serializer is missing"}),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

asyncTest("Parses with asyncParser", async t => {
  let struct = S.custom(~name="Test", ~asyncParser=_ => Promise.resolve(), ())

  t->Assert.deepEqual(await %raw(`undefined`)->S.parseAnyAsyncWith(struct), Ok(), ())
})

test("Throws for a Custom factory without either a parser, or a serializer", t => {
  t->Assert.throws(
    () => {
      S.custom(~name="Test", ())
    },
    ~expectations={
      message: "[rescript-struct] For a Custom struct factory either a parser, or a serializer is required",
    },
    (),
  )
})

test("Throws for a Custom factory with both parser and asyncParser provided", t => {
  t->Assert.throws(
    () => {
      S.custom(~name="Test", ~parser=_ => (), ~asyncParser=_ => Promise.resolve(), ())
    },
    ~expectations={
      message: "[rescript-struct] The S.custom doesn\'t support the `parser` and `asyncParser` arguments simultaneously. Keep only `asyncParser`.",
    },
    (),
  )
})
