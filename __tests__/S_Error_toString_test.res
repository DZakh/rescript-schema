open Ava

test("OperationFailed error", t => {
  t->Assert.is(
    {
      code: OperationFailed("Should be positive"),
      operation: Parsing,
      path: [],
    }->S.Error.toString,
    "[ReScript Struct] Failed parsing at root. Reason: Should be positive",
    (),
  )
})

test("Error with Serializing operation", t => {
  t->Assert.is(
    {
      code: OperationFailed("Should be positive"),
      operation: Serializing,
      path: [],
    }->S.Error.toString,
    "[ReScript Struct] Failed serializing at root. Reason: Should be positive",
    (),
  )
})

test("Error with path", t => {
  t->Assert.is(
    {
      code: OperationFailed("Should be positive"),
      operation: Parsing,
      path: ["0", "foo"],
    }->S.Error.toString,
    "[ReScript Struct] Failed parsing at [0][foo]. Reason: Should be positive",
    (),
  )
})

test("MissingParser error", t => {
  t->Assert.is(
    {
      code: MissingParser,
      operation: Parsing,
      path: [],
    }->S.Error.toString,
    "[ReScript Struct] Failed parsing at root. Reason: Struct parser is missing",
    (),
  )
})

test("MissingSerializer error", t => {
  t->Assert.is(
    {
      code: MissingSerializer,
      operation: Parsing,
      path: [],
    }->S.Error.toString,
    "[ReScript Struct] Failed parsing at root. Reason: Struct serializer is missing",
    (),
  )
})

test("UnexpectedType error", t => {
  t->Assert.is(
    {
      code: UnexpectedType({expected: "String", received: "Bool"}),
      operation: Parsing,
      path: [],
    }->S.Error.toString,
    "[ReScript Struct] Failed parsing at root. Reason: Expected String, received Bool",
    (),
  )
})

test("UnexpectedValue error", t => {
  t->Assert.is(
    {
      code: UnexpectedValue({expected: "false", received: "true"}),
      operation: Parsing,
      path: [],
    }->S.Error.toString,
    "[ReScript Struct] Failed parsing at root. Reason: Expected false, received true",
    (),
  )
})

test("ExcessField error", t => {
  t->Assert.is(
    {
      code: ExcessField("unknownKey"),
      operation: Parsing,
      path: [],
    }->S.Error.toString,
    `[ReScript Struct] Failed parsing at root. Reason: Encountered disallowed excess key "unknownKey" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely`,
    (),
  )
})

test("TupleSize error", t => {
  t->Assert.is(
    {
      code: TupleSize({expected: 1, received: 2}),
      operation: Parsing,
      path: [],
    }->S.Error.toString,
    `[ReScript Struct] Failed parsing at root. Reason: Expected Tuple with 1 items, received 2`,
    (),
  )
})

test("InvalidUnion error", t => {
  t->Assert.is(
    {
      code: InvalidUnion([
        {
          code: ExcessField("x"),
          operation: Parsing,
          path: [],
        },
        {
          code: ExcessField("y"),
          operation: Parsing,
          path: [],
        },
        {
          code: UnexpectedValue({expected: `"triangle"`, received: `"oval"`}),
          operation: Parsing,
          path: ["kind"],
        },
      ]),
      operation: Parsing,
      path: [],
    }->S.Error.toString,
    `[ReScript Struct] Failed parsing at root. Reason: Invalid union with following errors
- Encountered disallowed excess key "x" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely
- Encountered disallowed excess key "y" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely
- Expected "triangle", received "oval"`,
    (),
  )
})

test("InvalidUnion filters similar reasons", t => {
  t->Assert.is(
    {
      code: InvalidUnion([
        {
          code: UnexpectedType({expected: "Record", received: "String"}),
          operation: Parsing,
          path: [],
        },
        {
          code: UnexpectedType({expected: "Record", received: "String"}),
          operation: Parsing,
          path: [],
        },
        {
          code: UnexpectedType({expected: "Record", received: "String"}),
          operation: Parsing,
          path: [],
        },
      ]),
      operation: Parsing,
      path: [],
    }->S.Error.toString,
    `[ReScript Struct] Failed parsing at root. Reason: Invalid union with following errors
- Expected Record, received String`,
    (),
  )
})

test("Nested InvalidUnion error", t => {
  t->Assert.is(
    {
      code: InvalidUnion([
        {
          code: InvalidUnion([
            {
              code: UnexpectedType({expected: "Record", received: "String"}),
              operation: Parsing,
              path: [],
            },
            {
              code: UnexpectedType({expected: "Record", received: "String"}),
              operation: Parsing,
              path: [],
            },
            {
              code: UnexpectedType({expected: "Record", received: "String"}),
              operation: Parsing,
              path: [],
            },
          ]),
          operation: Parsing,
          path: [],
        },
      ]),
      operation: Parsing,
      path: [],
    }->S.Error.toString,
    `[ReScript Struct] Failed parsing at root. Reason: Invalid union with following errors
- Invalid union with following errors
  - Expected Record, received String`,
    (),
  )
})
