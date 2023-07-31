open Ava

test("Parses with wrapping the value in variant", t => {
  let struct = S.string->S.variant(s => Ok(s))

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(struct), Ok(Ok("Hello world!")), ())
})

test("Fails to parse wrapped struct", t => {
  let struct = S.string->S.variant(s => Ok(s))

  t->Assert.deepEqual(
    123->S.parseAnyWith(struct),
    Error({
      operation: Parsing,
      code: InvalidType({received: 123->Obj.magic, expected: S.string->S.toUnknown}),
      path: S.Path.empty,
    }),
    (),
  )
})

test("Serializes with unwrapping the value from variant", t => {
  let struct = S.string->S.variant(s => Ok(s))

  t->Assert.deepEqual(
    Ok("Hello world!")->S.serializeToUnknownWith(struct),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})

test("Fails to serialize when can't unwrap the value from variant", t => {
  let struct = S.string->S.variant(s => Ok(s))

  t->Assert.deepEqual(
    Error("Hello world!")->S.serializeToUnknownWith(struct),
    Error({
      code: InvalidLiteral({expected: String("Ok"), received: "Error"->Obj.magic}),
      path: S.Path.fromLocation("TAG"),
      operation: Serializing,
    }),
    (),
  )
})

test("Successfully parses when the value is not used as the variant payload", t => {
  let struct = S.string->S.variant(_ => #foo)

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(struct), Ok(#foo), ())
})

test("Fails to serialize when the value is not used as the variant payload", t => {
  let struct = S.string->S.variant(_ => #foo)

  t->Assert.deepEqual(
    #foo->S.serializeToUnknownWith(struct),
    Error({
      code: InvalidOperation({
        description: "Can\'t create serializer. The S.variant\'s value is not registered and not a literal. Use S.transform instead",
      }),
      path: S.Path.empty,
      operation: Serializing,
    }),
    (),
  )
})

test(
  "Successfully serializes when the value is not used as the variant payload for literal structs",
  t => {
    let struct = S.tuple2(S.literal(true), S.literal(12))->S.variant(_ => #foo)

    t->Assert.deepEqual(#foo->S.serializeToUnknownWith(struct), Ok(%raw(`[true, 12]`)), ())
  },
)

test("Successfully parses when tuple is destructured", t => {
  let struct = S.tuple2(S.literal(true), S.literal(12))->S.variant(((_, twelve)) => twelve)

  t->Assert.deepEqual(%raw(`[true, 12]`)->S.parseAnyWith(struct), Ok(12), ())
})

// TODO: Throw in proxy (???)
// test("Fails to serialize when tuple is destructured", t => {
//   let struct = S.tuple2(S.literal(true), S.literal(12))->S.variant(((_, twelve)) => twelve)

//   t->Assert.deepEqual(12->S.serializeToUnknownWith(struct), Ok(%raw(`[true, 12]`)), ())
// })

test("Successfully parses when value registered multiple times", t => {
  let struct = S.string->S.variant(s => #Foo(s, s))

  t->Assert.deepEqual(%raw(`"abc"`)->S.parseAnyWith(struct), Ok(#Foo("abc", "abc")), ())
})

test("Fails to serialize when value registered multiple times", t => {
  let struct = S.string->S.variant(s => #Foo(s, s))

  t->Assert.deepEqual(
    #Foo("abc", "abc")->S.serializeToUnknownWith(struct),
    Error({
      code: InvalidOperation({
        description: "Can\'t create serializer. The S.variant\'s value is registered multiple times. Use S.transform instead",
      }),
      path: S.Path.empty,
      operation: Serializing,
    }),
    (),
  )
})
