open Ava

type recordWithTwoFields = {foo: string, bar: string}

test("Works", t => {
  let record2: (
    ~fields: (S.field<'v1>, S.field<'v2>),
    ~constructor: (('v1, 'v2)) => result<'value, string>=?,
    ~destructor: 'value => result<('v1, 'v2), string>=?,
    unit,
  ) => S.t<'value> = S.Record.factory

  let value = {foo: "foofoo", bar: "barbar"}
  let any = %raw(`{foo: "foofoo", bar: "barbar"}`)

  let struct = record2(
    ~fields=(("foo", S.string()), ("bar", S.string())),
    ~constructor=((foo, bar)) => {{foo: foo, bar: bar}}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
})
