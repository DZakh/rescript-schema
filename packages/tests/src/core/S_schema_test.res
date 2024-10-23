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
    schema->U.getCompiledCodeString(~op=#ReverseConvert),
    `i=>{let v0=i["foo"];if(v0!=="bar"){e[0](v0)}return i}`,
    (),
  )
  t->Assert.is(
    objectSchema->U.getCompiledCodeString(~op=#ReverseConvert),
    `i=>{return {"foo":i["foo"],"zoo":i["zoo"],}}`, // FIXME: Validate literals for S.object schemas
    (),
  )
})

test("Strict object with embeded returns input without object recreation", t => {
  S.setGlobalConfig({
    defaultUnknownKeys: Strict,
  })
  let schema = S.schema(s =>
    {
      "foo": "bar",
      "zoo": s.matches(S.int),
    }
  )
  S.setGlobalConfig({})

  t->Assert.is(
    schema->U.getCompiledCodeString(~op=#Parse),
    `i=>{if(!i||i.constructor!==Object){e[3](i)}let v0=i["foo"],v1=i["zoo"],v2;if(v0!=="bar"){e[0](v0)}if(typeof v1!=="number"||v1>2147483647||v1<-2147483648||v1%1!==0){e[1](v1)}for(v2 in i){if(v2!=="foo"&&v2!=="zoo"){e[2](v2)}}return i}`,
    (),
  )
  t->Assert.is(
    schema->U.getCompiledCodeString(~op=#ReverseConvert),
    `i=>{let v0=i["foo"];if(v0!=="bar"){e[0](v0)}return i}`,
    (),
  )
})

test("Tuple with embeded", t => {
  let schema = S.schema(s => (s.matches(S.string), (), "bar"))
  let tupleSchema = S.tuple(s => (
    s.item(0, S.string),
    s.item(1, S.literal()),
    s.item(2, S.literal("bar")),
  ))

  t->U.assertEqualSchemas(schema, tupleSchema)
  // S.schema does return i without tuple recreation
  t->Assert.is(
    schema->U.getCompiledCodeString(~op=#Parse),
    `i=>{if(!Array.isArray(i)||i.length!==3){e[3](i)}let v0=i["0"],v1=i["1"],v2=i["2"];if(v2!=="bar"){e[2](v2)}if(v1!==undefined){e[1](v1)}if(typeof v0!=="string"){e[0](v0)}return i}`,
    (),
  )
  t->Assert.is(
    tupleSchema->U.getCompiledCodeString(~op=#Parse),
    `i=>{if(!Array.isArray(i)||i.length!==3){e[3](i)}let v0=i["0"],v1=i["1"],v2=i["2"];if(v2!=="bar"){e[2](v2)}if(v1!==undefined){e[1](v1)}if(typeof v0!=="string"){e[0](v0)}return [v0,v1,v2,]}`,
    (),
  )
  t->Assert.is(
    schema->U.getCompiledCodeString(~op=#ReverseConvert),
    `i=>{let v0=i["1"],v1=i["2"];if(v1!=="bar"){e[1](v1)}if(v0!==undefined){e[0](v0)}return i}`,
    (),
  )
  t->Assert.is(
    tupleSchema->U.getCompiledCodeString(~op=#ReverseConvert),
    `i=>{return [i["0"],i["1"],i["2"],]}`, // FIXME: validate literals for S.tuple schemas
    (),
  )
})

test("Nested embeded object", t => {
  let schema = S.schema(s =>
    {
      "nested": {
        "foo": "bar",
        "zoo": s.matches(S.int),
      },
    }
  )
  let objectSchema = S.object(s =>
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
  )
  t->U.assertEqualSchemas(schema, objectSchema)

  t->Assert.is(
    schema->U.getCompiledCodeString(~op=#Parse),
    objectSchema->U.getCompiledCodeString(~op=#Parse),
    (),
  )
  t->Assert.is(
    schema->U.getCompiledCodeString(~op=#ReverseConvert),
    `i=>{let v0=i["nested"];let v1=v0["foo"];if(v1!=="bar"){e[0](v1)}return i}`,
    (),
  )
  t->Assert.is(
    objectSchema->U.getCompiledCodeString(~op=#ReverseConvert),
    `i=>{return {"nested":{"foo":i["nested"]["foo"],"zoo":i["nested"]["zoo"],},}}`, // FIXME: validate literals for S.tuple schemas
    (),
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
