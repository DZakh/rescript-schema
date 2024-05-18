open Ava

test("OperationFailed error", t => {
  t->Assert.is(
    U.error({
      code: OperationFailed("Should be positive"),
      operation: Parsing,
      path: S.Path.empty,
    })->S.Error.message,
    "Failed parsing at root. Reason: Should be positive",
    (),
  )
})

test("Error with Serializing operation", t => {
  t->Assert.is(
    U.error({
      code: OperationFailed("Should be positive"),
      operation: Serializing,
      path: S.Path.empty,
    })->S.Error.message,
    "Failed serializing at root. Reason: Should be positive",
    (),
  )
})

test("Error with path", t => {
  t->Assert.is(
    U.error({
      code: OperationFailed("Should be positive"),
      operation: Parsing,
      path: S.Path.fromArray(["0", "foo"]),
    })->S.Error.message,
    `Failed parsing at ["0"]["foo"]. Reason: Should be positive`,
    (),
  )
})

test("InvalidOperation error", t => {
  t->Assert.is(
    U.error({
      code: InvalidOperation({description: "The S.transform serializer is missing"}),
      operation: Parsing,
      path: S.Path.empty,
    })->S.Error.message,
    "Failed parsing at root. Reason: The S.transform serializer is missing",
    (),
  )
})

test("InvalidType error", t => {
  t->Assert.is(
    U.error({
      code: InvalidType({expected: S.string->S.toUnknown, received: Obj.magic(true)}),
      operation: Parsing,
      path: S.Path.empty,
    })->S.Error.message,
    "Failed parsing at root. Reason: Expected String, received true",
    (),
  )
})

test("UnexpectedAsync error", t => {
  t->Assert.is(
    U.error({
      code: UnexpectedAsync,
      operation: Parsing,
      path: S.Path.empty,
    })->S.Error.message,
    "Failed parsing at root. Reason: Encountered unexpected asynchronous transform or refine. Use S.parseAsyncWith instead of S.parseWith",
    (),
  )
})

test("InvalidLiteral error", t => {
  t->Assert.is(
    U.error({
      code: InvalidLiteral({expected: S.Literal.parse(false), received: true->Obj.magic}),
      operation: Parsing,
      path: S.Path.empty,
    })->S.Error.message,
    "Failed parsing at root. Reason: Expected false, received true",
    (),
  )
})

test("ExcessField error", t => {
  t->Assert.is(
    U.error({
      code: ExcessField("unknownKey"),
      operation: Parsing,
      path: S.Path.empty,
    })->S.Error.message,
    `Failed parsing at root. Reason: Encountered disallowed excess key "unknownKey" on an object. Use Deprecated to ignore a specific field, or S.Object.strip to ignore excess keys completely`,
    (),
  )
})

test("InvalidType error (replacement for InvalidTupleSize)", t => {
  t->Assert.is(
    U.error({
      code: InvalidType({
        expected: S.tuple2(S.bool, S.int)->S.toUnknown,
        received: (1, 2, "foo")->Obj.magic,
      }),
      operation: Parsing,
      path: S.Path.empty,
    })->S.Error.message,
    `Failed parsing at root. Reason: Expected Tuple(Bool, Int), received [1,2,"foo"]`,
    (),
  )
})

test("InvalidUnion error", t => {
  t->Assert.is(
    U.error({
      code: InvalidUnion([
        U.error({
          code: InvalidLiteral({expected: S.Literal.parse("circle"), received: "oval"->Obj.magic}),
          operation: Parsing,
          path: S.Path.fromArray(["kind"]),
        }),
        U.error({
          code: InvalidLiteral({expected: S.Literal.parse("square"), received: "oval"->Obj.magic}),
          operation: Parsing,
          path: S.Path.fromArray(["kind"]),
        }),
        U.error({
          code: InvalidLiteral({
            expected: S.Literal.parse("triangle"),
            received: "oval"->Obj.magic,
          }),
          operation: Parsing,
          path: S.Path.fromArray(["kind"]),
        }),
      ]),
      operation: Parsing,
      path: S.Path.empty,
    })->S.Error.message,
    `Failed parsing at root. Reason: Invalid union with following errors
- Failed at ["kind"]. Expected "circle", received "oval"
- Failed at ["kind"]. Expected "square", received "oval"
- Failed at ["kind"]. Expected "triangle", received "oval"`,
    (),
  )
})

test("InvalidUnion filters similar reasons", t => {
  t->Assert.is(
    U.error({
      code: InvalidUnion([
        U.error({
          code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
          operation: Parsing,
          path: S.Path.empty,
        }),
        U.error({
          code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
          operation: Parsing,
          path: S.Path.empty,
        }),
        U.error({
          code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ]),
      operation: Parsing,
      path: S.Path.empty,
    })->S.Error.message,
    `Failed parsing at root. Reason: Invalid union with following errors
- Expected Bool, received "Hello world!"`,
    (),
  )
})

test("Nested InvalidUnion error", t => {
  t->Assert.is(
    U.error({
      code: InvalidUnion([
        U.error({
          code: InvalidUnion([
            U.error({
              code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
              operation: Parsing,
              path: S.Path.empty,
            }),
            U.error({
              code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
              operation: Parsing,
              path: S.Path.empty,
            }),
            U.error({
              code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
              operation: Parsing,
              path: S.Path.empty,
            }),
          ]),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ]),
      operation: Parsing,
      path: S.Path.empty,
    })->S.Error.message,
    `Failed parsing at root. Reason: Invalid union with following errors
- Invalid union with following errors
  - Expected Bool, received "Hello world!"`,
    (),
  )
})

test("InvalidJsonStruct error", t => {
  t->Assert.is(
    U.error({
      code: InvalidJsonStruct(S.option(S.literal(true))->S.toUnknown),
      operation: Serializing,
      path: S.Path.empty,
    })->S.Error.message,
    `Failed serializing at root. Reason: The schema Option(Literal(true)) is not compatible with JSON`,
    (),
  )
})
