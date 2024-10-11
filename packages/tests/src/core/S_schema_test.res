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
  let schema = S.schema(s =>
    {
      "foo": "bar",
      "zoo": s.matches(S.int),
    }
  )
  let objectSchema = S.object(s =>
    {
      "foo": s.field("foo", S.literal("bar")),
      "zoo": s.field("zoo", S.int),
    }
  )
  t->U.assertEqualSchemas(schema, objectSchema)
  t->Assert.is(
    schema->U.getCompiledCodeString(~op=#Parse),
    objectSchema->U.getCompiledCodeString(~op=#Parse),
    (),
  )
  t->Assert.is(
    schema->U.getCompiledCodeString(~op=#Serialize),
    `i=>{let v0=i["foo"];if(v0!=="bar"){e[0](v0)}return {"foo":v0,"zoo":i["zoo"]}}`,
    (),
  )
  t->Assert.is(
    objectSchema->U.getCompiledCodeString(~op=#Serialize),
    `i=>{return {"foo":i["foo"],"zoo":i["zoo"]}}`, // FIXME: Validate literals for S.object schemas
    (),
  )
})

test("Tuple with embeded", t => {
  let schema = S.schema(s => (s.matches(S.string), (), "bar"))
  let tupleSchema = S.tuple3(S.string, S.literal(), S.literal("bar"))

  t->U.assertEqualSchemas(schema, tupleSchema)
  t->Assert.is(
    schema->U.getCompiledCodeString(~op=#Parse),
    tupleSchema->U.getCompiledCodeString(~op=#Parse),
    (),
  )
  t->Assert.is(
    schema->U.getCompiledCodeString(~op=#Serialize),
    `i=>{let v0=i["1"],v1=i["2"];if(v1!=="bar"){e[1](v1)}if(v0!==undefined){e[0](v0)}return [i["0"],v0,v1]}`,
    (),
  )
  t->Assert.is(
    tupleSchema->U.getCompiledCodeString(~op=#Serialize),
    `i=>{return [i["0"],i["1"],i["2"]]}`, // FIXME: validate literals for S.tuple schemas
    (),
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
