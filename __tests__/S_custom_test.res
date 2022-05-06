open Ava

test("Constructs with a constructor", t => {
  let value = "Hello world!"
  let any = %raw(`"Hello world!"`)

  let struct = S.custom(~constructor=unknown => {
    switch unknown->Js.Types.classify {
    | JSString(string) => Ok(string)
    | _ => Error("Custom isn't a String")
    }
  }, ())

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
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
  let any = %raw(`"Hello world!"`)

  let struct = S.custom(~destructor=value => value->Ok, ())

  t->Assert.deepEqual(any->S.constructWith(struct), Error("Struct missing constructor at root"), ())
})

test("Construction fails when user returns error in constructor", t => {
  let wrongAny = %raw(`123`)

  let struct = S.custom(~constructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    wrongAny->S.constructWith(struct),
    Error("Struct construction failed at root. Reason: User error"),
    (),
  )
})

test("Destructs with a destructor", t => {
  let value = "Hello world!"
  let any = %raw(`"Hello world!"`)

  let struct = S.custom(~destructor=value => value->Ok, ())

  t->Assert.deepEqual(value->S.destructWith(struct), Ok(any), ())
})

test("Destruction fails when destructor isn't provided", t => {
  let value = "Hello world!"

  let struct = S.custom(~constructor=unknown => {
    switch unknown->Js.Types.classify {
    | JSString(string) => Ok(string)
    | _ => Error("Custom isn't a String")
    }
  }, ())

  t->Assert.deepEqual(value->S.destructWith(struct), Error("Struct missing destructor at root"), ())
})

test("Destruction fails when user returns error in destructor", t => {
  let value = "Hello world!"

  let struct = S.custom(~destructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    value->S.destructWith(struct),
    Error("Struct destruction failed at root. Reason: User error"),
    (),
  )
})

test("Constructs data and destructs it back to the initial state", t => {
  let any = %raw(`"Hello world!"`)

  let struct = S.custom(
    ~constructor=unknown => {
      switch unknown->Js.Types.classify {
      | JSString(string) => Ok(string)
      | _ => Error("Custom isn't a String")
      }
    },
    ~destructor=value => value->Js.Json.string->Ok,
    (),
  )

  t->Assert.deepEqual(
    any->S.constructWith(struct)->Belt.Result.map(record => record->S.destructWith(struct)),
    Ok(Ok(any)),
    (),
  )
})
