open Ava

type user = {name: string, email: string, age: int}
@live
type options = {fast?: bool, mode?: int}

test("Successfully parses empty object without declared fields", t => {
  let struct = S.object(_ => ())

  t->Assert.deepEqual(%raw(`{}`)->S.parseWith(struct), Ok(), ())
})

test("Successfully parses filled object without declared fields", t => {
  let struct = S.object(_ => ())

  t->Assert.deepEqual(%raw(`{field:"bar"}`)->S.parseWith(struct), Ok(), ())
})

test("Successfully parses object without declared fields and returns transformed value", t => {
  let transformedValue = {"bas": true}
  let struct = S.object(_ => transformedValue)

  t->Assert.deepEqual(%raw(`{field:"bar"}`)->S.parseWith(struct), Ok(transformedValue), ())
})

test("Successfully serializes object without declared fields, but with transformed value", t => {
  let transformedValue = {"bas": true}
  let struct = S.object(_ => transformedValue)

  t->Assert.deepEqual(transformedValue->S.serializeWith(struct), Ok(%raw("{}")), ())
})

test("Fails to parse object without declared fields when provided an array", t => {
  let struct = S.object(_ => ())

  t->Assert.deepEqual(
    %raw(`[]`)->S.parseWith(struct),
    Error({
      // FIXME: Proper type for arrays
      code: UnexpectedType({expected: "Object", received: "Object"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully parses object with inlinable string field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.string()),
    }
  )

  t->Assert.deepEqual(%raw(`{field: "bar"}`)->S.parseWith(struct), Ok({"field": "bar"}), ())
})

test("Fails to parse object with inlinable string field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.string()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: 123}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "String", received: "Float"}),
      operation: Parsing,
      path: ["field"],
    }),
    (),
  )
})

test("Successfully parses object with inlinable bool field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.bool()),
    }
  )

  t->Assert.deepEqual(%raw(`{field: true}`)->S.parseWith(struct), Ok({"field": true}), ())
})

test("Fails to parse object with inlinable bool field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.bool()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: 123}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Bool", received: "Float"}),
      operation: Parsing,
      path: ["field"],
    }),
    (),
  )
})

test("Successfully parses object with inlinable float field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.float()),
    }
  )

  t->Assert.deepEqual(%raw(`{field: 123}`)->S.parseWith(struct), Ok({"field": 123.}), ())
})

test("Fails to parse object with inlinable float field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.float()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: true}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Float", received: "Bool"}),
      operation: Parsing,
      path: ["field"],
    }),
    (),
  )
})

test("Successfully parses object with inlinable int field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.int()),
    }
  )

  t->Assert.deepEqual(%raw(`{field: 123}`)->S.parseWith(struct), Ok({"field": 123}), ())
})

test("Fails to parse object with inlinable int field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.int()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: true}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Int", received: "Bool"}),
      operation: Parsing,
      path: ["field"],
    }),
    (),
  )
})

// TODO: Add strict support
test("Successfully parses object with not inlinable empty object field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.object(_ => ())),
    }
  )

  t->Assert.deepEqual(%raw(`{field: {}}`)->S.parseWith(struct), Ok({"field": ()}), ())
})

test("Fails to parse object with not inlinable empty object field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.object(_ => ())),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: true}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Object", received: "Bool"}),
      operation: Parsing,
      path: ["field"],
    }),
    (),
  )
})

test("Fails to parse object when provided invalid data", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.string()),
    }
  )

  t->Assert.deepEqual(
    %raw(`12`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Object", received: "Float"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully parses object with multiple fields", t => {
  let struct = S.object(o =>
    {
      "boo": o->S.field("boo", S.string()),
      "zoo": o->S.field("zoo", S.string()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{boo: "bar", zoo: "jee"}`)->S.parseWith(struct),
    Ok({"boo": "bar", "zoo": "jee"}),
    (),
  )
})

test("Successfully parses object with transformed field", t => {
  let struct = S.object(o =>
    {
      "string": o->S.field(
        "string",
        S.string()->S.transform(~parser=string => string ++ "field", ()),
      ),
    }
  )

  t->Assert.deepEqual(%raw(`{string: "bar"}`)->S.parseWith(struct), Ok({"string": "barfield"}), ())
})

test("Successfully parses object with optional fields", t => {
  let struct = S.object(o =>
    {
      "boo": o->S.field("boo", S.option(S.string())),
      "zoo": o->S.field("zoo", S.option(S.string())),
    }
  )

  t->Assert.deepEqual(
    %raw(`{boo: "bar"}`)->S.parseWith(struct),
    Ok({"boo": Some("bar"), "zoo": None}),
    (),
  )
})

test("Successfully parses object with optional fields using (?)", t => {
  let optionsStruct = S.object(o => {
    let fastField = o->S.field("fast", S.option(S.bool()))
    {
      fast: ?fastField,
      mode: o->S.field("mode", S.int()),
    }
  })

  t->Assert.deepEqual(%raw(`{mode: 1}`)->S.parseWith(optionsStruct), Ok({mode: 1}), ())
})

test("Successfully parses object with mapped field names", t => {
  let struct = S.object(o =>
    {
      "name": o->S.field("Name", S.string()),
      "email": o->S.field("Email", S.string()),
      "age": o->S.field("Age", S.int()),
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
      "number": o->S.field("number", S.float()),
      "negNumber": o->S.field("negNumber", S.float()),
      "maxNumber": o->S.field("maxNumber", S.float()),
      "string": o->S.field("string", S.string()),
      "longString": o->S.field("longString", S.string()),
      "boolean": o->S.field("boolean", S.bool()),
      "deeplyNested": o->S.field(
        "deeplyNested",
        S.object(
          o =>
            {
              "foo": o->S.field("foo", S.string()),
              "num": o->S.field("num", S.float()),
              "bool": o->S.field("bool", S.bool()),
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
  let any = %raw(`{field: "bar"}`)

  let struct = S.object1(. ("field", S.string()))

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
