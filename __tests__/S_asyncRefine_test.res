open Ava

ava->test("Fails to parse using parseWith", t => {
  let struct = S.string()->S.asyncRefine(~parser=_ => Promise.resolve(), ())

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

ava->asyncTest("Successfully parses using parseAsyncWith", t => {
  let struct = S.string()->S.asyncRefine(~parser=_ => Promise.resolve(), ())

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

ava->asyncTest("Fails to parse with user error", t => {
  let struct =
    S.string()->S.asyncRefine(
      ~parser=_ => Promise.resolve()->Promise.then(() => S.Error.raise("User error")),
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

ava->asyncTest("Can apply other actions after asyncRefine", t => {
  let struct =
    S.string()
    ->S.asyncRefine(~parser=_ => Promise.resolve(), ())
    ->S.String.trimmed()
    ->S.asyncRefine(~parser=_ => Promise.resolve(), ())

  %raw(`"    Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})
