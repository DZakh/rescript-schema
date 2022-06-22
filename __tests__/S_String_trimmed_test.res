open Ava

test("Successfully parses", t => {
  let struct = S.string()->S.String.trimmed()

  t->Assert.deepEqual("   Hello world!"->S.parseWith(struct), Ok("Hello world!"), ())
})

test("Successfully serializes", t => {
  let struct = S.string()->S.String.trimmed()

  t->Assert.deepEqual("   Hello world!"->S.serializeWith(struct), Ok(%raw(`"Hello world!"`)), ())
})
