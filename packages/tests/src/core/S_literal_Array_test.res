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
        code: InvalidLiteral({
          expected: S.Literal.parse(("bar", true)),
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
        code: InvalidLiteral({
          expected: S.Literal.parse(("bar", true)),
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
        code: InvalidLiteral({
          expected: S.Literal.parse(("bar", true)),
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
        code: InvalidLiteral({
          expected: S.Literal.parse(("bar", true)),
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
}
