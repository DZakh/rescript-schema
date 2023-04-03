open Ava

test("Successfully parses valid data", t => {
  let struct = S.string()->S.String.pattern(%re(`/[0-9]/`))

  t->Assert.deepEqual("123"->S.parseAnyWith(struct), Ok("123"), ())
})

test("Fails to parse invalid data", t => {
  let struct = S.string()->S.String.pattern(%re(`/[0-9]/`))

  t->Assert.deepEqual(
    "abc"->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Invalid"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.string()->S.String.pattern(%re(`/[0-9]/`))

  t->Assert.deepEqual("123"->S.serializeToUnknownWith(struct), Ok(%raw(`"123"`)), ())
})

test("Fails to serialize invalid value", t => {
  let struct = S.string()->S.String.pattern(%re(`/[0-9]/`))

  t->Assert.deepEqual(
    "abc"->S.serializeToUnknownWith(struct),
    Error({
      code: OperationFailed("Invalid"),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Returns custom error message", t => {
  let struct = S.string()->S.String.pattern(~message="Custom", %re(`/[0-9]/`))

  t->Assert.deepEqual(
    "abc"->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Returns refinement", t => {
  let struct = S.string()->S.String.pattern(%re(`/[0-9]/`))

  t->Assert.deepEqual(
    struct->S.String.refinements,
    [{kind: Pattern({re: %re(`/[0-9]/`)}), message: "Invalid"}],
    (),
  )
})

test("Returns multiple refinement", t => {
  let struct1 = S.string()
  let struct2 = struct1->S.String.pattern(~message="Should have digit", %re(`/[0-9]+/`))
  let struct3 = struct2->S.String.pattern(~message="Should have text", %re(`/\w+/`))

  t->Assert.deepEqual(struct1->S.String.refinements, [], ())
  t->Assert.deepEqual(
    struct2->S.String.refinements,
    [{kind: Pattern({re: %re(`/[0-9]+/`)}), message: "Should have digit"}],
    (),
  )
  t->Assert.deepEqual(
    struct3->S.String.refinements,
    [
      {kind: Pattern({re: %re(`/[0-9]+/`)}), message: "Should have digit"},
      {kind: Pattern({re: %re(`/\w+/`)}), message: "Should have text"},
    ],
    (),
  )
})
