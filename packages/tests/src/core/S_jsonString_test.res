open Ava
open RescriptCore

test("Successfully parses JSON", t => {
  let schema = S.string

  t->Assert.deepEqual(`"Foo"`->S.parseAnyWith(S.jsonString(schema)), Ok("Foo"), ())
})

test("Successfully serializes JSON", t => {
  let schema = S.string

  t->Assert.deepEqual(
    `Foo`->S.serializeToUnknownWith(S.jsonString(schema)),
    Ok(%raw(`'"Foo"'`)),
    (),
  )
})

test("Successfully serializes JSON object", t => {
  let schema = S.schema(_ =>
    {
      "foo": "bar",
      "baz": [1, 3],
    }
  )

  t->Assert.deepEqual(
    {
      "foo": "bar",
      "baz": [1, 3],
    }->S.serializeToUnknownWith(S.jsonString(schema)),
    Ok(%raw(`'{"foo":"bar","baz":[1,3]}'`)),
    (),
  )
})

test("Successfully serializes JSON object with space", t => {
  let schema = S.schema(_ =>
    {
      "foo": "bar",
      "baz": [1, 3],
    }
  )

  t->Assert.deepEqual(
    {
      "foo": "bar",
      "baz": [1, 3],
    }->S.serializeToUnknownWith(S.jsonString(schema, ~space=2)),
    Ok(%raw(`'{\n  "foo": "bar",\n  "baz": [\n    1,\n    3\n  ]\n}'`)),
    (),
  )
})

test("Fails to create schema when passing non-jsonable schema to S.jsonString", t => {
  t->Assert.throws(
    () => {
      S.jsonString(S.object(s => s.field("foo", S.unknown)))
    },
    ~expectations={
      message: `[rescript-schema] The schema Object({"foo": Unknown}) passed to S.jsonString is not compatible with JSON`,
    },
    (),
  )
})

test("Compiled parse code snapshot", t => {
  let schema = S.jsonString(S.bool)

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{if(typeof i!=="string"){e[2](i)}let v0;try{v0=JSON.parse(i)}catch(t){e[0](t.message)}if(typeof v0!=="boolean"){e[1](v0)}return v0}`,
  )
})

test("Compiled async parse code snapshot", t => {
  let schema = S.jsonString(S.bool->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{if(typeof i!=="string"){e[3](i)}let v0,v1;try{v0=JSON.parse(i)}catch(t){e[0](t.message)}if(typeof v0!=="boolean"){e[1](v0)}v1=e[2](v0);return v1}`,
  )
})

test("Compiled serialize code snapshot", t => {
  let schema = S.jsonString(S.bool)

  t->U.assertCompiledCode(~schema, ~op=#serialize, `i=>{return JSON.stringify(i)}`)
})

test("Compiled serialize code snapshot with space", t => {
  let schema = S.jsonString(S.bool, ~space=2)

  t->U.assertCompiledCode(~schema, ~op=#serialize, `i=>{return JSON.stringify(i,null,2)}`)
})
