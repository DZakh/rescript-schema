open Ava

module Common = {
  let value = ("bar", true)
  let invalid = %raw(`123`)
  let factory = () => S.literal(("bar", true))

  test("Successfully parses", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.parseAnyWith(schema), Ok(value), ())
  })

  test("Fails to parse invalid", t => {
    let schema = factory()

    t->U.assertErrorResult(
      invalid->S.parseAnyWith(schema),
      {
        code: InvalidType({
          expected: S.literal(("bar", true))->S.toUnknown,
          received: invalid,
        }),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(schema), Ok(value->U.castAnyToUnknown), ())
  })

  test("Fails to serialize invalid", t => {
    let schema = factory()

    t->U.assertErrorResult(
      invalid->S.serializeToUnknownWith(schema),
      {
        code: InvalidType({
          expected: S.literal(("bar", true))->S.toUnknown,
          received: invalid->U.castAnyToUnknown,
        }),
        operation: SerializeToUnknown,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse array like object", t => {
    let schema = factory()

    t->U.assertErrorResult(
      %raw(`{0: "bar",1:true}`)->S.parseAnyWith(schema),
      {
        code: InvalidType({
          expected: S.literal(("bar", true))->S.toUnknown,
          received: %raw(`{0: "bar",1:true}`),
        }),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse array with excess item", t => {
    let schema = factory()

    t->U.assertErrorResult(
      %raw(`["bar", true, false]`)->S.parseAnyWith(schema),
      {
        code: InvalidType({
          expected: S.literal(("bar", true))->S.toUnknown,
          received: %raw(`["bar", true, false]`),
        }),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Parse,
      `i=>{if(i!==e[0]&&(!Array.isArray(i)||i.length!==2||i[0]!=="bar"||i[1]!==true)){e[1](i)}return i}`,
    )
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Serialize,
      `i=>{if(i!==e[0]&&(!Array.isArray(i)||i.length!==2||i[0]!=="bar"||i[1]!==true)){e[1](i)}return i}`,
    )
  })

  test("Reverse schema to self", t => {
    let schema = factory()

    t->Assert.is(schema->S.reverse, schema->S.toUnknown, ())
  })
}
