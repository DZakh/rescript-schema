open Ava

module Positive = {
  module TestData = {
    type t = {
      discriminantStruct: S.t<S.unknown>,
      discriminantValue: S.unknown,
      testNamePostfix: string,
    }

    let make = (
      ~discriminantStruct: S.t<'value>,
      ~discriminantValue: 'any,
      ~description as maybeDescription=?,
      (),
    ) => {
      discriminantStruct: discriminantStruct->Obj.magic,
      discriminantValue: discriminantValue->Obj.magic,
      testNamePostfix: switch maybeDescription {
      | Some(description) => ` ${description}`
      | None => ""
      },
    }
  }

  [
    TestData.make(
      ~discriminantStruct=S.literal(String("asdf")),
      ~discriminantValue=%raw(`"asdf"`),
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.literal(String("\"\'\`")),
      ~discriminantValue=%raw(`"\"\'\`"`),
      (),
    ),
    TestData.make(~discriminantStruct=S.literal(Int(123)), ~discriminantValue=%raw("123"), ()),
    TestData.make(~discriminantStruct=S.literal(Float(1.3)), ~discriminantValue=%raw("1.3"), ()),
    TestData.make(~discriminantStruct=S.literal(Bool(true)), ~discriminantValue=%raw("true"), ()),
    TestData.make(
      ~discriminantStruct=S.literal(EmptyOption),
      ~discriminantValue=%raw("undefined"),
      (),
    ),
    TestData.make(~discriminantStruct=S.literal(EmptyNull), ~discriminantValue=%raw("null"), ()),
    TestData.make(~discriminantStruct=S.literal(NaN), ~discriminantValue=%raw("NaN"), ()),
    TestData.make(
      ~discriminantStruct=S.union([S.literal(Bool(false)), S.bool()]),
      ~discriminantValue=%raw("false"),
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.tuple2(. S.literal(Bool(false)), S.literal(String("bar"))),
      ~discriminantValue=%raw(`[false, "bar"]`),
      (),
    ),
    TestData.make(
      ~discriminantStruct=S.object(o => {
        o->S.discriminant("nestedDiscriminant", S.literal(String("abc")))
        {
          "field": o->S.field("nestedField", S.literal(Bool(false))),
        }
      }),
      ~discriminantValue=%raw(`{
        "nestedDiscriminant": "abc",
        "nestedField": false
      }`),
      (),
    ),
    TestData.make(
      ~description="and values needed to be escaped",
      ~discriminantStruct=S.object(o => {
        o->S.discriminant("\"\'\`", S.literal(String("\"\'\`")))
        {
          "field": o->S.field("nestedField", S.literal(Bool(false))),
        }
      }),
      ~discriminantValue=%raw(`{
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
            o->S.discriminant("discriminant", testData.discriminantStruct)
            {
              "field": o->S.field("field", S.string()),
            }
          },
        )

        t->Assert.deepEqual(
          {
            "discriminant": testData.discriminantValue,
            "field": "bar",
          }->S.parseWith(struct),
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
            o->S.discriminant("discriminant", testData.discriminantStruct)
            {
              "field": o->S.field("field", S.string()),
            }
          },
        )

        t->Assert.deepEqual(
          {"field": "bar"}->S.serializeWith(struct),
          Ok(
            {
              "discriminant": testData.discriminantValue,
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
      discriminantStruct: S.t<S.unknown>,
      testNamePostfix: string,
    }

    let make = (~discriminantStruct: S.t<'value>, ~description as maybeDescription=?, ()) => {
      discriminantStruct: discriminantStruct->Obj.magic,
      testNamePostfix: switch maybeDescription {
      | Some(description) => ` ${description}`
      | None => ""
      },
    }
  }

  [
    TestData.make(~discriminantStruct=S.string(), ()),
    TestData.make(~discriminantStruct=S.int(), ()),
    TestData.make(~discriminantStruct=S.float(), ()),
    TestData.make(~discriminantStruct=S.bool(), ()),
    TestData.make(~discriminantStruct=S.option(S.literal(Bool(true))), ()),
    TestData.make(~discriminantStruct=S.null(S.literal(Bool(true))), ()),
    TestData.make(~discriminantStruct=S.never(), ()),
    TestData.make(~discriminantStruct=S.unknown(), ()),
    TestData.make(~discriminantStruct=S.array(S.literal(Bool(true))), ()),
    TestData.make(~discriminantStruct=S.dict(S.literal(Bool(true))), ()),
    TestData.make(~discriminantStruct=S.date(), ()),
    TestData.make(~discriminantStruct=S.tuple2(. S.literal(Bool(true)), S.bool()), ()),
    TestData.make(~discriminantStruct=S.object(o => o->S.field("field", S.bool())), ()),
    TestData.make(~discriminantStruct=S.union([S.bool(), S.literal(Bool(false))]), ()),
  ]->Js.Array2.forEach(testData => {
    test(
      `Fails to create an object struct with discriminant "${testData.discriminantStruct->S.name}"${testData.testNamePostfix}`,
      t => {
        t->Assert.throws(
          () => {
            S.object(
              o => {
                o->S.discriminant("discriminant", testData.discriminantStruct)
                {
                  "field": o->S.field("field", S.string()),
                }
              },
            )->ignore
          },
          ~expectations=ThrowsException.make(
            ~message=String(
              "[rescript-struct] Can\'t create serializer for the discriminant field with the name \"discriminant\"",
            ),
            (),
          ),
          (),
        )
      },
    )
  })
}
