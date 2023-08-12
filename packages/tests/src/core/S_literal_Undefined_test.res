open Ava

module Common = {
  let value = ()
  let invalidValue = %raw(`123`)
  let any = %raw(`undefined`)
  let invalidTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal()

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse invalid type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidTypeAny->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({expected: Undefined, received: invalidTypeAny}),
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
        code: InvalidLiteral({expected: Undefined, received: invalidValue}),
        operation: Serializing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Compiled parse code snapshot", t => {
    let struct = factory()

    t->TestUtils.assertCompiledCode(~struct, ~op=#parse, `i=>{i===void 0||e[0](i);return i}`, ())
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#serialize,
      `i=>{i===void 0||e[0](i);return i}`,
      (),
    )
  })
}
