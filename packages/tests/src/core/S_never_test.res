open Ava

module Common = {
  let any = %raw(`true`)
  let factory = () => S.never

  test("Fails to ", t => {
    let schema = factory()

    t->U.assertErrorResult(
      any->S.parseAnyWith(schema),
      {
        code: InvalidType({expected: S.never->S.toUnknown, received: any}),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to serialize ", t => {
    let schema = factory()

    t->U.assertErrorResult(
      any->S.serializeToUnknownWith(schema),
      {
        code: InvalidType({expected: schema->S.toUnknown, received: any}),
        operation: SerializeToUnknown,
        path: S.Path.empty,
      },
    )
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#parse, `i=>{e[0](i);return i}`)
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(~schema, ~op=#serialize, `i=>{e[0](i);return i}`)
  })
}

module ObjectField = {
  test("Fails to parse a object with Never field", t => {
    let schema = S.object(s =>
      {
        "key": s.field("key", S.string),
        "oldKey": s.field("oldKey", S.never),
      }
    )

    t->U.assertErrorResult(
      %raw(`{"key":"value"}`)->S.parseAnyWith(schema),
      {
        code: InvalidType({expected: S.never->S.toUnknown, received: %raw(`undefined`)}),
        operation: Parse,
        path: S.Path.fromArray(["oldKey"]),
      },
    )
  })

  test("Successfully parses a object with Never field when it's optional and not present", t => {
    let schema = S.object(s =>
      {
        "key": s.field("key", S.string),
        "oldKey": s.field(
          "oldKey",
          S.never->S.option->S.deprecate("We stopped using the field from the v0.9.0 release"),
        ),
      }
    )

    t->Assert.deepEqual(
      %raw(`{"key":"value"}`)->S.parseAnyWith(schema),
      Ok({
        "key": "value",
        "oldKey": None,
      }),
      (),
    )
  })
}
