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
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v1=i["foo"];let v0=i["bar"];if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="string"){e[1](v1)}return {"bar":v0,"foo":v1,}}`,
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
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v1=i["foo"];let v0=i["bar"];if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="string"){e[1](v1)}return {"bar":v0,"foo":v1,}}`,
  )
})

test("Can flatten strict object", t => {
  let schema = S.object(s =>
    {
      "bar": s.flatten(S.object(s => s.field("bar", S.string))->S.Object.strict),
      "foo": s.field("foo", S.string),
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
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v1=i["foo"];let v0=i["bar"];if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="string"){e[1](v1)}return {"bar":v0,"foo":v1,}}`,
  )
})

// FIXME: Should work
test("Flatten schema with duplicated field of the same type (flatten first)", t => {
  t->Assert.throws(
    () => {
      S.object(
        s =>
          {
            "bar": s.flatten(S.object(s => s.field("foo", S.string))),
            "foo": s.field("foo", S.string),
          },
      )
    },
    ~expectations={
      message: `[rescript-schema] The field "foo" defined twice with incompatible schemas`,
    },
    (),
  )
})

test("Flatten schema with duplicated field of the same type (flatten last)", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.flatten(S.object(s => s.field("foo", S.string))),
    }
  )

  t->U.unsafeAssertEqualSchemas(
    schema,
    S.object(s =>
      {
        "foo": s.field("foo", S.string),
      }
    ),
  )
  // FIXME: Can be improved
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["foo"];if(typeof v0!=="string"){e[0](v0)}let v1=i["foo"];if(typeof v1!=="string"){e[1](v1)}return {"foo":v0,"bar":v1,}}`,
  )
  // FIXME: Should validate that the fields are equal
  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{return {"foo":i["foo"],"foo":i["bar"],}}`,
  )
})

test("Flatten schema with duplicated field of different type", t => {
  t->Assert.throws(
    () => {
      S.object(
        s =>
          {
            "bar": s.flatten(S.object(s => s.field("foo", S.string))),
            "foo": s.field("foo", S.string->S.email),
          },
      )
    },
    ~expectations={
      message: `[rescript-schema] The field "foo" defined twice with incompatible schemas`,
    },
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
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v1=i["foo"];let v0=i["bar"];if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="string"){e[1](v1)}return {"bar":v0,"foo":v1,}}`,
  )
  t->Assert.is(schema->S.name, `{ bar: string; foo: string; }`, ())
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
    `i=>{if(!i||i.constructor!==Object){e[3](i)}let v1=i["foo"];let v0=i["bar"];if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="string"){e[2](v1)}return {"bar":e[1](v0),"foo":v1,}}`,
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
      message: `[rescript-schema] The 'string' schema can\'t be flattened`,
    },
    (),
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
    {"foo": "foo", "bar": "bar"}->S.reverseConvertOrThrow(schema),
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

  t->U.assertCompiledCode(
    ~op=#Parse,
    ~schema=entitySchema,
    `i=>{if(!i||i.constructor!==Object){e[3](i)}let v2=i["id"];let v0=i["name"],v1=i["age"];if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="number"||v1>2147483647||v1<-2147483648||v1%1!==0){e[1](v1)}if(typeof v2!=="string"){e[2](v2)}return {"id":v2,"name":v0,"age":v1,}}`,
  )

  t->Assert.deepEqual(
    {id: "1", name: "Dmitry", age: 23}->S.reverseConvertToJsonOrThrow(entitySchema),
    %raw(`{id: "1", name: "Dmitry", age: 23}`),
    (),
  )
  t->U.assertCompiledCode(
    ~op=#ReverseConvert,
    ~schema=entitySchema,
    // FIXME: Can be improved
    `i=>{let v0={"name":i["name"],"age":i["age"],};return {"name":v0["name"],"age":v0["age"],"id":i["id"],}}`,
  )
})
