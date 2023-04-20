open Ava

test("Doesn't affect valid parsing", t => {
  let struct = S.string()->S.catch(_ => "fallback")

  t->Assert.deepEqual("abc"->S.parseAnyWith(struct), Ok("abc"), ())
})

test("Doesn't do anything with unknown struct", t => {
  let struct = S.unknown()->S.catch(_ => %raw(`"fallback"`))

  t->Assert.deepEqual("abc"->S.parseAnyWith(struct), Ok(%raw(`"abc"`)), ())
})

test("Uses fallback value when parsing failed", t => {
  let struct = S.string()->S.catch(_ => "fallback")

  t->Assert.deepEqual(123->S.parseAnyWith(struct), Ok("fallback"), ())
})

test("Doesn't affect serializing in any way", t => {
  let struct = S.literal(String("123"))->S.catch(_ => "fallback")

  t->Assert.deepEqual(
    "abc"->S.serializeToUnknownWith(struct),
    Error({
      code: UnexpectedValue({received: `"abc"`, expected: `"123"`}),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Provides ctx to use in catch", t => {
  t->ExecutionContext.plan(2)

  let struct = S.string()->S.catch(ctx => {
    t->Assert.deepEqual(
      ctx,
      {
        error: {
          code: UnexpectedType({received: `Float`, expected: `String`}),
          operation: Parsing,
          path: S.Path.empty,
        },
        input: %raw("123"),
      },
      (),
    )
    "fallback"
  })

  t->Assert.deepEqual(123->S.parseAnyWith(struct), Ok("fallback"), ())
})

test("Can use S.fail inside of S.catch", t => {
  let struct = S.literal(String("0"))->S.catch(ctx => {
    switch ctx.input->S.parseAnyWith(S.string()) {
    | Ok(_) => "1"
    | Error(_) => S.fail("Fallback value only supported for strings.")
    }
  })

  t->Assert.deepEqual("0"->S.parseAnyWith(struct), Ok("0"), ())
  t->Assert.deepEqual("abc"->S.parseAnyWith(struct), Ok("1"), ())
  t->Assert.deepEqual(
    123->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Fallback value only supported for strings."),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
  t->Assert.deepEqual("0"->S.serializeToUnknownWith(struct), Ok(%raw(`"0"`)), ())
  t->Assert.deepEqual(
    "1"->S.serializeToUnknownWith(struct),
    Error({
      code: UnexpectedValue({expected: `"0"`, received: `"1"`}),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

asyncTest("Uses fallback value when async struct parsing failed during the sync part", async t => {
  let struct =
    S.string()->S.refine(~asyncParser=_ => Promise.resolve(), ())->S.catch(_ => "fallback")

  t->Assert.deepEqual(await 123->S.parseAnyAsyncWith(struct), Ok("fallback"), ())
})

asyncTest("Uses fallback value when async struct parsing failed during the async part", async t => {
  let struct = S.string()->S.refine(~asyncParser=_ => S.fail("fail"), ())->S.catch(_ => "fallback")

  t->Assert.deepEqual(await "123"->S.parseAnyAsyncWith(struct), Ok("fallback"), ())
})

asyncTest(
  "Uses fallback value when async struct parsing failed during the async part in promise",
  async t => {
    let struct =
      S.string()
      ->S.refine(~asyncParser=_ => Promise.resolve()->Promise.thenResolve(() => S.fail("fail")), ())
      ->S.catch(_ => "fallback")

    t->Assert.deepEqual(await "123"->S.parseAnyAsyncWith(struct), Ok("fallback"), ())
  },
)
