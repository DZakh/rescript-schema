open Ava

external unsafeToUnknown: 'unknown => Js.Json.t = "%identity"

test("Constructs with a constructor", t => {
  let customData = "Hello world!"
  let unknownCustomData = customData->unsafeToUnknown

  let struct = S.custom(
    ~constructor=unknown => unknown->Js.Json.decodeString->Belt.Option.getWithDefault("")->Ok,
    (),
  )

  t->Assert.deepEqual(unknownCustomData->S.constructWith(struct), Ok(customData), ())
})

test("Throws without either a constructor, or a destructor", t => {
  t->Assert.throws(() => {
    S.custom()->ignore
  }, ~expectations=ThrowsException.make(
    ~message="For a Custom struct either a constructor, or a destructor is required",
    (),
  ), ())
})

test("Construction fails when constructor isn't provided", t => {
  let customData = "Hello world!"
  let unknownCustomData = customData->unsafeToUnknown

  let struct = S.custom(~destructor=value => value->Js.Json.string->Ok, ())

  t->Assert.deepEqual(
    unknownCustomData->S.constructWith(struct),
    Error("Struct missing constructor at root"),
    (),
  )
})

test("Construction fails when user returns error in constructor", t => {
  let wrongCustomData = 123
  let unknownWrongCustomData = wrongCustomData->unsafeToUnknown

  let struct = S.custom(~constructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    unknownWrongCustomData->S.constructWith(struct),
    Error("Struct construction failed at root. Reason: User error"),
    (),
  )
})

test("Destructs with a destructor", t => {
  let customData = "Hello world!"
  let unknownCustomData = customData->unsafeToUnknown

  let struct = S.custom(~destructor=value => value->Js.Json.string->Ok, ())

  t->Assert.deepEqual(customData->S.destructWith(struct), Ok(unknownCustomData), ())
})

test("Destruction fails when destructor isn't provided", t => {
  let customData = "Hello world!"

  let struct = S.custom(
    ~constructor=unknown => unknown->Js.Json.decodeString->Belt.Option.getWithDefault("")->Ok,
    (),
  )

  t->Assert.deepEqual(
    customData->S.destructWith(struct),
    Error("Struct missing destructor at root"),
    (),
  )
})

test("Destruction fails when user returns error in destructor", t => {
  let primitive = "Hello world!"

  let struct = S.custom(~destructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    primitive->S.destructWith(struct),
    Error("Struct destruction failed at root. Reason: User error"),
    (),
  )
})

test("Constructs data and destructs it back to the initial state", t => {
  let customData = "Hello world!"
  let unknownCustomData = customData->unsafeToUnknown

  let struct = S.custom(
    ~constructor=unknown => unknown->Js.Json.decodeString->Belt.Option.getWithDefault("")->Ok,
    ~destructor=value => value->Js.Json.string->Ok,
    (),
  )

  t->Assert.deepEqual(
    unknownCustomData
    ->S.constructWith(struct)
    ->Belt.Result.map(record => record->S.destructWith(struct)),
    Ok(Ok(unknownCustomData)),
    (),
  )
})
