open Ava

test("Name of primitive struct", t => {
  t->Assert.deepEqual(S.string->S.name, "String", ())
})

test("Name of Literal struct", t => {
  t->Assert.deepEqual(S.literal(123)->S.name, "Literal(123)", ())
})

test("Name of Array struct", t => {
  t->Assert.deepEqual(S.array(S.string)->S.name, "Array(String)", ())
})

test("Name of Dict struct", t => {
  t->Assert.deepEqual(S.dict(S.string)->S.name, "Dict(String)", ())
})

test("Name of Option struct", t => {
  t->Assert.deepEqual(S.option(S.string)->S.name, "Option(String)", ())
})

test("Name of Null struct", t => {
  t->Assert.deepEqual(S.null(S.string)->S.name, "Null(String)", ())
})

test("Name of Union struct", t => {
  t->Assert.deepEqual(
    S.union([S.string, S.literal("foo")])->S.name,
    `Union(String, Literal("foo"))`,
    (),
  )
})

test("Name of Object struct", t => {
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

test("Name of Tuple struct", t => {
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

test("Name of custom struct", t => {
  t->Assert.deepEqual(S.custom("Test", s => s.fail("User error"))->S.name, "Test", ())
})

test("Name of renamed struct", t => {
  let originalStruct = S.unknown
  let renamedStruct = originalStruct->S.setName("Foo")
  t->Assert.deepEqual(originalStruct->S.name, "Unknown", ())
  t->Assert.deepEqual(renamedStruct->S.name, "Foo", ())
})
