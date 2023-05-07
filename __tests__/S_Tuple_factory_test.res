open Ava

test("Works", t => {
  let tuple3: (. S.t<'v1>, S.t<'v2>, S.t<'v3>) => S.t<('v1, 'v2, 'v3)> = (. v1, v2, v3) =>
    S.Tuple.factory([v1->S.toUnknown, v2->S.toUnknown, v3->S.toUnknown])->Obj.magic

  let value = ("a", 1, true)
  let any = %raw(`['a', 1, true]`)

  let struct = tuple3(. S.string, S.int, S.bool)

  t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
})
