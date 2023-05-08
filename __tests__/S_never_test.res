open Ava

module Common = {
  let any = %raw(`true`)
  let factory = () => S.never

  test("Fails to ", t => {
    let struct = factory()

    t->Assert.deepEqual(
      any->S.parseAnyWith(struct),
      Error({
        code: UnexpectedType({expected: "Never", received: "Bool"}),
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
        code: UnexpectedType({expected: "Never", received: "Bool"}),
        operation: Serializing,
        path: S.Path.empty,
      }),
      (),
    )
  })
}

module ObjectField = {
  test("Fails to parse a object with Never field", t => {
    let struct = S.object(o =>
      {
        "key": o.field("key", S.string),
        "oldKey": o.field("oldKey", S.never),
      }
    )

    t->Assert.deepEqual(
      %raw(`{"key":"value"}`)->S.parseAnyWith(struct),
      Error({
        code: UnexpectedType({expected: "Never", received: "Option"}),
        operation: Parsing,
        path: S.Path.fromArray(["oldKey"]),
      }),
      (),
    )
  })

  test("Successfully parses a object with Never field when it's optional and not present", t => {
    let struct = S.object(o =>
      {
        "key": o.field("key", S.string),
        "oldKey": o.field(
          "oldKey",
          S.never->S.deprecate("We stopped using the field from the v0.9.0 release"),
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
