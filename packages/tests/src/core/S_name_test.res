open Ava

test("Name of primitive schema", t => {
  t->Assert.deepEqual(S.string->S.name, "String", ())
})

test("Name of Literal schema", t => {
  t->Assert.deepEqual(S.literal(123)->S.name, "123", ())
})

test("Name of Literal object schema", t => {
  t->Assert.deepEqual(S.literal({"abc": 123})->S.name, `{"abc":123}`, ())
})

test("Name of Array schema", t => {
  t->Assert.deepEqual(S.array(S.string)->S.name, "Array(String)", ())
})

test("Name of Dict schema", t => {
  t->Assert.deepEqual(S.dict(S.string)->S.name, "Dict(String)", ())
})

test("Name of Option schema", t => {
  t->Assert.deepEqual(S.option(S.string)->S.name, "Option(String)", ())
})

test("Name of Null schema", t => {
  t->Assert.deepEqual(S.null(S.string)->S.name, "Null(String)", ())
})

test("Name of Union schema", t => {
  t->Assert.deepEqual(S.union([S.string, S.literal("foo")])->S.name, `Union(String, "foo")`, ())
})

test("Name of Object schema", t => {
  t->Assert.deepEqual(
    S.object(s =>
      {
        "foo": s.field("foo", S.string),
        "bar": s.field("bar", S.int),
      }
    )->S.name,
    `Object({"foo": String, "bar": Int})`,
    (),
  )
})

test("Name of Tuple schema", t => {
  t->Assert.deepEqual(
    S.tuple(s =>
      {
        "foo": s.item(0, S.string),
        "bar": s.item(1, S.int),
      }
    )->S.name,
    `Tuple(String, Int)`,
    (),
  )
})

test("Name of custom schema", t => {
  t->Assert.deepEqual(S.custom("Test", s => s.fail("User error"))->S.name, "Test", ())
})

test("Name of renamed schema", t => {
  let originalSchema = S.never
  let renamedSchema = originalSchema->S.setName("Ethers.BigInt")
  t->Assert.deepEqual(originalSchema->S.name, "Never", ())
  t->Assert.deepEqual(renamedSchema->S.name, "Ethers.BigInt", ())
  // Uses new name when failing
  t->U.assertErrorResult(
    "smth"->S.parseAnyWith(renamedSchema),
    {
      path: S.Path.empty,
      operation: Parse,
      code: InvalidType({expected: renamedSchema->S.toUnknown, received: "smth"->Obj.magic}),
    },
  )
  t->Assert.is(
    U.error({
      path: S.Path.empty,
      operation: Parse,
      code: InvalidType({expected: renamedSchema->S.toUnknown, received: "smth"->Obj.magic}),
    })->S.Error.message,
    `Failed parsing at root. Reason: Expected Ethers.BigInt, received "smth"`,
    (),
  )
  t->U.assertError(
    () => %raw(`"smth"`)->S.reverseConvertWith(S.null(S.never)->S.setName("Ethers.BigInt")),
    {
      path: S.Path.empty,
      operation: SerializeToUnknown,
      code: InvalidType({expected: S.never->S.toUnknown, received: "smth"->Obj.magic}),
    },
  )
})
