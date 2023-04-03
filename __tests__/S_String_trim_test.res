open Ava

test("Successfully parses", t => {
  let struct = S.string()->S.String.trim()

  t->Assert.deepEqual("   Hello world!"->S.parseAnyWith(struct), Ok("Hello world!"), ())
})

test("Successfully serializes", t => {
  let struct = S.string()->S.String.trim()

  t->Assert.deepEqual(
    "   Hello world!"->S.serializeToUnknownWith(struct),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})
