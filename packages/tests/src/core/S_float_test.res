open Ava

module Common = {
  let value = 123.
  let any = %raw(`123`)
  let invalidAny = %raw(`"Hello world!"`)
  let factory = () => S.float

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidAny->S.parseAnyWith(struct),
      Error(
        U.error({
          code: InvalidType({expected: struct->S.toUnknown, received: invalidAny}),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(struct), Ok(any), ())
  })

  test("Compiled parse code snapshot", t => {
    let struct = factory()

    t->U.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{if(typeof i!=="number"||Number.isNaN(i)){e[0](i)}return i}`,
      (),
    )
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    t->U.assertCompiledCodeIsNoop(~struct, ~op=#serialize, ())
  })
}

test("Successfully parses number with a fractional part", t => {
  let struct = S.float

  t->Assert.deepEqual(%raw(`123.123`)->S.parseAnyWith(struct), Ok(123.123), ())
})

test("Fails to parse NaN", t => {
  let struct = S.float

  t->Assert.deepEqual(
    %raw(`NaN`)->S.parseAnyWith(struct),
    Error(
      U.error({
        code: InvalidType({expected: struct->S.toUnknown, received: %raw(`NaN`)}),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})
