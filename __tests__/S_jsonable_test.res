open Ava

test("Supports String", t => {
  let struct = S.jsonable()
  let data = Js.Json.string("Foo")

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Number", t => {
  let struct = S.jsonable()
  let data = Js.Json.number(123.)

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Bool", t => {
  let struct = S.jsonable()
  let data = Js.Json.boolean(true)

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Null", t => {
  let struct = S.jsonable()
  let data = Js.Json.null

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Array", t => {
  let struct = S.jsonable()
  let data = Js.Json.array([Js.Json.string("foo"), Js.Json.null])

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})

test("Supports Object", t => {
  let struct = S.jsonable()
  let data = Js.Json.object_(
    [("bar", Js.Json.string("foo")), ("baz", Js.Json.null)]->Js.Dict.fromArray,
  )

  t->Assert.deepEqual(data->S.parseWith(struct), Ok(data), ())
  t->Assert.deepEqual(data->S.serializeWith(struct), Ok(data), ())
})
