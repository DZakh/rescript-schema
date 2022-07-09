open Ava

let nullableStruct = innerStruct =>
  S.custom(
    ~parser=(. ~unknown, ~mode) => {
      switch unknown->Obj.magic->Js.Nullable.toOption {
      | Some(innerValue) =>
        innerValue->S.parseWith(~mode, innerStruct)->Belt.Result.map(value => Some(value))
      | None => Ok(None)
      }
    },
    ~serializer=(. ~value, ~mode) => {
      switch value {
      | Some(innerValue) => innerValue->S.serializeWith(~mode, innerStruct)
      | None => Js.Null.empty->Obj.magic->Ok
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
  let struct = S.custom(~serializer=(. ~value as _, ~mode as _) => {
    Error(S.Error.make("User error"))
  }, ())

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
    S.custom()->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message=String("For a Custom struct factory either a parser, or a serializer is required"),
    (),
  ), ())
})
