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

test("Fails to use nested inside of another nested", t => {
  t->Assert.throws(
    () => {
      S.object(
        s =>
          {
            "foo": s.field("foo", S.string),
            "nested": s.nested(
              "nested1",
              s =>
                {
                  "bar": s.nested("nested2", s => s.field("bar", S.string)),
                },
            ),
          },
      )
    },
    ~expectations={
      message: `[rescript-schema] Nested "nested2" inside of another nested "nested1" is not supported`,
    },
    (),
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
})
