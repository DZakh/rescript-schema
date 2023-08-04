open Ava

module Common = {
  let any = %raw(`true`)
  let factory = () => S.never

  test("Fails to ", t => {
    let struct = factory()

    t->Assert.deepEqual(
      any->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: S.never->S.toUnknown, received: any}),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to serialize ", t => {
    let struct = factory()

    t->Assert.deepEqual(
      any->S.serializeToUnknownWith(struct),
      Error({
        code: InvalidType({expected: struct->S.toUnknown, received: any}),
        operation: Serializing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Compiled parse code snapshot", t => {
    let struct = factory()

    t->TestUtils.assertCompiledCode(~struct, ~op=#parse, `i=>{e[0](i);return i}`, ())
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    t->TestUtils.assertCompiledCode(~struct, ~op=#serialize, `i=>{e[0](i);return i}`, ())
  })
}

module ObjectField = {
  test("Fails to parse a object with Never field", t => {
    let struct = S.object(s =>
      {
        "key": s.field("key", S.string),
        "oldKey": s.field("oldKey", S.never),
      }
    )

    t->Assert.deepEqual(
      %raw(`{"key":"value"}`)->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: S.never->S.toUnknown, received: %raw(`undefined`)}),
        operation: Parsing,
        path: S.Path.fromArray(["oldKey"]),
      }),
      (),
    )
  })

  test("Successfully parses a object with Never field when it's optional and not present", t => {
    let struct = S.object(s =>
      {
        "key": s.field("key", S.string),
        "oldKey": s.field(
          "oldKey",
          S.never->S.option->S.deprecate("We stopped using the field from the v0.9.0 release"),
        ),
      }
    )

    t->Assert.deepEqual(
      %raw(`{"key":"value"}`)->S.parseAnyWith(struct),
      Ok({
        "key": "value",
        "oldKey": None,
      }),
      (),
    )
  })
}
