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

test("Fails to serialize Option schema", t => {
  let schema = S.jsonString(S.option(S.bool))
  t->U.assertErrorResult(
    None->S.serializeToUnknownWith(schema),
    {
      code: InvalidJsonStruct(S.option(S.bool)->S.toUnknown),
      operation: Serializing,
      path: S.Path.empty,
    },
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

test(
  "Create schema when passing non-jsonable schema to S.jsonString, but fails to serialize",
  t => {
    let schema = S.jsonString(S.object(s => s.field("foo", S.unknown)))

    t->U.assertErrorResult(
      %raw(`"foo"`)->S.serializeToUnknownWith(S.jsonString(schema, ~space=2)),
      {
        code: InvalidJsonStruct(S.unknown),
        operation: Serializing,
        path: S.Path.empty,
      },
    )
  },
)

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
    `i=>{if(typeof i!=="string"){e[3](i)}let v0;try{v0=JSON.parse(i)}catch(t){e[0](t.message)}if(typeof v0!=="boolean"){e[1](v0)}return e[2](v0)}`,
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
