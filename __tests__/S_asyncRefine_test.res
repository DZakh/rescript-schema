open Ava

test("Fails to parse using parseWith", t => {
  let struct = S.string()->S.asyncRefine(~parser=_ => None->Promise.resolve, ())

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

asyncTest("Successfully parses using parseAsyncWith", t => {
  let struct = S.string()->S.asyncRefine(~parser=_ => None->Promise.resolve, ())

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Belt.Result.getExn
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

asyncTest("Fails to parse with user error", t => {
  let struct = S.string()->S.asyncRefine(~parser=_ => Some("User error")->Promise.resolve, ())

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Belt.Result.getExn
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

asyncTest("Can apply other actions after asyncRefine", t => {
  let struct =
    S.string()
    ->S.asyncRefine(~parser=_ => None->Promise.resolve, ())
    ->S.String.trimmed()
    ->S.asyncRefine(~parser=_ => None->Promise.resolve, ())

  %raw(`"    Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Belt.Result.getExn
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})
