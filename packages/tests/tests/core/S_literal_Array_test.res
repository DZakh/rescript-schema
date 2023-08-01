open Ava

module Common = {
  let value = ("bar", true)
  let invalid = %raw(`123`)
  let factory = () => S.literal(("bar", true))

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse invalid", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalid->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({
          expected: Array([String("bar"), Boolean(true)]),
          received: invalid,
        }),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(
      value->S.serializeToUnknownWith(struct),
      Ok(value->TestUtils.castAnyToUnknown),
      (),
    )
  })

  test("Fails to serialize invalid", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalid->S.serializeToUnknownWith(struct),
      Error({
        code: InvalidLiteral({
          expected: Array([String("bar"), Boolean(true)]),
          received: invalid->TestUtils.castAnyToUnknown,
        }),
        operation: Serializing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to parse array like object", t => {
    let struct = factory()

    t->Assert.deepEqual(
      %raw(`{0: "bar",1:true}`)->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({
          expected: Array([String("bar"), Boolean(true)]),
          received: %raw(`{0: "bar",1:true}`),
        }),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to parse array with excess item", t => {
    let struct = factory()

    t->Assert.deepEqual(
      %raw(`["bar", true, false]`)->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({
          expected: Array([String("bar"), Boolean(true)]),
          received: %raw(`["bar", true, false]`),
        }),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Compiled parse code snapshot", t => {
    let struct = factory()

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{(i===e[0]||Array.isArray(i)&&i.length===2&&i[0]===e[1]&&i[1]===e[2])||e[3](i);return i}`,
      (),
    )
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#serialize,
      `i=>{(i===e[0]||Array.isArray(i)&&i.length===2&&i[0]===e[1]&&i[1]===e[2])||e[3](i);return i}`,
      (),
    )
  })
}
