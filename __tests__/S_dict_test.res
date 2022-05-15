open Ava

module CommonWithNested = {
  let value = Js.Dict.fromArray([("key1", "value1"), ("key2", "value2")])
  let any = %raw(`{"key1":"value1","key2":"value2"}`)
  let wrongAny = %raw(`true`)
  let nestedWrongAny = %raw(`{"key1":"value1","key2":true}`)
  let jsonString = `{"key1":"value1","key2":"value2"}`
  let wrongJsonString = `true`
  let factory = () => S.dict(S.string())

  test("Successfully constructs", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
  })

  test("Successfully destructs", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.destructWith(struct), Ok(any), ())
  })

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error("[ReScript Struct] Failed parsing at root. Reason: Expected Dict, got Bool"),
      (),
    )
  })

  test("Fails to parse nested", t => {
    let struct = factory()

    t->Assert.deepEqual(
      nestedWrongAny->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at ["key2"]. Reason: Expected String, got Bool`),
      (),
    )
  })

  test("Successfully parses from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(jsonString->S.parseJsonWith(struct), Ok(value), ())
  })

  test("Fails to parse from JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongJsonString->S.parseJsonWith(struct),
      Error(`[ReScript Struct] Failed parsing at root. Reason: Expected Dict, got Bool`),
      (),
    )
  })

  test("Successfully serializes to JSON string", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeJsonWith(struct), Ok(jsonString), ())
  })
}

test("Successfully parses dict with int keys", t => {
  let struct = S.dict(S.string())

  t->Assert.deepEqual(
    %raw(`{1:"b",2:"d"}`)->S.parseWith(struct),
    Ok(Js.Dict.fromArray([("1", "b"), ("2", "d")])),
    (),
  )
})

test("Successfully parses dict with optional items", t => {
  let struct = S.dict(S.option(S.string()))

  t->Assert.deepEqual(
    %raw(`{"key1":"value1","key2":undefined}`)->S.parseWith(struct),
    Ok(Js.Dict.fromArray([("key1", Some("value1")), ("key2", None)])),
    (),
  )
})
