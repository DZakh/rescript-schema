open Ava

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
      ~discriminantStruct=S.literal(String("asdf")),
      ~discriminantData=%raw(`"asdf"`),
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.literal(String("\"\'\`")),
      ~discriminantData=%raw(`"\"\'\`"`),
      (),
    ),
    TestData.make(~discriminantStruct=S.literal(Int(123)), ~discriminantData=%raw("123"), ()),
    TestData.make(~discriminantStruct=S.literal(Float(1.3)), ~discriminantData=%raw("1.3"), ()),
    TestData.make(~discriminantStruct=S.literal(Bool(true)), ~discriminantData=%raw("true"), ()),
    TestData.make(
      ~discriminantStruct=S.literal(EmptyOption),
      ~discriminantData=%raw("undefined"),
      (),
    ),
    TestData.make(~discriminantStruct=S.literal(EmptyNull), ~discriminantData=%raw("null"), ()),
    TestData.make(~discriminantStruct=S.literal(NaN), ~discriminantData=%raw("NaN"), ()),
    TestData.make(
      ~discriminantStruct=S.union([S.literal(Bool(false)), S.bool()]),
      ~discriminantData=%raw("false"),
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.tuple2(. S.literal(Bool(false)), S.literal(String("bar"))),
      ~discriminantData=%raw(`[false, "bar"]`),
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.object(o => {
        ignore(o->S.field("nestedDiscriminant", S.literal(String("abc"))))
        {
          "field": o->S.field("nestedField", S.literal(Bool(false))),
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
      ~discriminantStruct=S.object(o => {
        ignore(o->S.field("\"\'\`", S.literal(String("\"\'\`"))))
        {
          "field": o->S.field("nestedField", S.literal(Bool(false))),
        }
      }),
      ~discriminantData=%raw(`{
        "\"\'\`": "\"\'\`",
        "nestedField": false
      }`),
      (),
    ),
  ]->Js.Array2.forEach(testData => {
    test(
      `Successfully parses object with discriminant "${testData.discriminantStruct->S.name}"${testData.testNamePostfix}`,
      t => {
        let struct = S.object(
          o => {
            ignore(o->S.field("discriminant", testData.discriminantStruct))
            {
              "field": o->S.field("field", S.string()),
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
          o => {
            ignore(o->S.field("discriminant", testData.discriminantStruct))
            {
              "field": o->S.field("field", S.string()),
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
    TestData.make(~discriminantStruct=S.string(), ~discriminantData="foo", ()),
    TestData.make(~discriminantStruct=S.int(), ~discriminantData=123, ()),
    TestData.make(~discriminantStruct=S.float(), ~discriminantData=123., ()),
    TestData.make(~discriminantStruct=S.bool(), ~discriminantData=true, ()),
    TestData.make(~discriminantStruct=S.option(S.literal(Bool(true))), ~discriminantData=None, ()),
    TestData.make(
      ~discriminantStruct=S.null(S.literal(Bool(true))),
      ~discriminantData=%raw("null"),
      (),
    ),
    TestData.make(~discriminantStruct=S.unknown(), ~discriminantData="anything", ()),
    TestData.make(
      ~discriminantStruct=S.array(S.literal(Bool(true))),
      ~discriminantData=[true, true],
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.dict(S.literal(Bool(true))),
      ~discriminantData=Js.Dict.fromArray([("foo", true), ("bar", true)]),
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.tuple2(. S.literal(Bool(true)), S.bool()),
      ~discriminantData=(true, false),
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.object(o => o->S.field("field", S.bool())),
      ~discriminantData={"field": true},
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.union([S.bool(), S.literal(Bool(false))]),
      ~discriminantData=true,
      (),
    ),
  ]->Js.Array2.forEach(testData => {
    test(
      `Successfully parses object with discriminant that we don't know how to serialize "${testData.discriminantStruct->S.name}"${testData.testNamePostfix}`,
      t => {
        let struct = S.object(
          o => {
            ignore(o->S.field("discriminant", testData.discriminantStruct))
            {
              "field": o->S.field("field", S.string()),
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
          o => {
            ignore(o->S.field("discriminant", testData.discriminantStruct))
            {
              "field": o->S.field("field", S.string()),
            }
          },
        )

        t->Assert.deepEqual(
          {"field": "bar"}->S.serializeToUnknownWith(struct),
          Error({
            code: MissingSerializer,
            operation: Serializing,
            path: S.Path.fromArray(["discriminant"]),
          }),
          (),
        )
      },
    )
  })
}

test(`Fails to parse object with invalid data passed to discriminant field`, t => {
  let struct = S.object(o => {
    ignore(o->S.field("discriminant", S.string()))
    {
      "field": o->S.field("field", S.string()),
    }
  })

  t->Assert.deepEqual(
    {
      "discriminant": false,
      "field": "bar",
    }->S.parseAnyWith(struct),
    Error({
      code: UnexpectedType({expected: "String", received: "Bool"}),
      operation: Parsing,
      path: S.Path.fromArray(["discriminant"]),
    }),
    (),
  )
})

test(`Fails to serialize object with discriminant "Never"`, t => {
  let struct = S.object(o => {
    ignore(o->S.field("discriminant", S.never()))
    {
      "field": o->S.field("field", S.string()),
    }
  })

  t->Assert.deepEqual(
    {"field": "bar"}->S.serializeToUnknownWith(struct),
    Error({
      code: MissingSerializer,
      operation: Serializing,
      path: S.Path.fromArray(["discriminant"]),
    }),
    (),
  )
})
