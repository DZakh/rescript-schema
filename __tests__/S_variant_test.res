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
      code: MissingSerializer,
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

test("Fails to create variant struct with payload defined multiple times", t => {
  t->Assert.throws(
    () => {
      S.string->S.variant(s => #Foo(s, s))
    },
    ~expectations={
      message: `[rescript-struct] The variant\'s value is registered multiple times. If you want to duplicate it, use S.transform instead.`,
    },
    (),
  )
})
