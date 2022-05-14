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

test("Parses dict", t => {
  let struct = S.dict(S.string())

  t->Assert.deepEqual(
    %raw(`{a:"b",c:"d"}`)->S.parseWith(struct),
    Ok(Js.Dict.fromArray([("a", "b"), ("c", "d")])),
    (),
  )
})

test("Parses dict with int keys", t => {
  let struct = S.dict(S.string())

  t->Assert.deepEqual(
    %raw(`{1:"b",2:"d"}`)->S.parseWith(struct),
    Ok(Js.Dict.fromArray([("1", "b"), ("2", "d")])),
    (),
  )
})

test("Fails to parse dict", t => {
  let struct = S.dict(S.string())

  t->Assert.deepEqual(
    Js.Json.string("string")->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: Expected Dict, got String"),
    (),
  )
})

test("Fails to parse dict item", t => {
  let struct = S.dict(S.string())

  t->Assert.deepEqual(
    %raw(`{"a":"b","c":123}`)->S.parseWith(struct),
    Error(`[ReScript Struct] Failed parsing at ["c"]. Reason: Expected String, got Float`),
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

  test("Fails to parse record when JS object has a field that's not described", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(
      %raw(`{BAR:"bar",FOO:"bar",1:2}`)->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at root. Reason: Encountered extra properties ["1","BAR"] on an object. If you want to be less strict and ignore any extra properties, use Shape instead (not implemented), to ignore a specific extra property, use Deprecated`),
      (),
    )
  })
}
