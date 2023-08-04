open Ava
open RescriptCore

module Positive = {
  module TestData = {
    type t = {
      discriminantStruct: S.t<unknown>,
      discriminantData: unknown,
      testNamePostfix: string,
    }

    let make = (
      ~discriminantStruct: S.t<'value>,
      ~discriminantData: 'any,
      ~description as maybeDescription=?,
      (),
    ) => {
      discriminantStruct: discriminantStruct->Obj.magic,
      discriminantData: discriminantData->Obj.magic,
      testNamePostfix: switch maybeDescription {
      | Some(description) => ` ${description}`
      | None => ""
      },
    }
  }

  [
    TestData.make(
      ~discriminantStruct=S.literal("asdf"),
      ~discriminantData=%raw(`"asdf"`),
      ~description="String",
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.literal("\"\'\`"),
      ~discriminantData=%raw(`"\"\'\`"`),
      ~description="String which needs to be escaped",
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.literal(123),
      ~discriminantData=%raw("123"),
      ~description="Int",
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.literal(1.3),
      ~discriminantData=%raw("1.3"),
      ~description="Float",
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.literal(true),
      ~discriminantData=%raw("true"),
      ~description="Bool",
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.literal(),
      ~discriminantData=%raw(`undefined`),
      ~description="Unit",
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.literal(Null.null),
      ~discriminantData=%raw(`null`),
      ~description="Null",
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.literal(%raw(`NaN`)),
      ~discriminantData=%raw(`NaN`),
      ~description="NaN",
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.union([S.literal(false), S.bool]),
      ~discriminantData=%raw("false"),
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.tuple2(S.literal(false), S.literal("bar")),
      ~discriminantData=%raw(`[false, "bar"]`),
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.literal((false, "bar")),
      ~discriminantData=%raw(`[false, "bar"]`),
      ~description="Tuple",
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.object(s => {
        ignore(s.field("nestedDiscriminant", S.literal("abc")))
        {
          "field": s.field("nestedField", S.literal(false)),
        }
      }),
      ~discriminantData=%raw(`{
        "nestedDiscriminant": "abc",
        "nestedField": false
      }`),
      (),
    ),
    TestData.make(
      ~description="and values needed to be escaped",
      ~discriminantStruct=S.object(s => {
        ignore(s.field("\"\'\`", S.literal("\"\'\`")))
        {
          "field": s.field("nestedField", S.literal(false)),
        }
      }),
      ~discriminantData=%raw(`{
        "\"\'\`": "\"\'\`",
        "nestedField": false
      }`),
      (),
    ),
  ]->Array.forEach(testData => {
    test(
      `Successfully parses object with discriminant "${testData.discriminantStruct->S.name}"${testData.testNamePostfix}`,
      t => {
        let struct = S.object(
          s => {
            ignore(s.field("discriminant", testData.discriminantStruct))
            {
              "field": s.field("field", S.string),
            }
          },
        )

        t->Assert.deepEqual(
          {
            "discriminant": testData.discriminantData,
            "field": "bar",
          }->S.parseAnyWith(struct),
          Ok({"field": "bar"}),
          (),
        )
      },
    )

    test(
      `Successfully serializes object with discriminant "${testData.discriminantStruct->S.name}"${testData.testNamePostfix}`,
      t => {
        let struct = S.object(
          s => {
            ignore(s.field("discriminant", testData.discriminantStruct))
            {
              "field": s.field("field", S.string),
            }
          },
        )

        t->Assert.deepEqual(
          {"field": "bar"}->S.serializeToUnknownWith(struct),
          Ok(
            {
              "discriminant": testData.discriminantData,
              "field": "bar",
            }->Obj.magic,
          ),
          (),
        )
      },
    )
  })
}

module Negative = {
  module TestData = {
    type t = {
      discriminantStruct: S.t<unknown>,
      discriminantData: unknown,
      testNamePostfix: string,
    }

    let make = (
      ~discriminantStruct: S.t<'value>,
      ~discriminantData: 'any,
      ~description as maybeDescription=?,
      (),
    ) => {
      discriminantStruct: discriminantStruct->Obj.magic,
      discriminantData: discriminantData->Obj.magic,
      testNamePostfix: switch maybeDescription {
      | Some(description) => ` ${description}`
      | None => ""
      },
    }
  }

  [
    TestData.make(~discriminantStruct=S.string, ~discriminantData="foo", ()),
    TestData.make(~discriminantStruct=S.int, ~discriminantData=123, ()),
    TestData.make(~discriminantStruct=S.float, ~discriminantData=123., ()),
    TestData.make(~discriminantStruct=S.bool, ~discriminantData=true, ()),
    TestData.make(~discriminantStruct=S.option(S.literal(true)), ~discriminantData=None, ()),
    TestData.make(~discriminantStruct=S.null(S.literal(true)), ~discriminantData=%raw(`null`), ()),
    TestData.make(~discriminantStruct=S.unknown, ~discriminantData="anything", ()),
    TestData.make(~discriminantStruct=S.array(S.literal(true)), ~discriminantData=[true, true], ()),
    TestData.make(
      ~discriminantStruct=S.dict(S.literal(true)),
      ~discriminantData=Dict.fromArray([("foo", true), ("bar", true)]),
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.tuple2(S.literal(true), S.bool),
      ~discriminantData=(true, false),
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.object(s => s.field("field", S.bool)),
      ~discriminantData={"field": true},
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.union([S.bool, S.literal(false)]),
      ~discriminantData=true,
      (),
    ),
  ]->Array.forEach(testData => {
    test(
      `Successfully parses object with discriminant that we don't know how to serialize "${testData.discriminantStruct->S.name}"${testData.testNamePostfix}`,
      t => {
        let struct = S.object(
          s => {
            ignore(s.field("discriminant", testData.discriminantStruct))
            {
              "field": s.field("field", S.string),
            }
          },
        )

        t->Assert.deepEqual(
          {
            "discriminant": testData.discriminantData,
            "field": "bar",
          }->S.parseAnyWith(struct),
          Ok({"field": "bar"}),
          (),
        )
      },
    )

    test(
      `Fails to serialize object with discriminant that we don't know how to serialize "${testData.discriminantStruct->S.name}"${testData.testNamePostfix}`,
      t => {
        let struct = S.object(
          s => {
            ignore(s.field("discriminant", testData.discriminantStruct))
            {
              "field": s.field("field", S.string),
            }
          },
        )

        t->Assert.deepEqual(
          {"field": "bar"}->S.serializeToUnknownWith(struct),
          Error({
            code: InvalidOperation({
              description: `Can\'t create serializer. The "discriminant" field is not registered and not a literal. Use S.transform instead`,
            }),
            operation: Serializing,
            path: S.Path.empty,
          }),
          (),
        )
      },
    )
  })
}

test(`Fails to parse object with invalid data passed to discriminant field`, t => {
  let struct = S.object(s => {
    ignore(s.field("discriminant", S.string))
    {
      "field": s.field("field", S.string),
    }
  })

  t->Assert.deepEqual(
    {
      "discriminant": false,
      "field": "bar",
    }->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: S.string->S.toUnknown, received: Obj.magic(false)}),
      operation: Parsing,
      path: S.Path.fromArray(["discriminant"]),
    }),
    (),
  )
})

test(`Parses discriminant fields before registered fields`, t => {
  let struct = S.object(s => {
    ignore(s.field("discriminant", S.string))
    {
      "field": s.field("field", S.string),
    }
  })

  t->Assert.deepEqual(
    {
      "discriminant": false,
      "field": false,
    }->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: S.string->S.toUnknown, received: Obj.magic(false)}),
      operation: Parsing,
      path: S.Path.fromArray(["discriminant"]),
    }),
    (),
  )
})

test(`Fails to serialize object with discriminant "Never"`, t => {
  let struct = S.object(s => {
    ignore(s.field("discriminant", S.never))
    {
      "field": s.field("field", S.string),
    }
  })

  t->Assert.deepEqual(
    {"field": "bar"}->S.serializeToUnknownWith(struct),
    Error({
      code: InvalidOperation({
        description: `Can't create serializer. The "discriminant" field is not registered and not a literal. Use S.transform instead`,
      }),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test(`Serializes constant fields before registered fields`, t => {
  let struct = S.object(s => {
    {
      "field": s.field("field", S.literal(true)),
      "constant": true,
    }
  })

  t->Assert.deepEqual(
    {"constant": false, "field": false}->S.serializeToUnknownWith(struct),
    Error({
      code: InvalidLiteral({expected: Boolean(true), received: Obj.magic(false)}),
      operation: Serializing,
      path: S.Path.fromArray(["constant"]),
    }),
    (),
  )
})
