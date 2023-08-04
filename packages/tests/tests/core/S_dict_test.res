open Ava
open RescriptCore

module CommonWithNested = {
  let value = Dict.fromArray([("key1", "value1"), ("key2", "value2")])
  let any = %raw(`{"key1":"value1","key2":"value2"}`)
  let invalidAny = %raw(`true`)
  let nestedInvalidAny = %raw(`{"key1":"value1","key2":true}`)
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
      invalidAny->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: struct->S.toUnknown, received: invalidAny}),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to parse nested", t => {
    let struct = factory()

    t->Assert.deepEqual(
      nestedInvalidAny->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`true`)}),
        operation: Parsing,
        path: S.Path.fromArray(["key2"]),
      }),
      (),
    )
  })

  test("Compiled parse code snapshot", t => {
    let struct = factory()

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v1;if(!i||i.constructor!==Object){e[0](i)}v1={};for(let v0 in i){let v2;v2=i[v0];try{if(typeof v2!=="string"){e[1](v2)}}catch(t){if(t&&t.s===s){t.p=""+'["'+v0+'"]'+t.p}throw t}v1[v0]=v2}return v1}`,
      (),
    )
  })

  test("Compiled async parse code snapshot", t => {
    let struct = S.dict(S.unknown->S.asyncParserRefine(_ => _ => Promise.resolve()))

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v1,v10;if(!i||i.constructor!==Object){e[0](i)}v1={};for(let v0 in i){let v2,v3,v4,v5;v2=i[v0];try{v4=e[1](v2);v3=()=>v4().then(_=>v2);}catch(t){if(t&&t.s===s){t.p=""+'["'+v0+'"]'+t.p}throw t}v5=()=>{try{return v3().catch(t=>{if(t&&t.s===s){t.p=""+'["'+v0+'"]'+t.p}throw t})}catch(t){if(t&&t.s===s){t.p=""+'["'+v0+'"]'+t.p}throw t}};v1[v0]=v5}v10=()=>new Promise((v6,v7)=>{let v9=Object.keys(v1).length;for(let v0 in v1){v1[v0]().then(v8=>{v1[v0]=v8;if(v9--===1){v6(v1)}},v7)}});return v10}`,
      (),
    )
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    // TODO: Improve compiled code
    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#serialize,
      `i=>{let v1;v1={};for(let v0 in i){let v2;v2=i[v0];try{}catch(t){if(t&&t.s===s){t.p=""+'["'+v0+'"]'+t.p}throw t}v1[v0]=v2}return v1}`,
      (),
    )
  })
}

test("Successfully parses dict with int keys", t => {
  let struct = S.dict(S.string)

  t->Assert.deepEqual(
    %raw(`{1:"b",2:"d"}`)->S.parseAnyWith(struct),
    Ok(Dict.fromArray([("1", "b"), ("2", "d")])),
    (),
  )
})

test("Applies operation for each item on serializing", t => {
  let struct = S.dict(S.jsonString(S.int))

  t->Assert.deepEqual(
    Dict.fromArray([("a", 1), ("b", 2)])->S.serializeToUnknownWith(struct),
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
  let struct = S.dict(S.string->S.refine(s => _ => s.fail("User error")))

  t->Assert.deepEqual(
    Dict.fromArray([("a", "aa"), ("b", "bb")])->S.serializeToUnknownWith(struct),
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
    Ok(Dict.fromArray([("key1", Some("value1")), ("key2", None)])),
    (),
  )
})
