open Ava

module Common = {
  let any = %raw(`true`)
  let factory = () => S.never()

  ava->test("Fails to ", t => {
    let struct = factory()

    t->Assert.deepEqual(
      any->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "Never", received: "Bool"}),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  ava->test("Fails to serialize ", t => {
    let struct = factory()

    t->Assert.deepEqual(
      any->S.serializeWith(struct),
      Error({
        code: UnexpectedType({expected: "Never", received: "Bool"}),
        operation: Serializing,
        path: [],
      }),
      (),
    )
  })
}

module ObjectField = {
  ava->test("Fails to parse a object with Never field", t => {
    let struct = S.object2(. ("key", S.string()), ("oldKey", S.never()))

    t->Assert.deepEqual(
      %raw(`{"key":"value"}`)->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "Never", received: "Option"}),
        operation: Parsing,
        path: ["oldKey"],
      }),
      (),
    )
  })

  ava->test(
    "Successfully parses a object with Never field when it's optional and not present",
    t => {
      let struct = S.object2(.
        ("key", S.string()),
        (
          "oldKey",
          S.never()->S.deprecated(
            ~message="We stopped using the field from the v0.9.0 release",
            (),
          ),
        ),
      )

      t->Assert.deepEqual(%raw(`{"key":"value"}`)->S.parseWith(struct), Ok(("value", None)), ())
    },
  )
}
