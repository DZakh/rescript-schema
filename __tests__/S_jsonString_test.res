open Ava

test("Successfully parses JSON", t => {
  let struct = S.string

  t->Assert.deepEqual(`"Foo"`->S.parseAnyWith(S.jsonString(struct)), Ok("Foo"), ())
})

test("Fails to parse invalid JSON", t => {
  let struct = S.unknown

  t->Assert.deepEqual(
    `undefined`->S.parseAnyWith(S.jsonString(struct)),
    Error({
      code: OperationFailed("Unexpected token u in JSON at position 0"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully serializes JSON", t => {
  let struct = S.string

  t->Assert.deepEqual(
    `Foo`->S.serializeToUnknownWith(S.jsonString(struct)),
    Ok(%raw(`'"Foo"'`)),
    (),
  )
})

test("Fails to create struct when passing non-jsonable struct to S.jsonString", t => {
  t->Assert.throws(
    () => {
      S.jsonString(S.object(o => o.field("foo", S.unknown)))
    },
    ~expectations={
      message: `[rescript-struct] The struct Object({"foo": Unknown}) passed to S.jsonString is not compatible with JSON`,
    },
    (),
  )
})
