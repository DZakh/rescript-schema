open Ava

test("Supports String", t => {
  let struct = S.json
  let data = JSON.Encode.string("Foo")

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Number", t => {
  let struct = S.json
  let data = JSON.Encode.float(123.)

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Bool", t => {
  let struct = S.json
  let data = JSON.Encode.bool(true)

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Null", t => {
  let struct = S.json
  let data = JSON.Encode.null

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Array", t => {
  let struct = S.json
  let data = JSON.Encode.array([JSON.Encode.string("foo"), JSON.Encode.null])

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Object", t => {
  let struct = S.json
  let data = JSON.Encode.object(
    [("bar", JSON.Encode.string("foo")), ("baz", JSON.Encode.null)]->Dict.fromArray,
  )

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Fails to parse Object field", t => {
  let struct = S.json
  let data = JSON.Encode.object(
    [("bar", %raw(`undefined`)), ("baz", JSON.Encode.null)]->Dict.fromArray,
  )

  t->Assert.deepEqual(
    data->S.parseWith(struct),
    Error({
      code: InvalidType({received: %raw(`undefined`), expected: struct->S.toUnknown}),
      operation: Parsing,
      path: S.Path.fromLocation("bar"),
    }),
    (),
  )
})

test("Fails to parse matrix field", t => {
  let struct = S.json
  let data = %raw(`[1,[undefined]]`)

  t->Assert.deepEqual(
    data->S.parseWith(struct),
    Error({
      code: InvalidType({received: %raw(`undefined`), expected: struct->S.toUnknown}),
      operation: Parsing,
      path: S.Path.fromArray(["1", "0"]),
    }),
    (),
  )
})

test("Fails to parse NaN", t => {
  let struct = S.json
  t->Assert.deepEqual(
    %raw(`NaN`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({received: %raw(`NaN`), expected: struct->S.toUnknown}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to parse undefined", t => {
  let struct = S.json
  t->Assert.deepEqual(
    %raw(`undefined`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({received: %raw(`undefined`), expected: struct->S.toUnknown}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
