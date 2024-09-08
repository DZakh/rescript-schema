open Ava

test("Parses with wrapping the value in variant", t => {
  let schema = S.string->S.variant(s => Ok(s))

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(schema), Ok(Ok("Hello world!")), ())
})

test("Fails to parse wrapped schema", t => {
  let schema = S.string->S.variant(s => Ok(s))

  t->U.assertErrorResult(
    123->S.parseAnyWith(schema),
    {
      code: InvalidType({received: 123->Obj.magic, expected: schema->S.toUnknown}),
      operation: Parse,
      path: S.Path.empty,
    },
  )
})

test("Serializes with unwrapping the value from variant", t => {
  let schema = S.string->S.variant(s => Ok(s))

  t->Assert.deepEqual(
    Ok("Hello world!")->S.serializeToUnknownWith(schema),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})

test("Fails to serialize when can't unwrap the value from variant", t => {
  let schema = S.string->S.variant(s => Ok(s))

  t->U.assertErrorResult(
    Error("Hello world!")->S.serializeToUnknownWith(schema),
    {
      code: InvalidType({expected: S.literal("Ok")->S.toUnknown, received: "Error"->Obj.magic}),
      operation: SerializeToUnknown,
      path: S.Path.fromLocation("TAG"),
    },
  )
})

test("Successfully parses when the value is not used as the variant payload", t => {
  let schema = S.string->S.variant(_ => #foo)

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(schema), Ok(#foo), ())
})

test("Fails to serialize when the value is not used as the variant payload", t => {
  let schema = S.string->S.variant(_ => #foo)

  t->U.assertErrorResult(
    #foo->S.serializeToUnknownWith(schema),
    {
      code: InvalidOperation({
        description: "The S.variant\'s value is not registered",
      }),
      operation: SerializeToUnknown,
      path: S.Path.empty,
    },
  )
})

test(
  "Successfully serializes when the value is not used as the variant payload for literal schemas",
  t => {
    let schema = S.literal((true, 12))->S.variant(_ => #foo)

    t->Assert.deepEqual(#foo->S.serializeToUnknownWith(schema), Ok(%raw(`[true, 12]`)), ())
  },
)

test("Successfully parses when tuple is destructured", t => {
  let schema = S.literal((true, 12))->S.variant(((_, twelve)) => twelve)

  t->Assert.deepEqual(%raw(`[true, 12]`)->S.parseAnyWith(schema), Ok(12), ())
})

// TODO: Throw in proxy (???)
// test("Fails to serialize when tuple is destructured", t => {
//   let schema = S.tuple2(S.literal(true), S.literal(12))->S.variant(((_, twelve)) => twelve)

//   t->Assert.deepEqual(12->S.serializeToUnknownWith(schema), Ok(%raw(`[true, 12]`)), ())
// })

test("Successfully parses when value registered multiple times", t => {
  let schema = S.string->S.variant(s => #Foo(s, s))

  t->Assert.deepEqual(%raw(`"abc"`)->S.parseAnyWith(schema), Ok(#Foo("abc", "abc")), ())
})

test("Fails to serialize when value registered multiple times", t => {
  let schema = S.string->S.variant(s => #Foo(s, s))

  t->U.assertErrorResult(
    #Foo("abc", "abc")->S.serializeToUnknownWith(schema),
    {
      code: InvalidOperation({
        description: "The S.variant\'s value is registered multiple times",
      }),
      operation: SerializeToUnknown,
      path: S.Path.empty,
    },
  )
})

test("Can destructure object value passed to S.variant", t => {
  let schema =
    S.object(s => (s.field("foo", S.string), s.field("bar", S.string)))->S.variant(((foo, bar)) =>
      {"foo": foo, "bar": bar}
    )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["foo"],v1=i["bar"];if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="string"){e[1](v1)}return {"foo":v0,"bar":v1,}}`,
  )
  t->U.assertCompiledCode(~schema, ~op=#Serialize, `i=>{return {"foo":i["foo"],"bar":i["bar"],}}`)
})

test("Compiled code snapshot of variant applied to object", t => {
  let schema = S.object(s => s.field("foo", S.string))->S.variant(s => Ok(s))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["foo"];if(typeof v0!=="string"){e[0](v0)}return {"TAG":e[1],"_0":v0,}}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Serialize,
    `i=>{if(i["TAG"]!=="Ok"){e[0](i["TAG"])}return {"foo":i["_0"],}}`,
  )
})

test("Compiled parse code snapshot", t => {
  let schema = S.string->S.variant(s => Ok(s))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}return e[0](i)}`,
  )
})

test("Compiled parse code snapshot without transform", t => {
  let schema = S.string->S.variant(s => s)

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}return e[0](i)}`,
  )
})

test("Compiled serialize code snapshot", t => {
  let schema = S.string->S.variant(s => Ok(s))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Serialize,
    `i=>{let v0=i["TAG"];if(v0!=="Ok"){e[0](v0)}return i["_0"]}`,
  )
})

test("Compiled serialize code snapshot without transform", t => {
  let schema = S.string->S.variant(s => s)

  t->U.assertCompiledCodeIsNoop(~schema, ~op=#Serialize)
})

test(
  "Compiled serialize code snapshot when the value is not used as the variant payload for literal schemas",
  t => {
    let schema = S.literal((true, 12))->S.variant(_ => #foo)

    t->Assert.deepEqual(#foo->S.serializeToUnknownWith(schema), Ok(%raw(`[true,12]`)), ())

    t->U.assertCompiledCode(~schema, ~op=#Serialize, `i=>{if(i!=="foo"){e[0](i)}return e[1]}`)
  },
)

test("Works with variant schema used multiple times as a child schema", t => {
  let appVersionSpecSchema = S.string->S.variant(current => {"current": current, "minimum": "1.0"})

  let appVersionsSchema = S.object(s =>
    {
      "ios": s.field("ios", appVersionSpecSchema),
      "android": s.field("android", appVersionSpecSchema),
    }
  )

  let rawAppVersions = {
    "ios": "1.1",
    "android": "1.2",
  }
  let appVersions = {
    "ios": {"current": "1.1", "minimum": "1.0"},
    "android": {"current": "1.2", "minimum": "1.0"},
  }

  let value = rawAppVersions->S.parseAnyOrRaiseWith(appVersionsSchema)
  t->Assert.deepEqual(value, appVersions, ())

  let data = appVersions->S.serializeOrRaiseWith(appVersionsSchema)
  t->Assert.deepEqual(data, rawAppVersions->Obj.magic, ())

  let data = appVersions->S.serializeOrRaiseWith(appVersionsSchema)
  t->Assert.deepEqual(data, rawAppVersions->Obj.magic, ())
})

test("Reverse variant schema to literal", t => {
  let schema = S.literal("foo")->S.variant(_ => ())
  // t->U.assertEqualSchemas(schema->S.reverse, S.unit->S.toUnknown)
  t->U.assertEqualSchemas(schema->S.reverse, S.unknown)
})

test("Succesfully uses reversed variant schema to literal for parsing back to initial value", t => {
  let schema = S.literal("foo")->S.variant(_ => ())
  // t->U.assertReverseParsesBack(schema, ())
  t->U.assertEqualSchemas(schema->S.reverse, S.unknown)
})

test("Reverse variant schema to self", t => {
  let schema = S.bool->S.variant(v => v)
  // t->Assert.is(schema->S.reverse, schema->S.toUnknown, ())
  t->U.assertEqualSchemas(schema->S.reverse, S.unknown)
})

test("Succesfully uses reversed variant schema to self for parsing back to initial value", t => {
  let schema = S.bool->S.variant(v => v)
  t->U.assertReverseParsesBack(schema, true)
})

test("Reverse with output of nested object/tuple schema", t => {
  let schema = S.bool->S.variant(v => {
    {
      "nested": {
        "field": (v, true),
      },
    }
  })
  // t->U.assertEqualSchemas(
  //   schema->S.reverse,
  //   S.object(s => {
  //     let _ = s.field(
  //       "nested",
  //       S.object(
  //         s => {
  //           let _ = s.field(
  //             "field",
  //             S.tuple(
  //               s => {
  //                 let _ = s.item(0, S.bool)
  //                 s.tag(1, true)
  //               },
  //             ),
  //           )
  //         },
  //       ),
  //     )
  //   })->S.toUnknown,
  // )
  t->U.assertEqualSchemas(schema->S.reverse, S.unknown)
})

test(
  "Succesfully parses reversed schema with output of nested object/tuple and parses it back to initial value",
  t => {
    let schema = S.bool->S.variant(v => {
      {
        "nested": {
          "field": (v, true),
        },
      }
    })
    t->U.assertReverseParsesBack(schema, {"nested": {"field": (true, true)}})
  },
)
