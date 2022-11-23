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
    o->S.discriminant("\"\'\`", S.literal(EmptyNull))
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
    o->S.discriminant("\"\'\`", S.literal(EmptyNull))
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
    o->S.discriminant("kind", S.literal(String("\"\'\`")))
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
      o->S.discriminant("kind", S.literal(String("\"\'\`")))
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

// TODO: Test path in error
