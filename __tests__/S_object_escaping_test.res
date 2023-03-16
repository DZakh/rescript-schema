open Ava

test("Successfully parses object with quotes in a field name", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("\"\'\`", S.string()),
    }
  )

  t->Assert.deepEqual(%raw(`{"\"\'\`": "bar"}`)->S.parseWith(struct), Ok({"field": "bar"}), ())
})

test("Successfully serializing object with quotes in a field name", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("\"\'\`", S.string()),
    }
  )

  t->Assert.deepEqual({"field": "bar"}->S.serializeWith(struct), Ok(%raw(`{"\"\'\`": "bar"}`)), ())
})

test("Successfully parses object transformed to object with quotes in a field name", t => {
  let struct = S.object(o =>
    {
      "\"\'\`": o->S.field("field", S.string()),
    }
  )

  t->Assert.deepEqual(%raw(`{"field": "bar"}`)->S.parseWith(struct), Ok({"\"\'\`": "bar"}), ())
})

test("Successfully serializes object transformed to object with quotes in a field name", t => {
  let struct = S.object(o =>
    {
      "\"\'\`": o->S.field("field", S.string()),
    }
  )

  t->Assert.deepEqual({"\"\'\`": "bar"}->S.serializeWith(struct), Ok(%raw(`{"field": "bar"}`)), ())
})

test("Successfully parses object with discriminant which has quotes as the field name", t => {
  let struct = S.object(o => {
    ignore(o->S.field("\"\'\`", S.literal(EmptyNull)))
    {
      "field": o->S.field("field", S.string()),
    }
  })

  t->Assert.deepEqual(
    %raw(`{
      "\"\'\`": null,
      "field": "bar",
    }`)->S.parseWith(struct),
    Ok({"field": "bar"}),
    (),
  )
})

test("Successfully serializes object with discriminant which has quotes as the field name", t => {
  let struct = S.object(o => {
    ignore(o->S.field("\"\'\`", S.literal(EmptyNull)))
    {
      "field": o->S.field("field", S.string()),
    }
  })

  t->Assert.deepEqual(
    {"field": "bar"}->S.serializeWith(struct),
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
  let struct = S.object(o => {
    ignore(o->S.field("kind", S.literal(String("\"\'\`"))))
    {
      "field": o->S.field("field", S.string()),
    }
  })

  t->Assert.deepEqual(
    %raw(`{
      "kind": "\"\'\`",
      "field": "bar",
    }`)->S.parseWith(struct),
    Ok({"field": "bar"}),
    (),
  )
})

test(
  "Successfully serializes object with discriminant which has quotes as the literal value",
  t => {
    let struct = S.object(o => {
      ignore(o->S.field("kind", S.literal(String("\"\'\`"))))
      {
        "field": o->S.field("field", S.string()),
      }
    })

    t->Assert.deepEqual(
      {"field": "bar"}->S.serializeWith(struct),
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
    let struct = S.object(o =>
      {
        "\"\'\`": "hardcoded",
        "field": o->S.field("field", S.string()),
      }
    )

    t->Assert.deepEqual(
      %raw(`{"field": "bar"}`)->S.parseWith(struct),
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
    let struct = S.object(o =>
      {
        "\"\'\`": "hardcoded",
        "field": o->S.field("field", S.string()),
      }
    )

    t->Assert.deepEqual(
      {
        "\"\'\`": "hardcoded",
        "field": "bar",
      }->S.serializeWith(struct),
      Ok(%raw(`{"field": "bar"}`)),
      (),
    )
  },
)

test(
  "Successfully parses object transformed to object with quotes in value of hardcoded field",
  t => {
    let struct = S.object(o =>
      {
        "hardcoded": "\"\'\`",
        "field": o->S.field("field", S.string()),
      }
    )

    t->Assert.deepEqual(
      %raw(`{"field": "bar"}`)->S.parseWith(struct),
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
    let struct = S.object(o =>
      {
        "hardcoded": "\"\'\`",
        "field": o->S.field("field", S.string()),
      }
    )

    t->Assert.deepEqual(
      {
        "hardcoded": "\"\'\`",
        "field": "bar",
      }->S.serializeWith(struct),
      Ok(%raw(`{"field": "bar"}`)),
      (),
    )
  },
)

test("Has proper error path when fails to parse object with quotes in a field name", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field(
        "\"\'\`",
        S.string()->S.refine(~parser=_ => S.Error.raise("User error"), ()),
      ),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"\"\'\`": "bar"}`)->S.parseWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: S.Path.fromArray(["\"\'\`"]),
    }),
    (),
  )
})

test("Has proper error path when fails to serialize object with quotes in a field name", t => {
  let struct = S.object(o =>
    Js.Dict.fromArray([
      (
        "\"\'\`",
        o->S.field("field", S.string()->S.refine(~serializer=_ => S.Error.raise("User error"), ())),
      ),
    ])
  )

  t->Assert.deepEqual(
    Js.Dict.fromArray([("\"\'\`", "bar")])->S.serializeWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: S.Path.fromArray(["\"\'\`"]),
    }),
    (),
  )
})

test("Field name in a format of a path is handled properly", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field(`["abc"]["cde"]`, S.string()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"bar": "foo"}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "String", received: "Option"}),
      operation: Parsing,
      path: S.Path.fromArray([`["abc"]["cde"]`]),
    }),
    (),
  )
})
