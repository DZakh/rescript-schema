open Ava

test("Constructs unknown primitive with transformation to the same type", t => {
  let any = %raw(`"  Hello world!"`)
  let transformedValue = "Hello world!"

  let struct = S.string()->S.transform(~constructor=value => value->Js.String2.trim->Ok, ())

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(transformedValue), ())
})

test("Constructs unknown primitive with transformation to another type", t => {
  let any = %raw(`123`)
  let transformedValue = 123.

  let struct = S.int()->S.transform(~constructor=value => value->Js.Int.toFloat->Ok, ())

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(transformedValue), ())
})

test(
  "Throws for a Transformed Primitive factory without either a constructor, or a destructor",
  t => {
    t->Assert.throws(() => {
      S.string()->S.transform()->ignore
    }, ~expectations=ThrowsException.make(
      ~message="For transformation either a constructor, or a destructor is required",
      (),
    ), ())
  },
)

test("Transformed Primitive construction fails when constructor isn't provided", t => {
  let any = %raw(`"Hello world!"`)

  let struct = S.string()->S.transform(~destructor=value => value->Ok, ())

  t->Assert.deepEqual(any->S.constructWith(struct), Error("Struct missing constructor at root"), ())
})

test("Construction fails when user returns error in a Transformed Primitive constructor", t => {
  let any = %raw(`"Hello world!"`)

  let struct = S.string()->S.transform(~constructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    any->S.constructWith(struct),
    Error("Struct construction failed at root. Reason: User error"),
    (),
  )
})

test("Destructs primitive with transformation to the same type", t => {
  let value = "  Hello world!"
  let transformedAny = %raw(`"Hello world!"`)

  let struct = S.string()->S.transform(~destructor=value => value->Js.String2.trim->Ok, ())

  t->Assert.deepEqual(value->S.destructWith(struct), Ok(transformedAny), ())
})

test("Destructs primitive with transformation to another type", t => {
  let value = 123
  let transformedAny = %raw(`123`)

  let struct = S.float()->S.transform(~destructor=value => value->Js.Int.toFloat->Ok, ())

  t->Assert.deepEqual(value->S.destructWith(struct), Ok(transformedAny), ())
})

test("Transformed Primitive destruction fails when destructor isn't provided", t => {
  let value = "Hello world!"

  let struct = S.string()->S.transform(~constructor=value => value->Ok, ())

  t->Assert.deepEqual(value->S.destructWith(struct), Error("Struct missing destructor at root"), ())
})

test("Destruction fails when user returns error in a Transformed Primitive destructor", t => {
  let value = "Hello world!"

  let struct = S.string()->S.transform(~destructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    value->S.destructWith(struct),
    Error("Struct destruction failed at root. Reason: User error"),
    (),
  )
})

test("Constructs a Transformed Primitive and destructs it back to the initial state", t => {
  let any = %raw(`123`)

  let struct =
    S.int()->S.transform(
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
