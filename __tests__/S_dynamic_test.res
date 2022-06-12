open Ava

test("Successfully parses dynamic struct", t => {
  let struct = S.dynamic(~constructor=_ => S.string()->Ok, ())

  t->Assert.deepEqual(%raw(`"Hello world!"`)->S.parseWith(struct), Ok("Hello world!"), ())
})

test("Fails to parse when user returns error", t => {
  let struct = S.dynamic(~constructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    %raw(`"Hello world!"`)->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: User error"),
    (),
  )
})

test("Fails to parse when constructor isn't provided", t => {
  let struct = S.dynamic(~destructor=_ => S.string()->Ok, ())

  t->Assert.deepEqual(
    %raw(`"Hello world!"`)->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: Struct constructor is missing"),
    (),
  )
})

test("Fails to parse when provided invalid data", t => {
  let struct = S.dynamic(~constructor=_ => S.string()->Ok, ())

  t->Assert.deepEqual(
    %raw(`1234`)->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: Expected String, got Float"),
    (),
  )
})

test("Successfully serializes dynamic struct", t => {
  let struct = S.dynamic(~destructor=_ => S.string()->Ok, ())

  t->Assert.deepEqual("Hello world!"->S.serializeWith(struct), Ok(%raw(`"Hello world!"`)), ())
})

test("Fails to serialize when destructor isn't provided", t => {
  let struct = S.dynamic(~constructor=_ => S.string()->Ok, ())

  t->Assert.deepEqual(
    "Hello world!"->S.serializeWith(struct),
    Error("[ReScript Struct] Failed serializing at root. Reason: Struct destructor is missing"),
    (),
  )
})

test("Fails to serialize when user returns error", t => {
  let struct = S.dynamic(~destructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    "Hello world!"->S.serializeWith(struct),
    Error("[ReScript Struct] Failed serializing at root. Reason: User error"),
    (),
  )
})

test("Throws for a Dynamic struct factory without either a constructor, or a destructor", t => {
  t->Assert.throws(() => {
    S.dynamic()->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message="For a Dynamic struct factory either a constructor, or a destructor is required",
    (),
  ), ())
})
