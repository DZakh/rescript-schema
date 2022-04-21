open Ava

external unsafeToUnknown: 'unknown => Js.Json.t = "%identity"

test("Constructs unknown primitive with coercion to the same type", t => {
  let primitive = "  Hello world!"
  let coercedPrimitive = "Hello world!"
  let unknownPrimitive = primitive->unsafeToUnknown

  let struct = S.coercedString(~constructor=value => value->Js.String2.trim->Ok, ())

  t->Assert.deepEqual(unknownPrimitive->S.constructWith(struct), Ok(coercedPrimitive), ())
})

test("Constructs unknown primitive with coercion to another type", t => {
  let primitive = 123
  let coercedPrimitive = 123.
  let unknownPrimitive = primitive->unsafeToUnknown

  let struct = S.coercedInt(~constructor=value => value->Js.Int.toFloat->Ok, ())

  t->Assert.deepEqual(unknownPrimitive->S.constructWith(struct), Ok(coercedPrimitive), ())
})

test("Throws for a CoercedPrimitive factory without either a constructor, or a destructor", t => {
  t->Assert.throws(() => {
    S.coercedString()->ignore
  }, ~expectations=ThrowsException.make(
    ~message="For a Coerced struct either a constructor, or a destructor is required",
    (),
  ), ())
})

test("CoercedPrimitive construction fails when constructor isn't provided", t => {
  let primitive = "Hello world!"
  let unknownPrimitive = primitive->unsafeToUnknown

  let struct = S.coercedString(~destructor=value => value->Ok, ())

  t->Assert.deepEqual(
    unknownPrimitive->S.constructWith(struct),
    Error("Struct missing constructor at root"),
    (),
  )
})

test("Construction fails when user returns error in a CoercedPrimitive constructor", t => {
  let primitive = "Hello world!"
  let unknownPrimitive = primitive->unsafeToUnknown
  let struct = S.coercedString(~constructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    unknownPrimitive->S.constructWith(struct),
    Error("Struct construction failed at root. Reason: User error"),
    (),
  )
})

test("Destructs unknown record with with coercion to the same type", t => {
  let primitive = "  Hello world!"
  let coercedPrimitive = "Hello world!"
  let unknownCoercedPrimitive = coercedPrimitive->unsafeToUnknown

  let struct = S.coercedString(~destructor=value => value->Js.String2.trim->Ok, ())

  t->Assert.deepEqual(primitive->S.destructWith(struct), Ok(unknownCoercedPrimitive), ())
})

test("Destructs unknown record with with coercion to another type", t => {
  let primitive = 123
  let coercedPrimitive = 123.
  let unknownCoercedPrimitive = coercedPrimitive->unsafeToUnknown

  let struct = S.coercedFloat(~destructor=value => value->Js.Int.toFloat->Ok, ())

  t->Assert.deepEqual(primitive->S.destructWith(struct), Ok(unknownCoercedPrimitive), ())
})

test("CoercedPrimitive destruction fails when destructor isn't provided", t => {
  let primitive = "Hello world!"

  let struct = S.coercedString(~constructor=value => value->Ok, ())

  t->Assert.deepEqual(
    primitive->S.destructWith(struct),
    Error("Struct missing destructor at root"),
    (),
  )
})

test("Destruction fails when user returns error in a CoercedPrimitive destructor", t => {
  let primitive = "Hello world!"

  let struct = S.coercedString(~destructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    primitive->S.destructWith(struct),
    Error("Struct destruction failed at root. Reason: User error"),
    (),
  )
})

test("Constructs a CoercedPrimitive and destructs it back to the initial state", t => {
  let primitive = 123
  let unknownPrimitive = primitive->unsafeToUnknown

  let struct = S.coercedInt(
    ~constructor=int => int->Js.Int.toFloat->Ok,
    ~destructor=value => value->Belt.Int.fromFloat->Ok,
    (),
  )

  t->Assert.deepEqual(
    unknownPrimitive
    ->S.constructWith(struct)
    ->Belt.Result.map(record => record->S.destructWith(struct)),
    Ok(Ok(unknownPrimitive)),
    (),
  )
})
