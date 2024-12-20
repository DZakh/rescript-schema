open Ava

test(
  "Raised error is instance of RescriptSchemaError and displayed with a nice error message when not caught",
  t => {
    t->Assert.throws(
      () => {
        S.Error.make(
          ~code=OperationFailed("Should be positive"),
          ~flag=S.Flag.typeValidation,
          ~path=S.Path.empty,
        )->S.Error.raise
      },
      ~expectations={
        message: "Failed parsing at root. Reason: Should be positive",
        instanceOf: S.Error.class->(U.magic: S.Error.class => ThrowsExpectation.instanceOf),
      },
      (),
    )
  },
)

test("Raised error is also the S.Raised exeption and can be caught with catch", t => {
  let error = S.Error.make(
    ~code=OperationFailed("Should be positive"),
    ~flag=S.Flag.typeValidation,
    ~path=S.Path.empty,
  )
  t->ExecutionContext.plan(1)
  try {
    let _ = S.Error.raise(error)
    t->Assert.fail("Should raise before the line")
  } catch {
  | S.Raised(raisedError) => t->Assert.is(error, raisedError, ())
  }
})
