open Ava

module CommonWithNested = {
  let value = list{"Hello world!", ""}
  let any = %raw(`["Hello world!", ""]`)
  let invalidAny = %raw(`true`)
  let nestedInvalidAny = %raw(`["Hello world!", 1]`)
  let factory = () => S.list(S.string)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    switch invalidAny->S.parseAnyWith(struct) {
    | Ok(_) => t->Assert.fail("Unexpected result.")
    | Error(e) => {
        t->Assert.deepEqual(e.operation, Parsing, ())
        t->Assert.deepEqual(e.path, S.Path.empty, ())
        switch e.code {
        | InvalidType({expected, received}) => {
            t->Assert.deepEqual(received, invalidAny, ())
            t->U.unsafeAssertEqualStructs(expected, struct, ())
          }
        | _ => t->Assert.fail("Unexpected code.")
        }
      }
    }
  })

  test("Fails to parse nested", t => {
    let struct = factory()

    t->Assert.deepEqual(
      nestedInvalidAny->S.parseAnyWith(struct),
      Error(
        U.error({
          code: InvalidType({expected: S.string->S.toUnknown, received: 1->Obj.magic}),
          operation: Parsing,
          path: S.Path.fromArray(["1"]),
        }),
      ),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(struct), Ok(any), ())
  })
}

test("Successfully parses list of optional items", t => {
  let struct = S.list(S.option(S.string))

  t->Assert.deepEqual(
    %raw(`["a", undefined, undefined, "b"]`)->S.parseAnyWith(struct),
    Ok(list{Some("a"), None, None, Some("b")}),
    (),
  )
})
