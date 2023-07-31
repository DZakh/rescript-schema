open Ava

module Common = {
  let value = 123.
  let invalidValue = %raw(`444.`)
  let any = %raw(`123`)
  let invalidAny = %raw(`444`)
  let invalidTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(123.)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse invalid value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidAny->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({expected: Number(123.), received: 444.->Obj.magic}),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to parse invalid type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidTypeAny->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({expected: Number(123.), received: invalidTypeAny}),
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

  test("Fails to serialize invalid value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidValue->S.serializeToUnknownWith(struct),
      Error({
        code: InvalidLiteral({expected: Number(123.), received: invalidValue}),
        operation: Serializing,
        path: S.Path.empty,
      }),
      (),
    )
  })
}

test("Formatting of negative number with a decimal point in an error message", t => {
  let struct = S.literal(-123.567)

  t->Assert.deepEqual(
    %raw(`"foo"`)->S.parseAnyWith(struct),
    Error({
      code: InvalidLiteral({expected: Number(-123.567), received: "foo"->Obj.magic}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
