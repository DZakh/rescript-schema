open Ava
open RescriptCore

module Common = {
  let value = Null.null
  let invalidValue = %raw(`123`)
  let any = %raw(`null`)
  let invalidTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(Null.null)

  test("Successfully parses", t => {
    let schema = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(schema), Ok(value), ())
  })

  test("Fails to parse invalid type", t => {
    let schema = factory()

    t->U.assertErrorResult(invalidTypeAny->S.parseAnyWith(schema), {
          code: InvalidLiteral({expected: S.Literal.parse(%raw(`null`)), received: invalidTypeAny}),
          operation: Parsing,
          path: S.Path.empty,
        })
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(schema), Ok(any), ())
  })

  test("Fails to serialize invalid value", t => {
    let schema = factory()

    t->U.assertErrorResult(invalidValue->S.serializeToUnknownWith(schema), {
          code: InvalidLiteral({expected: S.Literal.parse(%raw(`null`)), received: invalidValue}),
          operation: Serializing,
          path: S.Path.empty,
        })
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#parse, `i=>{i===null||e[0](i);return i}`)
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#serialize, `i=>{i===null||e[0](i);return i}`)
  })
}
