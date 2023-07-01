open Ava

test("Supports String", t => {
  let struct = S.json
  let data = Js.Json.string("Foo")

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Number", t => {
  let struct = S.json
  let data = Js.Json.number(123.)

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Bool", t => {
  let struct = S.json
  let data = Js.Json.boolean(true)

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Null", t => {
  let struct = S.json
  let data = Js.Json.null

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Array", t => {
  let struct = S.json
  let data = Js.Json.array([Js.Json.string("foo"), Js.Json.null])

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Object", t => {
  let struct = S.json
  let data = Js.Json.object_(
    [("bar", Js.Json.string("foo")), ("baz", Js.Json.null)]->Js.Dict.fromArray,
  )

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Fails to parse Object field", t => {
  let struct = S.json
  let data = Js.Json.object_([("bar", %raw("undefined")), ("baz", Js.Json.null)]->Js.Dict.fromArray)

  t->Assert.deepEqual(
    data->S.parseWith(struct),
    Error({
      code: InvalidType({received: "Option", expected: "JSON"}),
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
      code: InvalidType({received: "Option", expected: "JSON"}),
      operation: Parsing,
      path: S.Path.fromArray(["1", "0"]),
    }),
    (),
  )
})

test("Fails to parse NaN", t => {
  let struct = S.json
  t->Assert.deepEqual(
    %raw("NaN")->S.parseAnyWith(struct),
    Error({
      code: InvalidType({received: "NaN Literal (NaN)", expected: "JSON"}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to parse undefined", t => {
  let struct = S.json
  t->Assert.deepEqual(
    %raw("undefined")->S.parseAnyWith(struct),
    Error({
      code: InvalidType({received: "Option", expected: "JSON"}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
