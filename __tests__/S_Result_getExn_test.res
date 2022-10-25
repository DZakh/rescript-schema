open Ava

test("Gets value with Ok", t => {
  t->Assert.is(Ok("value")->S.Result.getExn, "value", ())
})

test("Throws an Error with Error", t => {
  t->Assert.throws(() => {
    Error({
      code: OperationFailed("Should be positive"),
      operation: Parsing,
      path: [],
    })->S.Result.getExn
  }, ~expectations=ThrowsException.make(
    ~name="Error",
    ~message=String("[rescript-struct] Failed parsing at root. Reason: Should be positive"),
    (),
  ), ())
})
