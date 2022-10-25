open Ava

module Common = {
  let value = 123.
  let any = %raw(`123`)
  let wrongAny = %raw(`"Hello world!"`)
  let factory = () => S.float()

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "Float", received: "String"}),
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

test("Successfully parses number with a fractional part", t => {
  let struct = S.float()

  t->Assert.deepEqual(%raw(`123.123`)->S.parseWith(struct), Ok(123.123), ())
})

test("Fails to parse NaN", t => {
  let struct = S.float()

  t->Assert.deepEqual(
    %raw(`NaN`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Float", received: "NaN Literal (NaN)"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})
