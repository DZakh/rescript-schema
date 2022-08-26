open Ava

module Common = {
  let value = Js.Date.fromFloat(1656245105821.)
  let any = %raw(`new Date(1656245105821.)`)
  let wrongAny = %raw(`"Hello world!"`)
  let factory = () => S.date()

  test("Successfully parses ", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Fails to ", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "Date", received: "String"}),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })
}

test("Fails to parse Date with invalid time", t => {
  let struct = S.date()

  t->Assert.deepEqual(
    %raw("new Date('invalid')")->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Date", received: "Object"}),
      path: [],
      operation: Parsing,
    }),
    (),
  )
})
