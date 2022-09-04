open Ava

type recordWithOneField = {key: string}

ava->test("Successfully parses Record with unknown keys by default", t => {
  let any = %raw(`{key: "value", unknownKey: "value2"}`)

  let struct = S.record1(. ("key", S.string()))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok("value"), ())
})

ava->test("Fails fast and shows only one excees key in the error message", t => {
  let any = %raw(`{key: "value", unknownKey: "value2", unknownKey2: "value2"}`)

  let struct = S.record1(. ("key", S.string()))->S.Record.strict

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

ava->test("Successfully parses Record with unknown keys when Strip strategy applyed", t => {
  let value = "value"
  let any = %raw(`{key: "value", unknownKey: "value2"}`)

  let struct = S.record1(. ("key", S.string()))->S.Record.strip

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

ava->test("Works correctly when the same unknown keys strategy applyed multiple times", t => {
  let value = "value"
  let any = %raw(`{key: "value", unknownKey: "value2"}`)

  let struct = S.record1(. ("key", S.string()))->S.Record.strip->S.Record.strip->S.Record.strip

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

ava->test("Doesn't raise an error when unknown keys strategy applyed to a non Record struct", t => {
  t->Assert.notThrows(() => {
    S.string()->S.Record.strip->ignore
  }, ())
  t->Assert.notThrows(() => {
    S.string()->S.Record.strict->ignore
  }, ())
})

ava->test("Can reset unknown keys strategy applying Strict strategy", t => {
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
