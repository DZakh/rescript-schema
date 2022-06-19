open Ava

test("OperationFailed error", t => {
  t->Assert.is(
    {
      S.Error.code: OperationFailed("Should be positive"),
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
      S.Error.code: OperationFailed("Should be positive"),
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
      S.Error.code: OperationFailed("Should be positive"),
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
      S.Error.code: MissingParser,
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
      S.Error.code: MissingSerializer,
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
      S.Error.code: UnexpectedType({expected: "String", received: "Bool"}),
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
      S.Error.code: UnexpectedValue({expected: "false", received: "true"}),
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
      S.Error.code: ExcessField("unknownKey"),
      operation: Parsing,
      path: [],
    }->S.Error.toString,
    `[ReScript Struct] Failed parsing at root. Reason: Encountered disallowed excess key "unknownKey" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely`,
    (),
  )
})
