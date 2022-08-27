open Ava

ava->test("Successfully parses JSON", t => {
  let struct = S.string()

  t->Assert.deepEqual(`"Foo"`->S.parseWith(S.json(struct)), Ok("Foo"), ())
})

ava->test("Fails to parse invalid JSON", t => {
  let struct = S.unknown()

  t->Assert.deepEqual(
    `undefined`->S.parseWith(S.json(struct)),
    Error({
      code: OperationFailed("Unexpected token u in JSON at position 0"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

ava->test("Successfully serializes JSON", t => {
  let struct = S.string()

  t->Assert.deepEqual(`Foo`->S.serializeWith(S.json(struct)), Ok(%raw(`'"Foo"'`)), ())
})

ava->Failing.test("Fails to serialize Option to JSON", t => {
  let struct = S.option(S.unknown())

  t->Assert.deepEqual(None->S.serializeWith(S.json(struct))->Belt.Result.isError, true, ())
})
