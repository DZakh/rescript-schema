open Ava

let trimmed = S.advancedTransform(
  _,
  ~parser=(. ~struct as _) => Sync(value => value->Js.String2.trim),
  ~serializer=(. ~struct as _) => Sync(transformed => transformed->Js.String2.trim),
  (),
)

test("Successfully parses ", t => {
  let struct = S.string()->trimmed

  t->Assert.deepEqual("  Hello world!"->S.parseWith(struct), Ok("Hello world!"), ())
})

test("Throws for factory without either a parser, or a serializer", t => {
  t->Assert.throws(() => {
    S.string()->S.advancedTransform()->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message=String("For a struct factory Transform either a parser, or a serializer is required"),
    (),
  ), ())
})

test("Fails to parse when user returns error in parser", t => {
  let any = %raw(`"Hello world!"`)

  let struct =
    S.string()->S.advancedTransform(
      ~parser=(. ~struct as _) => Sync(_ => S.Error.raise("User error")),
      (),
    )

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully serializes", t => {
  let struct = S.string()->trimmed

  t->Assert.deepEqual("  Hello world!"->S.serializeWith(struct), Ok(%raw(`"Hello world!"`)), ())
})

test("Fails to serialize when user returns error in serializer", t => {
  let value = "Hello world!"

  let struct =
    S.string()->S.advancedTransform(
      ~serializer=(. ~struct as _) => Sync(_ => S.Error.raise("User error")),
      (),
    )

  t->Assert.deepEqual(
    value->S.serializeWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Transform operations applyed in the right order when parsing", t => {
  let any = %raw(`123`)

  let struct =
    S.int()
    ->S.advancedTransform(
      ~parser=(. ~struct as _) => Sync(_ => S.Error.raise("First transform")),
      (),
    )
    ->S.advancedTransform(
      ~parser=(. ~struct as _) => Sync(_ => S.Error.raise("Second transform")),
      (),
    )

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error({
      code: OperationFailed("First transform"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Transform operations applyed in the right order when serializing", t => {
  let any = %raw(`123`)

  let struct =
    S.int()
    ->S.advancedTransform(
      ~serializer=(. ~struct as _) => Sync(_ => S.Error.raise("Second transform")),
      (),
    )
    ->S.advancedTransform(
      ~serializer=(. ~struct as _) => Sync(_ => S.Error.raise("First transform")),
      (),
    )

  t->Assert.deepEqual(
    any->S.serializeWith(struct),
    Error({
      code: OperationFailed("First transform"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Fails to parse async using parseWith", t => {
  let struct =
    S.string()->S.advancedTransform(
      ~parser=(. ~struct as _) => Async(value => Promise.resolve(value)),
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

asyncTest("Successfully parses async using parseAsyncWith", t => {
  let struct =
    S.string()->S.advancedTransform(
      ~parser=(. ~struct as _) => Async(value => Promise.resolve(value)),
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
    S.string()->S.advancedTransform(
      ~parser=(. ~struct as _) => Async(_ => S.Error.raise("User error")),
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

asyncTest("Can apply other actions after async transform", t => {
  let struct =
    S.string()
    ->S.advancedTransform(~parser=(. ~struct as _) => Async(value => Promise.resolve(value)), ())
    ->S.String.trimmed()
    ->S.advancedTransform(~parser=(. ~struct as _) => Async(value => Promise.resolve(value)), ())

  %raw(`"    Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})
