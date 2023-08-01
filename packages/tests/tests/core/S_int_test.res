open Ava

module Common = {
  let value = 123
  let any = %raw(`123`)
  let invalidAny = %raw(`123.45`)
  let factory = () => S.int

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidAny->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: struct->S.toUnknown, received: invalidAny}),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(struct), Ok(any), ())
  })

  test("Compiled parse code snapshot", t => {
    let struct = factory()

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{if(!(typeof i==="number"&&i<2147483648&&i>-2147483649&&i%1===0)){e[0](i)}return i}`,
      (),
    )
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    t->TestUtils.assertCompiledCodeIsNoop(~struct, ~op=#serialize,  ())
  })
}

test("Fails to parse int when JSON is a number bigger than +2^31", t => {
  let struct = S.int

  t->Assert.deepEqual(
    %raw(`2147483648`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: struct->S.toUnknown, received: %raw(`2147483648`)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
  t->Assert.deepEqual(%raw(`2147483647`)->S.parseAnyWith(struct), Ok(2147483647), ())
})

test("Fails to parse int when JSON is a number lower than -2^31", t => {
  let struct = S.int

  t->Assert.deepEqual(
    %raw(`-2147483649`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: struct->S.toUnknown, received: %raw(`-2147483649`)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
  t->Assert.deepEqual(%raw(`-2147483648`)->S.parseAnyWith(struct), Ok(-2147483648), ())
})

test("Fails to parse NaN", t => {
  let struct = S.int

  t->Assert.deepEqual(
    %raw(`NaN`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: struct->S.toUnknown, received: %raw(`NaN`)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
