open Ava

test("Keeps operation of the error passed to S.Error.raise", t => {
  let schema = S.array(
    S.string->S.transform(_ => {
      parser: _ =>
        S.Error.raise(
          U.error({
            code: OperationFailed("User error"),
            operation: SerializeToUnknown,
            path: S.Path.fromArray(["a", "b"]),
          }),
        ),
    }),
  )

  t->U.assertErrorResult(
    ["Hello world!"]->S.parseAnyWith(schema),
    {
      code: OperationFailed("User error"),
      operation: SerializeToUnknown,
      path: S.Path.fromArray(["0", "a", "b"]),
    },
  )
})

test("Works with failing outside of the parser", t => {
  let schema = S.object(s =>
    s.field(
      "root",
      S.array(
        S.string->S.transform(
          _ =>
            S.Error.raise(
              U.error({
                code: OperationFailed("User error"),
                operation: Parse,
                path: S.Path.fromArray(["a", "b"]),
              }),
            ),
        ),
      ),
    )
  )

  t->U.assertErrorResult(
    ["Hello world!"]->S.parseAnyWith(schema),
    {
      code: OperationFailed("User error"),
      operation: Parse,
      path: S.Path.fromLocation("root")
      ->S.Path.concat(S.Path.dynamic)
      ->S.Path.concat(S.Path.fromArray(["a", "b"])),
    },
  )
})
