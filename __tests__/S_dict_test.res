open Ava

module CommonWithNested = {
  let value = Js.Dict.fromArray([("key1", "value1"), ("key2", "value2")])
  let any = %raw(`{"key1":"value1","key2":"value2"}`)
  let wrongAny = %raw(`true`)
  let nestedWrongAny = %raw(`{"key1":"value1","key2":true}`)
  let factory = () => S.dict(S.string)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(struct), Ok(any), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: "Dict", received: "Bool"}),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to parse nested", t => {
    let struct = factory()

    t->Assert.deepEqual(
      nestedWrongAny->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: "String", received: "Bool"}),
        operation: Parsing,
        path: S.Path.fromArray(["key2"]),
      }),
      (),
    )
  })
}

test("Successfully parses dict with int keys", t => {
  let struct = S.dict(S.string)

  t->Assert.deepEqual(
    %raw(`{1:"b",2:"d"}`)->S.parseAnyWith(struct),
    Ok(Js.Dict.fromArray([("1", "b"), ("2", "d")])),
    (),
  )
})

test("Applies operation for each item on serializing", t => {
  let struct = S.dict(S.jsonString(S.int))

  t->Assert.deepEqual(
    Js.Dict.fromArray([("a", 1), ("b", 2)])->S.serializeToUnknownWith(struct),
    Ok(
      %raw(`{
        "a": "1",
        "b": "2",
      }`),
    ),
    (),
  )
})

test("Fails to serialize dict item", t => {
  let struct = S.dict(S.string->S.refine(~serializer=_ => S.fail("User error"), ()))

  t->Assert.deepEqual(
    Js.Dict.fromArray([("a", "aa"), ("b", "bb")])->S.serializeToUnknownWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: S.Path.fromLocation("a"),
    }),
    (),
  )
})

test("Successfully parses dict with optional items", t => {
  let struct = S.dict(S.option(S.string))

  t->Assert.deepEqual(
    %raw(`{"key1":"value1","key2":undefined}`)->S.parseAnyWith(struct),
    Ok(Js.Dict.fromArray([("key1", Some("value1")), ("key2", None)])),
    (),
  )
})
