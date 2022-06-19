open Ava

type recordWithOneField = {key: string}

test("Fails to parse Record with unknown keys by default", t => {
  let any = %raw(`{key: "value", unknownKey: "value2"}`)

  let struct = S.record1(~fields=("key", S.string()), ~parser=key => {{key: key}}->Ok, ())

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error(`[ReScript Struct] Failed parsing at root. Reason: Encountered disallowed excess key "unknownKey" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely`),
    (),
  )
})

test("Fails fast and shows only one excees key in the error message", t => {
  let any = %raw(`{key: "value", unknownKey: "value2", unknownKey2: "value2"}`)

  let struct = S.record1(~fields=("key", S.string()), ~parser=key => {{key: key}}->Ok, ())

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error(`[ReScript Struct] Failed parsing at root. Reason: Encountered disallowed excess key "unknownKey" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely`),
    (),
  )
})

test("Successfully parses Record with unknown keys in Unsafe mode ignoring validation", t => {
  let value = {key: "value"}
  let any = %raw(`{key: "value", unknownKey: "value2"}`)

  let struct = S.record1(~fields=("key", S.string()), ~parser=key => {{key: key}}->Ok, ())

  t->Assert.deepEqual(any->S.parseWith(~mode=Unsafe, struct), Ok(value), ())
})

test("Successfully parses Record with unknown keys when Strip strategy applyed", t => {
  let value = {key: "value"}
  let any = %raw(`{key: "value", unknownKey: "value2"}`)

  let struct =
    S.record1(~fields=("key", S.string()), ~parser=key => {{key: key}}->Ok, ())->S.Record.strip

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Works correctly when the same unknown keys strategy applyed multiple times", t => {
  let value = {key: "value"}
  let any = %raw(`{key: "value", unknownKey: "value2"}`)

  let struct =
    S.record1(~fields=("key", S.string()), ~parser=key => {{key: key}}->Ok, ())
    ->S.Record.strip
    ->S.Record.strip
    ->S.Record.strip

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Raises error when unknown keys strategy applyed to a non Record struct", t => {
  t->Assert.throws(() => {
    S.string()->S.Record.strip->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message="Can\'t set up unknown keys strategy. The struct is not Record",
    (),
  ), ())
  t->Assert.throws(() => {
    S.string()->S.Record.strict->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message="Can\'t set up unknown keys strategy. The struct is not Record",
    (),
  ), ())
})

test("Can reset unknown keys strategy applying Strict strategy", t => {
  let any = %raw(`{key: "value", unknownKey: "value2"}`)

  let struct =
    S.record1(~fields=("key", S.string()), ~parser=key => {{key: key}}->Ok, ())
    ->S.Record.strip
    ->S.Record.strict

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error(`[ReScript Struct] Failed parsing at root. Reason: Encountered disallowed excess key "unknownKey" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely`),
    (),
  )
})
