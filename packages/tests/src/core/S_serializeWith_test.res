open Ava
open RescriptCore

test("Successfully serializes jsonable schemas", t => {
  t->Assert.deepEqual(true->S.serializeWith(S.bool), true->JSON.Encode.bool->Ok, ())
  t->Assert.deepEqual(true->S.serializeWith(S.literal(true)), true->JSON.Encode.bool->Ok, ())
  t->Assert.deepEqual("abc"->S.serializeWith(S.string), "abc"->JSON.Encode.string->Ok, ())
  t->Assert.deepEqual("abc"->S.serializeWith(S.literal("abc")), "abc"->JSON.Encode.string->Ok, ())
  t->Assert.deepEqual(123->S.serializeWith(S.int), 123.->JSON.Encode.float->Ok, ())
  t->Assert.deepEqual(123->S.serializeWith(S.literal(123)), 123.->JSON.Encode.float->Ok, ())
  t->Assert.deepEqual(123.->S.serializeWith(S.float), 123.->JSON.Encode.float->Ok, ())
  t->Assert.deepEqual(123.->S.serializeWith(S.literal(123.)), 123.->JSON.Encode.float->Ok, ())
  t->Assert.deepEqual(
    (true, "foo", 123)->S.serializeWith(S.literal((true, "foo", 123))),
    JSON.Encode.array([
      JSON.Encode.bool(true),
      JSON.Encode.string("foo"),
      JSON.Encode.float(123.),
    ])->Ok,
    (),
  )
  t->Assert.deepEqual(
    {"foo": true}->S.serializeWith(S.literal({"foo": true})),
    JSON.Encode.object(Dict.fromArray([("foo", JSON.Encode.bool(true))]))->Ok,
    (),
  )
  t->Assert.deepEqual(
    {"foo": (true, "foo", 123)}->S.serializeWith(S.literal({"foo": (true, "foo", 123)})),
    JSON.Encode.object(
      Dict.fromArray([
        (
          "foo",
          JSON.Encode.array([
            JSON.Encode.bool(true),
            JSON.Encode.string("foo"),
            JSON.Encode.float(123.),
          ]),
        ),
      ]),
    )->Ok,
    (),
  )
  t->Assert.deepEqual(None->S.serializeWith(S.null(S.bool)), JSON.Encode.null->Ok, ())
  t->Assert.deepEqual(
    JSON.Encode.null->S.serializeWith(S.literal(JSON.Encode.null)),
    JSON.Encode.null->Ok,
    (),
  )
  t->Assert.deepEqual([]->S.serializeWith(S.array(S.bool)), JSON.Encode.array([])->Ok, ())
  t->Assert.deepEqual(
    Dict.make()->S.serializeWith(S.dict(S.bool)),
    JSON.Encode.object(Dict.make())->Ok,
    (),
  )
  t->Assert.deepEqual(
    true->S.serializeWith(S.object(s => s.field("foo", S.bool))),
    JSON.Encode.object(Dict.fromArray([("foo", JSON.Encode.bool(true))]))->Ok,
    (),
  )
  t->Assert.deepEqual(
    true->S.serializeWith(S.tuple1(S.bool)),
    JSON.Encode.array([JSON.Encode.bool(true)])->Ok,
    (),
  )
  t->Assert.deepEqual(
    "foo"->S.serializeWith(S.union([S.literal("foo"), S.literal("bar")])),
    JSON.Encode.string("foo")->Ok,
    (),
  )
})

test("Fails to serialize Option schema", t => {
  let schema = S.option(S.bool)
  t->Assert.deepEqual(
    None->S.serializeWith(schema),
    Error(
      U.error({
        code: InvalidJsonStruct(schema->S.toUnknown),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Fails to serialize Undefined literal", t => {
  let schema = S.literal()
  t->Assert.deepEqual(
    ()->S.serializeWith(schema),
    Error(
      U.error({
        code: InvalidJsonStruct(schema->S.toUnknown),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Fails to serialize Function literal", t => {
  let fn = () => ()
  let schema = S.literal(fn)
  t->Assert.deepEqual(
    fn->S.serializeWith(schema),
    Error(
      U.error({
        code: InvalidJsonStruct(schema->S.toUnknown),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Fails to serialize Object literal", t => {
  let error = %raw(`new Error("foo")`)
  let schema = S.literal(error)
  t->Assert.deepEqual(
    error->S.serializeWith(schema),
    Error(
      U.error({
        code: InvalidJsonStruct(schema->S.toUnknown),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Fails to serialize Symbol literal", t => {
  let symbol = %raw(`Symbol()`)
  let schema = S.literal(symbol)
  t->Assert.deepEqual(
    symbol->S.serializeWith(schema),
    Error(
      U.error({
        code: InvalidJsonStruct(schema->S.toUnknown),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Fails to serialize BigInt literal", t => {
  let bigint = %raw(`1234n`)
  let schema = S.literal(bigint)
  t->Assert.deepEqual(
    bigint->S.serializeWith(schema),
    Error(
      U.error({
        code: InvalidJsonStruct(schema->S.toUnknown),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Fails to serialize Dict literal with invalid field", t => {
  let dict = %raw(`{"foo": 123n}`)
  let schema = S.literal(dict)
  t->Assert.deepEqual(
    dict->S.serializeWith(schema),
    Error(
      U.error({
        code: InvalidJsonStruct(schema->S.toUnknown),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Fails to serialize NaN literal", t => {
  let schema = S.literal(%raw(`NaN`))
  t->Assert.deepEqual(
    ()->S.serializeWith(schema),
    Error(
      U.error({
        code: InvalidJsonStruct(schema->S.toUnknown),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Fails to serialize Unknown schema", t => {
  t->Assert.deepEqual(
    Obj.magic(123)->S.serializeWith(S.unknown),
    Error(
      U.error({code: InvalidJsonStruct(S.unknown), operation: Serializing, path: S.Path.empty}),
    ),
    (),
  )
})

test("Fails to serialize Never schema", t => {
  t->Assert.deepEqual(
    Obj.magic(123)->S.serializeWith(S.never),
    Error(
      U.error({
        code: InvalidType({expected: S.never->S.toUnknown, received: Obj.magic(123)}),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Fails to serialize object with invalid nested schema", t => {
  t->Assert.deepEqual(
    Obj.magic(true)->S.serializeWith(S.object(s => s.field("foo", S.unknown))),
    Error(
      U.error({
        code: InvalidJsonStruct(S.unknown),
        operation: Serializing,
        path: S.Path.fromArray(["foo"]),
      }),
    ),
    (),
  )
})

test("Fails to serialize tuple with invalid nested schema", t => {
  t->Assert.deepEqual(
    Obj.magic(true)->S.serializeWith(S.tuple1(S.unknown)),
    Error(
      U.error({
        code: InvalidJsonStruct(S.unknown),
        operation: Serializing,
        path: S.Path.fromArray(["0"]),
      }),
    ),
    (),
  )
})

test("Fails to serialize union if one of the items is an invalid schema", t => {
  t->Assert.deepEqual(
    "foo"->S.serializeWith(S.union([S.string, S.unknown->(U.magic: S.t<unknown> => S.t<string>)])),
    Error(
      U.error({code: InvalidJsonStruct(S.unknown), operation: Serializing, path: S.Path.empty}),
    ),
    (),
  )
})
