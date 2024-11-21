open Ava

test("Object with a single nested field", t => {
  let schema = S.object(s => s.nested("nested").field("foo", S.string))

  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s => s.field("nested", S.object(s => s.field("foo", S.string)))),
  )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["nested"];if(!v0||v0.constructor!==Object){e[0](v0)}let v1=v0["foo"];if(typeof v1!=="string"){e[1](v1)}return v1}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0={"foo":i,};return {"nested":v0,}}`,
  )
})

test("Object with a nested tag and optional field", t => {
  let schema = S.object(s => {
    s.nested("nested").tag("tag", "value")
    {
      "foo": s.nested("nested").fieldOr("foo", S.string, ""),
      "bar": s.field("bar", S.string),
    }
  })

  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s => {
      let _ = s.field(
        "nested",
        S.object(
          s => {
            s.tag("tag", "value")
            let _ = s.fieldOr("foo", S.string, "")
          },
        ),
      )
      let _ = s.field("bar", S.string)
    }),
  )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[5](i)}let v0=i["nested"],v3=i["bar"];if(!v0||v0.constructor!==Object){e[0](v0)}if(typeof v3!=="string"){e[4](v3)}let v1=v0["tag"],v2=v0["foo"];if(v1!=="value"){e[1](v1)}if(v2!==void 0&&(typeof v2!=="string")){e[2](v2)}return {"foo":v2===void 0?e[3]:v2,"bar":v3,}}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    // FIXME: why default value is passed here?
    `i=>{let v0=i["foo"],v1={"tag":e[1],"foo":v0===void 0?e[0]:v0,};let v2=v1["foo"];return {"nested":v1,"bar":i["bar"],}}`,
  )
})

test("Object with a two nested field using the same ctx", t => {
  let schema = S.object(s => {
    let nested = s.nested("nested")
    {
      "foo": nested.field("foo", S.string),
      "bar": nested.field("bar", S.string),
    }
  })

  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s =>
      s.field(
        "nested",
        S.object(
          s =>
            {
              "foo": s.field("foo", S.string),
              "bar": s.field("bar", S.string),
            },
        ),
      )
    ),
  )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[3](i)}let v0=i["nested"];if(!v0||v0.constructor!==Object){e[0](v0)}let v1=v0["foo"],v2=v0["bar"];if(typeof v1!=="string"){e[1](v1)}if(typeof v2!=="string"){e[2](v2)}return {"foo":v1,"bar":v2,}}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0={"foo":i["foo"],"bar":i["bar"],};return {"nested":v0,}}`,
  )
})

test("Object with a single nested nested field", t => {
  let schema = S.object(s => s.nested("nested").nested("deeply").field("foo", S.string))

  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s =>
      s.field("nested", S.object(s => s.field("deeply", S.object(s => s.field("foo", S.string)))))
    ),
  )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[3](i)}let v0=i["nested"];if(!v0||v0.constructor!==Object){e[0](v0)}let v1=v0["deeply"];if(!v1||v1.constructor!==Object){e[1](v1)}let v2=v1["foo"];if(typeof v2!=="string"){e[2](v2)}return v2}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0={"foo":i,},v1={"deeply":v0,};let v2=v1["deeply"];return {"nested":v1,}}`,
  )
})

test("Object with a two nested field calling s.nested twice", t => {
  let schema = S.object(s => {
    {
      "foo": s.nested("nested").field("foo", S.string),
      "bar": s.nested("nested").field("bar", S.string),
    }
  })

  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s =>
      s.field(
        "nested",
        S.object(
          s =>
            {
              "foo": s.field("foo", S.string),
              "bar": s.field("bar", S.string),
            },
        ),
      )
    ),
  )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[3](i)}let v0=i["nested"];if(!v0||v0.constructor!==Object){e[0](v0)}let v1=v0["foo"],v2=v0["bar"];if(typeof v1!=="string"){e[1](v1)}if(typeof v2!=="string"){e[2](v2)}return {"foo":v1,"bar":v2,}}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0={"foo":i["foo"],"bar":i["bar"],};return {"nested":v0,}}`,
  )
})

Skip.test(
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

Skip.test("Fails to create schema with nested called additinally to non-object field", t => {
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

Skip.test("Successfully parses with nested object defined multiple times", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.field("nested", S.object(s => s.field("bar", S.string))),
      "baz": s.field("nested", S.object(s => s.field("baz", S.string))),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"foo": "foo", "nested": {"bar": "bar", "baz": "baz"}}`)->S.parseOrThrow(schema),
    {"foo": "foo", "bar": "bar", "baz": "baz"},
    (),
  )
  t->U.assertCompiledCode(
    ~op=#Parse,
    ~schema,
    `i=>{if(!i||i.constructor!==Object){e[4](i)}let v0=i["foo"],v1=i["nested"];if(typeof v0!=="string"){e[0](v0)}if(!v1||v1.constructor!==Object){e[1](v1)}let v2=v1["bar"],v3=v1["baz"];if(typeof v2!=="string"){e[2](v2)}if(typeof v3!=="string"){e[3](v3)}return {"foo":v0,"bar":v2,"baz":v3,}}`,
  )
})

Skip.test("Successfully serializes with nested object defined multiple times", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.field("nested", S.object(s => s.field("bar", S.string))),
      "baz": s.field("nested", S.object(s => s.field("baz", S.string))),
    }
  )

  t->Assert.deepEqual(
    {"foo": "foo", "bar": "bar", "baz": "baz"}->S.reverseConvertToJsonOrThrow(schema),
    %raw(`{"foo": "foo", "nested": {"bar": "bar", "baz": "baz"}}`),
    (),
  )
  t->U.assertCompiledCode(
    ~op=#ReverseConvert,
    ~schema,
    `i=>{return {"foo":i["foo"],"nested":{"bar":i["bar"],"baz":i["baz"],},}}`,
  )
})

Skip.test("Merges deeply nested in different branches", t => {
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
    %raw(`{"nested": {"nested2": {"bar": "bar", "baz": "baz"}}}`)->S.parseOrThrow(schema),
    {"bar": "bar", "baz": "baz"},
    (),
  )
  t->U.assertCompiledCode(
    ~op=#Parse,
    ~schema,
    `i=>{if(!i||i.constructor!==Object){e[4](i)}let v0=i["nested"];if(!v0||v0.constructor!==Object){e[0](v0)}let v1=v0["nested2"];if(!v1||v1.constructor!==Object){e[1](v1)}let v2=v1["bar"],v3=v1["baz"];if(typeof v2!=="string"){e[2](v2)}if(typeof v3!=="string"){e[3](v3)}return {"bar":v2,"baz":v3,}}`,
  )

  t->Assert.deepEqual(
    {"bar": "bar", "baz": "baz"}->S.reverseConvertToJsonOrThrow(schema),
    %raw(`{"nested": {"nested2": {"bar": "bar", "baz": "baz"}}}`),
    (),
  )
  t->U.assertCompiledCode(
    ~op=#ReverseConvert,
    ~schema,
    `i=>{return {"nested":{"nested2":{"bar":i["bar"],"baz":i["baz"],},},}}`,
  )
})
