open Ava

test("Parses unknown primitive with transformation to the same type", t => {
  let struct = S.string->S.transform(~parser=value => value->Js.String2.trim, ())

  t->Assert.deepEqual("  Hello world!"->S.parseAnyWith(struct), Ok("Hello world!"), ())
})

test("Parses unknown primitive with transformation to another type", t => {
  let struct = S.int->S.transform(~parser=value => value->Js.Int.toFloat, ())

  t->Assert.deepEqual(123->S.parseAnyWith(struct), Ok(123.), ())
})

asyncTest(
  "Asynchronously parses unknown primitive with transformation to another type",
  async t => {
    let struct =
      S.int->S.transform(
        ~asyncParser=value => Promise.resolve()->Promise.thenResolve(() => value->Js.Int.toFloat),
        (),
      )

    t->Assert.deepEqual(await 123->S.parseAnyAsyncWith(struct), Ok(123.), ())
  },
)

test("Throws for a Transformed Primitive factory without either a parser, or a serializer", t => {
  t->Assert.throws(
    () => {
      S.string->S.transform()
    },
    ~expectations={
      message: "[rescript-struct] For a struct factory Transform either a parser, or a serializer is required",
    },
    (),
  )
})

test("Fails to parse primitive with transform when parser isn't provided", t => {
  let struct = S.string->S.transform(~serializer=value => value, ())

  t->Assert.deepEqual(
    "Hello world!"->S.parseAnyWith(struct),
    Error({
      code: MissingParser,
      path: S.Path.empty,
      operation: Parsing,
    }),
    (),
  )
})

test("Fails to parse when user raises error in a Transformed Primitive parser", t => {
  let struct = S.string->S.transform(~parser=_ => S.fail("User error"), ())

  t->Assert.deepEqual(
    "Hello world!"->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully serializes primitive with transformation to the same type", t => {
  let struct = S.string->S.transform(~serializer=value => value->Js.String2.trim, ())

  t->Assert.deepEqual(
    "  Hello world!"->S.serializeToUnknownWith(struct),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})

test("Successfully serializes primitive with transformation to another type", t => {
  let struct = S.float->S.transform(~serializer=value => value->Js.Int.toFloat, ())

  t->Assert.deepEqual(123->S.serializeToUnknownWith(struct), Ok(%raw(`123`)), ())
})

test("Transformed Primitive serializing fails when serializer isn't provided", t => {
  let struct = S.string->S.transform(~parser=value => value, ())

  t->Assert.deepEqual(
    "Hello world!"->S.serializeToUnknownWith(struct),
    Error({
      code: MissingSerializer,
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to serialize when user raises error in a Transformed Primitive serializer", t => {
  let struct = S.string->S.transform(~serializer=_ => S.fail("User error"), ())

  t->Assert.deepEqual(
    "Hello world!"->S.serializeToUnknownWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Transform operations applyed in the right order when parsing", t => {
  let struct =
    S.int
    ->S.transform(~parser=_ => S.fail("First transform"), ())
    ->S.transform(~parser=_ => S.fail("Second transform"), ())

  t->Assert.deepEqual(
    123->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("First transform"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Transform operations applyed in the right order when serializing", t => {
  let struct =
    S.int
    ->S.transform(~serializer=_ => S.fail("First transform"), ())
    ->S.transform(~serializer=_ => S.fail("Second transform"), ())

  t->Assert.deepEqual(
    123->S.serializeToUnknownWith(struct),
    Error({
      code: OperationFailed("Second transform"),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test(
  "Successfully parses a Transformed Primitive and serializes it back to the initial state",
  t => {
    let any = %raw(`123`)

    let struct =
      S.int->S.transform(
        ~parser=int => int->Js.Int.toFloat,
        ~serializer=value => value->Belt.Int.fromFloat,
        (),
      )

    t->Assert.deepEqual(
      any
      ->S.parseAnyWith(struct)
      ->Belt.Result.map(object => object->S.serializeToUnknownWith(struct)),
      Ok(Ok(any)),
      (),
    )
  },
)

test("Throws for transform with both parser and asyncParser provided", t => {
  t->Assert.throws(
    () => {
      S.unknown->S.transform(~parser=_ => (), ~asyncParser=_ => Promise.resolve(), ())
    },
    ~expectations={
      message: "[rescript-struct] The S.transform doesn\'t support the `parser` and `asyncParser` arguments simultaneously. Move `asyncParser` to another S.transform.",
    },
    (),
  )
})
