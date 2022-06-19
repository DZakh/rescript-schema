open Ava

type recordWithTwoFields = {foo: string, bar: string}

test("Works", t => {
  let record2: (
    ~fields: (S.field<'v1>, S.field<'v2>),
    ~parser: (('v1, 'v2)) => result<'value, string>=?,
    ~serializer: 'value => result<('v1, 'v2), string>=?,
    unit,
  ) => S.t<'value> = S.Record.factory

  let value = {foo: "foofoo", bar: "barbar"}
  let any = %raw(`{foo: "foofoo", bar: "barbar"}`)

  let struct = record2(
    ~fields=(("foo", S.string()), ("bar", S.string())),
    ~parser=((foo, bar)) => {{foo: foo, bar: bar}}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.parseWith(~mode=Unsafe, struct), Ok(value), ())
})
