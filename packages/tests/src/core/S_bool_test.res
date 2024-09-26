open Ava
open RescriptCore

module Common = {
  let value = true
  let any = %raw(`true`)
  let invalidAny = %raw(`"Hello world!"`)
  let factory = () => S.bool

  test("Successfully parses", t => {
    let schema = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(schema), Ok(value), ())
  })

  test("Fails to parse ", t => {
    let schema = factory()

    t->U.assertErrorResult(
      invalidAny->S.parseAnyWith(schema),
      {
        code: InvalidType({expected: schema->S.toUnknown, received: invalidAny}),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(schema), Ok(any), ())
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#Parse, `i=>{if(typeof i!=="boolean"){e[0](i)}return i}`)
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCodeIsNoop(~schema, ~op=#Serialize)
  })

  test("Reverse schema to self", t => {
    let schema = factory()
    t->Assert.is(schema->S.\"~experimentalReverse", schema->S.toUnknown, ())
  })

  test("Succesfully uses reversed schema for parsing back to initial value", t => {
    let schema = factory()
    t->U.assertReverseParsesBack(schema, true)
  })
}

test("Parses bool when JSON is true", t => {
  let schema = S.bool

  t->Assert.deepEqual(JSON.Encode.bool(true)->S.parseAnyWith(schema), Ok(true), ())
})

test("Parses bool when JSON is false", t => {
  let schema = S.bool

  t->Assert.deepEqual(JSON.Encode.bool(false)->S.parseAnyWith(schema), Ok(false), ())
})
