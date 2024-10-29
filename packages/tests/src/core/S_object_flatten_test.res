open Ava

test("Has correct tagged type", t => {
  let schema = S.object(s =>
    {
      "bar": s.flatten(S.object(s => s.field("bar", S.string))),
      "foo": s.field("foo", S.string),
    }
  )

  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s =>
      {
        "bar": s.field("bar", S.string),
        "foo": s.field("foo", S.string),
      }
    ),
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["foo"];if(typeof v0!=="string"){e[0](v0)}let v1=i["bar"];if(typeof v1!=="string"){e[1](v1)}return {"bar":v1,"foo":v0,}}`,
  )
})

test("Can flatten S.schema", t => {
  let schema = S.object(s => {
    let flattened = s.flatten(S.schema(s => {"bar": s.matches(S.string)}))
    {
      "bar": flattened["bar"],
      "foo": s.field("foo", S.string),
    }
  })

  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s =>
      {
        "bar": s.field("bar", S.string),
        "foo": s.field("foo", S.string),
      }
    ),
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["foo"];if(typeof v0!=="string"){e[0](v0)}let v1=i["bar"];if(typeof v1!=="string"){e[1](v1)}return {"bar":v1,"foo":v0,}}`,
  )
})

Skip.test("Can flatten strict object", t => {
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

test("Can flatten renamed object schema", t => {
  let schema = S.object(s =>
    {
      "bar": s.flatten(S.object(s => s.field("bar", S.string))->S.setName("My Obj")),
      "foo": s.field("foo", S.string),
    }
  )

  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s =>
      {
        "bar": s.field("bar", S.string),
        "foo": s.field("foo", S.string),
      }
    ),
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["foo"];if(typeof v0!=="string"){e[0](v0)}let v1=i["bar"];if(typeof v1!=="string"){e[1](v1)}return {"bar":v1,"foo":v0,}}`,
  )
  t->Assert.is(schema->S.name, `Object({"bar": String, "foo": String})`, ())
})

test("Can flatten transformed object schema", t => {
  let schema = S.object(s =>
    {
      "bar": s.flatten(S.object(s => s.field("bar", S.string))->S.transform(_ => {parser: i => i})),
      "foo": s.field("foo", S.string),
    }
  )
  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s =>
      {
        "bar": s.field("bar", S.string),
        "foo": s.field("foo", S.string),
      }
    ),
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[3](i)}let v0=i["foo"];if(typeof v0!=="string"){e[0](v0)}let v1=i["bar"];if(typeof v1!=="string"){e[1](v1)}return {"bar":e[2](v1),"foo":v0,}}`,
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

Skip.test("Successfully serializes simple object with flatten", t => {
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

Skip.test("Can destructure flattened schema", t => {
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

  t->U.assertCompiledCode(
    ~op=#Parse,
    ~schema=entitySchema,
    `i=>{if(!i||i.constructor!==Object){e[3](i)}let v0=i["id"];if(typeof v0!=="string"){e[0](v0)}let v1=i["name"],v2=i["age"];if(typeof v1!=="string"){e[1](v1)}if(typeof v2!=="number"||v2>2147483647||v2<-2147483648||v2%1!==0){e[2](v2)}return {"id":v0,"name":v1,"age":v2,}}`,
  )

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
