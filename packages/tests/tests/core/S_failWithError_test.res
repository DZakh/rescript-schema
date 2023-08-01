open Ava

test("FIXME: Should keep operation of the error passed to advanced fail", t => {
  let struct = S.array(
    S.string->S.transform(s => {
      parser: _ =>
        s.failWithError({
          code: OperationFailed("User error"),
          operation: Serializing,
          path: S.Path.fromArray(["a", "b"]),
        }),
    }),
  )

  t->Assert.deepEqual(
    ["Hello world!"]->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: S.Path.fromArray(["0", "a", "b"]),
    }),
    (),
  )
})

test("Works with failing outside of the parser", t => {
  let struct = S.object(s =>
    s.field(
      "root",
      S.array(
        S.string->S.transform(
          s =>
            s.failWithError({
              code: OperationFailed("User error"),
              operation: Serializing,
              path: S.Path.fromArray(["a", "b"]),
            }),
        ),
      ),
    )
  )

  t->Assert.deepEqual(
    ["Hello world!"]->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: S.Path.fromLocation("root")
      ->S.Path.concat(S.Path.dynamic)
      ->S.Path.concat(S.Path.fromArray(["a", "b"])),
    }),
    (),
  )
})
