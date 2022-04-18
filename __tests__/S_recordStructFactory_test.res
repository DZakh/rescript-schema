open Ava

external unsafeToUnknown: 'unknown => Js.Json.t = "%identity"

type recordWithTwoFields = {foo: string, bar: string}

test("Works", t => {
  let record2: (
    ~fields: (S.field<'v1>, S.field<'v2>),
    ~constructor: (('v1, 'v2)) => result<'value, string>=?,
    ~destructor: 'value => result<('v1, 'v2), string>=?,
    unit,
  ) => S.t<'value> = S.Record.factory

  let record = {foo: "foofoo", bar: "barbar"}
  let unknownRecord = record->unsafeToUnknown
  let struct = record2(
    ~fields=(("foo", S.string()), ("bar", S.string())),
    ~constructor=((foo, bar)) => {{foo: foo, bar: bar}}->Ok,
    (),
  )

  t->Assert.deepEqual(struct->S.construct(unknownRecord), Ok(record), ())
})
