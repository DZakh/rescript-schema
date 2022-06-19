open Ava

test("Parses data and serializes it back to the initial state with transformation", t => {
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
})
