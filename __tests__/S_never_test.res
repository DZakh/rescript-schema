open Ava

module Common = {
  let any = %raw(`true`)
  let factory = () => S.never()

  test("Successfully parses without validation in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(~mode=Unsafe, struct), Ok(any), ())
  })

  test("Fails to parse in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(
      any->S.parseWith(struct),
      Error("[ReScript Struct] Failed parsing at root. Reason: Expected Never, got Bool"),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.serializeWith(struct), Ok(any), ())
  })
}

module RecordField = {
  type record = {key: string}

  test("Fails to parse a record with Never field", t => {
    let struct = S.record2(
      ~fields=(("key", S.string()), ("oldKey", S.never())),
      ~constructor=((key, _oldKey)) => {key: key}->Ok,
      (),
    )

    t->Assert.deepEqual(
      %raw(`{"key":"value"}`)->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at ["oldKey"]. Reason: Expected Never, got Option`),
      (),
    )
  })

  test("Successfully parses a record with Never field when it's optional and not present", t => {
    let struct = S.record2(
      ~fields=(
        ("key", S.string()),
        (
          "oldKey",
          S.deprecated(~message="We stopped using the field from the v0.9.0 release", S.never()),
        ),
      ),
      ~constructor=((key, _oldKey)) => {key: key}->Ok,
      (),
    )

    t->Assert.deepEqual(%raw(`{"key":"value"}`)->S.parseWith(struct), Ok({key: "value"}), ())
  })
}
