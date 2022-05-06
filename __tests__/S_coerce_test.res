open Ava

test("Constructs unknown primitive with coercion to the same type", t => {
  let any = %raw(`"  Hello world!"`)
  let coercedValue = "Hello world!"

  let struct = S.string()->S.coerce(~constructor=value => value->Js.String2.trim->Ok, ())

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(coercedValue), ())
})

test("Constructs unknown primitive with coercion to another type", t => {
  let any = %raw(`123`)
  let coercedValue = 123.

  let struct = S.int()->S.coerce(~constructor=value => value->Js.Int.toFloat->Ok, ())

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(coercedValue), ())
})

test("Throws for a CoercedPrimitive factory without either a constructor, or a destructor", t => {
  t->Assert.throws(() => {
    S.string()->S.coerce()->ignore
  }, ~expectations=ThrowsException.make(
    ~message="For coercion either a constructor, or a destructor is required",
    (),
  ), ())
})

test("CoercedPrimitive construction fails when constructor isn't provided", t => {
  let any = %raw(`"Hello world!"`)

  let struct = S.string()->S.coerce(~destructor=value => value->Ok, ())

  t->Assert.deepEqual(any->S.constructWith(struct), Error("Struct missing constructor at root"), ())
})

test("Construction fails when user returns error in a CoercedPrimitive constructor", t => {
  let any = %raw(`"Hello world!"`)

  let struct = S.string()->S.coerce(~constructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    any->S.constructWith(struct),
    Error("Struct construction failed at root. Reason: User error"),
    (),
  )
})

test("Destructs primitive with coercion to the same type", t => {
  let value = "  Hello world!"
  let coercedAny = %raw(`"Hello world!"`)

  let struct = S.string()->S.coerce(~destructor=value => value->Js.String2.trim->Ok, ())

  t->Assert.deepEqual(value->S.destructWith(struct), Ok(coercedAny), ())
})

test("Destructs primitive with coercion to another type", t => {
  let value = 123
  let coercedAny = %raw(`123`)

  let struct = S.float()->S.coerce(~destructor=value => value->Js.Int.toFloat->Ok, ())

  t->Assert.deepEqual(value->S.destructWith(struct), Ok(coercedAny), ())
})

test("CoercedPrimitive destruction fails when destructor isn't provided", t => {
  let value = "Hello world!"

  let struct = S.string()->S.coerce(~constructor=value => value->Ok, ())

  t->Assert.deepEqual(value->S.destructWith(struct), Error("Struct missing destructor at root"), ())
})

test("Destruction fails when user returns error in a CoercedPrimitive destructor", t => {
  let value = "Hello world!"

  let struct = S.string()->S.coerce(~destructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    value->S.destructWith(struct),
    Error("Struct destruction failed at root. Reason: User error"),
    (),
  )
})

test("Constructs a CoercedPrimitive and destructs it back to the initial state", t => {
  let any = %raw(`123`)

  let struct =
    S.int()->S.coerce(
      ~constructor=int => int->Js.Int.toFloat->Ok,
      ~destructor=value => value->Belt.Int.fromFloat->Ok,
      (),
    )

  t->Assert.deepEqual(
    any->S.constructWith(struct)->Belt.Result.map(record => record->S.destructWith(struct)),
    Ok(Ok(any)),
    (),
  )
})
