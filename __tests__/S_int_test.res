open Ava

module Common = {
  let value = 123
  let any = %raw(`123`)
  let wrongAny = %raw(`123.45`)
  let factory = () => S.int()

  ava->test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  ava->test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "Int", received: "Float"}),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  ava->test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })
}

ava->test("Fails to parse int when JSON is a number bigger than +2^31", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    %raw(`2147483648`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Int", received: "Float"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
  t->Assert.deepEqual(%raw(`2147483647`)->S.parseWith(struct), Ok(2147483647), ())
})

ava->test("Fails to parse int when JSON is a number lower than -2^31", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    %raw(`-2147483649`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Int", received: "Float"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
  t->Assert.deepEqual(%raw(`-2147483648`)->S.parseWith(struct), Ok(-2147483648), ())
})

ava->test("Fails to parse NaN", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    %raw(`NaN`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Int", received: "NaN Literal (NaN)"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})
