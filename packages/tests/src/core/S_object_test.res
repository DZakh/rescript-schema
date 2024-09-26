open Ava
open RescriptCore

@live
type options = {fast?: bool, mode?: int}

test("Successfully parses object with inlinable string field", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.string),
    }
  )

  t->Assert.deepEqual(%raw(`{field: "bar"}`)->S.parseAnyWith(schema), Ok({"field": "bar"}), ())
})

test("Fails to parse object with inlinable string field", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.string),
    }
  )

  t->U.assertErrorResult(
    %raw(`{field: 123}`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`123`)}),
      operation: Parse,
      path: S.Path.fromArray(["field"]),
    },
  )
})

test(
  "Fails to parse object with custom user error in array field (should have correct path)",
  t => {
    let schema = S.object(s =>
      {
        "field": s.field("field", S.array(S.string->S.refine(s => _ => s.fail("User error")))),
      }
    )

    t->U.assertErrorResult(
      %raw(`{field: ["foo"]}`)->S.parseAnyWith(schema),
      {
        code: OperationFailed("User error"),
        operation: Parse,
        path: S.Path.fromArray(["field", "0"]),
      },
    )
  },
)

test("Successfully parses object with inlinable bool field", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.bool),
    }
  )

  t->Assert.deepEqual(%raw(`{field: true}`)->S.parseAnyWith(schema), Ok({"field": true}), ())
})

test("Fails to parse object with inlinable bool field", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.bool),
    }
  )

  t->U.assertErrorResult(
    %raw(`{field: 123}`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`123`)}),
      operation: Parse,
      path: S.Path.fromArray(["field"]),
    },
  )
})

test("Successfully parses object with unknown field (Noop operation)", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.unknown),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: new Date("2015-12-12")}`)->S.parseAnyWith(schema),
    Ok(%raw(`{field: new Date("2015-12-12")}`)),
    (),
  )
})

test("Successfully serializes object with unknown field (Noop operation)", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.unknown),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: new Date("2015-12-12")}`)->S.serializeToUnknownWith(schema),
    Ok(%raw(`{field: new Date("2015-12-12")}`)),
    (),
  )
})

test("Fails to parse object with inlinable never field", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.never),
    }
  )

  t->U.assertErrorResult(
    %raw(`{field: true}`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: S.never->S.toUnknown, received: %raw(`true`)}),
      operation: Parse,
      path: S.Path.fromArray(["field"]),
    },
  )
})

test("Successfully parses object with inlinable float field", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.float),
    }
  )

  t->Assert.deepEqual(%raw(`{field: 123}`)->S.parseAnyWith(schema), Ok({"field": 123.}), ())
})

test("Fails to parse object with inlinable float field", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.float),
    }
  )

  t->U.assertErrorResult(
    %raw(`{field: true}`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: S.float->S.toUnknown, received: %raw(`true`)}),
      operation: Parse,
      path: S.Path.fromArray(["field"]),
    },
  )
})

test("Successfully parses object with inlinable int field", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.int),
    }
  )

  t->Assert.deepEqual(%raw(`{field: 123}`)->S.parseAnyWith(schema), Ok({"field": 123}), ())
})

test("Fails to parse object with inlinable int field", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.int),
    }
  )

  t->U.assertErrorResult(
    %raw(`{field: true}`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: S.int->S.toUnknown, received: %raw(`true`)}),
      operation: Parse,
      path: S.Path.fromArray(["field"]),
    },
  )
})

test("Successfully parses object with not inlinable empty object field", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.object(_ => ())),
    }
  )

  t->Assert.deepEqual(%raw(`{field: {}}`)->S.parseAnyWith(schema), Ok({"field": ()}), ())
})

test("Fails to parse object with not inlinable empty object field", t => {
  let fieldSchema = S.object(_ => ())
  let schema = S.object(s =>
    {
      "field": s.field("field", fieldSchema),
    }
  )

  t->U.assertErrorResult(
    %raw(`{field: true}`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: fieldSchema->S.toUnknown, received: %raw(`true`)}),
      operation: Parse,
      path: S.Path.fromArray(["field"]),
    },
  )
})

test("Fails to parse object when provided invalid data", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.string),
    }
  )

  t->U.assertErrorResult(
    %raw(`12`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: schema->S.toUnknown, received: %raw(`12`)}),
      operation: Parse,
      path: S.Path.empty,
    },
  )
})

test("Successfully serializes object with single field", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.string),
    }
  )

  t->Assert.deepEqual(
    {"field": "bar"}->S.serializeToUnknownWith(schema),
    Ok(%raw(`{field: "bar"}`)),
    (),
  )
})

test("Successfully parses object with multiple fields", t => {
  let schema = S.object(s =>
    {
      "boo": s.field("boo", S.string),
      "zoo": s.field("zoo", S.string),
    }
  )

  t->Assert.deepEqual(
    %raw(`{boo: "bar", zoo: "jee"}`)->S.parseAnyWith(schema),
    Ok({"boo": "bar", "zoo": "jee"}),
    (),
  )
})

test("Successfully serializes object with multiple fields", t => {
  let schema = S.object(s =>
    {
      "boo": s.field("boo", S.string),
      "zoo": s.field("zoo", S.string),
    }
  )

  t->Assert.deepEqual(
    {"boo": "bar", "zoo": "jee"}->S.serializeToUnknownWith(schema),
    Ok(%raw(`{boo: "bar", zoo: "jee"}`)),
    (),
  )
})

test("Successfully parses object with transformed field", t => {
  let schema = S.object(s =>
    {
      "string": s.field(
        "string",
        S.string->S.transform(_ => {parser: string => string ++ "field"}),
      ),
    }
  )

  t->Assert.deepEqual(
    %raw(`{string: "bar"}`)->S.parseAnyWith(schema),
    Ok({"string": "barfield"}),
    (),
  )
})

test("Fails to parse object when transformed field has raises error", t => {
  let schema = S.object(s =>
    {
      "field": s.field("field", S.string->S.transform(s => {parser: _ => s.fail("User error")})),
    }
  )

  t->U.assertErrorResult(
    {"field": "bar"}->S.parseAnyWith(schema),
    {
      code: OperationFailed("User error"),
      operation: Parse,
      path: S.Path.fromArray(["field"]),
    },
  )
})

test("Shows transformed object field name in error path when fails to parse", t => {
  let schema = S.object(s =>
    {
      "transformedFieldName": s.field(
        "originalFieldName",
        S.string->S.transform(s => {parser: _ => s.fail("User error")}),
      ),
    }
  )

  t->U.assertErrorResult(
    {"originalFieldName": "bar"}->S.parseAnyWith(schema),
    {
      code: OperationFailed("User error"),
      operation: Parse,
      path: S.Path.fromArray(["originalFieldName"]),
    },
  )
})

test("Successfully serializes object with transformed field", t => {
  let schema = S.object(s =>
    {
      "string": s.field(
        "string",
        S.string->S.transform(_ => {serializer: string => string ++ "field"}),
      ),
    }
  )

  t->Assert.deepEqual(
    {"string": "bar"}->S.serializeToUnknownWith(schema),
    Ok(%raw(`{"string": "barfield"}`)),
    (),
  )
})

test("Fails to serializes object when transformed field has raises error", t => {
  let schema = S.object(s =>
    {
      "field": s.field(
        "field",
        S.string->S.transform(s => {serializer: _ => s.fail("User error")}),
      ),
    }
  )

  t->U.assertErrorResult(
    {"field": "bar"}->S.serializeToUnknownWith(schema),
    {
      code: OperationFailed("User error"),
      operation: SerializeToUnknown,
      path: S.Path.fromArray(["field"]),
    },
  )
})

test("Shows transformed object field name in error path when fails to serializes", t => {
  let schema = S.object(s =>
    {
      "transformedFieldName": s.field(
        "originalFieldName",
        S.string->S.transform(s => {serializer: _ => s.fail("User error")}),
      ),
    }
  )

  t->U.assertErrorResult(
    {"transformedFieldName": "bar"}->S.serializeToUnknownWith(schema),
    {
      code: OperationFailed("User error"),
      operation: SerializeToUnknown,
      path: S.Path.fromArray(["transformedFieldName"]),
    },
  )
})

test("Shows transformed to nested object field name in error path when fails to serializes", t => {
  let schema = S.object(s =>
    {
      "v1": {
        "transformedFieldName": s.field(
          "originalFieldName",
          S.string->S.transform(s => {serializer: _ => s.fail("User error")}),
        ),
      },
    }
  )

  t->U.assertErrorResult(
    {
      "v1": {
        "transformedFieldName": "bar",
      },
    }->S.serializeToUnknownWith(schema),
    {
      code: OperationFailed("User error"),
      operation: SerializeToUnknown,
      path: S.Path.fromArray(["v1", "transformedFieldName"]),
    },
  )
})

test("Successfully parses object with optional fields", t => {
  let schema = S.object(s =>
    {
      "boo": s.field("boo", S.option(S.string)),
      "zoo": s.field("zoo", S.option(S.string)),
    }
  )

  t->Assert.deepEqual(
    %raw(`{boo: "bar"}`)->S.parseAnyWith(schema),
    Ok({"boo": Some("bar"), "zoo": None}),
    (),
  )
})

test("Successfully serializes object with optional fields", t => {
  let schema = S.object(s =>
    {
      "boo": s.field("boo", S.option(S.string)),
      "zoo": s.field("zoo", S.option(S.string)),
    }
  )

  t->Assert.deepEqual(
    {"boo": Some("bar"), "zoo": None}->S.serializeToUnknownWith(schema),
    Ok(%raw(`{boo: "bar", zoo: undefined}`)),
    (),
  )
})

test("Successfully parses object with optional fields with default", t => {
  let schema = S.object(s =>
    {
      "boo": s.fieldOr("boo", S.string, "default boo"),
      "zoo": s.fieldOr("zoo", S.string, "default zoo"),
    }
  )

  t->Assert.deepEqual(
    %raw(`{boo: "bar"}`)->S.parseAnyWith(schema),
    Ok({"boo": "bar", "zoo": "default zoo"}),
    (),
  )
})

test("Successfully serializes object with optional fields with default", t => {
  let schema = S.object(s =>
    {
      "boo": s.fieldOr("boo", S.string, "default boo"),
      "zoo": s.fieldOr("zoo", S.string, "default zoo"),
    }
  )

  t->Assert.deepEqual(
    {"boo": "bar", "zoo": "baz"}->S.serializeToUnknownWith(schema),
    Ok(%raw(`{boo: "bar", zoo: "baz"}`)),
    (),
  )
})

test(
  "Successfully parses object with optional fields using (?). The optinal field becomes undefined instead of beeing missing",
  t => {
    let optionsSchema = S.object(s => {
      {
        fast: ?s.field("fast", S.option(S.bool)),
        mode: s.field("mode", S.int),
      }
    })

    t->Assert.deepEqual(
      %raw(`{mode: 1}`)->S.parseAnyWith(optionsSchema),
      Ok({
        fast: %raw(`undefined`),
        mode: 1,
      }),
      (),
    )
  },
)

test("Successfully serializes object with optional fields using (?)", t => {
  let optionsSchema = S.object(s => {
    {
      fast: ?s.field("fast", S.option(S.bool)),
      mode: s.field("mode", S.int),
    }
  })

  t->Assert.deepEqual(
    {mode: 1}->S.serializeToUnknownWith(optionsSchema),
    Ok(%raw(`{mode: 1, fast: undefined}`)),
    (),
  )
})

test("Successfully parses object with mapped field names", t => {
  let schema = S.object(s =>
    {
      "name": s.field("Name", S.string),
      "email": s.field("Email", S.string),
      "age": s.field("Age", S.int),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)->S.parseAnyWith(schema),
    Ok({"name": "Dmitry", "email": "dzakh.dev@gmail.com", "age": 21}),
    (),
  )
})

test("Successfully serializes object with mapped field", t => {
  let schema = S.object(s =>
    {
      "name": s.field("Name", S.string),
      "email": s.field("Email", S.string),
      "age": s.field("Age", S.int),
    }
  )

  t->Assert.deepEqual(
    {"name": "Dmitry", "email": "dzakh.dev@gmail.com", "age": 21}->S.serializeToUnknownWith(schema),
    Ok(%raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)),
    (),
  )
})

test("Successfully parses object transformed to tuple", t => {
  let schema = S.object(s => (s.field("boo", S.int), s.field("zoo", S.int)))

  t->Assert.deepEqual(%raw(`{boo: 1, zoo: 2}`)->S.parseAnyWith(schema), Ok(1, 2), ())
})

test("Successfully serializes object transformed to tuple", t => {
  let schema = S.object(s => (s.field("boo", S.int), s.field("zoo", S.int)))

  t->Assert.deepEqual((1, 2)->S.serializeToUnknownWith(schema), Ok(%raw(`{boo: 1, zoo: 2}`)), ())
})

test("Successfully parses object transformed to nested object", t => {
  let schema = S.object(s =>
    {
      "v1": {
        "boo": s.field("boo", S.int),
        "zoo": s.field("zoo", S.int),
      },
    }
  )

  t->Assert.deepEqual(
    %raw(`{boo: 1, zoo: 2}`)->S.parseAnyWith(schema),
    Ok({"v1": {"boo": 1, "zoo": 2}}),
    (),
  )
})

test("Successfully serializes object transformed to nested object", t => {
  let schema = S.object(s =>
    {
      "v1": {
        "boo": s.field("boo", S.int),
        "zoo": s.field("zoo", S.int),
      },
    }
  )

  t->Assert.deepEqual(
    {"v1": {"boo": 1, "zoo": 2}}->S.serializeToUnknownWith(schema),
    Ok(%raw(`{boo: 1, zoo: 2}`)),
    (),
  )
})

test("Successfully parses object transformed to nested tuple", t => {
  let schema = S.object(s =>
    {
      "v1": (s.field("boo", S.int), s.field("zoo", S.int)),
    }
  )

  t->Assert.deepEqual(%raw(`{boo: 1, zoo: 2}`)->S.parseAnyWith(schema), Ok({"v1": (1, 2)}), ())
})

test("Successfully serializes object transformed to nested tuple", t => {
  let schema = S.object(s =>
    {
      "v1": (s.field("boo", S.int), s.field("zoo", S.int)),
    }
  )

  t->Assert.deepEqual(
    {"v1": (1, 2)}->S.serializeToUnknownWith(schema),
    Ok(%raw(`{boo: 1, zoo: 2}`)),
    (),
  )
})

test("Successfully parses object with only one field returned from transformer", t => {
  let schema = S.object(s => s.field("field", S.bool))

  t->Assert.deepEqual(%raw(`{"field": true}`)->S.parseAnyWith(schema), Ok(true), ())
})

test("Successfully serializes object with only one field returned from transformer", t => {
  let schema = S.object(s => s.field("field", S.bool))

  t->Assert.deepEqual(true->S.serializeToUnknownWith(schema), Ok(%raw(`{"field": true}`)), ())
})

test("Successfully parses object transformed to the one with hardcoded fields", t => {
  let schema = S.object(s =>
    {
      "hardcoded": false,
      "field": s.field("field", S.bool),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"field": true}`)->S.parseAnyWith(schema),
    Ok({
      "hardcoded": false,
      "field": true,
    }),
    (),
  )
})

test("Successfully serializes object transformed to the one with hardcoded fields", t => {
  let schema = S.object(s =>
    {
      "hardcoded": false,
      "field": s.field("field", S.bool),
    }
  )

  t->Assert.deepEqual(
    {
      "hardcoded": false,
      "field": true,
    }->S.serializeToUnknownWith(schema),
    Ok(%raw(`{"field": true}`)),
    (),
  )
})

test("Successfully parses object transformed to variant", t => {
  let schema = S.object(s => #VARIANT(s.field("field", S.bool)))

  t->Assert.deepEqual(%raw(`{"field": true}`)->S.parseAnyWith(schema), Ok(#VARIANT(true)), ())
})

test("Successfully serializes object transformed to variant", t => {
  let schema = S.object(s => #VARIANT(s.field("field", S.bool)))

  t->Assert.deepEqual(
    #VARIANT(true)->S.serializeToUnknownWith(schema),
    Ok(%raw(`{"field": true}`)),
    (),
  )
})

module Benchmark = {
  let makeTestObject = () => {
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
  })`)
  }

  let makeSchema = () => {
    S.object(s =>
      {
        "number": s.field("number", S.float),
        "negNumber": s.field("negNumber", S.float),
        "maxNumber": s.field("maxNumber", S.float),
        "string": s.field("string", S.string),
        "longString": s.field("longString", S.string),
        "boolean": s.field("boolean", S.bool),
        "deeplyNested": s.field(
          "deeplyNested",
          S.object(s =>
            {
              "foo": s.field("foo", S.string),
              "num": s.field("num", S.float),
              "bool": s.field("bool", S.bool),
            }
          ),
        ),
      }
    )
  }

  let makeAdvancedStrictObjectSchema = () => {
    S.object(s =>
      {
        "number": s.field("number", S.float),
        "negNumber": s.field("negNumber", S.float),
        "maxNumber": s.field("maxNumber", S.float),
        "string": s.field("string", S.string),
        "longString": s.field("longString", S.string),
        "boolean": s.field("boolean", S.bool),
        "deeplyNested": s.field(
          "deeplyNested",
          S.object(s =>
            {
              "foo": s.field("foo", S.string),
              "num": s.field("num", S.float),
              "bool": s.field("bool", S.bool),
            }
          )->S.Object.strict,
        ),
      }
    )->S.Object.strict
  }

  test("Successfully parses object from benchmark", t => {
    S.setGlobalConfig({
      disableNanNumberCheck: true,
    })
    let schema = makeSchema()

    t->Assert.deepEqual(
      makeTestObject()->S.parseAnyWith(schema),
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

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Parse,
      `i=>{if(!i||i.constructor!==Object){e[10](i)}let v0=i["number"],v1=i["negNumber"],v2=i["maxNumber"],v3=i["string"],v4=i["longString"],v5=i["boolean"],v6=i["deeplyNested"];if(typeof v0!=="number"){e[0](v0)}if(typeof v1!=="number"){e[1](v1)}if(typeof v2!=="number"){e[2](v2)}if(typeof v3!=="string"){e[3](v3)}if(typeof v4!=="string"){e[4](v4)}if(typeof v5!=="boolean"){e[5](v5)}if(!v6||v6.constructor!==Object){e[6](v6)}let v7=v6["foo"],v8=v6["num"],v9=v6["bool"];if(typeof v7!=="string"){e[7](v7)}if(typeof v8!=="number"){e[8](v8)}if(typeof v9!=="boolean"){e[9](v9)}return {"number":v0,"negNumber":v1,"maxNumber":v2,"string":v3,"longString":v4,"boolean":v5,"deeplyNested":{"foo":v7,"num":v8,"bool":v9,},}}`,
    )
    S.setGlobalConfig({})
  })

  test("Successfully asserts object from benchmark", t => {
    S.setGlobalConfig({
      disableNanNumberCheck: true,
    })
    let schema = makeSchema()

    t->Assert.deepEqual(makeTestObject()->S.assertOrRaiseWith(schema), (), ())

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Assert,
      `i=>{if(!i||i.constructor!==Object){e[10](i)}let v0=i["number"],v1=i["negNumber"],v2=i["maxNumber"],v3=i["string"],v4=i["longString"],v5=i["boolean"],v6=i["deeplyNested"];if(typeof v0!=="number"){e[0](v0)}if(typeof v1!=="number"){e[1](v1)}if(typeof v2!=="number"){e[2](v2)}if(typeof v3!=="string"){e[3](v3)}if(typeof v4!=="string"){e[4](v4)}if(typeof v5!=="boolean"){e[5](v5)}if(!v6||v6.constructor!==Object){e[6](v6)}let v7=v6["foo"],v8=v6["num"],v9=v6["bool"];if(typeof v7!=="string"){e[7](v7)}if(typeof v8!=="number"){e[8](v8)}if(typeof v9!=="boolean"){e[9](v9)}return void 0}`,
    )
    S.setGlobalConfig({})
  })

  test("Successfully parses strict object from benchmark", t => {
    S.setGlobalConfig({
      disableNanNumberCheck: true,
      defaultUnknownKeys: Strict,
    })
    let schema = makeSchema()

    t->Assert.deepEqual(
      makeTestObject()->S.parseAnyWith(schema),
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

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Parse,
      `i=>{if(!i||i.constructor!==Object){e[12](i)}let v0=i["number"],v1=i["negNumber"],v2=i["maxNumber"],v3=i["string"],v4=i["longString"],v5=i["boolean"],v6=i["deeplyNested"],v11;if(typeof v0!=="number"){e[0](v0)}if(typeof v1!=="number"){e[1](v1)}if(typeof v2!=="number"){e[2](v2)}if(typeof v3!=="string"){e[3](v3)}if(typeof v4!=="string"){e[4](v4)}if(typeof v5!=="boolean"){e[5](v5)}if(!v6||v6.constructor!==Object){e[6](v6)}let v7=v6["foo"],v8=v6["num"],v9=v6["bool"],v10;if(typeof v7!=="string"){e[7](v7)}if(typeof v8!=="number"){e[8](v8)}if(typeof v9!=="boolean"){e[9](v9)}for(v10 in v6){if(v10!=="foo"&&v10!=="num"&&v10!=="bool"){e[10](v10)}}for(v11 in i){if(v11!=="number"&&v11!=="negNumber"&&v11!=="maxNumber"&&v11!=="string"&&v11!=="longString"&&v11!=="boolean"&&v11!=="deeplyNested"){e[11](v11)}}return {"number":v0,"negNumber":v1,"maxNumber":v2,"string":v3,"longString":v4,"boolean":v5,"deeplyNested":{"foo":v7,"num":v8,"bool":v9,},}}`,
    )
    S.setGlobalConfig({})
  })

  test("Successfully asserts strict object from benchmark", t => {
    S.setGlobalConfig({
      disableNanNumberCheck: true,
      defaultUnknownKeys: Strict,
    })
    let schema = makeSchema()

    t->Assert.deepEqual(makeTestObject()->S.assertOrRaiseWith(schema), (), ())

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Assert,
      `i=>{if(!i||i.constructor!==Object){e[12](i)}let v0=i["number"],v1=i["negNumber"],v2=i["maxNumber"],v3=i["string"],v4=i["longString"],v5=i["boolean"],v6=i["deeplyNested"],v11;if(typeof v0!=="number"){e[0](v0)}if(typeof v1!=="number"){e[1](v1)}if(typeof v2!=="number"){e[2](v2)}if(typeof v3!=="string"){e[3](v3)}if(typeof v4!=="string"){e[4](v4)}if(typeof v5!=="boolean"){e[5](v5)}if(!v6||v6.constructor!==Object){e[6](v6)}let v7=v6["foo"],v8=v6["num"],v9=v6["bool"],v10;if(typeof v7!=="string"){e[7](v7)}if(typeof v8!=="number"){e[8](v8)}if(typeof v9!=="boolean"){e[9](v9)}for(v10 in v6){if(v10!=="foo"&&v10!=="num"&&v10!=="bool"){e[10](v10)}}for(v11 in i){if(v11!=="number"&&v11!=="negNumber"&&v11!=="maxNumber"&&v11!=="string"&&v11!=="longString"&&v11!=="boolean"&&v11!=="deeplyNested"){e[11](v11)}}return void 0}`,
    )
    S.setGlobalConfig({})
  })

  test("Successfully serializes object from benchmark", t => {
    S.setGlobalConfig({
      disableNanNumberCheck: true,
    })
    let schema = makeSchema()

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
      }->S.serializeToUnknownWith(schema),
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

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Serialize,
      `i=>{return {"number":i["number"],"negNumber":i["negNumber"],"maxNumber":i["maxNumber"],"string":i["string"],"longString":i["longString"],"boolean":i["boolean"],"deeplyNested":{"foo":i["deeplyNested"]["foo"],"num":i["deeplyNested"]["num"],"bool":i["deeplyNested"]["bool"],},}}`,
    )
    S.setGlobalConfig({})
  })
}

test("Successfully parses object and serializes it back to the initial data", t => {
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let schema = S.object(s =>
    {
      "name": s.field("Name", S.string),
      "email": s.field("Email", S.string),
      "age": s.field("Age", S.int),
    }
  )

  t->Assert.deepEqual(
    any->S.parseAnyWith(schema)->Result.map(object => object->S.serializeToUnknownWith(schema)),
    Ok(Ok(any)),
    (),
  )
})

test("Allows to create object schema with unused fields", t => {
  let schema = S.object(s => {
    ignore(s.field("unused", S.string))
    {
      "field": s.field("field", S.string),
    }
  })

  t->Assert.deepEqual(
    %raw(`{"field": "foo", "unused": "bar"}`)->S.parseAnyWith(schema),
    Ok({"field": "foo"}),
    (),
  )
})

test("Fails to create object schema with single field defined multiple times", t => {
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
      message: `[rescript-schema] The field "field" defined twice with incompatible schemas`,
    },
    (),
  )
})

test("Successfully parses object schema with single field registered multiple times", t => {
  let schema = S.object(s => {
    let field = s.field("field", S.string)
    {
      "field1": field,
      "field2": field,
    }
  })
  t->Assert.deepEqual(
    %raw(`{"field": "foo"}`)->S.parseAnyWith(schema),
    Ok({"field1": "foo", "field2": "foo"}),
    (),
  )
})

test("Fails to serialize object schema with single field registered multiple times", t => {
  let schema = S.object(s => {
    let field = s.field("field", S.string)
    {
      "field1": field,
      "field2": field,
    }
  })
  t->U.assertErrorResult(
    {"field1": "foo", "field2": "foo"}->S.serializeToUnknownWith(schema),
    {
      code: InvalidOperation({
        description: `The item "field" is registered multiple times`,
      }),
      operation: SerializeToUnknown,
      path: S.Path.empty,
    },
  )
})

test("Can destructure fields of simple nested objects", t => {
  let schema = S.object(s => {
    let nested = s.field(
      "nested",
      S.object(
        s =>
          {
            "foo": s.field("foo", S.string),
            "bar": s.field("bar", S.string),
          },
      ),
    )
    {
      "baz": nested["bar"],
      "foz": nested["foo"],
    }
  })
  t->Assert.deepEqual(
    %raw(`{"nested": {"foo": "foo", "bar": "bar"}}`)->S.parseAnyWith(schema),
    Ok({"baz": "bar", "foz": "foo"}),
    (),
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[3](i)}let v0=i["nested"];if(!v0||v0.constructor!==Object){e[0](v0)}let v1=v0["foo"],v2=v0["bar"];if(typeof v1!=="string"){e[1](v1)}if(typeof v2!=="string"){e[2](v2)}return {"baz":v2,"foz":v1,}}`,
  )

  t->Assert.deepEqual(
    {"baz": "bar", "foz": "foo"}->S.serializeWith(schema),
    Ok(%raw(`{"nested": {"foo": "foo", "bar": "bar"}}`)),
    (),
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Serialize,
    `i=>{return {"nested":{"foo":i["foz"],"bar":i["baz"],},}}`,
  )
})

test("Object schema parsing checks order", t => {
  let schema = S.object(s => {
    s.tag("tag", "value")
    {
      "key": s.field("key", S.string),
    }
  })->S.Object.strict

  // Type check should be the first
  t->U.assertErrorResult(
    %raw(`"foo"`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: schema->S.toUnknown, received: %raw(`"foo"`)}),
      operation: Parse,
      path: S.Path.empty,
    },
  )
  // Tag check should be the second
  t->U.assertErrorResult(
    %raw(`{tag: "wrong", key: 123, unknownKey: "value", unknownKey2: "value"}`)->S.parseAnyWith(
      schema,
    ),
    {
      code: InvalidType({expected: S.literal("value")->S.toUnknown, received: %raw(`"wrong"`)}),
      operation: Parse,
      path: S.Path.fromLocation("tag"),
    },
  )
  // Field check should be the third
  t->U.assertErrorResult(
    %raw(`{tag: "value", key: 123, unknownKey: "value", unknownKey2: "value"}`)->S.parseAnyWith(
      schema,
    ),
    {
      code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`123`)}),
      operation: Parse,
      path: S.Path.fromLocation("key"),
    },
  )
  // Unknown keys check should be the last
  t->U.assertErrorResult(
    %raw(`{tag: "value", key: "value", unknownKey: "value2", unknownKey2: "value2"}`)->S.parseAnyWith(
      schema,
    ),
    {code: ExcessField("unknownKey"), operation: Parse, path: S.Path.empty},
  )
  // Parses valid
  t->Assert.deepEqual(
    %raw(`{tag: "value", key: "value"}`)->S.parseAnyWith(schema),
    Ok({
      "key": "value",
    }),
    (),
  )
})

module Compiled = {
  test("Compiled parse code snapshot for simple object", t => {
    let schema = S.object(s =>
      {
        "foo": s.field("foo", S.string),
        "bar": s.field("bar", S.bool),
      }
    )

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Parse,
      `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["foo"],v1=i["bar"];if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="boolean"){e[1](v1)}return {"foo":v0,"bar":v1,}}`,
    )
  })

  test("Compiled parse code snapshot for simple object with async", t => {
    let schema = S.object(s =>
      {
        "foo": s.field(
          "foo",
          S.unknown->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}),
        ),
        "bar": s.field("bar", S.bool),
      }
    )

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Parse,
      `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["bar"];if(typeof v0!=="boolean"){e[1](v0)}return Promise.all([e[0](i["foo"])]).then(a=>({"foo":a[0],"bar":v0,}))}`,
    )
  })

  test("Compiled serialize code snapshot for simple object", t => {
    let schema = S.object(s =>
      {
        "foo": s.field("foo", S.string),
        "bar": s.field("bar", S.bool),
      }
    )

    t->U.assertCompiledCode(~schema, ~op=#Serialize, `i=>{return {"foo":i["foo"],"bar":i["bar"],}}`)
  })

  test("Compiled parse code snapshot for simple object with strict unknown keys", t => {
    let schema = S.object(s =>
      {
        "foo": s.field("foo", S.string),
        "bar": s.field("bar", S.bool),
      }
    )->S.Object.strict

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Parse,
      `i=>{if(!i||i.constructor!==Object){e[3](i)}let v0=i["foo"],v1=i["bar"],v2;if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="boolean"){e[1](v1)}for(v2 in i){if(v2!=="foo"&&v2!=="bar"){e[2](v2)}}return {"foo":v0,"bar":v1,}}`,
    )
  })

  test("Compiled serialize code snapshot for simple object with strict unknown keys", t => {
    let schema = S.object(s =>
      {
        "foo": s.field("foo", S.string),
        "bar": s.field("bar", S.bool),
      }
    )->S.Object.strict

    t->U.assertCompiledCode(~schema, ~op=#Serialize, `i=>{return {"foo":i["foo"],"bar":i["bar"],}}`)
  })

  test(
    "Compiled parse code snapshot for simple object with strict unknown keys, renamed fields, constants and discriminants",
    t => {
      let schema = S.object(s => {
        s.tag("tag", 0)
        {
          "foo": s.field("FOO", S.string),
          "bar": s.field("BAR", S.bool),
          "zoo": 1,
        }
      })->S.Object.strict

      t->U.assertCompiledCode(
        ~schema,
        ~op=#Parse,
        `i=>{if(!i||i.constructor!==Object){e[5](i)}let v0=i["tag"],v1=i["FOO"],v2=i["BAR"],v3;if(v0!==0){e[0](v0)}if(typeof v1!=="string"){e[1](v1)}if(typeof v2!=="boolean"){e[2](v2)}for(v3 in i){if(v3!=="tag"&&v3!=="FOO"&&v3!=="BAR"){e[3](v3)}}return {"foo":v1,"bar":v2,"zoo":e[4],}}`,
      )
    },
  )

  test(
    "Compiled serialize code snapshot for simple object with strict unknown keys, renamed fields, constants and discriminants",
    t => {
      let schema = S.object(s => {
        s.tag("tag", 0)
        {
          "foo": s.field("FOO", S.string),
          "bar": s.field("BAR", S.bool),
          "zoo": 1,
        }
      })->S.Object.strict

      t->U.assertCompiledCode(
        ~schema,
        ~op=#Serialize,
        `i=>{if(i["zoo"]!==1){e[0](i["zoo"])}return {"tag":e[1],"FOO":i["foo"],"BAR":i["bar"],}}`,
      )
    },
  )
}

test(
  "Works with object schema used multiple times as a child schema. See: https://github.com/DZakh/rescript-schema/issues/63",
  t => {
    let appVersionSpecSchema = S.object(s =>
      {
        "current": s.field("current", S.string),
        "minimum": s.field("minimum", S.string),
      }
    )

    let appVersionsSchema = S.object(s =>
      {
        "ios": s.field("ios", appVersionSpecSchema),
        "android": s.field("android", appVersionSpecSchema),
      }
    )

    let appVersions = {
      "ios": {"current": "1.1", "minimum": "1.0"},
      "android": {"current": "1.2", "minimum": "1.1"},
    }

    let value = appVersions->S.parseAnyWith(appVersionsSchema)->S.unwrap
    t->Assert.deepEqual(value, appVersions, ())

    let data = appVersions->S.serializeWith(appVersionsSchema)->S.unwrap
    t->Assert.deepEqual(data, appVersions->Obj.magic, ())
  },
)

test("Reverse empty object schema to literal", t => {
  let schema = S.object(_ => ())
  // t->U.assertEqualSchemas(schema->S.\"~experimentalReverse", S.unit->S.toUnknown)
  t->U.assertEqualSchemas(schema->S.\"~experimentalReverse", S.unknown)
})

test("Succesfully uses reversed empty object schema for parsing back to initial value", t => {
  let schema = S.object(_ => ())
  t->U.assertReverseParsesBack(schema, ())
})

test("Reverse tagged object to literal without payload", t => {
  let schema = S.object(s => {
    s.tag("kind", "test")
    #Test
  })
  // t->U.assertEqualSchemas(schema->S.\"~experimentalReverse", S.literal(#Test)->S.toUnknown)
  t->U.assertEqualSchemas(schema->S.\"~experimentalReverse", S.unknown)
})

test(
  "Succesfully uses reversed non-payloaded tagged object schema for parsing back to initial value",
  t => {
    let schema = S.object(s => {
      s.tag("kind", "test")
      #Test
    })
    t->U.assertReverseParsesBack(schema, #Test)
  },
)

test("Reverse tagged object to primitive schema", t => {
  let schema = S.object(s => {
    s.tag("kind", "test")
    s.field("field", S.bool)
  })
  // t->U.assertEqualSchemas(schema->S.\"~experimentalReverse", S.bool->S.toUnknown)
  t->U.assertEqualSchemas(schema->S.\"~experimentalReverse", S.unknown)
})

test(
  "Succesfully uses reversed tagged object schema with field as output for parsing back to initial value",
  t => {
    let schema = S.object(s => {
      s.tag("kind", "test")
      s.field("field", S.bool)
    })
    t->U.assertReverseParsesBack(schema, true)
  },
)

test("Reverse with output of nested object/tuple schema", t => {
  let schema = S.object(s => {
    s.tag("kind", "test")
    {
      "nested": {
        "field": (s.field("raw_field", S.bool), true),
      },
    }
  })
  // t->U.assertEqualSchemas(
  //   schema->S.\"~experimentalReverse",
  //   S.object(s => {
  //     let _ = s.field(
  //       "nested",
  //       S.object(
  //         s => {
  //           let _ = s.field(
  //             "field",
  //             S.tuple(
  //               s => {
  //                 let _ = s.item(0, S.bool)
  //                 s.tag(1, true)
  //               },
  //             ),
  //           )
  //         },
  //       ),
  //     )
  //   })->S.toUnknown,
  // )
  t->U.assertEqualSchemas(schema->S.\"~experimentalReverse", S.unknown)
})

test(
  "Succesfully parses reversed schema with output of nested object/tuple and parses it back to initial value",
  t => {
    let schema = S.object(s => {
      s.tag("kind", "test")
      {
        "nested": {
          "field": (s.field("raw_field", S.bool), true),
        },
      }
    })
    t->U.assertReverseParsesBack(schema, {"nested": {"field": (true, true)}})
  },
)
