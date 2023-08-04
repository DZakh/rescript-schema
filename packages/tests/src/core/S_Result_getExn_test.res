open Ava

test("Gets value with Ok", t => {
  t->Assert.is(Ok("value")->S.Result.getExn, "value", ())
})

test("Throws an Error with Error", t => {
  t->Assert.throws(
    () => {
      Error({
        code: OperationFailed("Should be positive"),
        operation: Parsing,
        path: S.Path.empty,
      })->S.Result.getExn
    },
    ~expectations={
      name: "Error",
      message: "[rescript-struct] Failed parsing at root. Reason: Should be positive",
    },
    (),
  )
})
