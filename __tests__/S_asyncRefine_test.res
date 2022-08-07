open Ava

test("Fails to parse using parseWith", t => {
  let struct = S.string()->S.asyncRefine(~parser=_ => None->Js.Promise.resolve, ())

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
  let struct = S.string()->S.asyncRefine(~parser=_ => None->Js.Promise.resolve, ())

  %raw(`"Hello world!"`)->S.parseAsyncWith(struct)->Belt.Result.getExn
    |> Js.Promise.then_(result => {
      t->Assert.deepEqual(result, Ok("Hello world!"), ())
      Js.Promise.resolve()
    })
})

asyncTest("Fails to parse with user error", t => {
  let struct = S.string()->S.asyncRefine(~parser=_ => Some("User error")->Js.Promise.resolve, ())

  %raw(`"Hello world!"`)->S.parseAsyncWith(struct)->Belt.Result.getExn
    |> Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("User error"),
          path: [],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    })
})

asyncTest("Can apply other actions after asyncRefine", t => {
  let struct =
    S.string()
    ->S.asyncRefine(~parser=_ => None->Js.Promise.resolve, ())
    ->S.String.trimmed()
    ->S.asyncRefine(~parser=_ => None->Js.Promise.resolve, ())

  %raw(`"    Hello world!"`)->S.parseAsyncWith(struct)->Belt.Result.getExn
    |> Js.Promise.then_(result => {
      t->Assert.deepEqual(result, Ok("Hello world!"), ())
      Js.Promise.resolve()
    })
})
