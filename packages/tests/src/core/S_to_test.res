open Ava

test("Parses with wrapping the value in variant", t => {
  let schema = S.string->S.to(s => Ok(s))

  t->Assert.deepEqual("Hello world!"->S.parseOrThrow(schema), Ok("Hello world!"), ())
})

asyncTest("Parses with wrapping async schema in variant", async t => {
  let schema = S.string->S.transform(_ => {asyncParser: i => async () => i})->S.to(s => Ok(s))

  t->Assert.deepEqual(await "Hello world!"->S.parseAsyncOrThrow(schema), Ok("Hello world!"), ())
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[2](i)}return Promise.all([e[0](i),]).then(a=>({"TAG":e[1],"_0":a[0],}))}`,
  )
})

test("Fails to parse wrapped schema", t => {
  let schema = S.string->S.to(s => Ok(s))

  t->U.assertRaised(
    () => 123->S.parseOrThrow(schema),
    {
      code: InvalidType({received: 123->Obj.magic, expected: schema->S.toUnknown}),
      operation: Parse,
      path: S.Path.empty,
    },
  )
})

test("Serializes with unwrapping the value from variant", t => {
  let schema = S.string->S.to(s => Ok(s))

  t->Assert.deepEqual(
    Ok("Hello world!")->S.reverseConvertOrThrow(schema),
    %raw(`"Hello world!"`),
    (),
  )
})

test("Fails to serialize when can't unwrap the value from variant", t => {
  let schema = S.string->S.to(s => Ok(s))

  t->U.assertRaised(
    () => Error("Hello world!")->S.reverseConvertOrThrow(schema),
    {
      code: InvalidType({expected: S.literal("Ok")->S.toUnknown, received: "Error"->Obj.magic}),
      operation: ReverseConvert,
      path: S.Path.fromLocation("TAG"),
    },
  )
})

test("Successfully parses when the value is not used as the variant payload", t => {
  let schema = S.string->S.to(_ => #foo)

  t->Assert.deepEqual("Hello world!"->S.parseOrThrow(schema), #foo, ())
})

test("Fails to serialize when the value is not used as the variant payload", t => {
  let schema = S.string->S.to(_ => #foo)

  t->U.assertRaised(
    () => #foo->S.reverseConvertOrThrow(schema),
    {
      code: InvalidOperation({
        description: `Schema for "" isn\'t registered`,
      }),
      operation: ReverseConvert,
      path: S.Path.empty,
    },
  )
})

test(
  "Successfully serializes when the value is not used as the variant payload for literal schemas",
  t => {
    let schema = S.literal((true, 12))->S.to(_ => #foo)

    t->Assert.deepEqual(#foo->S.reverseConvertOrThrow(schema), %raw(`[true, 12]`), ())
  },
)

test("Successfully parses when tuple is destructured", t => {
  let schema = S.literal((true, 12))->S.to(((_, twelve)) => twelve)

  t->Assert.deepEqual(%raw(`[true, 12]`)->S.parseOrThrow(schema), %raw(`12`), ())
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(i!==e[0]&&(!Array.isArray(i)||i.length!==2||i[0]!==true||i[1]!==12)){e[1](i)}return i["1"]}`,
  )
})

test("Successfully parses when schema object is destructured - it doesn't create an object", t => {
  let schema = S.schema(s =>
    {
      "foo": s.matches(S.string),
    }
  )->S.to(obj => obj["foo"])

  t->Assert.deepEqual(
    {
      "foo": "bar",
    }->S.parseOrThrow(schema),
    %raw(`"bar"`),
    (),
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[1](i)}let v0=i["foo"];if(typeof v0!=="string"){e[0](v0)}return v0}`,
  )
})

test(
  "Successfully parses when transformed object schema is destructured - it does create an object and extracts a field from it afterwards",
  t => {
    let schema =
      S.schema(s =>
        {
          "foo": s.matches(S.string),
        }
      )
      ->S.transform(_ => {
        parser: obj =>
          {
            "faz": obj["foo"],
          },
      })
      ->S.to(obj => obj["faz"])

    t->Assert.deepEqual(
      {
        "foo": "bar",
      }->S.parseOrThrow(schema),
      %raw(`"bar"`),
      (),
    )
    t->U.assertCompiledCode(
      ~schema,
      ~op=#Parse,
      `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["foo"],v1=e[1]({"foo":v0,});if(typeof v0!=="string"){e[0](v0)}return v1["faz"]}`,
    )
  },
)

// FIXME: Throw in proxy (???)
test("BROKEN: Fails to serialize when tuple is destructured", t => {
  let schema = S.tuple2(S.literal(true), S.literal(12))->S.to(((_, twelve)) => twelve)

  // t->Assert.deepEqual(12->S.reverseConvertOrThrow(schema), Ok(%raw(`[true, 12]`)), ())
  t->Assert.throws(
    () => {
      12->S.reverseConvertOrThrow(schema)
    },
    ~expectations={
      message: `Failed converting reverse at root. Reason: Schema for "" isn\'t registered`,
    },
    (),
  )
})

test("Successfully parses when value registered multiple times", t => {
  let schema = S.string->S.to(s => #Foo(s, s))

  t->Assert.deepEqual(%raw(`"abc"`)->S.parseOrThrow(schema), #Foo("abc", "abc"), ())
})

test("Reverse convert with value registered multiple times", t => {
  let schema = S.string->S.to(s => #Foo(s, s))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0=i["VAL"]["0"],v1=i["VAL"]["1"];if(i["NAME"]!=="Foo"){e[0](i["NAME"])}if(v0!==v1){e[1]()}return v0}`,
  )

  t->Assert.deepEqual(#Foo("abc", "abc")->S.reverseConvertOrThrow(schema), %raw(`"abc"`), ())
  t->U.assertRaised(
    () => #Foo("abc", "abcd")->S.reverseConvertOrThrow(schema),
    {
      code: InvalidOperation({
        description: `Multiple sources provided not equal data for ""`,
      }),
      operation: ReverseConvert,
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
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["foo"],v1=i["bar"];if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="string"){e[1](v1)}return {"foo":v0,"bar":v1,}}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{return {"foo":i["foo"],"bar":i["bar"],}}`,
  )
})

test("Compiled code snapshot of variant applied to object", t => {
  let schema = S.object(s => s.field("foo", S.string))->S.to(s => Ok(s))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["foo"];if(typeof v0!=="string"){e[0](v0)}return {"TAG":e[1],"_0":v0,}}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{if(i["TAG"]!=="Ok"){e[0](i["TAG"])}return {"foo":i["_0"],}}`,
  )
})

test("Compiled parse code snapshot", t => {
  let schema = S.string->S.to(s => Ok(s))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}return {"TAG":e[0],"_0":i,}}`,
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
    ~op=#ReverseConvert,
    `i=>{if(i["TAG"]!=="Ok"){e[0](i["TAG"])}return i["_0"]}`,
  )
})

test("Compiled serialize code snapshot without transform", t => {
  let schema = S.string->S.to(s => s)

  t->U.assertCompiledCodeIsNoop(~schema, ~op=#ReverseConvert)
})

test(
  "Compiled serialize code snapshot when the value is not used as the variant payload for literal schemas",
  t => {
    let schema = S.literal((true, 12))->S.to(_ => #foo)

    t->Assert.deepEqual(#foo->S.reverseConvertOrThrow(schema), %raw(`[true,12]`), ())

    t->U.assertCompiledCode(~schema, ~op=#ReverseConvert, `i=>{if(i!=="foo"){e[0](i)}return e[1]}`)
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

  let value = rawAppVersions->S.parseOrThrow(appVersionsSchema)
  t->Assert.deepEqual(value, appVersions, ())

  let data = appVersions->S.reverseConvertToJsonOrThrow(appVersionsSchema)
  t->Assert.deepEqual(data, rawAppVersions->Obj.magic, ())

  let data = appVersions->S.reverseConvertToJsonOrThrow(appVersionsSchema)
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

  t->Assert.deepEqual(Ok(("foo", true))->S.reverseConvertOrThrow(schema), %raw(`["foo", true]`), ())
  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0=i["_0"];if(i["TAG"]!=="Ok"){e[0](i["TAG"])}return v0}`,
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
