open Ava

asyncTest("Resets S.float cache after disableNanNumberCheck=true removed", async t => {
  let nan = %raw(`NaN`)

  S.setGlobalConfig({
    disableNanNumberCheck: true,
  })
  t->Assert.deepEqual(nan->S.parseAnyWith(S.float), Ok(nan), ())
  t->Assert.deepEqual(await nan->S.parseAnyAsyncWith(S.float), Ok(nan), ())
  t->Assert.deepEqual(nan->S.assertAnyWith(S.float), (), ())

  S.setGlobalConfig({})
  t->Assert.deepEqual(
    nan->S.parseAnyWith(S.float),
    Error(
      S.Error.make(
        ~code=S.InvalidType({
          expected: S.float->S.toUnknown,
          received: nan,
        }),
        ~operation=S.Parse,
        ~path=S.Path.empty,
      ),
    ),
    (),
  )
  t->Assert.deepEqual(
    await nan->S.parseAnyAsyncWith(S.float),
    Error(
      S.Error.make(
        ~code=S.InvalidType({
          expected: S.float->S.toUnknown,
          received: nan,
        }),
        ~operation=S.ParseAsync,
        ~path=S.Path.empty,
      ),
    ),
    (),
  )
  t->Assert.throws(
    () => {
      nan->S.assertAnyWith(S.float)
    },
    ~expectations={
      message: "Failed asserting at root. Reason: Expected Float, received NaN",
    },
    (),
  )
})
