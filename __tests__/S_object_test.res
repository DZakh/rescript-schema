open Ava

type user = {name: string, email: string, age: int}

test("Successfully parses object without fields", t => {
  let value = ()
  let any = %raw(`{}`)

  let struct = S.object0(.)

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses object with single field", t => {
  let value = "bar"
  let any = %raw(`{foo: "bar"}`)

  let struct = S.object1(. ("foo", S.string()))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses object with multiple fields", t => {
  let value = ("bar", "jee")
  let any = %raw(`{boo: "bar", zoo: "jee"}`)

  let struct = S.object2(. ("boo", S.string()), ("zoo", S.string()))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses object with mapped field names", t => {
  let value = {name: "Dmitry", email: "dzakh.dev@gmail.com", age: 21}
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let struct =
    S.object3(.
      ("Name", S.string()),
      ("Email", S.string()),
      ("Age", S.int()),
    )->S.transform(~parser=((name, email, age)) => {name, email, age}, ())

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses object with optional nested object when it's Some", t => {
  let value = Some("bar")
  let any = %raw(`{"singleFieldObject":{"MUST_BE_MAPPED":"bar"}}`)

  let struct = S.object1(. (
    "singleFieldObject",
    S.option(S.object1(. ("MUST_BE_MAPPED", S.string()))),
  ))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses object with optional nested object when it's None", t => {
  let value = None
  let any = %raw(`{}`)

  let struct = S.object1(. (
    "singleFieldObject",
    S.option(S.object1(. ("MUST_BE_MAPPED", S.string()))),
  ))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses object with deprecated nested object when it's Some", t => {
  let value = Some("bar")
  let any = %raw(`{"singleFieldObject":{"MUST_BE_MAPPED":"bar"}}`)

  let struct = S.object1(. (
    "singleFieldObject",
    S.object1(. ("MUST_BE_MAPPED", S.string()))->S.deprecated(),
  ))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses object with deprecated nested object when it's None", t => {
  let value = None
  let any = %raw(`{}`)

  let struct = S.object1(. (
    "singleFieldObject",
    S.object1(. ("MUST_BE_MAPPED", S.string()))->S.deprecated(),
  ))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses array of objects", t => {
  let value = ["bar", "baz"]
  let any = %raw(`[{"MUST_BE_MAPPED":"bar"},{"MUST_BE_MAPPED":"baz"}]`)

  let struct = S.array(S.object1(. ("MUST_BE_MAPPED", S.string())))

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully serializes object without fields", t => {
  let value = ()
  let any = %raw(`{}`)

  let struct = S.object0(.)

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes object with single field", t => {
  let value = "bar"
  let any = %raw(`{foo: "bar"}`)

  let struct = S.object1(. ("foo", S.string()))

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes object with multiple fields", t => {
  let value = ("bar", "jee")
  let any = %raw(`{boo: "bar", zoo: "jee"}`)

  let struct = S.object2(. ("boo", S.string()), ("zoo", S.string()))

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes object with mapped field", t => {
  let value = {name: "Dmitry", email: "dzakh.dev@gmail.com", age: 21}
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let struct =
    S.object3(.
      ("Name", S.string()),
      ("Email", S.string()),
      ("Age", S.int()),
    )->S.transform(~serializer=({name, email, age}) => (name, email, age), ())

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes object with optional nested object when it's Some", t => {
  let value = Some("bar")
  let any = %raw(`{"singleFieldObject":{"MUST_BE_MAPPED":"bar"}}`)

  let struct = S.object1(. (
    "singleFieldObject",
    S.option(S.object1(. ("MUST_BE_MAPPED", S.string()))),
  ))

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes object with optional nested object when it's None", t => {
  let value = None
  let any = %raw(`{"singleFieldObject":undefined}`)

  let struct = S.object1(. (
    "singleFieldObject",
    S.option(S.object1(. ("MUST_BE_MAPPED", S.string()))),
  ))

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes unknown array of objects", t => {
  let value = ["bar", "baz"]
  let any = %raw(`[{"MUST_BE_MAPPED":"bar"},{"MUST_BE_MAPPED":"baz"}]`)

  let struct = S.array(S.object1(. ("MUST_BE_MAPPED", S.string())))

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully parses a object and serializes it back to the initial state", t => {
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let struct = S.object3(. ("Name", S.string()), ("Email", S.string()), ("Age", S.int()))

  t->Assert.deepEqual(
    any->S.parseWith(struct)->Belt.Result.map(object => object->S.serializeWith(struct)),
    Ok(Ok(any)),
    (),
  )
})

test("Fails to parse object when provided data of another type", t => {
  let struct = S.object1(. ("FOO", S.string()))

  t->Assert.deepEqual(
    Js.Json.string("string")->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Object", received: "String"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Fails to parse object item when it's not present", t => {
  let struct = S.object1(. ("FOO", S.string()))

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

test("Fails to parse object item when it's not valid", t => {
  let struct = S.object1(. ("FOO", S.string()))

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
  "Object fields are in correct order when field structs have different operation types. We keep originalIdx to make it work",
  t => {
    let any = {
      "noopOp1": 1,
      "syncOp1": 2,
      "noopOp2": 3,
    }

    let struct = S.object3(.
      ("noopOp1", S.int()),
      ("syncOp1", S.int()->S.transform(~parser=v => v, ())),
      ("noopOp2", S.int()),
    )

    t->Assert.deepEqual(any->S.parseWith(struct), Ok((1, 2, 3)), ())
  },
)
