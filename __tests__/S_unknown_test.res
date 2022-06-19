open Ava

module Common = {
  let any = %raw(`"Hello world!"`)
  let factory = () => S.unknown()

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(any), ())
  })

  test("Successfully parses in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(~mode=Unsafe, struct), Ok(any), ())
  })

  test("Successfully serializes in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.serializeWith(~mode=Safe, struct), Ok(any), ())
  })

  test("Successfully serializes in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.serializeWith(~mode=Unsafe, struct), Ok(any), ())
  })
}

module Custom = {
  test(
    "Parses data and serializes it back to the initial state with transformation. aka custom struct factory",
    t => {
      let any = %raw(`"Hello world!"`)

      let struct = S.unknown()->S.transformUnknown(
        ~parser=unknown => {
          switch unknown->Js.Types.classify {
          | JSString(string) => Ok(string)
          | _ => Error("Custom isn't a String")
          }
        },
        ~serializer=value => value->Ok,
        (),
      )

      t->Assert.deepEqual(
        any
        ->S.parseWith(struct)
        ->Belt.Result.map(record => record->S.serializeWith(~mode=Safe, struct)),
        Ok(Ok(any)),
        (),
      )
    },
  )
}
