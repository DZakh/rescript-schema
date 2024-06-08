open Ava

test("Has correct tagged type", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.nested("nested", s => s.field("bar", S.string)),
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
              },
          ),
        ),
      }
    ),
  )
})

test("Has correct tagged type with nested called multiple times", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.nested("nested", s => s.field("bar", S.string)),
      "baz": s.nested("nested", s => s.field("baz", S.string)),
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
                "bar": s.field("baz", S.string),
              },
          ),
        ),
      }
    ),
  )
})

test("Has correct tagged type with nested called additianally to object field", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.field("nested", S.object(s => s.field("bar", S.string))),
      "baz": s.nested("nested", s => s.field("baz", S.string)),
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
                "bar": s.field("baz", S.string),
              },
          ),
        ),
      }
    ),
  )
})

test("Fails to create schema with nested called before object field", t => {
  t->Assert.throws(
    () => {
      S.object(
        s =>
          {
            "foo": s.field("foo", S.string),
            "baz": s.nested("nested", s => s.field("baz", S.string)),
            "bar": s.field("nested", S.object(s => s.field("bar", S.string))),
          },
      )
    },
    ~expectations={
      message: `[rescript-schema] The field "nested" is defined multiple times. If you want to duplicate the field, use S.transform instead`,
    },
    (),
  )
})

test("Fails to create schema with nested called additinally to non-object field", t => {
  t->Assert.throws(
    () => {
      S.object(
        s =>
          {
            "foo": s.field("foo", S.string),
            "bar": s.field("nested", S.string),
            "baz": s.nested("nested", s => s.field("baz", S.string)),
          },
      )
    },
    ~expectations={
      message: `[rescript-schema] Failed to define nested "nested" field since it\'s already defined as non-object`,
    },
    (),
  )
})

test("Has correct tagged type with nested inside another nested", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "nested": s.nested(
        "nested1",
        s =>
          {
            "bar": s.nested("nested2", s => s.field("bar", S.string)),
          },
      ),
    }
  )

  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s =>
      {
        "foo": s.field("foo", S.string),
        "nested": s.field(
          "nested1",
          S.object(
            s =>
              {
                "nested2": s.field(
                  "nested2",
                  S.object(
                    s =>
                      {
                        "bar": s.field("bar", S.string),
                      },
                  ),
                ),
              },
          ),
        ),
      }
    ),
  )
})

test("Successfully parses simple schema with nested", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.nested("nested", s => s.field("bar", S.string)),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"foo": "foo", "nested": {"bar": "bar"}}`)->S.parseAnyWith(schema),
    Ok({"foo": "foo", "bar": "bar"}),
    (),
  )
  t->U.assertCompiledCode(
    ~op=#parse,
    ~schema,
    `i=>{if(!i||i.constructor!==Object){e[3](i)}let v0=i["foo"],v1=i["nested"];if(typeof v0!=="string"){e[0](v0)}if(!v1||v1.constructor!==Object){e[1](v1)}let v2=v1["bar"];if(typeof v2!=="string"){e[2](v2)}return {"foo":v0,"bar":v2,}}`,
  )
})

test("Successfully parses schema with nested called multiple times", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.nested("nested", s => s.field("bar", S.string)),
      "baz": s.nested("nested", s => s.field("baz", S.string)),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"foo": "foo", "nested": {"bar": "bar", "baz": "baz"}}`)->S.parseAnyWith(schema),
    Ok({"foo": "foo", "bar": "bar", "baz": "baz"}),
    (),
  )
  t->U.assertCompiledCode(
    ~op=#parse,
    ~schema,
    `i=>{if(!i||i.constructor!==Object){e[4](i)}let v0=i["foo"],v1=i["nested"];if(typeof v0!=="string"){e[0](v0)}if(!v1||v1.constructor!==Object){e[1](v1)}let v2=v1["bar"],v3=v1["baz"];if(typeof v2!=="string"){e[2](v2)}if(typeof v3!=="string"){e[3](v3)}return {"foo":v0,"bar":v2,"baz":v3,}}`,
  )
})

test("Successfully parses schema with nested inside another nested", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.nested("nested1", s => s.nested("nested2", s => s.field("bar", S.string))),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"foo": "foo", "nested1": {"nested2": {"bar":"bar"}}}`)->S.parseAnyWith(schema),
    Ok({"foo": "foo", "bar": "bar"}),
    (),
  )
  t->U.assertCompiledCode(
    ~op=#parse,
    ~schema,
    `i=>{if(!i||i.constructor!==Object){e[4](i)}let v0=i["foo"],v1=i["nested1"];if(typeof v0!=="string"){e[0](v0)}if(!v1||v1.constructor!==Object){e[1](v1)}let v2=v1["nested2"];if(!v2||v2.constructor!==Object){e[2](v2)}let v3=v2["bar"];if(typeof v3!=="string"){e[3](v3)}return {"foo":v0,"bar":v3,}}`,
  )
})

test("Fails to parse nested which is not an object", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.nested("nested", s => s.field("bar", S.string)),
    }
  )

  t->U.assertErrorResult(
    %raw(`{"foo": "foo", "nested": "string"}`)->S.parseAnyWith(schema),
    {
      code: InvalidType({
        expected: S.object(s =>
          {
            "bar": s.field("bar", S.string),
          }
        )->S.toUnknown,
        received: %raw(`"string"`),
      }),
      operation: Parsing,
      path: S.Path.fromLocation("nested"),
    },
  )
})

test("Fails to parse nested field", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.nested("nested", s => s.field("bar", S.string)),
    }
  )

  t->U.assertErrorResult(
    %raw(`{"foo": "foo", "nested": {"bar": 123}}`)->S.parseAnyWith(schema),
    {
      code: InvalidType({
        expected: S.string->S.toUnknown,
        received: %raw(`123`),
      }),
      operation: Parsing,
      path: S.Path.fromArray(["nested", "bar"]),
    },
  )
})
