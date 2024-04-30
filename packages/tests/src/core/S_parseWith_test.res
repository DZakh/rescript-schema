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
    %raw("123")->S.parseWith(schema),
    {
      code: InvalidType({expected: schema->S.toUnknown, received: %raw("123")}),
      operation: Parsing,
      path: S.Path.empty,
    },
  )
})
