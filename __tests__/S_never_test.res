open Ava

module Common = {
  let any = %raw(`true`)
  let factory = () => S.never()

  test("Successfully parses without validation in Migration mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(~mode=Migration, struct), Ok(any), ())
  })

  test("Fails to parse in Safe mode", t => {
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

  test("Fails to serialize in Safe mode", t => {
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

module RecordField = {
  test("Fails to parse a record with Never field", t => {
    let struct = S.record2(. ("key", S.string()), ("oldKey", S.never()))

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

  test("Successfully parses a record with Never field when it's optional and not present", t => {
    let struct = S.record2(.
      ("key", S.string()),
      (
        "oldKey",
        S.deprecated(~message="We stopped using the field from the v0.9.0 release", S.never()),
      ),
    )

    t->Assert.deepEqual(%raw(`{"key":"value"}`)->S.parseWith(struct), Ok(("value", None)), ())
  })
}
