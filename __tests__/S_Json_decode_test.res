open Ava

test("Decodes string", t => {
  let primitive = "ReScript is Great!"
  let struct = S.string()

  t->Assert.deepEqual(Js.Json.string(primitive)->S.Json.decodeWith(struct), Ok(primitive), ())
})

test("Fails to decode string", t => {
  let struct = S.string()

  t->Assert.deepEqual(
    Js.Json.number(123.)->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected String, got Float"),
    (),
  )
})

test("Decodes int", t => {
  let struct = S.int()

  t->Assert.deepEqual(Js.Json.number(123.)->S.Json.decodeWith(struct), Ok(123), ())
})

test("Fails to decode int", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    Js.Json.string("string")->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Int, got String"),
    (),
  )
})

test("Fails to decode int when JSON is a number has fractional part", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    Js.Json.number(123.12)->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Int, got Float"),
    (),
  )
})

test("Fails to decode int when JSON is a number bigger than +2^31", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    Js.Json.number(2147483648.)->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Int, got Float"),
    (),
  )
  t->Assert.deepEqual(Js.Json.number(2147483647.)->S.Json.decodeWith(struct), Ok(2147483647), ())
})

test("Fails to decode int when JSON is a number lower than -2^31", t => {
  let struct = S.int()

  t->Assert.deepEqual(
    Js.Json.number(-2147483648.)->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Int, got Float"),
    (),
  )
  t->Assert.deepEqual(Js.Json.number(-2147483647.)->S.Json.decodeWith(struct), Ok(-2147483647), ())
})

test("Decodes float", t => {
  let struct = S.float()

  t->Assert.deepEqual(Js.Json.number(123.)->S.Json.decodeWith(struct), Ok(123.), ())
})

test("Decodes float when JSON is a number has fractional part", t => {
  let struct = S.float()

  t->Assert.deepEqual(Js.Json.number(123.123)->S.Json.decodeWith(struct), Ok(123.123), ())
})

test("Fails to decode float", t => {
  let struct = S.float()

  t->Assert.deepEqual(
    Js.Json.boolean(true)->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Float, got Bool"),
    (),
  )
})

test("Decodes bool when JSON is true", t => {
  let struct = S.bool()

  t->Assert.deepEqual(Js.Json.boolean(true)->S.Json.decodeWith(struct), Ok(true), ())
})

test("Decodes bool when JSON is false", t => {
  let struct = S.bool()

  t->Assert.deepEqual(Js.Json.boolean(false)->S.Json.decodeWith(struct), Ok(false), ())
})

test("Fails to decode bool", t => {
  let struct = S.bool()

  t->Assert.deepEqual(
    Js.Json.string("string")->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Bool, got String"),
    (),
  )
})

test("Decodes option when provided JS undefined", t => {
  let struct = S.option(S.bool())

  t->Assert.deepEqual(%raw(`undefined`)->S.Json.decodeWith(struct), Ok(None), ())
})

test("Decodes option when provided primitive", t => {
  let struct = S.option(S.bool())

  t->Assert.deepEqual(Js.Json.boolean(true)->S.Json.decodeWith(struct), Ok(Some(true)), ())
})

test("Fails to decode option", t => {
  let struct = S.option(S.bool())

  t->Assert.deepEqual(
    Js.Json.string("string")->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Bool, got String"),
    (),
  )
})

test("Fails to decode JS undefined when struct doesn't allow optional data", t => {
  let struct = S.bool()

  t->Assert.deepEqual(
    %raw(`undefined`)->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Bool, got Option"),
    (),
  )
})

test("Decodes deprecated when provided JS undefined", t => {
  let struct = S.deprecated(S.bool())

  t->Assert.deepEqual(%raw(`undefined`)->S.Json.decodeWith(struct), Ok(None), ())
})

test("Decodes deprecated when provided primitive", t => {
  let struct = S.deprecated(S.bool())

  t->Assert.deepEqual(Js.Json.boolean(true)->S.Json.decodeWith(struct), Ok(Some(true)), ())
})

test("Fails to decode deprecated", t => {
  let struct = S.deprecated(S.bool())

  t->Assert.deepEqual(
    Js.Json.string("string")->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Bool, got String"),
    (),
  )
})

test("Decodes data with default when provided JS undefined", t => {
  let struct = S.option(S.bool())->S.default(false)

  t->Assert.deepEqual(%raw(`undefined`)->S.Json.decodeWith(struct), Ok(false), ())
})

test("Decodes data with default when provided primitive", t => {
  let struct = S.option(S.bool())->S.default(false)

  t->Assert.deepEqual(Js.Json.boolean(true)->S.Json.decodeWith(struct), Ok(true), ())
})

test("Fails to decode data with default", t => {
  let struct = S.option(S.bool())->S.default(false)

  t->Assert.deepEqual(
    Js.Json.string("string")->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Bool, got String"),
    (),
  )
})

test("Decodes array", t => {
  let struct = S.array(S.string())

  t->Assert.deepEqual(
    Js.Json.stringArray(["a", "b"])->S.Json.decodeWith(struct),
    Ok(["a", "b"]),
    (),
  )
})

test("Fails to decode array", t => {
  let struct = S.array(S.string())

  t->Assert.deepEqual(
    Js.Json.string("string")->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Array, got String"),
    (),
  )
})

test("Fails to decode array item", t => {
  let struct = S.array(S.string())

  t->Assert.deepEqual(
    %raw(`["a", 123]`)->S.Json.decodeWith(struct),
    Error("Struct decoding failed at .[1]. Reason: Expected String, got Float"),
    (),
  )
})

test("Decodes dict", t => {
  let struct = S.dict(S.string())

  t->Assert.deepEqual(
    %raw(`{a:"b",c:"d"}`)->S.Json.decodeWith(struct),
    Ok(Js.Dict.fromArray([("a", "b"), ("c", "d")])),
    (),
  )
})

test("Decodes dict with int keys", t => {
  let struct = S.dict(S.string())

  t->Assert.deepEqual(
    %raw(`{1:"b",2:"d"}`)->S.Json.decodeWith(struct),
    Ok(Js.Dict.fromArray([("1", "b"), ("2", "d")])),
    (),
  )
})

test("Fails to decode dict", t => {
  let struct = S.dict(S.string())

  t->Assert.deepEqual(
    Js.Json.string("string")->S.Json.decodeWith(struct),
    Error("Struct decoding failed at root. Reason: Expected Dict, got String"),
    (),
  )
})

test("Fails to decode dict item", t => {
  let struct = S.dict(S.string())

  t->Assert.deepEqual(
    %raw(`{"a":"b","c":123}`)->S.Json.decodeWith(struct),
    Error(`Struct decoding failed at ."c". Reason: Expected String, got Float`),
    (),
  )
})

module Record = {
  type singleFieldRecord = {foo: string}
  type optionalSingleFieldRecord = {baz: option<string>}

  test("Decodes record", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(%raw(`{FOO:"bar"}`)->S.Json.decodeWith(struct), Ok({foo: "bar"}), ())
  })

  test("Decodes record with optional item", t => {
    let struct = S.record1(
      ~fields=("FOO", S.option(S.string())),
      ~constructor=baz => {baz: baz}->Ok,
      (),
    )

    t->Assert.deepEqual(%raw(`{FOO:"bar"}`)->S.Json.decodeWith(struct), Ok({baz: Some("bar")}), ())
  })

  test("Decodes record with optional item when it's not present", t => {
    let struct = S.record1(
      ~fields=("FOO", S.option(S.string())),
      ~constructor=baz => {baz: baz}->Ok,
      (),
    )

    t->Assert.deepEqual(%raw(`{}`)->S.Json.decodeWith(struct), Ok({baz: None}), ())
  })

  test("Fails to decode record", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(
      Js.Json.string("string")->S.Json.decodeWith(struct),
      Error("Struct decoding failed at root. Reason: Expected Record, got String"),
      (),
    )
  })

  test("Fails to decode record item when it's not present", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(
      %raw(`{}`)->S.Json.decodeWith(struct),
      Error(`Struct decoding failed at ."FOO". Reason: Expected String, got Option`),
      (),
    )
  })

  test("Fails to decode record item when it's not valid", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(
      %raw(`{FOO:123}`)->S.Json.decodeWith(struct),
      Error(`Struct decoding failed at ."FOO". Reason: Expected String, got Float`),
      (),
    )
  })

  test("Fails to decode record when JS object has a field that's not described", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(
      %raw(`{BAR:"bar", FOO:"bar"}`)->S.Json.decodeWith(struct),
      Error(`Struct decoding failed at root. Reason: Encountered extra properties ["BAR"] on an object. If you want to be less strict and ignore any extra properties, use Shape instead (not implemented), to ignore a specific extra property, use Deprecated`),
      (),
    )
  })
}
