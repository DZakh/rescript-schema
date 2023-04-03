open Ava

let nullableStruct = innerStruct =>
  S.custom(
    ~name="Nullable",
    ~parser=(. ~unknown) => {
      unknown
      ->Obj.magic
      ->Js.Nullable.toOption
      ->Belt.Option.map(innerValue =>
        switch innerValue->S.parseAnyWith(innerStruct) {
        | Ok(value) => value
        | Error(error) => S.Error.raiseCustom(error)
        }
      )
    },
    ~serializer=(. ~value) => {
      switch value {
      | Some(innerValue) =>
        switch innerValue->S.serializeToUnknownWith(innerStruct) {
        | Ok(value) => value
        | Error(error) => S.Error.raiseCustom(error)
        }
      | None => %raw("null")
      }
    },
    (),
  )

test("Correctly parses custom struct", t => {
  let struct = nullableStruct(S.string())

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(struct), Ok(Some("Hello world!")), ())
  t->Assert.deepEqual(%raw("null")->S.parseAnyWith(struct), Ok(None), ())
  t->Assert.deepEqual(%raw("undefined")->S.parseAnyWith(struct), Ok(None), ())
  t->Assert.deepEqual(
    123->S.parseAnyWith(struct),
    Error({
      code: UnexpectedType({expected: "String", received: "Float"}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Correctly serializes custom struct", t => {
  let struct = nullableStruct(S.string())

  t->Assert.deepEqual(
    Some("Hello world!")->S.serializeToUnknownWith(struct),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
  t->Assert.deepEqual(None->S.serializeToUnknownWith(struct), Ok(%raw("null")), ())
})

test("Fails to serialize with user error", t => {
  let struct = S.custom(
    ~name="Test",
    ~serializer=(. ~value as _) => {
      S.Error.raise("User error")
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
