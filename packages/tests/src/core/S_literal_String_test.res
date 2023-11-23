open Ava

module Common = {
  let value = "ReScript is Great!"
  let invalidValue = "Hello world!"
  let any = %raw(`"ReScript is Great!"`)
  let invalidAny = %raw(`"Hello world!"`)
  let invalidTypeAny = %raw(`true`)
  let factory = () => S.literal("ReScript is Great!")

  test("Successfully parses", t => {
    let schema = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(schema), Ok(value), ())
  })

  test("Fails to parse invalid value", t => {
    let schema = factory()

    t->Assert.deepEqual(
      invalidAny->S.parseAnyWith(schema),
      Error(
        U.error({
          code: InvalidLiteral({
            expected: String("ReScript is Great!"),
            received: "Hello world!"->Obj.magic,
          }),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Fails to parse invalid type", t => {
    let schema = factory()

    t->Assert.deepEqual(
      invalidTypeAny->S.parseAnyWith(schema),
      Error(
        U.error({
          code: InvalidLiteral({
            expected: String("ReScript is Great!"),
            received: invalidTypeAny,
          }),
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
          code: InvalidLiteral({
            expected: String("ReScript is Great!"),
            received: "Hello world!"->Obj.magic,
          }),
          operation: Serializing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#parse, `i=>{i===e[0]||e[1](i);return i}`)
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#serialize, `i=>{i===e[0]||e[1](i);return i}`)
  })
}
