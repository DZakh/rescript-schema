open Ava
open RescriptCore

module Tuple0 = {
  let value = ()
  let any = %raw(`[]`)
  let invalidAny = %raw(`[true]`)
  let invalidTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.tuple(_ => ())

  test("Successfully parses", t => {
    let schema = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(schema), Ok(value), ())
  })

  test("Fails to parse invalid value", t => {
    let schema = factory()

    t->U.assertErrorResult(
      invalidAny->S.parseAnyWith(schema),
      {
        code: InvalidType({
          expected: schema->S.toUnknown,
          received: invalidAny,
        }),
        operation: Parsing,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse invalid type", t => {
    let schema = factory()

    t->U.assertErrorResult(
      invalidTypeAny->S.parseAnyWith(schema),
      {
        code: InvalidType({expected: schema->S.toUnknown, received: invalidTypeAny}),
        operation: Parsing,
        path: S.Path.empty,
      },
    )
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(schema), Ok(any), ())
  })
}

test("Fills wholes with S.unit", t => {
  let schema = S.tuple(s => (s.item(0, S.string), s.item(2, S.int)))

  t->U.assertEqualSchemas(schema->S.toUnknown, S.tuple3(S.string, S.unit, S.int)->S.toUnknown)
})

test("Successfully parses tuple with holes", t => {
  let schema = S.tuple(s => (s.item(0, S.string), s.item(2, S.int)))

  t->Assert.deepEqual(%raw(`["value",, 123]`)->S.parseAnyWith(schema), Ok("value", 123), ())
})

test("Fails to parse tuple with holes", t => {
  let schema = S.tuple(s => (s.item(0, S.string), s.item(2, S.int)))

  t->U.assertErrorResult(
    %raw(`["value", "smth", 123]`)->S.parseAnyWith(schema),
    {
      code: InvalidLiteral({expected: S.Literal.parse(None), received: %raw(`"smth"`)}),
      operation: Parsing,
      path: S.Path.fromLocation("1"),
    },
  )
})

test("Successfully serializes tuple with holes", t => {
  let schema = S.tuple(s => (s.item(0, S.string), s.item(2, S.int)))

  t->Assert.deepEqual(
    ("value", 123)->S.serializeToUnknownWith(schema),
    Ok(%raw(`["value",, 123]`)),
    (),
  )
})

test("Fails to serialize tuple schema with single item registered multiple times", t => {
  let schema = S.tuple(s => {
    let item = s.item(0, S.string)
    {
      "item1": item,
      "item2": item,
    }
  })
  t->U.assertErrorResult(
    {"item1": "foo", "item2": "foo"}->S.serializeToUnknownWith(schema),
    {
      code: InvalidOperation({
        description: `The item "0" is registered multiple times`,
      }),
      operation: Serializing,
      path: S.Path.empty,
    },
  )
})

test(`Fails to serialize tuple with discriminant "Never"`, t => {
  let schema = S.tuple(s => {
    ignore(s.item(0, S.never))
    s.item(1, S.string)
  })

  t->Assert.deepEqual(
    "bar"->S.serializeToUnknownWith(schema),
    Error(
      U.error({
        code: InvalidOperation({
          description: `The "0" item is not registered or not a literal`,
        }),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Successfully parses tuple transformed to variant", t => {
  let schema = S.tuple(s => #VARIANT(s.item(0, S.bool)))

  t->Assert.deepEqual(%raw(`[true]`)->S.parseAnyWith(schema), Ok(#VARIANT(true)), ())
})

test("Successfully serializes tuple transformed to variant", t => {
  let schema = S.tuple(s => #VARIANT(s.item(0, S.bool)))

  t->Assert.deepEqual(#VARIANT(true)->S.serializeToUnknownWith(schema), Ok(%raw(`[true]`)), ())
})

test("Fails to serialize tuple transformed to variant", t => {
  let schema = S.tuple(s => Ok(s.item(0, S.bool)))

  t->U.assertErrorResult(
    Error("foo")->S.serializeToUnknownWith(schema),
    {
      code: InvalidLiteral({expected: S.Literal.parse("Ok"), received: %raw(`"Error"`)}),
      operation: Serializing,
      path: S.Path.fromLocation("TAG"),
    },
  )
})

test("Fails to create tuple schema with single item defined multiple times", t => {
  t->Assert.throws(
    () => {
      S.tuple(
        s =>
          {
            "boo": s.item(0, S.string),
            "zoo": s.item(0, S.int),
          },
      )
    },
    ~expectations={
      message: `[rescript-schema] The item "0" is defined multiple times`,
    },
    (),
  )
})

test("Tuple schema parsing checks order", t => {
  let schema = S.tuple(s => {
    s.tag(1, "value")
    {
      "key": s.item(0, S.string),
    }
  })

  // Type check should be the first
  t->U.assertErrorResult(
    %raw(`"foo"`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: schema->S.toUnknown, received: %raw(`"foo"`)}),
      operation: Parsing,
      path: S.Path.empty,
    },
  )
  // Length check should be the second
  t->U.assertErrorResult(
    %raw(`["value", "value", "value", "value"]`)->S.parseAnyWith(schema),
    {
      code: InvalidType({
        expected: schema->S.toUnknown,
        received: %raw(`["value", "value", "value", "value"]`),
      }),
      operation: Parsing,
      path: S.Path.empty,
    },
  )
  // Tag check should be the third
  t->U.assertErrorResult(
    %raw(`["value", "wrong"]`)->S.parseAnyWith(schema),
    {
      code: InvalidLiteral({expected: S.Literal.parse("value"), received: %raw(`"wrong"`)}),
      operation: Parsing,
      path: S.Path.fromLocation("1"),
    },
  )
  // Field check should be the last
  t->U.assertErrorResult(
    %raw(`[1, "value"]`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`1`)}),
      operation: Parsing,
      path: S.Path.fromLocation("0"),
    },
  )
  // Parses valid
  t->Assert.deepEqual(
    %raw(`["value", "value"]`)->S.parseAnyWith(schema),
    Ok({
      "key": "value",
    }),
    (),
  )
})

test("Works correctly with not-modified object item", t => {
  let schema = S.tuple1(S.object(s => s.field("foo", S.string)))

  t->Assert.deepEqual(%raw(`[{"foo": "bar"}]`)->S.parseAnyWith(schema), Ok("bar"), ())
  t->Assert.deepEqual("bar"->S.serializeWith(schema), Ok(%raw(`[{"foo": "bar"}]`)), ())
})

module Compiled = {
  test("Compiled parse code snapshot for simple tuple", t => {
    let schema = S.tuple(s => (s.item(0, S.string), s.item(1, S.bool)))

    t->U.assertCompiledCode(
      ~schema,
      ~op=#parse,
      `i=>{if(!Array.isArray(i)||i.length!==2){e[2](i)}let v0=i["0"],v1=i["1"];if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="boolean"){e[1](v1)}return [v0,v1,]}`,
    )
  })

  test("Compiled parse code snapshot for simple tuple with async", t => {
    let schema = S.tuple(s => (
      s.item(0, S.unknown->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)})),
      s.item(1, S.bool),
    ))

    t->U.assertCompiledCode(
      ~schema,
      ~op=#parse,
      `i=>{if(!Array.isArray(i)||i.length!==2){e[2](i)}let v0=e[0](i["0"]),v1=i["1"];if(typeof v1!=="boolean"){e[1](v1)}return ()=>Promise.all([v0()]).then(([v0])=>([v0,v1,]))}`,
    )
  })

  test("Compiled serialize code snapshot for simple tuple", t => {
    let schema = S.tuple(s => (s.item(0, S.string), s.item(1, S.bool)))

    t->U.assertCompiledCode(~schema, ~op=#serialize, `i=>{return [i["0"],i["1"],]}`)
  })

  test("Compiled serialize code snapshot for empty tuple", t => {
    let schema = S.tuple(_ => ())

    // TODO: No need to do unit check ?
    t->U.assertCompiledCode(~schema, ~op=#serialize, `i=>{if(i!==e[0]){e[1](i)}return []}`)
  })

  test(
    "Compiled parse code snapshot for simple tuple with transformation, constants and discriminants",
    t => {
      let schema = S.tuple(s => {
        s.tag(0, 0)
        {
          "foo": s.item(1, S.string),
          "bar": s.item(2, S.bool),
          "zoo": 1,
        }
      })

      t->U.assertCompiledCode(
        ~schema,
        ~op=#parse,
        `i=>{if(!Array.isArray(i)||i.length!==3){e[4](i)}let v0=i["0"],v1=i["1"],v2=i["2"];v0===0||e[0](v0);if(typeof v1!=="string"){e[1](v1)}if(typeof v2!=="boolean"){e[2](v2)}return {"foo":v1,"bar":v2,"zoo":e[3],}}`,
      )
    },
  )

  test(
    "Compiled serialize code snapshot for simple tuple with transformation, constants and discriminants",
    t => {
      let schema = S.tuple(s => {
        s.tag(0, 0)
        {
          "foo": s.item(1, S.string),
          "bar": s.item(2, S.bool),
          "zoo": 1,
        }
      })

      t->U.assertCompiledCode(
        ~schema,
        ~op=#serialize,
        `i=>{if(i["zoo"]!==e[0]){e[1](i["zoo"])}return [e[2],i["foo"],i["bar"],]}`,
      )
    },
  )
}

test("Works with tuple schema used multiple times as a child schema", t => {
  let appVersionSpecSchema = S.tuple(s =>
    {
      "current": s.item(0, S.string),
      "minimum": s.item(1, S.string),
    }
  )

  let appVersionsSchema = S.object(s =>
    {
      "ios": s.field("ios", appVersionSpecSchema),
      "android": s.field("android", appVersionSpecSchema),
    }
  )

  let rawAppVersions = {
    "ios": ("1.1", "1.0"),
    "android": ("1.2", "1.1"),
  }
  let appVersions = {
    "ios": {"current": "1.1", "minimum": "1.0"},
    "android": {"current": "1.2", "minimum": "1.1"},
  }

  let value = rawAppVersions->S.parseAnyOrRaiseWith(appVersionsSchema)
  t->Assert.deepEqual(value, appVersions, ())

  let data = appVersions->S.serializeOrRaiseWith(appVersionsSchema)
  t->Assert.deepEqual(data, rawAppVersions->Obj.magic, ())
})
