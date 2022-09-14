open Ava

ava->test("Parses unknown primitive with transformation to the same type", t => {
  let struct = S.string()->S.transform(~parser=value => value->Js.String2.trim, ())

  t->Assert.deepEqual("  Hello world!"->S.parseWith(struct), Ok("Hello world!"), ())
})

ava->test("Parses unknown primitive with transformation to another type", t => {
  let struct = S.int()->S.transform(~parser=value => value->Js.Int.toFloat, ())

  t->Assert.deepEqual(123->S.parseWith(struct), Ok(123.), ())
})

ava->test(
  "Throws for a Transformed Primitive factory without either a parser, or a serializer",
  t => {
    t->Assert.throws(() => {
      S.string()->S.transform()->ignore
    }, ~expectations=ThrowsException.make(
      ~message=String(
        "[rescript-struct] For a struct factory Transform either a parser, or a serializer is required",
      ),
      (),
    ), ())
  },
)

ava->test("Fails to parse primitive with transform when parser isn't provided", t => {
  let struct = S.string()->S.transform(~serializer=value => value, ())

  t->Assert.deepEqual(
    "Hello world!"->S.parseWith(struct),
    Error({
      code: MissingParser,
      path: [],
      operation: Parsing,
    }),
    (),
  )
})

ava->test("Fails to parse when user raises error in a Transformed Primitive parser", t => {
  let struct = S.string()->S.transform(~parser=_ => S.Error.raise("User error"), ())

  t->Assert.deepEqual(
    "Hello world!"->S.parseWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

ava->test("Successfully serializes primitive with transformation to the same type", t => {
  let struct = S.string()->S.transform(~serializer=value => value->Js.String2.trim, ())

  t->Assert.deepEqual("  Hello world!"->S.serializeWith(struct), Ok(%raw(`"Hello world!"`)), ())
})

ava->test("Successfully serializes primitive with transformation to another type", t => {
  let struct = S.float()->S.transform(~serializer=value => value->Js.Int.toFloat, ())

  t->Assert.deepEqual(123->S.serializeWith(struct), Ok(%raw(`123`)), ())
})

ava->test("Transformed Primitive serializing fails when serializer isn't provided", t => {
  let struct = S.string()->S.transform(~parser=value => value, ())

  t->Assert.deepEqual(
    "Hello world!"->S.serializeWith(struct),
    Error({
      code: MissingSerializer,
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

ava->test("Fails to serialize when user raises error in a Transformed Primitive serializer", t => {
  let struct = S.string()->S.transform(~serializer=_ => S.Error.raise("User error"), ())

  t->Assert.deepEqual(
    "Hello world!"->S.serializeWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

ava->test("Transform operations applyed in the right order when parsing", t => {
  let struct =
    S.int()
    ->S.transform(~parser=_ => S.Error.raise("First transform"), ())
    ->S.transform(~parser=_ => S.Error.raise("Second transform"), ())

  t->Assert.deepEqual(
    123->S.parseWith(struct),
    Error({
      code: OperationFailed("First transform"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

ava->test("Transform operations applyed in the right order when serializing", t => {
  let struct =
    S.int()
    ->S.transform(~serializer=_ => S.Error.raise("First transform"), ())
    ->S.transform(~serializer=_ => S.Error.raise("Second transform"), ())

  t->Assert.deepEqual(
    123->S.serializeWith(struct),
    Error({
      code: OperationFailed("Second transform"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

ava->test(
  "Successfully parses a Transformed Primitive and serializes it back to the initial state",
  t => {
    let any = %raw(`123`)

    let struct =
      S.int()->S.transform(
        ~parser=int => int->Js.Int.toFloat,
        ~serializer=value => value->Belt.Int.fromFloat,
        (),
      )

    t->Assert.deepEqual(
      any->S.parseWith(struct)->Belt.Result.map(object => object->S.serializeWith(struct)),
      Ok(Ok(any)),
      (),
    )
  },
)
