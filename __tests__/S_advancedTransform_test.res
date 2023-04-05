open Ava

let trimmed = S.advancedTransform(
  _,
  ~parser=(~struct as _) => Sync(value => value->Js.String2.trim),
  ~serializer=(~struct as _) => Sync(transformed => transformed->Js.String2.trim),
  (),
)

test("Successfully parses", t => {
  let struct = S.string()->trimmed

  t->Assert.deepEqual("  Hello world!"->S.parseAnyWith(struct), Ok("Hello world!"), ())
})

test("Throws for factory without either a parser, or a serializer", t => {
  t->Assert.throws(
    () => {
      S.string()->S.advancedTransform()
    },
    ~expectations={
      message: "[rescript-struct] For a struct factory Transform either a parser, or a serializer is required",
    },
    (),
  )
})

test("Fails to parse when user raises error in parser", t => {
  let struct =
    S.string()->S.advancedTransform(~parser=(~struct as _) => Sync(_ => S.fail("User error")), ())

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

test("Successfully serializes", t => {
  let struct = S.string()->trimmed

  t->Assert.deepEqual(
    "  Hello world!"->S.serializeToUnknownWith(struct),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})

test("Fails to serialize when user raises error in serializer", t => {
  let struct =
    S.string()->S.advancedTransform(
      ~serializer=(~struct as _) => Sync(_ => S.fail("User error")),
      (),
    )

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
    S.int()
    ->S.advancedTransform(~parser=(~struct as _) => Sync(_ => S.fail("First transform")), ())
    ->S.advancedTransform(~parser=(~struct as _) => Sync(_ => S.fail("Second transform")), ())

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
    S.int()
    ->S.advancedTransform(~serializer=(~struct as _) => Sync(_ => S.fail("First transform")), ())
    ->S.advancedTransform(~serializer=(~struct as _) => Sync(_ => S.fail("Second transform")), ())

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

test("Fails to parse async using parseAnyWith", t => {
  let struct =
    S.string()->S.advancedTransform(
      ~parser=(~struct as _) => Async(value => Promise.resolve(value)),
      (),
    )

  t->Assert.deepEqual(
    %raw(`"Hello world!"`)->S.parseAnyWith(struct),
    Error({
      code: UnexpectedAsync,
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

asyncTest("Successfully parses async using parseAsyncWith", t => {
  let struct =
    S.string()->S.advancedTransform(
      ~parser=(~struct as _) => Async(value => Promise.resolve(value)),
      (),
    )

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

asyncTest("Fails to parse async with user error", t => {
  let struct =
    S.string()->S.advancedTransform(~parser=(~struct as _) => Async(_ => S.fail("User error")), ())

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(
      result,
      Error({
        S.Error.code: OperationFailed("User error"),
        path: S.Path.empty,
        operation: Parsing,
      }),
      (),
    )
  })
})

asyncTest("Can apply other actions after async transform", t => {
  let struct =
    S.string()
    ->S.advancedTransform(~parser=(~struct as _) => Async(value => Promise.resolve(value)), ())
    ->S.String.trim()
    ->S.advancedTransform(~parser=(~struct as _) => Async(value => Promise.resolve(value)), ())

  %raw(`"    Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})
