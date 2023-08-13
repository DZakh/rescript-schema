open Ava

test("Doesn't affect Ok value", t => {
  t->Assert.deepEqual(Ok("value")->S.Result.mapErrorToString, Ok("value"), ())
})

test("Maps the S.Error.t to text", t => {
  t->Assert.deepEqual(
    Error(
      U.error({
        code: OperationFailed("Should be positive"),
        operation: Parsing,
        path: S.Path.empty,
      }),
    )->S.Result.mapErrorToString,
    Error("Failed parsing at root. Reason: Should be positive"),
    (),
  )
})
