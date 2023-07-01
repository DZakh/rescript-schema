open Ava

module Json = Js.Json

test("Successfully serializes jsonable structs", t => {
  t->Assert.deepEqual(true->S.serializeWith(S.bool), true->Json.boolean->Ok, ())
  t->Assert.deepEqual(true->S.serializeWith(S.literal(true)), true->Json.boolean->Ok, ())
  t->Assert.deepEqual("abc"->S.serializeWith(S.string), "abc"->Json.string->Ok, ())
  t->Assert.deepEqual("abc"->S.serializeWith(S.literal("abc")), "abc"->Json.string->Ok, ())
  t->Assert.deepEqual(123->S.serializeWith(S.int), 123.->Json.number->Ok, ())
  t->Assert.deepEqual(123->S.serializeWith(S.literal(123)), 123.->Json.number->Ok, ())
  t->Assert.deepEqual(123.->S.serializeWith(S.float), 123.->Json.number->Ok, ())
  t->Assert.deepEqual(123.->S.serializeWith(S.literal(123.)), 123.->Json.number->Ok, ())
  t->Assert.deepEqual(None->S.serializeWith(S.null(S.bool)), Json.null->Ok, ())
  t->Assert.deepEqual(Json.null->S.serializeWith(S.literal(Json.null)), Json.null->Ok, ())
  t->Assert.deepEqual([]->S.serializeWith(S.array(S.bool)), Json.array([])->Ok, ())
  t->Assert.deepEqual(
    Js.Dict.empty()->S.serializeWith(S.dict(S.bool)),
    Json.object_(Js.Dict.empty())->Ok,
    (),
  )
  t->Assert.deepEqual(
    true->S.serializeWith(S.object(o => o.field("foo", S.bool))),
    Json.object_(Js.Dict.fromArray([("foo", Json.boolean(true))]))->Ok,
    (),
  )
  t->Assert.deepEqual(
    true->S.serializeWith(S.tuple1(. S.bool)),
    Json.array([Json.boolean(true)])->Ok,
    (),
  )
  t->Assert.deepEqual(
    "foo"->S.serializeWith(S.union([S.literal("foo"), S.literal("bar")])),
    Json.string("foo")->Ok,
    (),
  )
})

test("Fails to serialize Option struct", t => {
  let struct = S.option(S.bool)
  t->Assert.deepEqual(
    None->S.serializeWith(struct),
    Error({
      code: InvalidJsonStruct(struct->S.toUnknown),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to serialize Undefined literal", t => {
  let struct = S.literal()
  t->Assert.deepEqual(
    ()->S.serializeWith(struct),
    Error({
      code: InvalidJsonStruct(struct->S.toUnknown),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to serialize NaN literal", t => {
  let struct = S.literal(%raw("NaN"))
  t->Assert.deepEqual(
    ()->S.serializeWith(struct),
    Error({
      code: InvalidJsonStruct(struct->S.toUnknown),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to serialize Unknown struct", t => {
  t->Assert.deepEqual(
    Obj.magic(123)->S.serializeWith(S.unknown),
    Error({
      code: InvalidJsonStruct(S.unknown),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to serialize Never struct", t => {
  t->Assert.deepEqual(
    Obj.magic(123)->S.serializeWith(S.never),
    Error({
      code: InvalidType({expected: "Never", received: "Float"}),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to serialize object with invalid nested struct", t => {
  t->Assert.deepEqual(
    Obj.magic(true)->S.serializeWith(S.object(o => o.field("foo", S.unknown))),
    Error({
      code: InvalidJsonStruct(S.unknown),
      operation: Serializing,
      path: S.Path.fromArray(["foo"]),
    }),
    (),
  )
})

test("Fails to serialize tuple with invalid nested struct", t => {
  t->Assert.deepEqual(
    Obj.magic(true)->S.serializeWith(S.tuple1(. S.unknown)),
    Error({
      code: InvalidJsonStruct(S.unknown),
      operation: Serializing,
      path: S.Path.fromArray(["0"]),
    }),
    (),
  )
})

test("Fails to serialize union if one of the items is an invalid struct", t => {
  t->Assert.deepEqual(
    "foo"->S.serializeWith(
      S.union([S.string, S.unknown->(Obj.magic: S.t<unknown> => S.t<string>)]),
    ),
    Error({
      code: InvalidJsonStruct(S.unknown),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})
