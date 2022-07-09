open Ava

type recordWithOneField = {key: string}

test("Fails to parse Record with unknown keys by default", t => {
  let any = %raw(`{key: "value", unknownKey: "value2"}`)

  let struct = S.record1(. ("key", S.string()))

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error({
      code: ExcessField("unknownKey"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Fails fast and shows only one excees key in the error message", t => {
  let any = %raw(`{key: "value", unknownKey: "value2", unknownKey2: "value2"}`)

  let struct = S.record1(. ("key", S.string()))

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error({
      code: ExcessField("unknownKey"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully parses Record with unknown keys in Unsafe mode ignoring validation", t => {
  let value = "value"
  let any = %raw(`{key: "value", unknownKey: "value2"}`)

  let struct = S.record1(. ("key", S.string()))

  t->Assert.deepEqual(any->S.parseWith(~mode=Unsafe, struct), Ok(value), ())
})

test("Successfully parses Record with unknown keys when Strip strategy applyed", t => {
  let value = "value"
  let any = %raw(`{key: "value", unknownKey: "value2"}`)

  let struct = S.record1(. ("key", S.string()))->S.Record.strip

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Works correctly when the same unknown keys strategy applyed multiple times", t => {
  let value = "value"
  let any = %raw(`{key: "value", unknownKey: "value2"}`)

  let struct = S.record1(. ("key", S.string()))->S.Record.strip->S.Record.strip->S.Record.strip

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Raises error when unknown keys strategy applyed to a non Record struct", t => {
  t->Assert.throws(() => {
    S.string()->S.Record.strip->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message=String("Can\'t set up unknown keys strategy. The struct is not Record"),
    (),
  ), ())
  t->Assert.throws(() => {
    S.string()->S.Record.strict->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message=String("Can\'t set up unknown keys strategy. The struct is not Record"),
    (),
  ), ())
})

test("Can reset unknown keys strategy applying Strict strategy", t => {
  let any = %raw(`{key: "value", unknownKey: "value2"}`)

  let struct = S.record1(. ("key", S.string()))->S.Record.strip->S.Record.strict

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error({
      code: ExcessField("unknownKey"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})
