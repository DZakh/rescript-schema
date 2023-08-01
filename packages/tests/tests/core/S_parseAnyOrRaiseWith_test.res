open Ava

test("Successfully parses", t => {
  let struct = S.bool

  t->Assert.deepEqual(true->S.parseAnyOrRaiseWith(struct), true, ())
})

test("Successfully parses unknown", t => {
  let struct = S.unknown

  t->Assert.deepEqual(true->S.parseAnyOrRaiseWith(struct), true->Obj.magic, ())
})

test("Fails to parse", t => {
  let struct = S.bool

  let maybeError = try {
    123->S.parseAnyOrRaiseWith(struct)->ignore
    None
  } catch {
  | S.Raised(error) => Some(error)
  }

  t->Assert.deepEqual(
    maybeError,
    Some({
      code: InvalidType({expected: struct->S.toUnknown, received: Obj.magic(123)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
