open Ava

module Common = {
  let value = false
  let invalidValue = %raw(`true`)
  let any = %raw(`false`)
  let invalidAny = %raw(`true`)
  let invalidTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(false)

  test("Successfully parses", t => {
    let schema = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(schema), Ok(value), ())
  })

  test("Fails to parse invalid value", t => {
    let schema = factory()

    t->U.assertErrorResult(
      () => invalidAny->S.parseAnyWith(schema),
      {
        code: InvalidType({expected: S.literal(false)->S.toUnknown, received: true->Obj.magic}),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse invalid type", t => {
    let schema = factory()

    t->U.assertErrorResult(
      () => invalidTypeAny->S.parseAnyWith(schema),
      {
        code: InvalidType({expected: S.literal(false)->S.toUnknown, received: invalidTypeAny}),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.reverseConvertWith(schema), any, ())
  })

  test("Fails to serialize invalid value", t => {
    let schema = factory()

    t->U.assertRaised(
      () => invalidValue->S.reverseConvertWith(schema),
      {
        code: InvalidType({expected: S.literal(false)->S.toUnknown, received: invalidValue}),
        operation: SerializeToUnknown,
        path: S.Path.empty,
      },
    )
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#Parse, `i=>{if(i!==false){e[0](i)}return i}`)
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#Serialize, `i=>{if(i!==false){e[0](i)}return i}`)
  })

  test("Reverse schema to self", t => {
    let schema = factory()
    t->Assert.is(schema->S.reverse, schema->S.toUnknown, ())
  })

  test("Succesfully uses reversed schema for parsing back to initial value", t => {
    let schema = factory()
    t->U.assertReverseParsesBack(schema, false)
  })
}
