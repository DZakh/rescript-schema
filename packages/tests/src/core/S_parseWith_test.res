open Ava
open RescriptCore

test("Successfully parses", t => {
  let schema = S.bool

  t->Assert.deepEqual(JSON.Encode.bool(true)->S.parseWith(schema), Ok(true), ())
})

test("Successfully parses unknown", t => {
  let schema = S.unknown

  t->Assert.deepEqual(JSON.Encode.bool(true)->S.parseWith(schema), Ok(true->Obj.magic), ())
})

test("Fails to parse", t => {
  let schema = S.bool

  t->U.assertErrorResult(
    () => %raw("123")->S.parseWith(schema),
    {
      code: InvalidType({expected: schema->S.toUnknown, received: %raw("123")}),
      operation: Parse,
      path: S.Path.empty,
    },
  )
})

test("Fails to parse with unwraped result", t => {
  let schema = S.bool

  t->Assert.throws(() => {
    %raw("123")->S.parseWith(schema)->S.unwrap
  }, ~expectations={message: "Failed parsing at root. Reason: Expected Bool, received 123"}, ())
})
