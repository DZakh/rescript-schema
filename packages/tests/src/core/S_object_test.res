open Ava
open RescriptCore

@live
type options = {fast?: bool, mode?: int}

test("Successfully parses object with inlinable string field", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.string),
    }
  )

  t->Assert.deepEqual(%raw(`{field: "bar"}`)->S.parseAnyWith(struct), Ok({"field": "bar"}), ())
})

test("Fails to parse object with inlinable string field", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.string),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: 123}`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`123`)}),
      operation: Parsing,
      path: S.Path.fromArray(["field"]),
    }),
    (),
  )
})

test(
  "Fails to parse object with custom user error in array field (should have correct path)",
  t => {
    let struct = S.object(s =>
      {
        "field": s.field("field", S.array(S.string->S.refine(s => _ => s.fail("User error")))),
      }
    )

    t->Assert.deepEqual(
      %raw(`{field: ["foo"]}`)->S.parseAnyWith(struct),
      Error({
        code: OperationFailed("User error"),
        operation: Parsing,
        path: S.Path.fromArray(["field", "0"]),
      }),
      (),
    )
  },
)

test("Successfully parses object with inlinable bool field", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.bool),
    }
  )

  t->Assert.deepEqual(%raw(`{field: true}`)->S.parseAnyWith(struct), Ok({"field": true}), ())
})

test("Fails to parse object with inlinable bool field", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.bool),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: 123}`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`123`)}),
      operation: Parsing,
      path: S.Path.fromArray(["field"]),
    }),
    (),
  )
})

test("Successfully parses object with unknown field (Noop operation)", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.unknown),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: new Date("2015-12-12")}`)->S.parseAnyWith(struct),
    Ok(%raw(`{field: new Date("2015-12-12")}`)),
    (),
  )
})

test("Successfully serializes object with unknown field (Noop operation)", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.unknown),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: new Date("2015-12-12")}`)->S.serializeToUnknownWith(struct),
    Ok(%raw(`{field: new Date("2015-12-12")}`)),
    (),
  )
})

test("Fails to parse object with inlinable never field", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.never),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: true}`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: S.never->S.toUnknown, received: %raw(`true`)}),
      operation: Parsing,
      path: S.Path.fromArray(["field"]),
    }),
    (),
  )
})

test("Successfully parses object with inlinable float field", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.float),
    }
  )

  t->Assert.deepEqual(%raw(`{field: 123}`)->S.parseAnyWith(struct), Ok({"field": 123.}), ())
})

test("Fails to parse object with inlinable float field", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.float),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: true}`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: S.float->S.toUnknown, received: %raw(`true`)}),
      operation: Parsing,
      path: S.Path.fromArray(["field"]),
    }),
    (),
  )
})

test("Successfully parses object with inlinable int field", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.int),
    }
  )

  t->Assert.deepEqual(%raw(`{field: 123}`)->S.parseAnyWith(struct), Ok({"field": 123}), ())
})

test("Fails to parse object with inlinable int field", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.int),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: true}`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: S.int->S.toUnknown, received: %raw(`true`)}),
      operation: Parsing,
      path: S.Path.fromArray(["field"]),
    }),
    (),
  )
})

test("Successfully parses object with not inlinable empty object field", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.object(_ => ())),
    }
  )

  t->Assert.deepEqual(%raw(`{field: {}}`)->S.parseAnyWith(struct), Ok({"field": ()}), ())
})

test("Fails to parse object with not inlinable empty object field", t => {
  let fieldStruct = S.object(_ => ())
  let struct = S.object(s =>
    {
      "field": s.field("field", fieldStruct),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: true}`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: fieldStruct->S.toUnknown, received: %raw(`true`)}),
      operation: Parsing,
      path: S.Path.fromArray(["field"]),
    }),
    (),
  )
})

test("Fails to parse object when provided invalid data", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.string),
    }
  )

  t->Assert.deepEqual(
    %raw(`12`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: struct->S.toUnknown, received: %raw(`12`)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully serializes object with single field", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.string),
    }
  )

  t->Assert.deepEqual(
    {"field": "bar"}->S.serializeToUnknownWith(struct),
    Ok(%raw(`{field: "bar"}`)),
    (),
  )
})

test("Successfully parses object with multiple fields", t => {
  let struct = S.object(s =>
    {
      "boo": s.field("boo", S.string),
      "zoo": s.field("zoo", S.string),
    }
  )

  t->Assert.deepEqual(
    %raw(`{boo: "bar", zoo: "jee"}`)->S.parseAnyWith(struct),
    Ok({"boo": "bar", "zoo": "jee"}),
    (),
  )
})

test("Successfully serializes object with multiple fields", t => {
  let struct = S.object(s =>
    {
      "boo": s.field("boo", S.string),
      "zoo": s.field("zoo", S.string),
    }
  )

  t->Assert.deepEqual(
    {"boo": "bar", "zoo": "jee"}->S.serializeToUnknownWith(struct),
    Ok(%raw(`{boo: "bar", zoo: "jee"}`)),
    (),
  )
})

test("Successfully parses object with transformed field", t => {
  let struct = S.object(s =>
    {
      "string": s.field(
        "string",
        S.string->S.transform(_ => {parser: string => string ++ "field"}),
      ),
    }
  )

  t->Assert.deepEqual(
    %raw(`{string: "bar"}`)->S.parseAnyWith(struct),
    Ok({"string": "barfield"}),
    (),
  )
})

test("Fails to parse object when transformed field has raises error", t => {
  let struct = S.object(s =>
    {
      "field": s.field("field", S.string->S.transform(s => {parser: _ => s.fail("User error")})),
    }
  )

  t->Assert.deepEqual(
    {"field": "bar"}->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: S.Path.fromArray(["field"]),
    }),
    (),
  )
})

test("Shows transformed object field name in error path when fails to parse", t => {
  let struct = S.object(s =>
    {
      "transformedFieldName": s.field(
        "originalFieldName",
        S.string->S.transform(s => {parser: _ => s.fail("User error")}),
      ),
    }
  )

  t->Assert.deepEqual(
    {"originalFieldName": "bar"}->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: S.Path.fromArray(["originalFieldName"]),
    }),
    (),
  )
})

test("Successfully serializes object with transformed field", t => {
  let struct = S.object(s =>
    {
      "string": s.field(
        "string",
        S.string->S.transform(_ => {serializer: string => string ++ "field"}),
      ),
    }
  )

  t->Assert.deepEqual(
    {"string": "bar"}->S.serializeToUnknownWith(struct),
    Ok(%raw(`{"string": "barfield"}`)),
    (),
  )
})

test("Fails to serializes object when transformed field has raises error", t => {
  let struct = S.object(s =>
    {
      "field": s.field(
        "field",
        S.string->S.transform(s => {serializer: _ => s.fail("User error")}),
      ),
    }
  )

  t->Assert.deepEqual(
    {"field": "bar"}->S.serializeToUnknownWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: S.Path.fromArray(["field"]),
    }),
    (),
  )
})

test("Shows transformed object field name in error path when fails to serializes", t => {
  let struct = S.object(s =>
    {
      "transformedFieldName": s.field(
        "originalFieldName",
        S.string->S.transform(s => {serializer: _ => s.fail("User error")}),
      ),
    }
  )

  t->Assert.deepEqual(
    {"transformedFieldName": "bar"}->S.serializeToUnknownWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: S.Path.fromArray(["transformedFieldName"]),
    }),
    (),
  )
})

test("Shows transformed to nested object field name in error path when fails to serializes", t => {
  let struct = S.object(s =>
    {
      "v1": {
        "transformedFieldName": s.field(
          "originalFieldName",
          S.string->S.transform(s => {serializer: _ => s.fail("User error")}),
        ),
      },
    }
  )

  t->Assert.deepEqual(
    {
      "v1": {
        "transformedFieldName": "bar",
      },
    }->S.serializeToUnknownWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: S.Path.fromArray(["v1", "transformedFieldName"]),
    }),
    (),
  )
})

test("Successfully parses object with optional fields", t => {
  let struct = S.object(s =>
    {
      "boo": s.field("boo", S.option(S.string)),
      "zoo": s.field("zoo", S.option(S.string)),
    }
  )

  t->Assert.deepEqual(
    %raw(`{boo: "bar"}`)->S.parseAnyWith(struct),
    Ok({"boo": Some("bar"), "zoo": None}),
    (),
  )
})

test("Successfully serializes object with optional fields", t => {
  let struct = S.object(s =>
    {
      "boo": s.field("boo", S.option(S.string)),
      "zoo": s.field("zoo", S.option(S.string)),
    }
  )

  t->Assert.deepEqual(
    {"boo": Some("bar"), "zoo": None}->S.serializeToUnknownWith(struct),
    Ok(%raw(`{boo: "bar", zoo: undefined}`)),
    (),
  )
})

test(
  "Successfully parses object with optional fields using (?). The optinal field becomes undefined instead of beeing missing",
  t => {
    let optionsStruct = S.object(s => {
      {
        fast: ?s.field("fast", S.option(S.bool)),
        mode: s.field("mode", S.int),
      }
    })

    t->Assert.deepEqual(
      %raw(`{mode: 1}`)->S.parseAnyWith(optionsStruct),
      Ok({
        fast: %raw(`undefined`),
        mode: 1,
      }),
      (),
    )
  },
)

test("Successfully serializes object with optional fields using (?)", t => {
  let optionsStruct = S.object(s => {
    {
      fast: ?s.field("fast", S.option(S.bool)),
      mode: s.field("mode", S.int),
    }
  })

  t->Assert.deepEqual(
    {mode: 1}->S.serializeToUnknownWith(optionsStruct),
    Ok(%raw(`{mode: 1, fast: undefined}`)),
    (),
  )
})

test("Successfully parses object with mapped field names", t => {
  let struct = S.object(s =>
    {
      "name": s.field("Name", S.string),
      "email": s.field("Email", S.string),
      "age": s.field("Age", S.int),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)->S.parseAnyWith(struct),
    Ok({"name": "Dmitry", "email": "dzakh.dev@gmail.com", "age": 21}),
    (),
  )
})

test("Successfully serializes object with mapped field", t => {
  let struct = S.object(s =>
    {
      "name": s.field("Name", S.string),
      "email": s.field("Email", S.string),
      "age": s.field("Age", S.int),
    }
  )

  t->Assert.deepEqual(
    {"name": "Dmitry", "email": "dzakh.dev@gmail.com", "age": 21}->S.serializeToUnknownWith(struct),
    Ok(%raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)),
    (),
  )
})

test("Successfully parses object transformed to tuple", t => {
  let struct = S.object(s => (s.field("boo", S.int), s.field("zoo", S.int)))

  t->Assert.deepEqual(%raw(`{boo: 1, zoo: 2}`)->S.parseAnyWith(struct), Ok(1, 2), ())
})

test("Successfully serializes object transformed to tuple", t => {
  let struct = S.object(s => (s.field("boo", S.int), s.field("zoo", S.int)))

  t->Assert.deepEqual((1, 2)->S.serializeToUnknownWith(struct), Ok(%raw(`{boo: 1, zoo: 2}`)), ())
})

test("Successfully parses object transformed to nested object", t => {
  let struct = S.object(s =>
    {
      "v1": {
        "boo": s.field("boo", S.int),
        "zoo": s.field("zoo", S.int),
      },
    }
  )

  t->Assert.deepEqual(
    %raw(`{boo: 1, zoo: 2}`)->S.parseAnyWith(struct),
    Ok({"v1": {"boo": 1, "zoo": 2}}),
    (),
  )
})

test("Successfully serializes object transformed to nested object", t => {
  let struct = S.object(s =>
    {
      "v1": {
        "boo": s.field("boo", S.int),
        "zoo": s.field("zoo", S.int),
      },
    }
  )

  t->Assert.deepEqual(
    {"v1": {"boo": 1, "zoo": 2}}->S.serializeToUnknownWith(struct),
    Ok(%raw(`{boo: 1, zoo: 2}`)),
    (),
  )
})

test("Successfully parses object transformed to nested tuple", t => {
  let struct = S.object(s =>
    {
      "v1": (s.field("boo", S.int), s.field("zoo", S.int)),
    }
  )

  t->Assert.deepEqual(%raw(`{boo: 1, zoo: 2}`)->S.parseAnyWith(struct), Ok({"v1": (1, 2)}), ())
})

test("Successfully serializes object transformed to nested tuple", t => {
  let struct = S.object(s =>
    {
      "v1": (s.field("boo", S.int), s.field("zoo", S.int)),
    }
  )

  t->Assert.deepEqual(
    {"v1": (1, 2)}->S.serializeToUnknownWith(struct),
    Ok(%raw(`{boo: 1, zoo: 2}`)),
    (),
  )
})

test("Successfully parses object with only one field returned from transformer", t => {
  let struct = S.object(s => s.field("field", S.bool))

  t->Assert.deepEqual(%raw(`{"field": true}`)->S.parseAnyWith(struct), Ok(true), ())
})

test("Successfully serializes object with only one field returned from transformer", t => {
  let struct = S.object(s => s.field("field", S.bool))

  t->Assert.deepEqual(true->S.serializeToUnknownWith(struct), Ok(%raw(`{"field": true}`)), ())
})

test("Successfully parses object transformed to the one with hardcoded fields", t => {
  let struct = S.object(s =>
    {
      "hardcoded": false,
      "field": s.field("field", S.bool),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"field": true}`)->S.parseAnyWith(struct),
    Ok({
      "hardcoded": false,
      "field": true,
    }),
    (),
  )
})

test("Successfully serializes object transformed to the one with hardcoded fields", t => {
  let struct = S.object(s =>
    {
      "hardcoded": false,
      "field": s.field("field", S.bool),
    }
  )

  t->Assert.deepEqual(
    {
      "hardcoded": false,
      "field": true,
    }->S.serializeToUnknownWith(struct),
    Ok(%raw(`{"field": true}`)),
    (),
  )
})

test("Successfully parses object transformed to variant", t => {
  let struct = S.object(s => #VARIANT(s.field("field", S.bool)))

  t->Assert.deepEqual(%raw(`{"field": true}`)->S.parseAnyWith(struct), Ok(#VARIANT(true)), ())
})

test("Successfully serializes object transformed to variant", t => {
  let struct = S.object(s => #VARIANT(s.field("field", S.bool)))

  t->Assert.deepEqual(
    #VARIANT(true)->S.serializeToUnknownWith(struct),
    Ok(%raw(`{"field": true}`)),
    (),
  )
})

test("Successfully parses object from benchmark", t => {
  let struct = S.object(s =>
    {
      "number": s.field("number", S.float),
      "negNumber": s.field("negNumber", S.float),
      "maxNumber": s.field("maxNumber", S.float),
      "string": s.field("string", S.string),
      "longString": s.field("longString", S.string),
      "boolean": s.field("boolean", S.bool),
      "deeplyNested": s.field(
        "deeplyNested",
        S.object(
          s =>
            {
              "foo": s.field("foo", S.string),
              "num": s.field("num", S.float),
              "bool": s.field("bool", S.bool),
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
    })`)->S.parseAnyWith(struct),
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

test("Successfully parses strict object from benchmark", t => {
  let struct = S.object(s =>
    {
      "number": s.field("number", S.float),
      "negNumber": s.field("negNumber", S.float),
      "maxNumber": s.field("maxNumber", S.float),
      "string": s.field("string", S.string),
      "longString": s.field("longString", S.string),
      "boolean": s.field("boolean", S.bool),
      "deeplyNested": s.field(
        "deeplyNested",
        S.object(
          s =>
            {
              "foo": s.field("foo", S.string),
              "num": s.field("num", S.float),
              "bool": s.field("bool", S.bool),
            },
        )->S.Object.strict,
      ),
    }
  )->S.Object.strict

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
    })`)->S.parseAnyWith(struct),
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

test("Successfully serializes object from benchmark", t => {
  let struct = S.object(s =>
    {
      "number": s.field("number", S.float),
      "negNumber": s.field("negNumber", S.float),
      "maxNumber": s.field("maxNumber", S.float),
      "string": s.field("string", S.string),
      "longString": s.field("longString", S.string),
      "boolean": s.field("boolean", S.bool),
      "deeplyNested": s.field(
        "deeplyNested",
        S.object(
          s =>
            {
              "foo": s.field("foo", S.string),
              "num": s.field("num", S.float),
              "bool": s.field("bool", S.bool),
            },
        ),
      ),
    }
  )

  t->Assert.deepEqual(
    {
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
    }->S.serializeToUnknownWith(struct),
    Ok(
      %raw(`{
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
      }`),
    ),
    (),
  )
})

test("Successfully parses object and serializes it back to the initial data", t => {
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let struct = S.object(s =>
    {
      "name": s.field("Name", S.string),
      "email": s.field("Email", S.string),
      "age": s.field("Age", S.int),
    }
  )

  t->Assert.deepEqual(
    any->S.parseAnyWith(struct)->Result.map(object => object->S.serializeToUnknownWith(struct)),
    Ok(Ok(any)),
    (),
  )
})

test("Allows to create object struct with unused fields", t => {
  let struct = S.object(s => {
    ignore(s.field("unused", S.string))
    {
      "field": s.field("field", S.string),
    }
  })

  t->Assert.deepEqual(
    %raw(`{"field": "foo", "unused": "bar"}`)->S.parseAnyWith(struct),
    Ok({"field": "foo"}),
    (),
  )
})

test("Fails to create object struct with single field defined multiple times", t => {
  t->Assert.throws(
    () => {
      S.object(
        s =>
          {
            "boo": s.field("field", S.string),
            "zoo": s.field("field", S.int),
          },
      )
    },
    ~expectations={
      message: `[rescript-struct] The field "field" is defined multiple times. If you want to duplicate the field, use S.transform instead.`,
    },
    (),
  )
})

test("Successfully parses object struct with single field registered multiple times", t => {
  let struct = S.object(s => {
    let field = s.field("field", S.string)
    {
      "field1": field,
      "field2": field,
    }
  })
  t->Assert.deepEqual(
    %raw(`{"field": "foo"}`)->S.parseAnyWith(struct),
    Ok({"field1": "foo", "field2": "foo"}),
    (),
  )
})

test("Fails to serialize object struct with single field registered multiple times", t => {
  let struct = S.object(s => {
    let field = s.field("field", S.string)
    {
      "field1": field,
      "field2": field,
    }
  })
  t->Assert.deepEqual(
    {"field1": "foo", "field2": "foo"}->S.serializeToUnknownWith(struct),
    Error({
      code: InvalidOperation({
        description: `The field "field" is registered multiple times. If you want to duplicate the field, use S.transform instead`,
      }),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Object struct parsing checks order", t => {
  let struct = S.object(s => {
    s.tag("tag", "value")
    {
      "key": s.field("key", S.literal("value")),
    }
  })->S.Object.strict

  // Type check should be the first
  t->Assert.deepEqual(
    %raw(`"foo"`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: struct->S.toUnknown, received: %raw(`"foo"`)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
  // Tag check should be the second
  t->Assert.deepEqual(
    %raw(`{tag: "wrong", key: "wrong", unknownKey: "value", unknownKey2: "value"}`)->S.parseAnyWith(
      struct,
    ),
    Error({
      code: InvalidLiteral({expected: String("value"), received: %raw(`"wrong"`)}),
      operation: Parsing,
      path: S.Path.fromLocation("tag"),
    }),
    (),
  )
  // Field check should be the third
  t->Assert.deepEqual(
    %raw(`{tag: "value", key: "wrong", unknownKey: "value", unknownKey2: "value"}`)->S.parseAnyWith(
      struct,
    ),
    Error({
      code: InvalidLiteral({expected: String("value"), received: %raw(`"wrong"`)}),
      operation: Parsing,
      path: S.Path.fromLocation("key"),
    }),
    (),
  )
  // Unknown keys check should be the last
  t->Assert.deepEqual(
    %raw(`{tag: "value", key: "value", unknownKey: "value2", unknownKey2: "value2"}`)->S.parseAnyWith(
      struct,
    ),
    Error({
      code: ExcessField("unknownKey"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
  // Parses valid
  t->Assert.deepEqual(
    %raw(`{tag: "value", key: "value"}`)->S.parseAnyWith(struct),
    Ok({
      "key": "value",
    }),
    (),
  )
})

module Compiled = {
  test("Compiled parse code snapshot for simple object", t => {
    let struct = S.object(s =>
      {
        "foo": s.field("foo", S.string),
        "bar": s.field("bar", S.bool),
      }
    )

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v0,v1;if(!i||i.constructor!==Object){e[0](i)}v0=i["foo"];if(typeof v0!=="string"){e[1](v0)}v1=i["bar"];if(typeof v1!=="boolean"){e[2](v1)}return {"foo":v0,"bar":v1,}}`,
      (),
    )
  })

  test("Compiled parse code snapshot for simple object with async", t => {
    let struct = S.object(s =>
      {
        "foo": s.field("foo", S.unknown->S.asyncParserRefine(_ => _ => Promise.resolve())),
        "bar": s.field("bar", S.bool),
      }
    )

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v0,v1,v2,v3,v4;if(!i||i.constructor!==Object){e[0](i)}v0=i["foo"];v2=e[1](v0);v1=()=>v2().then(_=>v0);v3=i["bar"];if(typeof v3!=="boolean"){e[2](v3)}v4=()=>Promise.all([v1()]).then(([v1])=>({"foo":v1,"bar":v3,}));return v4}`,
      (),
    )
  })

  test("Compiled serialize code snapshot for simple object", t => {
    let struct = S.object(s =>
      {
        "foo": s.field("foo", S.string),
        "bar": s.field("bar", S.bool),
      }
    )

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#serialize,
      `i=>{return {"foo":i["foo"],"bar":i["bar"],}}`,
      (),
    )
  })

  test("Compiled parse code snapshot for simple object with strict unknown keys", t => {
    let struct = S.object(s =>
      {
        "foo": s.field("foo", S.string),
        "bar": s.field("bar", S.bool),
      }
    )->S.Object.strict

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v0,v1,v2;if(!i||i.constructor!==Object){e[0](i)}v1=i["foo"];if(typeof v1!=="string"){e[2](v1)}v2=i["bar"];if(typeof v2!=="boolean"){e[3](v2)}for(v0 in i){if(v0!=="foo"&&v0!=="bar"){e[1](v0)}}return {"foo":v1,"bar":v2,}}`,
      (),
    )
  })

  test("Compiled serialize code snapshot for simple object with strict unknown keys", t => {
    let struct = S.object(s =>
      {
        "foo": s.field("foo", S.string),
        "bar": s.field("bar", S.bool),
      }
    )->S.Object.strict

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#serialize,
      `i=>{return {"foo":i["foo"],"bar":i["bar"],}}`,
      (),
    )
  })

  test(
    "Compiled parse code snapshot for simple object with strict unknown keys, renamed fields, constants and discriminants",
    t => {
      let struct = S.object(s => {
        s.tag("tag", 0)
        {
          "foo": s.field("FOO", S.string),
          "bar": s.field("BAR", S.bool),
          "zoo": 1,
        }
      })->S.Object.strict

      t->TestUtils.assertCompiledCode(
        ~struct,
        ~op=#parse,
        `i=>{let v0,v1,v2,v3;if(!i||i.constructor!==Object){e[0](i)}v3=i["tag"];v3===e[5]||e[6](v3);v1=i["FOO"];if(typeof v1!=="string"){e[2](v1)}v2=i["BAR"];if(typeof v2!=="boolean"){e[3](v2)}for(v0 in i){if(v0!=="tag"&&v0!=="FOO"&&v0!=="BAR"){e[1](v0)}}return {"foo":v1,"bar":v2,"zoo":e[4],}}`,
        (),
      )
    },
  )

  test(
    "Compiled serialize code snapshot for simple object with strict unknown keys, renamed fields, constants and discriminants",
    t => {
      let struct = S.object(s => {
        s.tag("tag", 0)
        {
          "foo": s.field("FOO", S.string),
          "bar": s.field("BAR", S.bool),
          "zoo": 1,
        }
      })->S.Object.strict

      t->TestUtils.assertCompiledCode(
        ~struct,
        ~op=#serialize,
        `i=>{if(i["zoo"]!==e[0]){e[1](i["zoo"])}return {"FOO":i["foo"],"BAR":i["bar"],"tag":e[2],}}`,
        (),
      )
    },
  )
}
