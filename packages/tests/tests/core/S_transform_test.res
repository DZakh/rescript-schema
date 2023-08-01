open Ava
open RescriptCore

test("Parses unknown primitive with transformation to the same type", t => {
  let struct = S.string->S.transform(_ => {parser: value => value->String.trim})

  t->Assert.deepEqual("  Hello world!"->S.parseAnyWith(struct), Ok("Hello world!"), ())
})

test("Parses unknown primitive with transformation to another type", t => {
  let struct = S.int->S.transform(_ => {parser: value => value->Int.toFloat})

  t->Assert.deepEqual(123->S.parseAnyWith(struct), Ok(123.), ())
})

asyncTest(
  "Asynchronously parses unknown primitive with transformation to another type",
  async t => {
    let struct = S.int->S.transform(_ => {
      asyncParser: value => () => Promise.resolve()->Promise.thenResolve(() => value->Int.toFloat),
    })

    t->Assert.deepEqual(await 123->S.parseAnyAsyncWith(struct), Ok(123.), ())
  },
)

test("Fails to parse primitive with transform when parser isn't provided", t => {
  let struct = S.string->S.transform(_ => {serializer: value => value})

  t->Assert.deepEqual(
    "Hello world!"->S.parseAnyWith(struct),
    Error({
      code: InvalidOperation({description: "The S.transform parser is missing"}),
      path: S.Path.empty,
      operation: Parsing,
    }),
    (),
  )
})

test("Fails to parse when user raises error in a Transformed Primitive parser", t => {
  let struct = S.string->S.transform(s => {parser: _ => s.fail("User error")})

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

test("Uses the path from failWithError called in the transform parser", t => {
  let struct = S.array(
    S.string->S.transform(s => {
      parser: _ =>
        s.failWithError({
          code: OperationFailed("User error"),
          operation: Parsing,
          path: S.Path.fromArray(["a", "b"]),
        }),
    }),
  )

  t->Assert.deepEqual(
    ["Hello world!"]->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: S.Path.fromArray(["0", "a", "b"]),
    }),
    (),
  )
})

test("Uses the path from failWithError called in the transform serializer", t => {
  let struct = S.array(
    S.string->S.transform(s => {
      serializer: _ =>
        s.failWithError({
          code: OperationFailed("User error"),
          operation: Parsing,
          path: S.Path.fromArray(["a", "b"]),
        }),
    }),
  )

  t->Assert.deepEqual(
    ["Hello world!"]->S.serializeWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: S.Path.fromArray(["0", "a", "b"]),
    }),
    (),
  )
})

test("Transform parser passes through non rescript-struct errors", t => {
  let struct = S.array(
    S.string->S.transform(_ => {parser: _ => Exn.raiseError("Application crashed")}),
  )

  t->Assert.throws(
    () => {["Hello world!"]->S.parseAnyWith(struct)},
    ~expectations={
      message: "Application crashed",
    },
    (),
  )
})

test("Transform parser passes through other rescript exceptions", t => {
  let struct = S.array(S.string->S.transform(_ => {parser: _ => TestUtils.raiseTestException()}))

  t->TestUtils.assertThrowsTestException(() => {["Hello world!"]->S.parseAnyWith(struct)}, ())
})

test("Transform definition passes through non rescript-struct errors", t => {
  let struct = S.array(S.string->S.transform(_ => Exn.raiseError("Application crashed")))

  t->Assert.throws(
    () => {["Hello world!"]->S.parseAnyWith(struct)},
    ~expectations={
      message: "Application crashed",
    },
    (),
  )
})

test("Transform definition passes through other rescript exceptions", t => {
  let struct = S.array(S.string->S.transform(_ => TestUtils.raiseTestException()))

  t->TestUtils.assertThrowsTestException(() => {["Hello world!"]->S.parseAnyWith(struct)}, ())
})

test("Successfully serializes primitive with transformation to the same type", t => {
  let struct = S.string->S.transform(_ => {serializer: value => value->String.trim})

  t->Assert.deepEqual(
    "  Hello world!"->S.serializeToUnknownWith(struct),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})

test("Successfully serializes primitive with transformation to another type", t => {
  let struct = S.float->S.transform(_ => {serializer: value => value->Int.toFloat})

  t->Assert.deepEqual(123->S.serializeToUnknownWith(struct), Ok(%raw(`123`)), ())
})

test("Transformed Primitive serializing fails when serializer isn't provided", t => {
  let struct = S.string->S.transform(_ => {parser: value => value})

  t->Assert.deepEqual(
    "Hello world!"->S.serializeToUnknownWith(struct),
    Error({
      code: InvalidOperation({description: "The S.transform serializer is missing"}),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to serialize when user raises error in a Transformed Primitive serializer", t => {
  let struct = S.string->S.transform(s => {serializer: _ => s.fail("User error")})

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
    ->S.transform(s => {parser: _ => s.fail("First transform")})
    ->S.transform(s => {parser: _ => s.fail("Second transform")})

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
    ->S.transform(s => {serializer: _ => s.fail("First transform")})
    ->S.transform(s => {serializer: _ => s.fail("Second transform")})

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

    let struct = S.int->S.transform(_ => {
      parser: int => int->Int.toFloat,
      serializer: value => value->Int.fromFloat,
    })

    t->Assert.deepEqual(
      any->S.parseAnyWith(struct)->Result.map(object => object->S.serializeToUnknownWith(struct)),
      Ok(Ok(any)),
      (),
    )
  },
)

test("Fails to parse struct with transform having both parser and asyncParser", t => {
  let struct =
    S.string->S.transform(_ => {parser: _ => (), asyncParser: _ => () => Promise.resolve()})

  t->Assert.deepEqual(
    "foo"->S.parseAnyWith(struct),
    Error({
      code: InvalidOperation({
        description: "The S.transform doesn\'t allow parser and asyncParser at the same time. Remove parser in favor of asyncParser.",
      }),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to parse async using parseAnyWith", t => {
  let struct = S.string->S.transform(_ => {asyncParser: value => () => Promise.resolve(value)})

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

test("Successfully parses with empty transform", t => {
  let struct = S.string->S.transform(_ => {})

  t->Assert.deepEqual(%raw(`"Hello world!"`)->S.parseAnyWith(struct), Ok("Hello world!"), ())
})

test("Successfully serializes with empty transform", t => {
  let struct = S.string->S.transform(_ => {})

  t->Assert.deepEqual(
    "Hello world!"->S.serializeToUnknownWith(struct),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})

asyncTest("Successfully parses async using parseAsyncWith", t => {
  let struct = S.string->S.transform(_ => {asyncParser: value => () => Promise.resolve(value)})

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

asyncTest("Fails to parse async with user error", t => {
  let struct = S.string->S.transform(s => {asyncParser: _ => () => s.fail("User error")})

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(
      result,
      Error({
        S.code: OperationFailed("User error"),
        path: S.Path.empty,
        operation: Parsing,
      }),
      (),
    )
  })
})

asyncTest("Can apply other actions after async transform", t => {
  let struct =
    S.string
    ->S.transform(_ => {asyncParser: value => () => Promise.resolve(value)})
    ->S.String.trim()
    ->S.transform(_ => {asyncParser: value => () => Promise.resolve(value)})

  %raw(`"    Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})
