open Ava

test("Successfully parses", t => {
  let schema = S.bool

  t->Assert.deepEqual(true->S.parseAnyOrRaiseWith(schema), true, ())
})

test("Successfully parses unknown", t => {
  let schema = S.unknown

  t->Assert.deepEqual(true->S.parseAnyOrRaiseWith(schema), true->Obj.magic, ())
})

test("Fails to parse", t => {
  let schema = S.bool

  let maybeError = try {
    123->S.parseAnyOrRaiseWith(schema)->ignore
    None
  } catch {
  | S.Raised(error) => Some(error)
  }

  t->Assert.deepEqual(
    maybeError,
    Some(
      U.error({
        code: InvalidType({expected: schema->S.toUnknown, received: Obj.magic(123)}),
        operation: Parse,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})
