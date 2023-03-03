open Ava

module Json = Js.Json

test("Successfully serializes jsonable structs", t => {
  t->Assert.deepEqual(true->S.serializeToJsonWith(S.bool()), true->Json.boolean->Ok, ())
  t->Assert.deepEqual(
    true->S.serializeToJsonWith(S.literal(Bool(true))),
    true->Json.boolean->Ok,
    (),
  )
  t->Assert.deepEqual("abc"->S.serializeToJsonWith(S.string()), "abc"->Json.string->Ok, ())
  t->Assert.deepEqual(
    "abc"->S.serializeToJsonWith(S.literal(String("abc"))),
    "abc"->Json.string->Ok,
    (),
  )
  t->Assert.deepEqual(123->S.serializeToJsonWith(S.int()), 123.->Json.number->Ok, ())
  t->Assert.deepEqual(123->S.serializeToJsonWith(S.literal(Int(123))), 123.->Json.number->Ok, ())
  t->Assert.deepEqual(123.->S.serializeToJsonWith(S.float()), 123.->Json.number->Ok, ())
  t->Assert.deepEqual(
    123.->S.serializeToJsonWith(S.literal(Float(123.))),
    123.->Json.number->Ok,
    (),
  )
  t->Assert.deepEqual(None->S.serializeToJsonWith(S.null(S.bool())), Json.null->Ok, ())
  t->Assert.deepEqual(()->S.serializeToJsonWith(S.literal(EmptyNull)), Json.null->Ok, ())
  t->Assert.deepEqual([]->S.serializeToJsonWith(S.array(S.bool())), Json.array([])->Ok, ())
  t->Assert.deepEqual(
    Js.Dict.empty()->S.serializeToJsonWith(S.dict(S.bool())),
    Json.object_(Js.Dict.empty())->Ok,
    (),
  )
  t->Assert.deepEqual(
    true->S.serializeToJsonWith(S.object(f => f->S.field("foo", S.bool()))),
    Json.object_(Js.Dict.fromArray([("foo", Json.boolean(true))]))->Ok,
    (),
  )
  t->Assert.deepEqual(
    true->S.serializeToJsonWith(S.tuple1(. S.bool())),
    Json.array([Json.boolean(true)])->Ok,
    (),
  )
  t->Assert.deepEqual(
    "foo"->S.serializeToJsonWith(S.union([S.literal(String("foo")), S.literal(String("bar"))])),
    Json.string("foo")->Ok,
    (),
  )
})

test("Fails to serialize Option struct", t => {
  t->Assert.deepEqual(
    None->S.serializeToJsonWith(S.option(S.bool())),
    Error({
      code: InvalidJsonStruct({received: "Option"}),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Fails to serialize EmptyOption Literal (undefined) struct", t => {
  t->Assert.deepEqual(
    ()->S.serializeToJsonWith(S.literal(EmptyOption)),
    Error({
      code: InvalidJsonStruct({received: "EmptyOption Literal (undefined)"}),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Fails to serialize NaN Literal (NaN) struct", t => {
  t->Assert.deepEqual(
    ()->S.serializeToJsonWith(S.literal(NaN)),
    Error({
      code: InvalidJsonStruct({received: "NaN Literal (NaN)"}),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Fails to serialize Unknown struct", t => {
  t->Assert.deepEqual(
    Obj.magic(123)->S.serializeToJsonWith(S.unknown()),
    Error({
      code: InvalidJsonStruct({received: "Unknown"}),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Fails to serialize Never struct", t => {
  t->Assert.deepEqual(
    Obj.magic(123)->S.serializeToJsonWith(S.never()),
    Error({
      code: UnexpectedType({expected: "Never", received: "Float"}),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Fails to serialize object with invalid nested struct", t => {
  t->Assert.deepEqual(
    Obj.magic(true)->S.serializeToJsonWith(S.object(f => f->S.field("foo", S.unknown()))),
    Error({
      code: InvalidJsonStruct({received: "Unknown"}),
      operation: Serializing,
      path: ["foo"],
    }),
    (),
  )
})

test("Fails to serialize tuple with invalid nested struct", t => {
  t->Assert.deepEqual(
    Obj.magic(true)->S.serializeToJsonWith(S.tuple1(. S.unknown())),
    Error({
      code: InvalidJsonStruct({received: "Unknown"}),
      operation: Serializing,
      path: ["0"],
    }),
    (),
  )
})

test("Fails to serialize union if one of the items is an invalid struct", t => {
  t->Assert.deepEqual(
    "foo"->S.serializeToJsonWith(
      S.union([S.string(), S.unknown()->(Obj.magic: S.t<unknown> => S.t<string>)]),
    ),
    Error({
      code: InvalidJsonStruct({received: "Unknown"}),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})
