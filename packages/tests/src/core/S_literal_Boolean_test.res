open Ava

module Common = {
  let value = false
  let invalidValue = %raw(`true`)
  let any = %raw(`false`)
  let invalidAny = %raw(`true`)
  let invalidTypeAny = %raw(`"Hello world!"`)
  let factory = () => S.literal(false)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse invalid value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidAny->S.parseAnyWith(struct),
      Error(
        U.error({
          code: InvalidLiteral({expected: Boolean(false), received: true->Obj.magic}),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Fails to parse invalid type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidTypeAny->S.parseAnyWith(struct),
      Error(
        U.error({
          code: InvalidLiteral({expected: Boolean(false), received: invalidTypeAny}),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ),
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
      Error(
        U.error({
          code: InvalidLiteral({expected: Boolean(false), received: invalidValue}),
          operation: Serializing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Compiled parse code snapshot", t => {
    let struct = factory()

    t->U.assertCompiledCode(~struct, ~op=#parse, `i=>{i===e[0]||e[1](i);return i}`)
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    t->U.assertCompiledCode(~struct, ~op=#serialize, `i=>{i===e[0]||e[1](i);return i}`)
  })
}
