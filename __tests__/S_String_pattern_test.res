open Ava

ava->test("Successfully parses valid data", t => {
  let struct = S.string()->S.String.pattern(%re(`/[0-9]/`))

  t->Assert.deepEqual("123"->S.parseWith(struct), Ok("123"), ())
})

ava->test("Fails to parse invalid data", t => {
  let struct = S.string()->S.String.pattern(%re(`/[0-9]/`))

  t->Assert.deepEqual(
    "abc"->S.parseWith(struct),
    Error({
      code: OperationFailed("Invalid"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

ava->test("Successfully serializes valid value", t => {
  let struct = S.string()->S.String.pattern(%re(`/[0-9]/`))

  t->Assert.deepEqual("123"->S.serializeWith(struct), Ok(%raw(`"123"`)), ())
})

ava->test("Fails to serialize invalid value", t => {
  let struct = S.string()->S.String.pattern(%re(`/[0-9]/`))

  t->Assert.deepEqual(
    "abc"->S.serializeWith(struct),
    Error({
      code: OperationFailed("Invalid"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

ava->test("Returns custom error message", t => {
  let struct = S.string()->S.String.pattern(~message="Custom", %re(`/[0-9]/`))

  t->Assert.deepEqual(
    "abc"->S.parseWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})
