open Ava

test("Works", t => {
  let record3: (
    . S.field<'v1>,
    S.field<'v2>,
    S.field<'v3>,
  ) => S.t<('v1, 'v2, 'v3)> = S.Record.factory

  let value = ("foofoo", "barbar", false)
  let any = %raw(`{foo: "foofoo", bar: "barbar", "bool": false}`)

  let struct = record3(. ("foo", S.string()), ("bar", S.string()), ("bool", S.bool()))

  t->Assert.deepEqual(any->S.parseWith(~mode=Migration, struct), Ok(value), ())
})
