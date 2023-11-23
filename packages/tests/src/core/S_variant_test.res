open Ava

test("Parses with wrapping the value in variant", t => {
  let schema = S.string->S.variant(s => Ok(s))

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(schema), Ok(Ok("Hello world!")), ())
})

test("Fails to parse wrapped schema", t => {
  let schema = S.string->S.variant(s => Ok(s))

  t->Assert.deepEqual(
    123->S.parseAnyWith(schema),
    Error(
      U.error({
        code: InvalidType({received: 123->Obj.magic, expected: schema->S.toUnknown}),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
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

  t->Assert.deepEqual(
    Error("Hello world!")->S.serializeToUnknownWith(schema),
    Error(
      U.error({
        code: InvalidLiteral({expected: String("Ok"), received: "Error"->Obj.magic}),
        operation: Serializing,
        path: S.Path.fromLocation("TAG"),
      }),
    ),
    (),
  )
})

test("Successfully parses when the value is not used as the variant payload", t => {
  let schema = S.string->S.variant(_ => #foo)

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(schema), Ok(#foo), ())
})

test("Fails to serialize when the value is not used as the variant payload", t => {
  let schema = S.string->S.variant(_ => #foo)

  t->Assert.deepEqual(
    #foo->S.serializeToUnknownWith(schema),
    Error(
      U.error({
        code: InvalidOperation({
          description: "Can\'t create serializer. The S.variant\'s value is not registered and not a literal. Use S.transform instead",
        }),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test(
  "Successfully serializes when the value is not used as the variant payload for literal schemas",
  t => {
    let schema = S.tuple2(S.literal(true), S.literal(12))->S.variant(_ => #foo)

    t->Assert.deepEqual(#foo->S.serializeToUnknownWith(schema), Ok(%raw(`[true, 12]`)), ())
  },
)

test("Successfully parses when tuple is destructured", t => {
  let schema = S.tuple2(S.literal(true), S.literal(12))->S.variant(((_, twelve)) => twelve)

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

  t->Assert.deepEqual(
    #Foo("abc", "abc")->S.serializeToUnknownWith(schema),
    Error(
      U.error({
        code: InvalidOperation({
          description: "Can\'t create serializer. The S.variant\'s value is registered multiple times. Use S.transform instead",
        }),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Compiled parse code snapshot", t => {
  let schema = S.string->S.variant(s => Ok(s))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{if(typeof i!=="string"){e[1](i)}return e[0](i)}`,
  )
})

test("Compiled serialize code snapshot", t => {
  let schema = S.string->S.variant(s => Ok(s))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#serialize,
    `i=>{let v0;v0=i["TAG"];if(v0!==e[0]){e[1](v0)}return i["_0"]}`,
  )
})

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
