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
      Error(
        U.error({
          code: InvalidType({expected: struct->S.toUnknown, received: invalidAny}),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Fails to parse nested", t => {
    let struct = factory()

    t->Assert.deepEqual(
      nestedInvalidAny->S.parseAnyWith(struct),
      Error(
        U.error({
          code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`true`)}),
          operation: Parsing,
          path: S.Path.fromArray(["key2"]),
        }),
      ),
      (),
    )
  })

  test("Compiled parse code snapshot", t => {
    let struct = factory()

    t->U.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v1;if(!i||i.constructor!==Object){e[1](i)}v1={};for(let v0 in i){let v3;try{v3=i[v0];if(typeof v3!=="string"){e[0](v3)}}catch(v2){if(v2&&v2.s===s){v2.path=""+'["'+v0+'"]'+v2.path}throw v2}v1[v0]=v3}return v1}`,
      (),
    )
  })

  test("Compiled async parse code snapshot", t => {
    let struct = S.dict(S.unknown->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}))

    t->U.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v1,v9;if(!i||i.constructor!==Object){e[1](i)}v1={};for(let v0 in i){let v3,v4;try{v3=e[0](i[v0]);v4=()=>{try{return v3().catch(v2=>{if(v2&&v2.s===s){v2.path=""+'["'+v0+'"]'+v2.path}throw v2})}catch(v2){if(v2&&v2.s===s){v2.path=""+'["'+v0+'"]'+v2.path}throw v2}};}catch(v2){if(v2&&v2.s===s){v2.path=""+'["'+v0+'"]'+v2.path}throw v2}v1[v0]=v4}v9=()=>new Promise((v5,v6)=>{let v8=Object.keys(v1).length;for(let v0 in v1){v1[v0]().then(v7=>{v1[v0]=v7;if(v8--===1){v5(v1)}},v6)}});return v9}`,
      (),
    )
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    // TODO: Improve compiled code
    t->U.assertCompiledCode(
      ~struct,
      ~op=#serialize,
      `i=>{let v1;v1={};for(let v0 in i){let v3;try{v3=i[v0]}catch(v2){if(v2&&v2.s===s){v2.path=""+'["'+v0+'"]'+v2.path}throw v2}v1[v0]=v3}return v1}`,
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
    Error(
      U.error({
        code: OperationFailed("User error"),
        operation: Serializing,
        path: S.Path.fromLocation("a"),
      }),
    ),
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
