open Ava

test(
  "Has correct tagged type with nested called multiple times and nested objects are not mutate",
  t => {
    let nested1 = S.object(s => s.field("baz", S.string))
    let nested3 = S.object(s => s.field("bar", S.string))
    let schema = S.object(s =>
      {
        "foo": s.field("foo", S.string),
        "baz": s.field("nested", nested1),
        "baj": s.field("nested", S.object(s => s.field("baj", S.string))),
        "bar": s.field("nested", nested3),
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
                  "baz": s.field("baz", S.string),
                  "baj": s.field("baj", S.string),
                  "bar": s.field("bar", S.string),
                },
            ),
          ),
        }
      ),
    )
    t->U.unsafeAssertEqualSchemas(nested1, S.object(s => s.field("baz", S.string)))
    t->U.unsafeAssertEqualSchemas(nested3, S.object(s => s.field("bar", S.string)))
  },
)

test("Fails to create schema with nested called additinally to non-object field", t => {
  t->Assert.throws(
    () => {
      S.object(
        s =>
          {
            "foo": s.field("foo", S.string),
            "bar": s.field("nested", S.string),
            "baz": s.field("nested", S.object(s => s.field("baz", S.string))),
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
            "baz": s.field("nested", S.object(s => s.field("baz", S.string))),
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

test("Successfully parses with nested object defined multiple times", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.field("nested", S.object(s => s.field("bar", S.string))),
      "baz": s.field("nested", S.object(s => s.field("baz", S.string))),
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

test("Successfully serializes with nested object defined multiple times", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.field("nested", S.object(s => s.field("bar", S.string))),
      "baz": s.field("nested", S.object(s => s.field("baz", S.string))),
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

test("Merges deeply nested in different branches", t => {
  let schema = S.object(s =>
    {
      "bar": s.field(
        "nested",
        S.object(s => s.field("nested2", S.object(s => s.field("bar", S.string)))),
      ),
      "baz": s.field(
        "nested",
        S.object(s => s.field("nested2", S.object(s => s.field("baz", S.string)))),
      ),
    }
  )

  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s =>
      {
        "nested": s.field(
          "nested",
          S.object(
            s =>
              s.field(
                "nested2",
                S.object(
                  s =>
                    {
                      "bar": s.field("bar", S.string),
                      "baz": s.field("baz", S.string),
                    },
                ),
              ),
          ),
        ),
      }
    ),
  )

  t->Assert.deepEqual(
    %raw(`{"nested": {"nested2": {"bar": "bar", "baz": "baz"}}}`)->S.parseAnyWith(schema),
    Ok({"bar": "bar", "baz": "baz"}),
    (),
  )
  t->U.assertCompiledCode(
    ~op=#Parse,
    ~schema,
    `i=>{if(!i||i.constructor!==Object){e[4](i)}let v0=i["nested"];if(!v0||v0.constructor!==Object){e[0](v0)}let v1=v0["nested2"];if(!v1||v1.constructor!==Object){e[1](v1)}let v2=v1["bar"],v3=v1["baz"];if(typeof v2!=="string"){e[2](v2)}if(typeof v3!=="string"){e[3](v3)}return {"bar":v2,"baz":v3}}`,
  )

  t->Assert.deepEqual(
    {"bar": "bar", "baz": "baz"}->S.serializeWith(schema),
    Ok(%raw(`{"nested": {"nested2": {"bar": "bar", "baz": "baz"}}}`)),
    (),
  )
  t->U.assertCompiledCode(
    ~op=#Serialize,
    ~schema,
    `i=>{return {"nested":{"nested2":{"bar":i["bar"],"baz":i["baz"]}}}}`,
  )
})
