open Ava
open RescriptCore

test("Doesn't affect valid parsing", t => {
  let struct = S.string->S.catch(_ => "fallback")

  t->Assert.deepEqual("abc"->S.parseAnyWith(struct), Ok("abc"), ())
})

test("Doesn't do anything with unknown struct", t => {
  let struct = S.unknown->S.catch(_ => %raw(`"fallback"`))

  t->Assert.deepEqual("abc"->S.parseAnyWith(struct), Ok(%raw(`"abc"`)), ())
})

test("Uses fallback value when parsing failed", t => {
  let struct = S.string->S.catch(_ => "fallback")

  t->Assert.deepEqual(123->S.parseAnyWith(struct), Ok("fallback"), ())
})

test("Doesn't affect serializing in any way", t => {
  let struct = S.literal("123")->S.catch(_ => "fallback")

  t->Assert.deepEqual(
    "abc"->S.serializeToUnknownWith(struct),
    Error(
      U.error({
        code: InvalidLiteral({received: "abc"->Obj.magic, expected: String("123")}),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Provides ctx to use in catch", t => {
  t->ExecutionContext.plan(3)
  let struct = S.string->S.catch(s => {
    t->Assert.deepEqual(
      s.error,
      U.error({
        code: InvalidType({received: %raw(`123`), expected: S.string->S.toUnknown}),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
    t->Assert.deepEqual(s.input, %raw(`123`), ())
    "fallback"
  })

  t->Assert.deepEqual(123->S.parseAnyWith(struct), Ok("fallback"), ())
})

test("Can use s.fail inside of S.catch", t => {
  let struct = S.literal("0")->S.catch(s => {
    switch s.input->S.parseAnyWith(S.string) {
    | Ok(_) => "1"
    | Error(_) => s.fail("Fallback value only supported for strings.")
    }
  })

  t->Assert.deepEqual("0"->S.parseAnyWith(struct), Ok("0"), ())
  t->Assert.deepEqual("abc"->S.parseAnyWith(struct), Ok("1"), ())
  t->Assert.deepEqual(
    123->S.parseAnyWith(struct),
    Error(
      U.error({
        code: OperationFailed("Fallback value only supported for strings."),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
  t->Assert.deepEqual("0"->S.serializeToUnknownWith(struct), Ok(%raw(`"0"`)), ())
  t->Assert.deepEqual(
    "1"->S.serializeToUnknownWith(struct),
    Error(
      U.error({
        code: InvalidLiteral({expected: String("0"), received: "1"->Obj.magic}),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

asyncTest("Uses fallback value when async struct parsing failed during the sync part", async t => {
  let struct =
    S.string
    ->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)})
    ->S.catch(_ => "fallback")

  t->Assert.deepEqual(await 123->S.parseAnyAsyncWith(struct), Ok("fallback"), ())
})

asyncTest("Uses fallback value when async struct parsing failed during the async part", async t => {
  let struct =
    S.string->S.transform(s => {asyncParser: _ => s.fail("foo")})->S.catch(_ => "fallback")

  t->Assert.deepEqual(await "123"->S.parseAnyAsyncWith(struct), Ok("fallback"), ())
})

asyncTest(
  "Uses fallback value when async struct parsing failed during the async part in promise",
  async t => {
    let struct =
      S.string
      ->S.transform(s => {
        asyncParser: _ => () => Promise.resolve()->Promise.thenResolve(() => s.fail("fail")),
      })
      ->S.catch(_ => "fallback")

    t->Assert.deepEqual(await "123"->S.parseAnyAsyncWith(struct), Ok("fallback"), ())
  },
)

test("Compiled parse code snapshot", t => {
  let struct = S.bool->S.catch(_ => false)

  t->U.assertCompiledCode(
    ~struct,
    ~op=#parse,
    `i=>{try{if(typeof i!=="boolean"){e[1](i)}}catch(v0){if(v0&&v0.s===s){i=e[0](i,v0)}else{throw v0}}return i}`,
  )
})

test("Compiled async parse code snapshot", t => {
  let struct =
    S.bool->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)})->S.catch(_ => false)

  t->U.assertCompiledCode(
    ~struct,
    ~op=#parse,
    `i=>{let v1,v2;try{if(typeof i!=="boolean"){e[1](i)}v1=e[2](i);v2=()=>{try{return v1().catch(v0=>{if(v0&&v0.s===s){return e[0](i,v0)}else{throw v0}})}catch(v0){if(v0&&v0.s===s){return Promise.resolve(e[0](i,v0))}else{throw v0}}};}catch(v0){if(v0&&v0.s===s){v2=()=>Promise.resolve(e[0](i,v0))}else{throw v0}}return v2}`,
  )
})

test("Compiled serialize code snapshot", t => {
  let struct = S.bool->S.catch(_ => false)

  t->U.assertCompiledCodeIsNoop(~struct, ~op=#serialize)
})
