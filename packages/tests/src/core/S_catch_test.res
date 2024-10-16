open Ava
open RescriptCore

test("Doesn't affect valid parsing", t => {
  let schema = S.string->S.catch(_ => "fallback")

  t->Assert.deepEqual("abc"->S.parseAnyWith(schema), Ok("abc"), ())
})

test("Doesn't do anything with unknown schema", t => {
  let schema = S.unknown->S.catch(_ => %raw(`"fallback"`))

  t->Assert.deepEqual("abc"->S.parseAnyWith(schema), Ok(%raw(`"abc"`)), ())
})

test("Uses fallback value when parsing failed", t => {
  let schema = S.string->S.catch(_ => "fallback")

  t->Assert.deepEqual(123->S.parseAnyWith(schema), Ok("fallback"), ())
})

test("Doesn't affect serializing in any way", t => {
  let schema = S.literal("123")->S.catch(_ => "fallback")

  t->U.assertError(
    () => "abc"->S.reverseConvertWith(schema),
    {
      code: InvalidType({received: "abc"->Obj.magic, expected: S.literal("123")->S.toUnknown}),
      operation: SerializeToUnknown,
      path: S.Path.empty,
    },
  )
})

test("Provides ctx to use in catch", t => {
  t->ExecutionContext.plan(3)
  let schema = S.string->S.catch(s => {
    t->Assert.deepEqual(
      s.error,
      U.error({
        code: InvalidType({received: %raw(`123`), expected: S.string->S.toUnknown}),
        operation: Parse,
        path: S.Path.empty,
      }),
      (),
    )
    t->Assert.deepEqual(s.input, %raw(`123`), ())
    "fallback"
  })

  t->Assert.deepEqual(123->S.parseAnyWith(schema), Ok("fallback"), ())
})

test("Can use s.fail inside of S.catch", t => {
  let schema = S.literal("0")->S.catch(s => {
    switch s.input->S.parseAnyWith(S.string) {
    | Ok(_) => "1"
    | Error(_) => s.fail("Fallback value only supported for strings.")
    }
  })
  t->Assert.deepEqual("0"->S.parseAnyWith(schema), Ok("0"), ())
  t->Assert.deepEqual("abc"->S.parseAnyWith(schema), Ok("1"), ())
  t->U.assertErrorResult(
    123->S.parseAnyWith(schema),
    {
      code: OperationFailed("Fallback value only supported for strings."),
      operation: Parse,
      path: S.Path.empty,
    },
  )
  t->Assert.deepEqual("0"->S.reverseConvertWith(schema), %raw(`"0"`), ())
  t->U.assertError(
    () => "1"->S.reverseConvertWith(schema),
    {
      code: InvalidType({expected: S.literal("0")->S.toUnknown, received: "1"->Obj.magic}),
      operation: SerializeToUnknown,
      path: S.Path.empty,
    },
  )
})

asyncTest("Uses fallback value when async schema parsing failed during the sync part", async t => {
  let schema =
    S.string
    ->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)})
    ->S.catch(_ => "fallback")

  t->Assert.deepEqual(await 123->S.parseAnyAsyncWith(schema), Ok("fallback"), ())
})

asyncTest("Uses fallback value when async schema parsing failed during the async part", async t => {
  let schema =
    S.string->S.transform(s => {asyncParser: _ => s.fail("foo")})->S.catch(_ => "fallback")

  t->Assert.deepEqual(await "123"->S.parseAnyAsyncWith(schema), Ok("fallback"), ())
})

asyncTest(
  "Uses fallback value when async schema parsing failed during the async part in promise",
  async t => {
    let schema =
      S.string
      ->S.transform(s => {
        asyncParser: _ => () => Promise.resolve()->Promise.thenResolve(() => s.fail("fail")),
      })
      ->S.catch(_ => "fallback")

    t->Assert.deepEqual(await "123"->S.parseAnyAsyncWith(schema), Ok("fallback"), ())
  },
)

test("Compiled parse code snapshot", t => {
  let schema = S.bool->S.catch(_ => false)

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{try{if(typeof i!=="boolean"){e[1](i)}}catch(v0){if(v0&&v0.s===s){i=e[0](i,v0)}else{throw v0}}return i}`,
  )
})

test("Compiled async parse code snapshot", t => {
  let schema =
    S.bool->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)})->S.catch(_ => false)

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{let v1;try{if(typeof i!=="boolean"){e[1](i)}v1=e[2](i).catch(v0=>{if(v0&&v0.s===s){return e[0](i,v0)}else{throw v0}})}catch(v0){if(v0&&v0.s===s){v1=Promise.resolve(e[0](i,v0))}else{throw v0}}return v1}`,
  )
})

test("Compiled serialize code snapshot", t => {
  let schema = S.bool->S.catch(_ => false)

  t->U.assertCompiledCodeIsNoop(~schema, ~op=#Serialize)
})
