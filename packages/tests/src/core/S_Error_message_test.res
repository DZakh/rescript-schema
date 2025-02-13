open Ava

test("OperationFailed error", t => {
  t->Assert.is(
    U.error({
      code: OperationFailed("Should be positive"),
      operation: Parse,
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
      operation: ReverseConvert,
      path: S.Path.empty,
    })->S.Error.message,
    "Failed converting at root. Reason: Should be positive",
    (),
  )
})

test("Error with path", t => {
  t->Assert.is(
    U.error({
      code: OperationFailed("Should be positive"),
      operation: Parse,
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
      operation: Parse,
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
      operation: Parse,
      path: S.Path.empty,
    })->S.Error.message,
    "Failed parsing at root. Reason: Expected string, received true",
    (),
  )
})

test("UnexpectedAsync error", t => {
  t->Assert.is(
    U.error({
      code: UnexpectedAsync,
      operation: Parse,
      path: S.Path.empty,
    })->S.Error.message,
    "Failed parsing at root. Reason: Encountered unexpected async transform or refine. Use ParseAsync operation instead",
    (),
  )
})

test("InvalidType with literal error", t => {
  t->Assert.is(
    U.error({
      code: InvalidType({expected: S.literal(false)->S.toUnknown, received: true->Obj.magic}),
      operation: Parse,
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
      operation: Parse,
      path: S.Path.empty,
    })->S.Error.message,
    `Failed parsing at root. Reason: Encountered disallowed excess key "unknownKey" on an object`,
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
      operation: Parse,
      path: S.Path.empty,
    })->S.Error.message,
    `Failed parsing at root. Reason: Expected [boolean, int32], received [1, 2, "foo"]`,
    (),
  )
})

test("InvalidUnion error", t => {
  t->Assert.is(
    U.error({
      code: InvalidUnion([
        U.error({
          code: InvalidType({
            expected: S.literal("circle")->S.toUnknown,
            received: "oval"->Obj.magic,
          }),
          operation: Parse,
          path: S.Path.fromArray(["kind"]),
        }),
        U.error({
          code: InvalidType({
            expected: S.literal("square")->S.toUnknown,
            received: "oval"->Obj.magic,
          }),
          operation: Parse,
          path: S.Path.fromArray(["kind"]),
        }),
        U.error({
          code: InvalidType({
            expected: S.literal("triangle")->S.toUnknown,
            received: "oval"->Obj.magic,
          }),
          operation: Parse,
          path: S.Path.fromArray(["kind"]),
        }),
      ]),
      operation: Parse,
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
          operation: Parse,
          path: S.Path.empty,
        }),
        U.error({
          code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
          operation: Parse,
          path: S.Path.empty,
        }),
        U.error({
          code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
          operation: Parse,
          path: S.Path.empty,
        }),
      ]),
      operation: Parse,
      path: S.Path.empty,
    })->S.Error.message,
    `Failed parsing at root. Reason: Invalid union with following errors
- Expected boolean, received "Hello world!"`,
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
              operation: Parse,
              path: S.Path.empty,
            }),
            U.error({
              code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
              operation: Parse,
              path: S.Path.empty,
            }),
            U.error({
              code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
              operation: Parse,
              path: S.Path.empty,
            }),
          ]),
          operation: Parse,
          path: S.Path.empty,
        }),
      ]),
      operation: Parse,
      path: S.Path.empty,
    })->S.Error.message,
    `Failed parsing at root. Reason: Invalid union with following errors
- Invalid union with following errors
  - Expected boolean, received "Hello world!"`,
    (),
  )
})

test("InvalidJsonSchema error", t => {
  t->Assert.is(
    U.error({
      code: InvalidJsonSchema(S.option(S.literal(true))->S.toUnknown),
      operation: ReverseConvert,
      path: S.Path.empty,
    })->S.Error.message,
    `Failed converting at root. Reason: The 'true | undefined' schema cannot be converted to JSON`,
    (),
  )
})
