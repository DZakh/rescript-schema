open Ava

test("FIXME: Should keep operation of the error passed to advanced fail", t => {
  let schema = S.array(
    S.string->S.transform(s => {
      parser: _ =>
        s.failWithError(
          U.error({
            code: OperationFailed("User error"),
            operation: Serializing,
            path: S.Path.fromArray(["a", "b"]),
          }),
        ),
    }),
  )

  t->U.assertErrorResult(["Hello world!"]->S.parseAnyWith(schema), {
        code: OperationFailed("User error"),
        operation: Parsing,
        path: S.Path.fromArray(["0", "a", "b"]),
      })
})

test("Works with failing outside of the parser", t => {
  let schema = S.object(s =>
    s.field(
      "root",
      S.array(
        S.string->S.transform(
          s =>
            s.failWithError(
              U.error({
                code: OperationFailed("User error"),
                operation: Serializing,
                path: S.Path.fromArray(["a", "b"]),
              }),
            ),
        ),
      ),
    )
  )

  t->U.assertErrorResult(["Hello world!"]->S.parseAnyWith(schema), {
        code: OperationFailed("User error"),
        operation: Parsing,
        path: S.Path.fromLocation("root")
        ->S.Path.concat(S.Path.dynamic)
        ->S.Path.concat(S.Path.fromArray(["a", "b"])),
      })
})
