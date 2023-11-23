open Ava

module Common = {
  let value = %raw(`NaN`)
  let invalidValue = %raw(`123`)
  let any = %raw(`NaN`)
  let invalidTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(%raw(`NaN`))

  test("Successfully parses", t => {
    let schema = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(schema), Ok(value), ())
  })

  test("Fails to parse invalid type", t => {
    let schema = factory()

    t->Assert.deepEqual(
      invalidTypeAny->S.parseAnyWith(schema),
      Error(
        U.error({
          code: InvalidLiteral({expected: NaN, received: invalidTypeAny}),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(schema), Ok(any), ())
  })

  test("Fails to serialize invalid value", t => {
    let schema = factory()

    t->Assert.deepEqual(
      invalidValue->S.serializeToUnknownWith(schema),
      Error(
        U.error({
          code: InvalidLiteral({expected: NaN, received: invalidValue}),
          operation: Serializing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#parse, `i=>{Number.isNaN(i)||e[0](i);return i}`)
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#serialize, `i=>{Number.isNaN(i)||e[0](i);return i}`)
  })
}
