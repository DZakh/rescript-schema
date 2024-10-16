open Ava

test("Parses with wrapping the value in variant", t => {
  let schema = S.string->S.to(s => Ok(s))

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(schema), Ok(Ok("Hello world!")), ())
})

asyncTest("Parses with wrapping async schema in variant", async t => {
  let schema = S.string->S.transform(_ => {asyncParser: i => async () => i})->S.to(s => Ok(s))

  t->Assert.deepEqual(await "Hello world!"->S.parseAnyAsyncWith(schema), Ok(Ok("Hello world!")), ())
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[2](i)}return Promise.all([e[0](i)]).then(a=>({"TAG":e[1],"_0":a[0]}))}`,
  )
})

test("Fails to parse wrapped schema", t => {
  let schema = S.string->S.to(s => Ok(s))

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
  let schema = S.string->S.to(s => Ok(s))

  t->Assert.deepEqual(Ok("Hello world!")->S.reverseConvertWith(schema), %raw(`"Hello world!"`), ())
})

test("Fails to serialize when can't unwrap the value from variant", t => {
  let schema = S.string->S.to(s => Ok(s))

  t->U.assertError(
    () => Error("Hello world!")->S.reverseConvertWith(schema),
    {
      code: InvalidType({expected: S.literal("Ok")->S.toUnknown, received: "Error"->Obj.magic}),
      operation: SerializeToUnknown,
      path: S.Path.fromLocation("TAG"),
    },
  )
})

test("Successfully parses when the value is not used as the variant payload", t => {
  let schema = S.string->S.to(_ => #foo)

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(schema), Ok(#foo), ())
})

test("Fails to serialize when the value is not used as the variant payload", t => {
  let schema = S.string->S.to(_ => #foo)

  t->U.assertError(
    () => #foo->S.reverseConvertWith(schema),
    {
      code: InvalidOperation({
        description: `Schema for "" isn\'t registered`,
      }),
      operation: SerializeToUnknown,
      path: S.Path.empty,
    },
  )
})

test(
  "Successfully serializes when the value is not used as the variant payload for literal schemas",
  t => {
    let schema = S.literal((true, 12))->S.to(_ => #foo)

    t->Assert.deepEqual(#foo->S.reverseConvertWith(schema), %raw(`[true, 12]`), ())
  },
)

test("BROKEN: Successfully parses when tuple is destructured", t => {
  let schema = S.literal((true, 12))->S.to(((_, twelve)) => twelve)

  // FIXME: This is wrong, the result should be Ok(12)
  t->Assert.deepEqual(%raw(`[true, 12]`)->S.parseAnyWith(schema), Ok(%raw(`undefined`)), ())
})

// FIXME: Throw in proxy (???)
test("BROKEN: Fails to serialize when tuple is destructured", t => {
  let schema = S.tuple2(S.literal(true), S.literal(12))->S.to(((_, twelve)) => twelve)

  // t->Assert.deepEqual(12->S.reverseConvertWith(schema), Ok(%raw(`[true, 12]`)), ())
  t->Assert.throws(
    () => {
      12->S.reverseConvertWith(schema)
    },
    ~expectations={
      message: `Failed serializing at root. Reason: Schema for "" isn\'t registered`,
    },
    (),
  )
})

test("Successfully parses when value registered multiple times", t => {
  let schema = S.string->S.to(s => #Foo(s, s))

  t->Assert.deepEqual(%raw(`"abc"`)->S.parseAnyWith(schema), Ok(#Foo("abc", "abc")), ())
})

test("Reverse convert with value registered multiple times", t => {
  let schema = S.string->S.to(s => #Foo(s, s))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Serialize,
    `i=>{let v0=i["VAL"]["0"],v1=i["VAL"]["1"];if(i["NAME"]!=="Foo"){e[0](i["NAME"])}if(v0!==v1){e[1]()}return v0}`,
  )

  t->Assert.deepEqual(#Foo("abc", "abc")->S.reverseConvertWith(schema), %raw(`"abc"`), ())
  t->U.assertError(
    () => #Foo("abc", "abcd")->S.reverseConvertWith(schema),
    {
      code: InvalidOperation({
        description: `Multiple sources provided not equal data for ""`,
      }),
      operation: SerializeToUnknown,
      path: S.Path.empty,
    },
  )
})

test("Can destructure object value passed to S.to", t => {
  let schema =
    S.object(s => (s.field("foo", S.string), s.field("bar", S.string)))->S.to(((foo, bar)) =>
      {"foo": foo, "bar": bar}
    )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["foo"],v1=i["bar"];if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="string"){e[1](v1)}return {"foo":v0,"bar":v1}}`,
  )
  t->U.assertCompiledCode(~schema, ~op=#Serialize, `i=>{return {"foo":i["foo"],"bar":i["bar"]}}`)
})

test("Compiled code snapshot of variant applied to object", t => {
  let schema = S.object(s => s.field("foo", S.string))->S.to(s => Ok(s))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["foo"];if(typeof v0!=="string"){e[0](v0)}return {"TAG":e[1],"_0":v0}}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Serialize,
    `i=>{if(i["TAG"]!=="Ok"){e[0](i["TAG"])}return {"foo":i["_0"]}}`,
  )
})

test("Compiled parse code snapshot", t => {
  let schema = S.string->S.to(s => Ok(s))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}return {"TAG":e[0],"_0":i}}`,
  )
})

test("Compiled parse code snapshot without transform", t => {
  let schema = S.string->S.to(s => s)

  t->U.assertCompiledCode(~schema, ~op=#Parse, `i=>{if(typeof i!=="string"){e[0](i)}return i}`)
})

test("Compiled serialize code snapshot", t => {
  let schema = S.string->S.to(s => Ok(s))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Serialize,
    `i=>{if(i["TAG"]!=="Ok"){e[0](i["TAG"])}return i["_0"]}`,
  )
})

test("Compiled serialize code snapshot without transform", t => {
  let schema = S.string->S.to(s => s)

  t->U.assertCompiledCodeIsNoop(~schema, ~op=#Serialize)
})

test(
  "Compiled serialize code snapshot when the value is not used as the variant payload for literal schemas",
  t => {
    let schema = S.literal((true, 12))->S.to(_ => #foo)

    t->Assert.deepEqual(#foo->S.reverseConvertWith(schema), %raw(`[true,12]`), ())

    t->U.assertCompiledCode(~schema, ~op=#Serialize, `i=>{if(i!=="foo"){e[0](i)}return e[1]}`)
  },
)

test("Works with variant schema used multiple times as a child schema", t => {
  let appVersionSpecSchema = S.string->S.to(current => {"current": current, "minimum": "1.0"})

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

  let value = rawAppVersions->S.parseAnyWith(appVersionsSchema)->S.unwrap
  t->Assert.deepEqual(value, appVersions, ())

  let data = appVersions->S.serializeWith(appVersionsSchema)->S.unwrap
  t->Assert.deepEqual(data, rawAppVersions->Obj.magic, ())

  let data = appVersions->S.serializeWith(appVersionsSchema)->S.unwrap
  t->Assert.deepEqual(data, rawAppVersions->Obj.magic, ())
})

test("Reverse variant schema to literal", t => {
  let schema = S.literal("foo")->S.to(_ => ())
  // t->U.assertEqualSchemas(schema->S.reverse, S.unit->S.toUnknown)
  t->U.assertEqualSchemas(schema->S.reverse, S.unknown)
})

test("Succesfully uses reversed variant schema to literal for parsing back to initial value", t => {
  let schema = S.literal("foo")->S.to(_ => ())
  // t->U.assertReverseParsesBack(schema, ())
  t->U.assertEqualSchemas(schema->S.reverse, S.unknown)
})

test("Reverse variant schema to self", t => {
  let schema = S.bool->S.to(v => v)
  // t->Assert.is(schema->S.reverse, schema->S.toUnknown, ())
  t->U.assertEqualSchemas(schema->S.reverse, S.unknown)
})

test("Succesfully uses reversed variant schema to self for parsing back to initial value", t => {
  let schema = S.bool->S.to(v => v)
  t->U.assertReverseParsesBack(schema, true)
})

test("Reverse convert tuple turned to Ok", t => {
  let schema = S.tuple2(S.string, S.bool)->S.to(t => Ok(t))

  t->Assert.deepEqual(Ok(("foo", true))->S.reverseConvertWith(schema), %raw(`["foo", true]`), ())
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Serialize,
    `i=>{let v0=i["_0"];if(i["TAG"]!=="Ok"){e[0](i["TAG"])}return [v0["0"],v0["1"]]}`, // TODO: Can prevent tuple recreation
  )
})

test("Reverse with output of nested object/tuple schema", t => {
  let schema = S.bool->S.to(v => {
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
    let schema = S.bool->S.to(v => {
      {
        "nested": {
          "field": (v, true),
        },
      }
    })
    t->U.assertReverseParsesBack(schema, {"nested": {"field": (true, true)}})
  },
)
