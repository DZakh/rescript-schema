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
