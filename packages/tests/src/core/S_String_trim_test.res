open Ava

test("Successfully parses", t => {
  let schema = S.string->S.String.trim

  t->Assert.deepEqual("   Hello world!"->S.parseAnyWith(schema), Ok("Hello world!"), ())
})

test("Successfully serializes", t => {
  let schema = S.string->S.String.trim

  t->Assert.deepEqual(
    "   Hello world!"->S.serializeToUnknownWith(schema),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})
