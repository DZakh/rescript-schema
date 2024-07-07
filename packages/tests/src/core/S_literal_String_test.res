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

    t->U.assertErrorResult(
      invalidAny->S.parseAnyWith(schema),
      {
        code: InvalidLiteral({
          expected: S.Literal.parse("ReScript is Great!"),
          received: "Hello world!"->Obj.magic,
        }),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse invalid type", t => {
    let schema = factory()

    t->U.assertErrorResult(
      invalidTypeAny->S.parseAnyWith(schema),
      {
        code: InvalidLiteral({
          expected: S.Literal.parse("ReScript is Great!"),
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
        code: InvalidLiteral({
          expected: S.Literal.parse("ReScript is Great!"),
          received: "Hello world!"->Obj.magic,
        }),
        operation: SerializeToUnknown,
        path: S.Path.empty,
      },
    )
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#Parse, `i=>{i==="ReScript is Great!"||e[0](i);return i}`)
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Serialize,
      `i=>{i==="ReScript is Great!"||e[0](i);return i}`,
    )
  })
}
