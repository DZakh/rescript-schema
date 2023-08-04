open Ava
open RescriptCore

module Tuple0 = {
  let value = ()
  let any = %raw(`[]`)
  let invalidAny = %raw(`[true]`)
  let invalidTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.tuple(_ => ())

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse invalid value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidAny->S.parseAnyWith(struct),
      Error({
        code: InvalidTupleSize({
          expected: 0,
          received: 1,
        }),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to parse invalid type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidTypeAny->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: struct->S.toUnknown, received: invalidTypeAny}),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(struct), Ok(any), ())
  })
}

test("Classify of tuple with holes", t => {
  let struct = S.tuple(s => (s.item(0, S.string), s.item(2, S.int)))

  t->Assert.deepEqual(
    struct->S.classify,
    Tuple([S.string->S.toUnknown, S.unit->S.toUnknown, S.int->S.toUnknown]),
    (),
  )
})

test("Successfully parses tuple with holes", t => {
  let struct = S.tuple(s => (s.item(0, S.string), s.item(2, S.int)))

  t->Assert.deepEqual(%raw(`["value",, 123]`)->S.parseAnyWith(struct), Ok("value", 123), ())
})

test("Fails to parse tuple with holes", t => {
  let struct = S.tuple(s => (s.item(0, S.string), s.item(2, S.int)))

  t->Assert.deepEqual(
    %raw(`["value", "smth", 123]`)->S.parseAnyWith(struct),
    Error({
      code: InvalidLiteral({expected: Undefined, received: %raw(`"smth"`)}),
      operation: Parsing,
      path: S.Path.fromLocation("1"),
    }),
    (),
  )
})

test("Successfully serializes tuple with holes", t => {
  let struct = S.tuple(s => (s.item(0, S.string), s.item(2, S.int)))

  t->Assert.deepEqual(
    ("value", 123)->S.serializeToUnknownWith(struct),
    Ok(%raw(`["value",, 123]`)),
    (),
  )
})

test("Fails to serialize tuple struct with single item registered multiple times", t => {
  let struct = S.tuple(s => {
    let item = s.item(0, S.string)
    {
      "item1": item,
      "item2": item,
    }
  })
  t->Assert.deepEqual(
    {"item1": "foo", "item2": "foo"}->S.serializeToUnknownWith(struct),
    Error({
      code: InvalidOperation({
        description: `The item "0" is registered multiple times. If you want to duplicate the item, use S.transform instead`,
      }),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test(`Fails to serialize tuple with discriminant "Never"`, t => {
  let struct = S.tuple(s => {
    ignore(s.item(0, S.never))
    s.item(1, S.string)
  })

  t->Assert.deepEqual(
    "bar"->S.serializeToUnknownWith(struct),
    Error({
      code: InvalidOperation({
        description: `Can't create serializer. The "0" item is not registered and not a literal. Use S.transform instead`,
      }),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully parses tuple transformed to variant", t => {
  let struct = S.tuple(s => #VARIANT(s.item(0, S.bool)))

  t->Assert.deepEqual(%raw(`[true]`)->S.parseAnyWith(struct), Ok(#VARIANT(true)), ())
})

test("Successfully serializes tuple transformed to variant", t => {
  let struct = S.tuple(s => #VARIANT(s.item(0, S.bool)))

  t->Assert.deepEqual(#VARIANT(true)->S.serializeToUnknownWith(struct), Ok(%raw(`[true]`)), ())
})

test("Fails to serialize tuple transformed to variant", t => {
  let struct = S.tuple(s => Ok(s.item(0, S.bool)))

  t->Assert.deepEqual(
    Error("foo")->S.serializeToUnknownWith(struct),
    Error({
      code: InvalidLiteral({expected: String("Ok"), received: %raw(`"Error"`)}),
      operation: Serializing,
      path: S.Path.fromLocation("TAG"),
    }),
    (),
  )
})

test("Fails to create tuple struct with single item defined multiple times", t => {
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
      message: `[rescript-struct] The item "0" is defined multiple times. If you want to duplicate the item, use S.transform instead.`,
    },
    (),
  )
})

test("Tuple struct parsing checks order", t => {
  let struct = S.tuple(s => {
    s.tag(1, "value")
    {
      "key": s.item(0, S.literal("value")),
    }
  })

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
  // Length check should be the second
  t->Assert.deepEqual(
    %raw(`["wrong", "wrong", "value", "value"]`)->S.parseAnyWith(struct),
    Error({
      code: InvalidTupleSize({expected: 2, received: 4}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
  // Tag check should be the third
  t->Assert.deepEqual(
    %raw(`["wrong", "wrong"]`)->S.parseAnyWith(struct),
    Error({
      code: InvalidLiteral({expected: String("value"), received: %raw(`"wrong"`)}),
      operation: Parsing,
      path: S.Path.fromLocation("1"),
    }),
    (),
  )
  // Field check should be the last
  t->Assert.deepEqual(
    %raw(`["wrong", "value"]`)->S.parseAnyWith(struct),
    Error({
      code: InvalidLiteral({expected: String("value"), received: %raw(`"wrong"`)}),
      operation: Parsing,
      path: S.Path.fromLocation("0"),
    }),
    (),
  )
  // Parses valid
  t->Assert.deepEqual(
    %raw(`["value", "value"]`)->S.parseAnyWith(struct),
    Ok({
      "key": "value",
    }),
    (),
  )
})

module Compiled = {
  test("Compiled parse code snapshot for simple tuple", t => {
    let struct = S.tuple(s => (s.item(0, S.string), s.item(1, S.bool)))

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v0,v1;if(!Array.isArray(i)){e[0](i)}if(i.length!==2){e[1](i.length)}v0=i["0"];if(typeof v0!=="string"){e[2](v0)}v1=i["1"];if(typeof v1!=="boolean"){e[3](v1)}return [v0,v1,]}`,
      (),
    )
  })

  test("Compiled parse code snapshot for simple tuple with async", t => {
    let struct = S.tuple(s => (
      s.item(0, S.unknown->S.asyncParserRefine(_ => _ => Promise.resolve())),
      s.item(1, S.bool),
    ))

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v0,v1,v2,v3,v4;if(!Array.isArray(i)){e[0](i)}if(i.length!==2){e[1](i.length)}v0=i["0"];v2=e[2](v0);v1=()=>v2().then(_=>v0);v3=i["1"];if(typeof v3!=="boolean"){e[3](v3)}v4=()=>Promise.all([v1()]).then(([v1])=>([v1,v3,]));return v4}`,
      (),
    )
  })

  test("Compiled serialize code snapshot for simple tuple", t => {
    let struct = S.tuple(s => (s.item(0, S.string), s.item(1, S.bool)))

    // TODO: Improve
    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#serialize,
      `i=>{let v0;v0=[];v0["0"]=i["0"];v0["1"]=i["1"];return v0}`,
      (),
    )
  })

  test(
    "Compiled parse code snapshot for simple tuple with transformation, constants and discriminants",
    t => {
      let struct = S.tuple(s => {
        s.tag(0, 0)
        {
          "foo": s.item(1, S.string),
          "bar": s.item(2, S.bool),
          "zoo": 1,
        }
      })

      t->TestUtils.assertCompiledCode(
        ~struct,
        ~op=#parse,
        `i=>{let v0,v1,v2;if(!Array.isArray(i)){e[0](i)}if(i.length!==3){e[1](i.length)}v2=i["0"];v2===e[5]||e[6](v2);v0=i["1"];if(typeof v0!=="string"){e[2](v0)}v1=i["2"];if(typeof v1!=="boolean"){e[3](v1)}return {"foo":v0,"bar":v1,"zoo":e[4],}}`,
        (),
      )
    },
  )

  test(
    "Compiled serialize code snapshot for simple tuple with transformation, constants and discriminants",
    t => {
      let struct = S.tuple(s => {
        s.tag(0, 0)
        {
          "foo": s.item(1, S.string),
          "bar": s.item(2, S.bool),
          "zoo": 1,
        }
      })

      t->TestUtils.assertCompiledCode(
        ~struct,
        ~op=#serialize,
        `i=>{let v0;v0=[];if(i["zoo"]!==e[0]){e[1](i["zoo"])}v0["1"]=i["foo"];v0["2"]=i["bar"];v0["0"]=e[2];return v0}`,
        (),
      )
    },
  )
}
