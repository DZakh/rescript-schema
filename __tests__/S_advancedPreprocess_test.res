open Ava

let preprocessNumberToString = S.advancedPreprocess(
  _,
  ~parser=(~struct as _) => Sync(
    unknown => {
      if unknown->Js.typeof === "number" {
        unknown->Obj.magic->Js.Float.toString
      } else {
        unknown->Obj.magic
      }
    },
  ),
  ~serializer=(~struct as _) => Sync(
    unknown => {
      if unknown->Js.typeof === "string" {
        let string: string = unknown->Obj.magic
        switch string->Belt.Float.fromString {
        | Some(float) => float->Obj.magic
        | None => string
        }
      } else {
        unknown->Obj.magic
      }
    },
  ),
  (),
)

test("Successfully parses", t => {
  let struct = S.string()->preprocessNumberToString

  t->Assert.deepEqual(123->S.parseWith(struct), Ok("123"), ())
  t->Assert.deepEqual("Hello world!"->S.parseWith(struct), Ok("Hello world!"), ())
})

test("Throws for factory without either a parser, or a serializer", t => {
  t->Assert.throws(
    () => {
      S.string()->S.advancedPreprocess()
    },
    ~expectations={
      message: "[rescript-struct] For a struct factory Preprocess either a parser, or a serializer is required",
    },
    (),
  )
})

test("Fails to parse when user raises error in parser", t => {
  let struct =
    S.string()->S.advancedPreprocess(
      ~parser=(~struct as _) => Sync(_ => S.Error.raise("User error")),
      (),
    )

  t->Assert.deepEqual(
    "Hello world!"->S.parseWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully serializes", t => {
  let struct = S.string()->preprocessNumberToString

  t->Assert.deepEqual("Hello world!"->S.serializeWith(struct), Ok(%raw(`"Hello world!"`)), ())
  t->Assert.deepEqual("123"->S.serializeWith(struct), Ok(%raw(`123`)), ())
})

test("Fails to serialize when user raises error in serializer", t => {
  let struct =
    S.string()->S.advancedPreprocess(
      ~serializer=(~struct as _) => Sync(_ => S.Error.raise("User error")),
      (),
    )

  t->Assert.deepEqual(
    "Hello world!"->S.serializeWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Preprocess operations applyed in the right order when parsing", t => {
  let struct =
    S.int()
    ->S.advancedPreprocess(
      ~parser=(~struct as _) => Sync(_ => S.Error.raise("First preprocess")),
      (),
    )
    ->S.advancedPreprocess(
      ~parser=(~struct as _) => Sync(_ => S.Error.raise("Second preprocess")),
      (),
    )

  t->Assert.deepEqual(
    123->S.parseWith(struct),
    Error({
      code: OperationFailed("Second preprocess"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Preprocess operations applyed in the right order when serializing", t => {
  let struct =
    S.int()
    ->S.advancedPreprocess(
      ~serializer=(~struct as _) => Sync(_ => S.Error.raise("First preprocess")),
      (),
    )
    ->S.advancedPreprocess(
      ~serializer=(~struct as _) => Sync(_ => S.Error.raise("Second preprocess")),
      (),
    )

  t->Assert.deepEqual(
    123->S.serializeWith(struct),
    Error({
      code: OperationFailed("First preprocess"),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to parse async using parseWith", t => {
  let struct =
    S.string()->S.advancedPreprocess(
      ~parser=(~struct as _) => Async(value => Promise.resolve(value)),
      (),
    )

  t->Assert.deepEqual(
    %raw(`"Hello world!"`)->S.parseWith(struct),
    Error({
      code: UnexpectedAsync,
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

asyncTest("Successfully parses async using parseAsyncWith", t => {
  let struct =
    S.string()->S.advancedPreprocess(
      ~parser=(~struct as _) => Async(value => Promise.resolve(value)),
      (),
    )

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

asyncTest("Fails to parse async with user error", t => {
  let struct =
    S.string()->S.advancedPreprocess(
      ~parser=(~struct as _) => Async(_ => S.Error.raise("User error")),
      (),
    )

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(
      result,
      Error({
        S.Error.code: OperationFailed("User error"),
        path: S.Path.empty,
        operation: Parsing,
      }),
      (),
    )
  })
})

asyncTest("Can apply other actions after async preprocess", t => {
  let struct =
    S.string()
    ->S.advancedPreprocess(~parser=(~struct as _) => Async(value => Promise.resolve(value)), ())
    ->S.String.trimmed()
    ->S.advancedPreprocess(~parser=(~struct as _) => Async(value => Promise.resolve(value)), ())

  %raw(`"    Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

test("Applies preproces for union structs separately", t => {
  let prepareEnvStruct = S.advancedPreprocess(
    _,
    ~parser=(~struct) => {
      switch struct->S.classify {
      | Bool =>
        Sync(
          unknown => {
            switch unknown->Obj.magic {
            | "true"
            | "t"
            | "1" => true
            | "false"
            | "f"
            | "0" => false
            | _ => unknown->Obj.magic
            }->Obj.magic
          },
        )
      | Int =>
        Sync(
          unknown => {
            if unknown->Js.typeof === "string" {
              %raw(`+unknown`)
            } else {
              unknown
            }
          },
        )
      | _ => Sync(Obj.magic)
      }
    },
    (),
  )

  let struct =
    S.union([
      S.bool()->S.transform(~parser=bool => #Bool(bool), ()),
      S.int()->S.transform(~parser=int => #Int(int), ()),
    ])->prepareEnvStruct

  t->Assert.deepEqual("f"->S.parseWith(struct), Ok(#Bool(false)), ())
  t->Assert.deepEqual("1"->S.parseWith(struct), Ok(#Bool(true)), ())
  t->Assert.deepEqual("2"->S.parseWith(struct), Ok(#Int(2)), ())
})
