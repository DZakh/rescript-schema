open Ava

test("Successfully serializes", t => {
  let schema = S.bool

  t->Assert.deepEqual(true->S.serializeOrRaiseWith(schema), true->Obj.magic, ())
})

test("Fails to serialize", t => {
  let schema = S.bool->S.refine(s => _ => s.fail("User error"))

  let maybeError = try {
    true->S.serializeOrRaiseWith(schema)->ignore
    None
  } catch {
  | S.Raised(error) => Some(error)
  }

  t->Assert.deepEqual(
    maybeError,
    Some(
      U.error({
        code: OperationFailed("User error"),
        operation: SerializeToJson,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})
