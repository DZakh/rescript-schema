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
