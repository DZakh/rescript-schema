open Ava

module CommonWithNested = {
  let value = Js.Dict.fromArray([("key1", "value1"), ("key2", "value2")])
  let any = %raw(`{"key1":"value1","key2":"value2"}`)
  let wrongAny = %raw(`true`)
  let nestedWrongAny = %raw(`{"key1":"value1","key2":true}`)
  let factory = () => S.dict(S.string())

  ava->test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  ava->test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })

  ava->test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "Dict", received: "Bool"}),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  ava->test("Fails to parse nested", t => {
    let struct = factory()

    t->Assert.deepEqual(
      nestedWrongAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "String", received: "Bool"}),
        operation: Parsing,
        path: ["key2"],
      }),
      (),
    )
  })
}

ava->test("Successfully parses dict with int keys", t => {
  let struct = S.dict(S.string())

  t->Assert.deepEqual(
    %raw(`{1:"b",2:"d"}`)->S.parseWith(struct),
    Ok(Js.Dict.fromArray([("1", "b"), ("2", "d")])),
    (),
  )
})

ava->test("Successfully parses dict with optional items", t => {
  let struct = S.dict(S.option(S.string()))

  t->Assert.deepEqual(
    %raw(`{"key1":"value1","key2":undefined}`)->S.parseWith(struct),
    Ok(Js.Dict.fromArray([("key1", Some("value1")), ("key2", None)])),
    (),
  )
})
