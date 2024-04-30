open Ava
open RescriptCore

test("Parses unknown primitive with transformation to the same type", t => {
  let schema = S.string->S.transform(_ => {parser: value => value->String.trim})

  t->Assert.deepEqual("  Hello world!"->S.parseAnyWith(schema), Ok("Hello world!"), ())
})

test("Parses unknown primitive with transformation to another type", t => {
  let schema = S.int->S.transform(_ => {parser: value => value->Int.toFloat})

  t->Assert.deepEqual(123->S.parseAnyWith(schema), Ok(123.), ())
})

asyncTest(
  "Asynchronously parses unknown primitive with transformation to another type",
  async t => {
    let schema = S.int->S.transform(_ => {
      asyncParser: value => () => Promise.resolve()->Promise.thenResolve(() => value->Int.toFloat),
    })

    t->Assert.deepEqual(await 123->S.parseAnyAsyncWith(schema), Ok(123.), ())
  },
)

test("Fails to parse primitive with transform when parser isn't provided", t => {
  let schema = S.string->S.transform(_ => {serializer: value => value})

  t->U.assertErrorResult(
    "Hello world!"->S.parseAnyWith(schema),
    {
      code: InvalidOperation({description: "The S.transform parser is missing"}),
      operation: Parsing,
      path: S.Path.empty,
    },
  )
})

test("Fails to parse when user raises error in a Transformed Primitive parser", t => {
  let schema = S.string->S.transform(s => {parser: _ => s.fail("User error")})

  t->Assert.deepEqual(
    "Hello world!"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("User error"), operation: Parsing, path: S.Path.empty})),
    (),
  )
})

test("Uses the path from failWithError called in the transform parser", t => {
  let schema = S.array(
    S.string->S.transform(s => {
      parser: _ =>
        s.failWithError(
          U.error({
            code: OperationFailed("User error"),
            operation: Parsing,
            path: S.Path.fromArray(["a", "b"]),
          }),
        ),
    }),
  )

  t->U.assertErrorResult(
    ["Hello world!"]->S.parseAnyWith(schema),
    {
      code: OperationFailed("User error"),
      operation: Parsing,
      path: S.Path.fromArray(["0", "a", "b"]),
    },
  )
})

test("Uses the path from failWithError called in the transform serializer", t => {
  let schema = S.array(
    S.string->S.transform(s => {
      serializer: _ =>
        s.failWithError(
          U.error({
            code: OperationFailed("User error"),
            operation: Parsing,
            path: S.Path.fromArray(["a", "b"]),
          }),
        ),
    }),
  )

  t->U.assertErrorResult(
    ["Hello world!"]->S.serializeWith(schema),
    {
      code: OperationFailed("User error"),
      operation: Serializing,
      path: S.Path.fromArray(["0", "a", "b"]),
    },
  )
})

test("Transform parser passes through non rescript-schema errors", t => {
  let schema = S.array(
    S.string->S.transform(_ => {parser: _ => Exn.raiseError("Application crashed")}),
  )

  t->Assert.throws(
    () => {["Hello world!"]->S.parseAnyWith(schema)},
    ~expectations={
      message: "Application crashed",
    },
    (),
  )
})

test("Transform parser passes through other rescript exceptions", t => {
  let schema = S.array(S.string->S.transform(_ => {parser: _ => U.raiseTestException()}))

  t->U.assertThrowsTestException(() => {["Hello world!"]->S.parseAnyWith(schema)}, ())
})

test("Transform definition passes through non rescript-schema errors", t => {
  let schema = S.array(S.string->S.transform(_ => Exn.raiseError("Application crashed")))

  t->Assert.throws(
    () => {["Hello world!"]->S.parseAnyWith(schema)},
    ~expectations={
      message: "Application crashed",
    },
    (),
  )
})

test("Transform definition passes through other rescript exceptions", t => {
  let schema = S.array(S.string->S.transform(_ => U.raiseTestException()))

  t->U.assertThrowsTestException(() => {["Hello world!"]->S.parseAnyWith(schema)}, ())
})

test("Successfully serializes primitive with transformation to the same type", t => {
  let schema = S.string->S.transform(_ => {serializer: value => value->String.trim})

  t->Assert.deepEqual(
    "  Hello world!"->S.serializeToUnknownWith(schema),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})

test("Successfully serializes primitive with transformation to another type", t => {
  let schema = S.float->S.transform(_ => {serializer: value => value->Int.toFloat})

  t->Assert.deepEqual(123->S.serializeToUnknownWith(schema), Ok(%raw(`123`)), ())
})

test("Transformed Primitive serializing fails when serializer isn't provided", t => {
  let schema = S.string->S.transform(_ => {parser: value => value})

  t->U.assertErrorResult(
    "Hello world!"->S.serializeToUnknownWith(schema),
    {
      code: InvalidOperation({description: "The S.transform serializer is missing"}),
      operation: Serializing,
      path: S.Path.empty,
    },
  )
})

test("Fails to serialize when user raises error in a Transformed Primitive serializer", t => {
  let schema = S.string->S.transform(s => {serializer: _ => s.fail("User error")})

  t->U.assertErrorResult(
    "Hello world!"->S.serializeToUnknownWith(schema),
    {code: OperationFailed("User error"), operation: Serializing, path: S.Path.empty},
  )
})

test("Transform operations applyed in the right order when parsing", t => {
  let schema =
    S.int
    ->S.transform(s => {parser: _ => s.fail("First transform")})
    ->S.transform(s => {parser: _ => s.fail("Second transform")})

  t->U.assertErrorResult(
    123->S.parseAnyWith(schema),
    {code: OperationFailed("First transform"), operation: Parsing, path: S.Path.empty},
  )
})

test("Transform operations applyed in the right order when serializing", t => {
  let schema =
    S.int
    ->S.transform(s => {serializer: _ => s.fail("First transform")})
    ->S.transform(s => {serializer: _ => s.fail("Second transform")})

  t->U.assertErrorResult(
    123->S.serializeToUnknownWith(schema),
    {
      code: OperationFailed("Second transform"),
      operation: Serializing,
      path: S.Path.empty,
    },
  )
})

test(
  "Successfully parses a Transformed Primitive and serializes it back to the initial state",
  t => {
    let any = %raw(`123`)

    let schema = S.int->S.transform(_ => {
      parser: int => int->Int.toFloat,
      serializer: value => value->Int.fromFloat,
    })

    t->Assert.deepEqual(
      any->S.parseAnyWith(schema)->Result.map(object => object->S.serializeToUnknownWith(schema)),
      Ok(Ok(any)),
      (),
    )
  },
)

test("Fails to parse schema with transform having both parser and asyncParser", t => {
  let schema =
    S.string->S.transform(_ => {parser: _ => (), asyncParser: _ => () => Promise.resolve()})

  t->U.assertErrorResult(
    "foo"->S.parseAnyWith(schema),
    {
      code: InvalidOperation({
        description: "The S.transform doesn\'t allow parser and asyncParser at the same time. Remove parser in favor of asyncParser.",
      }),
      operation: Parsing,
      path: S.Path.empty,
    },
  )
})

test("Fails to parse async using parseAnyWith", t => {
  let schema = S.string->S.transform(_ => {asyncParser: value => () => Promise.resolve(value)})

  t->Assert.deepEqual(
    %raw(`"Hello world!"`)->S.parseAnyWith(schema),
    Error(U.error({code: UnexpectedAsync, operation: Parsing, path: S.Path.empty})),
    (),
  )
})

test("Successfully parses with empty transform", t => {
  let schema = S.string->S.transform(_ => {})

  t->Assert.deepEqual(%raw(`"Hello world!"`)->S.parseAnyWith(schema), Ok("Hello world!"), ())
})

test("Successfully serializes with empty transform", t => {
  let schema = S.string->S.transform(_ => {})

  t->Assert.deepEqual(
    "Hello world!"->S.serializeToUnknownWith(schema),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})

asyncTest("Successfully parses async using parseAsyncWith", t => {
  let schema = S.string->S.transform(_ => {asyncParser: value => () => Promise.resolve(value)})

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(schema)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

asyncTest("Fails to parse async with user error", t => {
  let schema = S.string->S.transform(s => {asyncParser: _ => () => s.fail("User error")})

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(schema)
  ->Promise.thenResolve(result => {
    t->U.assertErrorResult(
      result,
      {
        code: OperationFailed("User error"),
        path: S.Path.empty,
        operation: Parsing,
      },
    )
  })
})

asyncTest("Can apply other actions after async transform", t => {
  let schema =
    S.string
    ->S.transform(_ => {asyncParser: value => () => Promise.resolve(value)})
    ->S.String.trim
    ->S.transform(_ => {asyncParser: value => () => Promise.resolve(value)})

  %raw(`"    Hello world!"`)
  ->S.parseAsyncWith(schema)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

test("Compiled parse code snapshot", t => {
  let schema = S.int->S.transform(_ => {
    parser: int => int->Int.toFloat,
    serializer: value => value->Int.fromFloat,
  })

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{if(typeof i!=="number"||i>2147483647||i<-2147483648||i%1!==0){e[1](i)}return e[0](i)}`,
  )
})

test("Compiled async parse code snapshot", t => {
  let schema = S.int->S.transform(_ => {
    asyncParser: int => () => int->Int.toFloat->Promise.resolve,
    serializer: value => value->Int.fromFloat,
  })

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{let v0;if(typeof i!=="number"||i>2147483647||i<-2147483648||i%1!==0){e[1](i)}v0=e[0](i);return v0}`,
  )
})

test("Compiled serialize code snapshot", t => {
  let schema = S.int->S.transform(_ => {
    parser: int => int->Int.toFloat,
    serializer: value => value->Int.fromFloat,
  })

  t->U.assertCompiledCode(~schema, ~op=#serialize, `i=>{return e[0](i)}`)
})
