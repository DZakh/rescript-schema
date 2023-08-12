open Ava

test("Gets default value when Option.getOr is used", t => {
  let struct = S.option(S.float)->S.Option.getOr(123.)

  t->Assert.deepEqual(
    struct->S.Option.default,
    Some(Value(123.->(TestUtils.magic: float => unknown))),
    (),
  )
})

test("Returns the last default value", t => {
  let struct =
    S.option(S.float)
    ->S.Option.getOr(123.)
    ->S.transform(_ => {
      parser: number =>
        if number > 0. {
          Some("positive")
        } else {
          None
        },
    })
    ->S.Option.getOr("not positive")

  t->Assert.deepEqual(
    struct->S.Option.default,
    Some(Value("not positive"->(TestUtils.magic: string => unknown))),
    (),
  )
})

test("Gets default value when Option.getOrWith is used", t => {
  let cb = () => 123.
  let struct = S.option(S.float)->S.Option.getOrWith(cb)

  t->Assert.deepEqual(
    struct->S.Option.default,
    Some(Callback(cb->(TestUtils.magic: (unit => float) => unit => unknown))),
    (),
  )
})

test("Doesn't get default value for structs without default", t => {
  let struct = S.float

  t->Assert.deepEqual(struct->S.Option.default, None, ())
})
