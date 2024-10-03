open Ava

test("Literal schema", t => {
  t->U.assertEqualSchemas(S.schema(_ => 1), S.literal(1))
  t->U.assertEqualSchemas(S.schema(_ => ()), S.literal())
  t->U.assertEqualSchemas(S.schema(_ => "foo"), S.literal("foo"))
})

test("Object of literals schema", t => {
  t->U.assertEqualSchemas(
    S.schema(_ =>
      {
        "foo": "bar",
        "zoo": 123,
      }
    ),
    S.object(s =>
      {
        "foo": s.field("foo", S.literal("bar")),
        "zoo": s.field("zoo", S.literal(123)),
      }
    ),
  )
})

test("Tuple of literals schema", t => {
  t->U.assertEqualSchemas(
    S.schema(_ => (1, (), "bar")),
    S.tuple3(S.literal(1), S.literal(), S.literal("bar")),
  )
})

test("Object with embeded", t => {
  t->U.assertEqualSchemas(
    S.schema(s =>
      {
        "foo": "bar",
        "zoo": s.matches(S.int),
      }
    ),
    S.object(s =>
      {
        "foo": s.field("foo", S.literal("bar")),
        "zoo": s.field("zoo", S.int),
      }
    ),
  )
})

test("Tuple with embeded", t => {
  t->U.assertEqualSchemas(
    S.schema(s => (s.matches(S.string), (), "bar")),
    S.tuple3(S.string, S.literal(), S.literal("bar")),
  )
})

test("Nested embeded object", t => {
  t->U.assertEqualSchemas(
    S.schema(s =>
      {
        "nested": {
          "foo": "bar",
          "zoo": s.matches(S.int),
        },
      }
    ),
    S.object(s =>
      {
        "nested": s.field(
          "nested",
          S.object(
            s =>
              {
                "foo": s.field("foo", S.literal("bar")),
                "zoo": s.field("zoo", S.int),
              },
          ),
        ),
      }
    ),
  )
})

@unboxed
type answer =
  | Text(string)
  | MultiSelect(array<string>)
  | Other({value: string, @as("description") maybeDescription: option<string>})

test("Example", t => {
  t->U.assertEqualSchemas(
    S.schema(s => Text(s.matches(S.string))),
    S.string->S.to(string => Text(string)),
  )
  t->U.assertEqualSchemas(
    S.schema(s => MultiSelect(s.matches(S.array(S.string)))),
    S.array(S.string)->S.to(array => MultiSelect(array)),
  )
  t->U.assertEqualSchemas(
    S.schema(s => Other({
      value: s.matches(S.string),
      maybeDescription: s.matches(S.option(S.string)),
    })),
    S.object(s => Other({
      value: s.field("value", S.string),
      maybeDescription: s.field("description", S.option(S.string)),
    })),
  )
  t->U.assertEqualSchemas(
    S.schema(s => (#id, s.matches(S.string))),
    S.tuple(s => (s.item(0, S.literal(#id)), s.item(1, S.string))),
  )
})
