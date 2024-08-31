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

    t->U.assertErrorResult(
      invalidTypeAny->S.parseAnyWith(schema),
      {
        code: InvalidType({
          expected: S.literal(%raw(`null`))->S.toUnknown,
          received: invalidTypeAny,
        }),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(schema), Ok(any), ())
  })

  test("Fails to serialize invalid value", t => {
    let schema = factory()

    t->U.assertErrorResult(
      invalidValue->S.serializeToUnknownWith(schema),
      {
        code: InvalidType({expected: S.literal(%raw(`null`))->S.toUnknown, received: invalidValue}),
        operation: SerializeToUnknown,
        path: S.Path.empty,
      },
    )
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#Parse, `i=>{if(i!==null){e[0](i)}return i}`)
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#Serialize, `i=>{if(i!==null){e[0](i)}return i}`)
  })

  test("Reverse schema to self", t => {
    let schema = factory()

    t->Assert.is(schema->S.reverse, schema->S.toUnknown, ())
  })
}
