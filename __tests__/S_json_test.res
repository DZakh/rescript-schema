open Ava

test("Successfully parses JSON in Safe mode", t => {
  let struct = S.string()

  t->Assert.deepEqual(`"Foo"`->S.parseWith(S.json(struct)), Ok("Foo"), ())
})

test("Successfully parses JSON without validation in Migration mode", t => {
  let struct = S.string()

  t->Assert.deepEqual(`123`->S.parseWith(~mode=Migration, S.json(struct)), Ok(%raw(`123`)), ())
})

test("Fails to parse invalid JSON in Safe mode", t => {
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

test("Fails to parse invalid JSON in Migration mode", t => {
  let struct = S.unknown()

  t->Assert.deepEqual(
    `undefined`->S.parseWith(~mode=Migration, S.json(struct)),
    Error({
      code: OperationFailed("Unexpected token u in JSON at position 0"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully serializes JSON", t => {
  let struct = S.string()

  t->Assert.deepEqual(`Foo`->S.serializeWith(S.json(struct)), Ok(%raw(`'"Foo"'`)), ())
})

failing("Fails to serialize Option to JSON", t => {
  let struct = S.option(S.unknown())

  t->Assert.deepEqual(None->S.serializeWith(S.json(struct))->Belt.Result.isError, true, ())
})
