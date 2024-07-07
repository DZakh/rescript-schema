open Ava
open RescriptCore

test("Successfully parses object with quotes in a field name", t => {
  let schema = S.object(s =>
    {
      "field": s.field("\"\'\`", S.string),
    }
  )

  t->Assert.deepEqual(%raw(`{"\"\'\`": "bar"}`)->S.parseAnyWith(schema), Ok({"field": "bar"}), ())
})

test("Successfully serializing object with quotes in a field name", t => {
  let schema = S.object(s =>
    {
      "field": s.field("\"\'\`", S.string),
    }
  )

  t->Assert.deepEqual(
    {"field": "bar"}->S.serializeToUnknownWith(schema),
    Ok(%raw(`{"\"\'\`": "bar"}`)),
    (),
  )
})

test("Successfully parses object transformed to object with quotes in a field name", t => {
  let schema = S.object(s =>
    {
      "\"\'\`": s.field("field", S.string),
    }
  )

  t->Assert.deepEqual(%raw(`{"field": "bar"}`)->S.parseAnyWith(schema), Ok({"\"\'\`": "bar"}), ())
})

test("Successfully serializes object transformed to object with quotes in a field name", t => {
  let schema = S.object(s =>
    {
      "\"\'\`": s.field("field", S.string),
    }
  )

  t->Assert.deepEqual(
    {"\"\'\`": "bar"}->S.serializeToUnknownWith(schema),
    Ok(%raw(`{"field": "bar"}`)),
    (),
  )
})

test("Successfully parses object with discriminant which has quotes as the field name", t => {
  let schema = S.object(s => {
    ignore(s.field("\"\'\`", S.literal(Null.null)))
    {
      "field": s.field("field", S.string),
    }
  })

  t->Assert.deepEqual(
    %raw(`{
      "\"\'\`": null,
      "field": "bar",
    }`)->S.parseAnyWith(schema),
    Ok({"field": "bar"}),
    (),
  )
})

test("Successfully serializes object with discriminant which has quotes as the field name", t => {
  let schema = S.object(s => {
    ignore(s.field("\"\'\`", S.literal(Null.null)))
    {
      "field": s.field("field", S.string),
    }
  })

  t->Assert.deepEqual(
    {"field": "bar"}->S.serializeToUnknownWith(schema),
    Ok(
      %raw(`{
        "\"\'\`": null,
        "field": "bar",
      }`),
    ),
    (),
  )
})

test("Successfully parses object with discriminant which has quotes as the literal value", t => {
  let schema = S.object(s => {
    ignore(s.field("kind", S.literal("\"\'\`")))
    {
      "field": s.field("field", S.string),
    }
  })

  t->Assert.deepEqual(
    %raw(`{
      "kind": "\"\'\`",
      "field": "bar",
    }`)->S.parseAnyWith(schema),
    Ok({"field": "bar"}),
    (),
  )
})

test(
  "Successfully serializes object with discriminant which has quotes as the literal value",
  t => {
    let schema = S.object(s => {
      ignore(s.field("kind", S.literal("\"\'\`")))
      {
        "field": s.field("field", S.string),
      }
    })

    t->Assert.deepEqual(
      {"field": "bar"}->S.serializeToUnknownWith(schema),
      Ok(
        %raw(`{
          "kind": "\"\'\`",
          "field": "bar",
        }`),
      ),
      (),
    )
  },
)

test(
  "Successfully parses object transformed to object with quotes in name of hardcoded field",
  t => {
    let schema = S.object(s =>
      {
        "\"\'\`": "hardcoded",
        "field": s.field("field", S.string),
      }
    )

    t->Assert.deepEqual(
      %raw(`{"field": "bar"}`)->S.parseAnyWith(schema),
      Ok({
        "\"\'\`": "hardcoded",
        "field": "bar",
      }),
      (),
    )
  },
)

test(
  "Successfully serializes object transformed to object with quotes in name of hardcoded field",
  t => {
    let schema = S.object(s =>
      {
        "\"\'\`": "hardcoded",
        "field": s.field("field", S.string),
      }
    )

    t->Assert.deepEqual(
      {
        "\"\'\`": "hardcoded",
        "field": "bar",
      }->S.serializeToUnknownWith(schema),
      Ok(%raw(`{"field": "bar"}`)),
      (),
    )
  },
)

test(
  "Successfully parses object transformed to object with quotes in value of hardcoded field",
  t => {
    let schema = S.object(s =>
      {
        "hardcoded": "\"\'\`",
        "field": s.field("field", S.string),
      }
    )

    t->Assert.deepEqual(
      %raw(`{"field": "bar"}`)->S.parseAnyWith(schema),
      Ok({
        "hardcoded": "\"\'\`",
        "field": "bar",
      }),
      (),
    )
  },
)

test(
  "Successfully serializes object transformed to object with quotes in value of hardcoded field",
  t => {
    let schema = S.object(s =>
      {
        "hardcoded": "\"\'\`",
        "field": s.field("field", S.string),
      }
    )

    t->Assert.deepEqual(
      {
        "hardcoded": "\"\'\`",
        "field": "bar",
      }->S.serializeToUnknownWith(schema),
      Ok(%raw(`{"field": "bar"}`)),
      (),
    )
  },
)

test("Has proper error path when fails to parse object with quotes in a field name", t => {
  let schema = S.object(s =>
    {
      "field": s.field("\"\'\`", S.string->S.refine(s => _ => s.fail("User error"))),
    }
  )

  t->U.assertErrorResult(
    %raw(`{"\"\'\`": "bar"}`)->S.parseAnyWith(schema),
    {
      code: OperationFailed("User error"),
      operation: Parse,
      path: S.Path.fromArray(["\"\'\`"]),
    },
  )
})

test("Has proper error path when fails to serialize object with quotes in a field name", t => {
  let schema = S.object(s =>
    Dict.fromArray([
      ("\"\'\`", s.field("field", S.string->S.refine(s => _ => s.fail("User error")))),
    ])
  )

  t->U.assertErrorResult(
    Dict.fromArray([("\"\'\`", "bar")])->S.serializeToUnknownWith(schema),
    {
      code: OperationFailed("User error"),
      operation: SerializeToUnknown,
      path: S.Path.fromArray(["\"\'\`"]),
    },
  )
})

test("Field name in a format of a path is handled properly", t => {
  let schema = S.object(s =>
    {
      "field": s.field(`["abc"]["cde"]`, S.string),
    }
  )

  t->U.assertErrorResult(
    %raw(`{"bar": "foo"}`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`undefined`)}),
      operation: Parse,
      path: S.Path.fromArray([`["abc"]["cde"]`]),
    },
  )
})
