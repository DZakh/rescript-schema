open Ava

let nullableStruct = innerStruct =>
  S.custom(
    ~name="Nullable",
    ~parser=(. ~unknown) => {
      unknown
      ->Obj.magic
      ->Js.Nullable.toOption
      ->Belt.Option.map(innerValue =>
        switch innerValue->S.parseWith(innerStruct) {
        | Ok(value) => value
        | Error(error) => S.Error.raiseCustom(error)
        }
      )
    },
    ~serializer=(. ~value) => {
      switch value {
      | Some(innerValue) =>
        switch innerValue->S.serializeWith(innerStruct) {
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

  t->Assert.deepEqual("Hello world!"->S.parseWith(struct), Ok(Some("Hello world!")), ())
  t->Assert.deepEqual(%raw("null")->S.parseWith(struct), Ok(None), ())
  t->Assert.deepEqual(%raw("undefined")->S.parseWith(struct), Ok(None), ())
  t->Assert.deepEqual(
    123->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "String", received: "Float"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Correctly serializes custom struct", t => {
  let struct = nullableStruct(S.string())

  t->Assert.deepEqual(Some("Hello world!")->S.serializeWith(struct), Ok(%raw(`"Hello world!"`)), ())
  t->Assert.deepEqual(None->S.serializeWith(struct), Ok(%raw("null")), ())
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
    None->S.serializeWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Throws for a Custom factory without either a parser, or a serializer", t => {
  t->Assert.throws(() => {
    S.custom(~name="Test", ())->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message=String("For a Custom struct factory either a parser, or a serializer is required"),
    (),
  ), ())
})
