open Ava

test("Parses unknown primitive with transformation to the same type", t => {
  let any = %raw(`"  Hello world!"`)
  let transformedValue = "Hello world!"

  let struct = S.string()->S.transform(~constructor=value => value->Js.String2.trim->Ok, ())

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(transformedValue), ())
})

test("Parses unknown primitive with transformation to another type", t => {
  let any = %raw(`123`)
  let transformedValue = 123.

  let struct = S.int()->S.transform(~constructor=value => value->Js.Int.toFloat->Ok, ())

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(transformedValue), ())
})

test(
  "Throws for a Transformed Primitive factory without either a constructor, or a destructor",
  t => {
    t->Assert.throws(() => {
      S.string()->S.transform()->ignore
    }, ~expectations=ThrowsException.make(
      ~name="RescriptStructError",
      ~message="For a struct factory Transform either a constructor, or a destructor is required",
      (),
    ), ())
  },
)

test("Fails to parse primitive with transform when constructor isn't provided", t => {
  let any = %raw(`"Hello world!"`)

  let struct = S.string()->S.transform(~destructor=value => value->Ok, ())

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: Struct constructor is missing"),
    (),
  )
})

test("Fails to parse when user returns error in a Transformed Primitive constructor", t => {
  let any = %raw(`"Hello world!"`)

  let struct = S.string()->S.transform(~constructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: User error"),
    (),
  )
})

test("Successfully serializes primitive with transformation to the same type", t => {
  let value = "  Hello world!"
  let transformedAny = %raw(`"Hello world!"`)

  let struct = S.string()->S.transform(~destructor=value => value->Js.String2.trim->Ok, ())

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(transformedAny), ())
})

test("Successfully serializes primitive with transformation to another type", t => {
  let value = 123
  let transformedAny = %raw(`123`)

  let struct = S.float()->S.transform(~destructor=value => value->Js.Int.toFloat->Ok, ())

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(transformedAny), ())
})

test("Transformed Primitive serializing fails when destructor isn't provided", t => {
  let value = "Hello world!"

  let struct = S.string()->S.transform(~constructor=value => value->Ok, ())

  t->Assert.deepEqual(
    value->S.serializeWith(struct),
    Error("[ReScript Struct] Failed serializing at root. Reason: Struct destructor is missing"),
    (),
  )
})

test("Fails to serialize when user returns error in a Transformed Primitive destructor", t => {
  let value = "Hello world!"

  let struct = S.string()->S.transform(~destructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    value->S.serializeWith(struct),
    Error("[ReScript Struct] Failed serializing at root. Reason: User error"),
    (),
  )
})

test("Transform operations applyed in the right order when parsing", t => {
  let any = %raw(`123`)

  let struct =
    S.int()
    ->S.transform(~constructor=_ => Error("First transform"), ())
    ->S.transform(~constructor=_ => Error("Second transform"), ())

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: First transform"),
    (),
  )
})

test("Transform operations applyed in the right order when serializing", t => {
  let any = %raw(`123`)

  let struct =
    S.int()
    ->S.transform(~destructor=_ => Error("Second transform"), ())
    ->S.transform(~destructor=_ => Error("First transform"), ())

  t->Assert.deepEqual(
    any->S.serializeWith(struct),
    Error("[ReScript Struct] Failed serializing at root. Reason: First transform"),
    (),
  )
})

test(
  "Successfully parses a Transformed Primitive and serializes it back to the initial state",
  t => {
    let any = %raw(`123`)

    let struct =
      S.int()->S.transform(
        ~constructor=int => int->Js.Int.toFloat->Ok,
        ~destructor=value => value->Belt.Int.fromFloat->Ok,
        (),
      )

    t->Assert.deepEqual(
      any
      ->S.parseWith(~mode=Unsafe, struct)
      ->Belt.Result.map(record => record->S.serializeWith(struct)),
      Ok(Ok(any)),
      (),
    )
  },
)
