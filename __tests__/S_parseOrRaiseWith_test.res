open Ava

ava->test("Successfully parses", t => {
  let struct = S.bool()

  t->Assert.deepEqual(true->S.parseOrRaiseWith(struct), true, ())
})

ava->test("Successfully parses unknown", t => {
  let struct = S.unknown()

  t->Assert.deepEqual(true->S.parseOrRaiseWith(struct), true->Obj.magic, ())
})

ava->test("Fails to parse", t => {
  let struct = S.bool()

  let maybeError = try {
    123->S.parseOrRaiseWith(struct)->ignore
    None
  } catch {
  | S.Raised(error) => Some(error)
  }

  t->Assert.deepEqual(
    maybeError,
    Some({
      code: UnexpectedType({expected: "Bool", received: "Float"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})
