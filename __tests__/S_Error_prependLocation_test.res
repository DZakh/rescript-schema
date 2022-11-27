open Ava

test("Works", t => {
  let initialError: S.Error.t = {
    code: MissingParser,
    operation: Parsing,
    path: [],
  }

  t->Assert.deepEqual(
    initialError->S.Error.prependLocation("first"),
    {
      code: MissingParser,
      operation: Parsing,
      path: ["first"],
    },
    (),
  )
  t->Assert.deepEqual(
    initialError->S.Error.prependLocation("first")->S.Error.prependLocation("second"),
    {
      code: MissingParser,
      operation: Parsing,
      path: ["second", "first"],
    },
    (),
  )
})
