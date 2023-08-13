open Ava
open RescriptCore

test("Successfully parses object with quotes in a field name", t => {
  let struct = S.object(s =>
    {
      "field": s.field("\"\'\`", S.string),
    }
  )

  t->Assert.deepEqual(%raw(`{"\"\'\`": "bar"}`)->S.parseAnyWith(struct), Ok({"field": "bar"}), ())
})

test("Successfully serializing object with quotes in a field name", t => {
  let struct = S.object(s =>
    {
      "field": s.field("\"\'\`", S.string),
    }
  )

  t->Assert.deepEqual(
    {"field": "bar"}->S.serializeToUnknownWith(struct),
    Ok(%raw(`{"\"\'\`": "bar"}`)),
    (),
  )
})

test("Successfully parses object transformed to object with quotes in a field name", t => {
  let struct = S.object(s =>
    {
      "\"\'\`": s.field("field", S.string),
    }
  )

  t->Assert.deepEqual(%raw(`{"field": "bar"}`)->S.parseAnyWith(struct), Ok({"\"\'\`": "bar"}), ())
})

test("Successfully serializes object transformed to object with quotes in a field name", t => {
  let struct = S.object(s =>
    {
      "\"\'\`": s.field("field", S.string),
    }
  )

  t->Assert.deepEqual(
    {"\"\'\`": "bar"}->S.serializeToUnknownWith(struct),
    Ok(%raw(`{"field": "bar"}`)),
    (),
  )
})

test("Successfully parses object with discriminant which has quotes as the field name", t => {
  let struct = S.object(s => {
    ignore(s.field("\"\'\`", S.literal(Null.null)))
    {
      "field": s.field("field", S.string),
    }
  })

  t->Assert.deepEqual(
    %raw(`{
      "\"\'\`": null,
      "field": "bar",
    }`)->S.parseAnyWith(struct),
    Ok({"field": "bar"}),
    (),
  )
})

test("Successfully serializes object with discriminant which has quotes as the field name", t => {
  let struct = S.object(s => {
    ignore(s.field("\"\'\`", S.literal(Null.null)))
    {
      "field": s.field("field", S.string),
    }
  })

  t->Assert.deepEqual(
    {"field": "bar"}->S.serializeToUnknownWith(struct),
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
  let struct = S.object(s => {
    ignore(s.field("kind", S.literal("\"\'\`")))
    {
      "field": s.field("field", S.string),
    }
  })

  t->Assert.deepEqual(
    %raw(`{
      "kind": "\"\'\`",
      "field": "bar",
    }`)->S.parseAnyWith(struct),
    Ok({"field": "bar"}),
    (),
  )
})

test(
  "Successfully serializes object with discriminant which has quotes as the literal value",
  t => {
    let struct = S.object(s => {
      ignore(s.field("kind", S.literal("\"\'\`")))
      {
        "field": s.field("field", S.string),
      }
    })

    t->Assert.deepEqual(
      {"field": "bar"}->S.serializeToUnknownWith(struct),
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
    let struct = S.object(s =>
      {
        "\"\'\`": "hardcoded",
        "field": s.field("field", S.string),
      }
    )

    t->Assert.deepEqual(
      %raw(`{"field": "bar"}`)->S.parseAnyWith(struct),
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
    let struct = S.object(s =>
      {
        "\"\'\`": "hardcoded",
        "field": s.field("field", S.string),
      }
    )

    t->Assert.deepEqual(
      {
        "\"\'\`": "hardcoded",
        "field": "bar",
      }->S.serializeToUnknownWith(struct),
      Ok(%raw(`{"field": "bar"}`)),
      (),
    )
  },
)

test(
  "Successfully parses object transformed to object with quotes in value of hardcoded field",
  t => {
    let struct = S.object(s =>
      {
        "hardcoded": "\"\'\`",
        "field": s.field("field", S.string),
      }
    )

    t->Assert.deepEqual(
      %raw(`{"field": "bar"}`)->S.parseAnyWith(struct),
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
    let struct = S.object(s =>
      {
        "hardcoded": "\"\'\`",
        "field": s.field("field", S.string),
      }
    )

    t->Assert.deepEqual(
      {
        "hardcoded": "\"\'\`",
        "field": "bar",
      }->S.serializeToUnknownWith(struct),
      Ok(%raw(`{"field": "bar"}`)),
      (),
    )
  },
)

test("Has proper error path when fails to parse object with quotes in a field name", t => {
  let struct = S.object(s =>
    {
      "field": s.field("\"\'\`", S.string->S.refine(s => _ => s.fail("User error"))),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"\"\'\`": "bar"}`)->S.parseAnyWith(struct),
    Error(
      U.error({
        code: OperationFailed("User error"),
        operation: Parsing,
        path: S.Path.fromArray(["\"\'\`"]),
      }),
    ),
    (),
  )
})

test("Has proper error path when fails to serialize object with quotes in a field name", t => {
  let struct = S.object(s =>
    Dict.fromArray([
      ("\"\'\`", s.field("field", S.string->S.refine(s => _ => s.fail("User error")))),
    ])
  )

  t->Assert.deepEqual(
    Dict.fromArray([("\"\'\`", "bar")])->S.serializeToUnknownWith(struct),
    Error(
      U.error({
        code: OperationFailed("User error"),
        operation: Serializing,
        path: S.Path.fromArray(["\"\'\`"]),
      }),
    ),
    (),
  )
})

test("Field name in a format of a path is handled properly", t => {
  let struct = S.object(s =>
    {
      "field": s.field(`["abc"]["cde"]`, S.string),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"bar": "foo"}`)->S.parseAnyWith(struct),
    Error(
      U.error({
        code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`undefined`)}),
        operation: Parsing,
        path: S.Path.fromArray([`["abc"]["cde"]`]),
      }),
    ),
    (),
  )
})
