open Ava

test("Parses data with default when provided JS undefined", t => {
  let struct = S.option(S.bool())->S.default(false)

  t->Assert.deepEqual(%raw(`undefined`)->S.parseWith(struct), Ok(false), ())
})

test("Parses data with default when provided primitive", t => {
  let struct = S.option(S.bool())->S.default(false)

  t->Assert.deepEqual(Js.Json.boolean(true)->S.parseWith(struct), Ok(true), ())
})

test("Fails to parse data with default", t => {
  let struct = S.option(S.bool())->S.default(false)

  t->Assert.deepEqual(
    Js.Json.string("string")->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: Expected Bool, got String"),
    (),
  )
})

module Record = {
  type singleFieldRecord = {foo: string}
  type optionalSingleFieldRecord = {baz: option<string>}

  test("Parses record", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(%raw(`{FOO:"bar"}`)->S.parseWith(struct), Ok({foo: "bar"}), ())
  })

  test("Parses record with optional item", t => {
    let struct = S.record1(
      ~fields=("FOO", S.option(S.string())),
      ~constructor=baz => {baz: baz}->Ok,
      (),
    )

    t->Assert.deepEqual(%raw(`{FOO:"bar"}`)->S.parseWith(struct), Ok({baz: Some("bar")}), ())
  })

  test("Parses record with optional item when it's not present", t => {
    let struct = S.record1(
      ~fields=("FOO", S.option(S.string())),
      ~constructor=baz => {baz: baz}->Ok,
      (),
    )

    t->Assert.deepEqual(%raw(`{}`)->S.parseWith(struct), Ok({baz: None}), ())
  })

  test("Fails to parse record", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(
      Js.Json.string("string")->S.parseWith(struct),
      Error("[ReScript Struct] Failed parsing at root. Reason: Expected Record, got String"),
      (),
    )
  })

  test("Fails to parse record item when it's not present", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(
      %raw(`{}`)->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at ["FOO"]. Reason: Expected String, got Option`),
      (),
    )
  })

  test("Fails to parse record item when it's not valid", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(
      %raw(`{FOO:123}`)->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at ["FOO"]. Reason: Expected String, got Float`),
      (),
    )
  })
}
