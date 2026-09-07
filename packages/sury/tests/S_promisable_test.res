open Vitest

let syncSchema = S.string->S.to(S.float)
let asyncSchema =
  S.string->S.to(S.float, ~custom={decode: Async(s => Promise.resolve(Float.parseFloat(s))), encode: Auto})

// One compiled operation answers for both: a synchronous schema hands back the
// result itself, an async one a promise of it.
test("parseAsPromisableResult answers in the schema's own shape", t => {
  switch %raw(`"1.5"`)->S.parseAsPromisableResult(~to=syncSchema)->S.classify {
  | Sync(result) => t->Assert.deepEqual(result, Ok(1.5))
  | Async(_) => t->Assert.fail("Expected Sync")
  }
  switch %raw(`1`)->S.parseAsPromisableResult(~to=syncSchema)->S.classify {
  | Sync(Error(error)) => t->Assert.is(error.message, "Expected string, received 1")
  | _ => t->Assert.fail("Expected Sync(Error)")
  }
})

asyncTest("an async schema answers with a promise of the result", async t => {
  switch %raw(`"2.5"`)->S.parseAsPromisableResult(~to=asyncSchema)->S.classify {
  | Async(promise) => t->Assert.deepEqual(await promise, Ok(2.5))
  | Sync(_) => t->Assert.fail("Expected Async")
  }
  // A value that fails before the first await still comes back as a promise,
  // so the caller branches once.
  switch %raw(`1`)->S.parseAsPromisableResult(~to=asyncSchema)->S.classify {
  | Async(promise) => t->Assert.deepEqual((await promise)->Result.isError, true)
  | Sync(_) => t->Assert.fail("Expected Async")
  }
})

test("convert and make take the same outcome", t => {
  switch 1.5->S.convertAsPromisableResult(~from=syncSchema, ~to=S.string)->S.classify {
  | Sync(result) => t->Assert.deepEqual(result, Ok("1.5"))
  | Async(_) => t->Assert.fail("Expected Sync")
  }
  switch 1.5->S.makeAsPromisableResult(~schema=syncSchema)->S.classify {
  | Sync(result) => t->Assert.deepEqual(result, Ok(1.5))
  | Async(_) => t->Assert.fail("Expected Sync")
  }
})
