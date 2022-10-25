open Ava

test("Successfully serializes", t => {
  let struct = S.bool()

  t->Assert.deepEqual(true->S.serializeOrRaiseWith(struct), true->Obj.magic, ())
})

test("Fails to serialize", t => {
  let struct = S.bool()->S.refine(~serializer=_ => S.Error.raise("User error"), ())

  let maybeError = try {
    true->S.serializeOrRaiseWith(struct)->ignore
    None
  } catch {
  | S.Raised(error) => Some(error)
  }

  t->Assert.deepEqual(
    maybeError,
    Some({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})
