open Ava

test("Has correct tagged type", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.flatten(S.object(s => s.field("bar", S.string))),
    }
  )

  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s =>
      {
        "foo": s.field("foo", S.string),
        "bar": s.field("bar", S.string),
      }
    ),
  )
})

test("Can flatten S.schema", t => {
  t->Assert.throws(
    () => {
      S.object(
        s =>
          {
            "foo": s.field("foo", S.string),
            "bar": s.flatten(S.schema(s => {"baz": s.matches(S.string)})),
          },
      )
    },
    ~expectations={
      // FIXME: This is a regression of v8.4.0
      message: `[rescript-schema] The Object({"baz": String}) schema can\'t be flattened`,
    },
    (),
  )

  // t->U.unsafeAssertEqualSchemas(
  //   schema,
  //   S.object(s =>
  //     {
  //       "foo": s.field("foo", S.string),
  //       "bar": s.field("bar", S.string),
  //     }
  //   ),
  // )
})

test("Can flatten strict object", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.flatten(S.object(s => s.field("bar", S.string))->S.Object.strict),
    }
  )

  t->Assert.deepEqual(
    switch schema->S.classify {
    | Object({unknownKeys}) => unknownKeys
    | _ => assert(false)
    },
    S.Strip,
    (),
  )
})

test("Fails to flatten renamed object schema", t => {
  t->Assert.throws(
    () => {
      S.object(
        s =>
          {
            "foo": s.field("foo", S.string),
            "bar": s.flatten(S.object(s => s.field("bar", S.string))->S.setName("My Obj")),
          },
      )
    },
    ~expectations={
      message: `[rescript-schema] The My Obj schema can\'t be flattened`,
    },
    (),
  )
})

test("Fails to flatten transformed object schema", t => {
  t->Assert.throws(
    () => {
      S.object(
        s =>
          {
            "foo": s.field("foo", S.string),
            "bar": s.flatten(
              S.object(s => s.field("bar", S.string))->S.transform(_ => {parser: i => i}),
            ),
          },
      )
    },
    ~expectations={
      message: `[rescript-schema] The Object({"bar": String}) schema can\'t be flattened`,
    },
    (),
  )
})

test("Fails to flatten non-object schema", t => {
  t->Assert.throws(
    () => {
      S.object(
        s =>
          {
            "foo": s.field("foo", S.string),
            "bar": s.flatten(S.string),
          },
      )
    },
    ~expectations={
      message: `[rescript-schema] The String schema can\'t be flattened`,
    },
    (),
  )
})

test("Successfully parses simple object with flatten", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.flatten(S.object(s => s.field("bar", S.string))),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"foo": "foo", "bar": "bar"}`)->S.parseOrThrow(schema),
    {"foo": "foo", "bar": "bar"},
    (),
  )
  t->U.assertCompiledCode(
    ~op=#Parse,
    ~schema,
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["foo"],v1=i["bar"];if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="string"){e[1](v1)}return {"foo":v0,"bar":v1,}}`,
  )
})

test("Successfully serializes simple object with flatten", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.flatten(S.object(s => s.field("bar", S.string))),
    }
  )

  t->Assert.deepEqual(
    {"foo": "foo", "bar": "bar"}->S.reverseConvertToJsonOrThrow(schema),
    %raw(`{"foo": "foo", "bar": "bar"}`),
    (),
  )
  t->U.assertCompiledCode(
    ~op=#ReverseConvert,
    ~schema,
    `i=>{return {"foo":i["foo"],"bar":i["bar"],}}`,
  )
})

type entityData = {
  name: string,
  age: int,
}
type entity = {
  id: string,
  ...entityData,
}

test("Can destructure flattened schema", t => {
  let entityDataSchema = S.object(s => {
    name: s.field("name", S.string),
    age: s.field("age", S.int),
  })
  let entitySchema = S.object(s => {
    let {name, age} = s.flatten(entityDataSchema)
    {
      id: s.field("id", S.string),
      name,
      age,
    }
  })

  t->Assert.deepEqual(
    {id: "1", name: "Dmitry", age: 23}->S.reverseConvertToJsonOrThrow(entitySchema),
    %raw(`{id: "1", name: "Dmitry", age: 23}`),
    (),
  )
  t->U.assertCompiledCode(
    ~op=#ReverseConvert,
    ~schema=entitySchema,
    `i=>{return {"name":i["name"],"age":i["age"],"id":i["id"],}}`,
  )
})
