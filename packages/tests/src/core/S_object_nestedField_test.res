open Ava

test("Has correct tagged type with nestedField called multiple times", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.nestedField("nested", "bar", S.string),
      "baz": s.nestedField("nested", "baz", S.string),
      "baj": s.nestedField("nested", "baj", S.string),
    }
  )

  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s =>
      {
        "foo": s.field("foo", S.string),
        "nested": s.field(
          "nested",
          S.object(
            s =>
              {
                "bar": s.field("bar", S.string),
                "baz": s.field("baz", S.string),
                "baj": s.field("baj", S.string),
              },
          ),
        ),
      }
    ),
  )
})

test("Fails to create schema with nestedField called additinally to non-object field", t => {
  t->Assert.throws(
    () => {
      S.object(
        s =>
          {
            "foo": s.field("foo", S.string),
            "bar": s.field("nested", S.string),
            "baz": s.nestedField("nested", "baz", S.string),
          },
      )
    },
    ~expectations={
      message: `[rescript-schema] The field "nested" defined twice with incompatible schemas`,
    },
    (),
  )
  t->Assert.throws(
    () => {
      S.object(
        s =>
          {
            "foo": s.field("foo", S.string),
            "baz": s.nestedField("nested", "baz", S.string),
            "bar": s.field("nested", S.string),
          },
      )
    },
    ~expectations={
      message: `[rescript-schema] The field "nested" defined twice with incompatible schemas`,
    },
    (),
  )
})

test("Successfully parses with nestedField used multiple times", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.nestedField("nested", "bar", S.string),
      "baz": s.nestedField("nested", "baz", S.string),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"foo": "foo", "nested": {"bar": "bar", "baz": "baz"}}`)->S.parseAnyWith(schema),
    Ok({"foo": "foo", "bar": "bar", "baz": "baz"}),
    (),
  )
  t->U.assertCompiledCode(
    ~op=#Parse,
    ~schema,
    `i=>{if(!i||i.constructor!==Object){e[4](i)}let v0=i["foo"],v1=i["nested"];if(typeof v0!=="string"){e[0](v0)}if(!v1||v1.constructor!==Object){e[1](v1)}let v2=v1["bar"],v3=v1["baz"];if(typeof v2!=="string"){e[2](v2)}if(typeof v3!=="string"){e[3](v3)}return {"foo":v0,"bar":v2,"baz":v3}}`,
  )
})

test("Successfully serializes with nestedField used multiple times", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.nestedField("nested", "bar", S.string),
      "baz": s.nestedField("nested", "baz", S.string),
    }
  )

  t->Assert.deepEqual(
    {"foo": "foo", "bar": "bar", "baz": "baz"}->S.serializeWith(schema),
    Ok(%raw(`{"foo": "foo", "nested": {"bar": "bar", "baz": "baz"}}`)),
    (),
  )
  t->U.assertCompiledCode(
    ~op=#Serialize,
    ~schema,
    `i=>{return {"foo":i["foo"],"nested":{"bar":i["bar"],"baz":i["baz"]}}}`,
  )
})
