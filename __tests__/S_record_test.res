open Ava

type user = {name: string, email: string, age: int}

test("Successfully parses record without fields", t => {
  let value = ()
  let any = %raw(`{}`)

  let struct = S.record0(.)

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses record with single field", t => {
  let value = "bar"
  let any = %raw(`{foo: "bar"}`)

  let struct = S.record1(. ("foo", S.string()))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses record with multiple fields", t => {
  let value = ("bar", "jee")
  let any = %raw(`{boo: "bar", zoo: "jee"}`)

  let struct = S.record2(. ("boo", S.string()), ("zoo", S.string()))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses record with mapped field names", t => {
  let value = {name: "Dmitry", email: "dzakh.dev@gmail.com", age: 21}
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let struct =
    S.record3(.
      ("Name", S.string()),
      ("Email", S.string()),
      ("Age", S.int()),
    )->S.transform(~parser=((name, email, age)) => {name: name, email: email, age: age}->Ok, ())

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses record with optional nested record when it's Some", t => {
  let value = Some("bar")
  let any = %raw(`{"singleFieldRecord":{"MUST_BE_MAPPED":"bar"}}`)

  let struct = S.record1(. (
    "singleFieldRecord",
    S.option(S.record1(. ("MUST_BE_MAPPED", S.string()))),
  ))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses record with optional nested record when it's None", t => {
  let value = None
  let any = %raw(`{}`)

  let struct = S.record1(. (
    "singleFieldRecord",
    S.option(S.record1(. ("MUST_BE_MAPPED", S.string()))),
  ))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses record with deprecated nested record when it's Some", t => {
  let value = Some("bar")
  let any = %raw(`{"singleFieldRecord":{"MUST_BE_MAPPED":"bar"}}`)

  let struct = S.record1(. (
    "singleFieldRecord",
    S.deprecated(S.record1(. ("MUST_BE_MAPPED", S.string()))),
  ))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses record with deprecated nested record when it's None", t => {
  let value = None
  let any = %raw(`{}`)

  let struct = S.record1(. (
    "singleFieldRecord",
    S.deprecated(S.record1(. ("MUST_BE_MAPPED", S.string()))),
  ))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses array of records", t => {
  let value = ["bar", "baz"]
  let any = %raw(`[{"MUST_BE_MAPPED":"bar"},{"MUST_BE_MAPPED":"baz"}]`)

  let struct = S.array(S.record1(. ("MUST_BE_MAPPED", S.string())))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully serializes record without fields", t => {
  let value = ()
  let any = %raw(`{}`)

  let struct = S.record0(.)

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes record with single field", t => {
  let value = "bar"
  let any = %raw(`{foo: "bar"}`)

  let struct = S.record1(. ("foo", S.string()))

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes record with multiple fields", t => {
  let value = ("bar", "jee")
  let any = %raw(`{boo: "bar", zoo: "jee"}`)

  let struct = S.record2(. ("boo", S.string()), ("zoo", S.string()))

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes record with mapped field", t => {
  let value = {name: "Dmitry", email: "dzakh.dev@gmail.com", age: 21}
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let struct =
    S.record3(.
      ("Name", S.string()),
      ("Email", S.string()),
      ("Age", S.int()),
    )->S.transform(~serializer=({name, email, age}) => (name, email, age)->Ok, ())

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes record with optional nested record when it's Some", t => {
  let value = Some("bar")
  let any = %raw(`{"singleFieldRecord":{"MUST_BE_MAPPED":"bar"}}`)

  let struct = S.record1(. (
    "singleFieldRecord",
    S.option(S.record1(. ("MUST_BE_MAPPED", S.string()))),
  ))

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes record with optional nested record when it's None", t => {
  let value = None
  let any = %raw(`{"singleFieldRecord":undefined}`)

  let struct = S.record1(. (
    "singleFieldRecord",
    S.option(S.record1(. ("MUST_BE_MAPPED", S.string()))),
  ))

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes unknown array of records", t => {
  let value = ["bar", "baz"]
  let any = %raw(`[{"MUST_BE_MAPPED":"bar"},{"MUST_BE_MAPPED":"baz"}]`)

  let struct = S.array(S.record1(. ("MUST_BE_MAPPED", S.string())))

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully parses a record and serializes it back to the initial state", t => {
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let struct = S.record3(. ("Name", S.string()), ("Email", S.string()), ("Age", S.int()))

  t->Assert.deepEqual(
    any->S.parseWith(struct)->Belt.Result.map(record => record->S.serializeWith(struct)),
    Ok(Ok(any)),
    (),
  )
})

test("Fails to parse record when provided data of another type", t => {
  let struct = S.record1(. ("FOO", S.string()))

  t->Assert.deepEqual(
    Js.Json.string("string")->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Record", received: "String"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Fails to parse record item when it's not present", t => {
  let struct = S.record1(. ("FOO", S.string()))

  t->Assert.deepEqual(
    %raw(`{}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "String", received: "Option"}),
      operation: Parsing,
      path: ["FOO"],
    }),
    (),
  )
})

test("Fails to parse record item when it's not valid", t => {
  let struct = S.record1(. ("FOO", S.string()))

  t->Assert.deepEqual(
    %raw(`{FOO:123}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "String", received: "Float"}),
      operation: Parsing,
      path: ["FOO"],
    }),
    (),
  )
})

test(
  "Record fields are in correct order when field structs have different operation types. We keep originalIdx to make it work",
  t => {
    let any = {
      "noopOp1": 1,
      "syncOp1": 2,
      "noopOp2": 3,
    }

    let struct = S.record3(.
      ("noopOp1", S.int()),
      ("syncOp1", S.int()->S.transform(~parser=v => v->Ok, ())),
      ("noopOp2", S.int()),
    )

    t->Assert.deepEqual(any->S.parseWith(~mode=Migration, struct), Ok((1, 2, 3)), ())
  },
)
