open Ava

let trimmed = S.advancedTransform(
  _,
  ~parser=(~struct as _) => Sync(value => value->Js.String2.trim),
  ~serializer=(~struct as _) => Sync(transformed => transformed->Js.String2.trim),
  (),
)

ava->test("Successfully parses", t => {
  let struct = S.string()->trimmed

  t->Assert.deepEqual("  Hello world!"->S.parseWith(struct), Ok("Hello world!"), ())
})

ava->test("Throws for factory without either a parser, or a serializer", t => {
  t->Assert.throws(() => {
    S.string()->S.advancedTransform()->ignore
  }, ~expectations=ThrowsException.make(
    ~message=String(
      "[rescript-struct] For a struct factory Transform either a parser, or a serializer is required",
    ),
    (),
  ), ())
})

ava->test("Fails to parse when user raises error in parser", t => {
  let struct =
    S.string()->S.advancedTransform(
      ~parser=(~struct as _) => Sync(_ => S.Error.raise("User error")),
      (),
    )

  t->Assert.deepEqual(
    "Hello world!"->S.parseWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

ava->test("Successfully serializes", t => {
  let struct = S.string()->trimmed

  t->Assert.deepEqual("  Hello world!"->S.serializeWith(struct), Ok(%raw(`"Hello world!"`)), ())
})

ava->test("Fails to serialize when user raises error in serializer", t => {
  let struct =
    S.string()->S.advancedTransform(
      ~serializer=(~struct as _) => Sync(_ => S.Error.raise("User error")),
      (),
    )

  t->Assert.deepEqual(
    "Hello world!"->S.serializeWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

ava->test("Transform operations applyed in the right order when parsing", t => {
  let struct =
    S.int()
    ->S.advancedTransform(~parser=(~struct as _) => Sync(_ => S.Error.raise("First transform")), ())
    ->S.advancedTransform(
      ~parser=(~struct as _) => Sync(_ => S.Error.raise("Second transform")),
      (),
    )

  t->Assert.deepEqual(
    123->S.parseWith(struct),
    Error({
      code: OperationFailed("First transform"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

ava->test("Transform operations applyed in the right order when serializing", t => {
  let struct =
    S.int()
    ->S.advancedTransform(
      ~serializer=(~struct as _) => Sync(_ => S.Error.raise("First transform")),
      (),
    )
    ->S.advancedTransform(
      ~serializer=(~struct as _) => Sync(_ => S.Error.raise("Second transform")),
      (),
    )

  t->Assert.deepEqual(
    123->S.serializeWith(struct),
    Error({
      code: OperationFailed("Second transform"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

ava->test("Fails to parse async using parseWith", t => {
  let struct =
    S.string()->S.advancedTransform(
      ~parser=(~struct as _) => Async(value => Promise.resolve(value)),
      (),
    )

  t->Assert.deepEqual(
    %raw(`"Hello world!"`)->S.parseWith(struct),
    Error({
      code: UnexpectedAsync,
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

ava->asyncTest("Successfully parses async using parseAsyncWith", t => {
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

ava->asyncTest("Fails to parse async with user error", t => {
  let struct =
    S.string()->S.advancedTransform(
      ~parser=(~struct as _) => Async(_ => S.Error.raise("User error")),
      (),
    )

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(
      result,
      Error({
        S.Error.code: OperationFailed("User error"),
        path: [],
        operation: Parsing,
      }),
      (),
    )
  })
})

ava->asyncTest("Can apply other actions after async transform", t => {
  let struct =
    S.string()
    ->S.advancedTransform(~parser=(~struct as _) => Async(value => Promise.resolve(value)), ())
    ->S.String.trimmed()
    ->S.advancedTransform(~parser=(~struct as _) => Async(value => Promise.resolve(value)), ())

  %raw(`"    Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})
