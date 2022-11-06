open Ava

type user = {name: string, email: string, age: int}

test("Successfully parses object without fields", t => {
  let value = ()
  let any = %raw(`{}`)

  let struct = S.object0(.)

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses object with single field", t => {
  let struct = S.object(o =>
    {
      "foo": o->S.field(S.string()),
    }
  )

  t->Assert.deepEqual(%raw(`{foo: "bar"}`)->S.parseWith(struct), Ok({"foo": "bar"}), ())
})

test("Successfully parses object with multiple fields", t => {
  let struct = S.object(o =>
    {
      "boo": o->S.field(S.string()),
      "zoo": o->S.field(S.string()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{boo: "bar", zoo: "jee"}`)->S.parseWith(struct),
    Ok({"boo": "bar", "zoo": "jee"}),
    (),
  )
})

test("Successfully parses object with mapped field names", t => {
  let struct = S.object(o =>
    {
      "name": o->S.field(~name="Name", S.string()),
      "email": o->S.field(~name="Email", S.string()),
      "age": o->S.field(~name="Age", S.int()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)->S.parseWith(struct),
    Ok({"name": "Dmitry", "email": "dzakh.dev@gmail.com", "age": 21}),
    (),
  )
})

test("Successfully parses object from benchmark", t => {
  let struct = S.object(o =>
    {
      "number": o->S.field(S.float()),
      "negNumber": o->S.field(S.float()),
      "maxNumber": o->S.field(S.float()),
      "string": o->S.field(S.string()),
      "longString": o->S.field(S.string()),
      "boolean": o->S.field(S.bool()),
      "deeplyNested": o->S.field(
        S.object(
          o =>
            {
              "foo": o->S.field(S.string()),
              "num": o->S.field(S.float()),
              "bool": o->S.field(S.bool()),
            },
        ),
      ),
    }
  )

  t->Assert.deepEqual(
    %raw(`Object.freeze({
      number: 1,
      negNumber: -1,
      maxNumber: Number.MAX_VALUE,
      string: 'string',
      longString:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Vivendum intellegat et qui, ei denique consequuntur vix. Semper aeterno percipit ut his, sea ex utinam referrentur repudiandae. No epicuri hendrerit consetetur sit, sit dicta adipiscing ex, in facete detracto deterruisset duo. Quot populo ad qui. Sit fugit nostrum et. Ad per diam dicant interesset, lorem iusto sensibus ut sed. No dicam aperiam vis. Pri posse graeco definitiones cu, id eam populo quaestio adipiscing, usu quod malorum te. Ex nam agam veri, dicunt efficiantur ad qui, ad legere adversarium sit. Commune platonem mel id, brute adipiscing duo an. Vivendum intellegat et qui, ei denique consequuntur vix. Offendit eleifend moderatius ex vix, quem odio mazim et qui, purto expetendis cotidieque quo cu, veri persius vituperata ei nec. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
      boolean: true,
      deeplyNested: {
        foo: 'bar',
        num: 1,
        bool: false,
      },
    })`)->S.parseWith(struct),
    Ok({
      "number": 1.,
      "negNumber": -1.,
      "maxNumber": %raw("Number.MAX_VALUE"),
      "string": "string",
      "longString": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Vivendum intellegat et qui, ei denique consequuntur vix. Semper aeterno percipit ut his, sea ex utinam referrentur repudiandae. No epicuri hendrerit consetetur sit, sit dicta adipiscing ex, in facete detracto deterruisset duo. Quot populo ad qui. Sit fugit nostrum et. Ad per diam dicant interesset, lorem iusto sensibus ut sed. No dicam aperiam vis. Pri posse graeco definitiones cu, id eam populo quaestio adipiscing, usu quod malorum te. Ex nam agam veri, dicunt efficiantur ad qui, ad legere adversarium sit. Commune platonem mel id, brute adipiscing duo an. Vivendum intellegat et qui, ei denique consequuntur vix. Offendit eleifend moderatius ex vix, quem odio mazim et qui, purto expetendis cotidieque quo cu, veri persius vituperata ei nec. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
      "boolean": true,
      "deeplyNested": {
        "foo": "bar",
        "num": 1.,
        "bool": false,
      },
    }),
    (),
  )
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
