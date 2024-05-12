open Ava
open RescriptCore

module CommonWithNested = {
  let value = Dict.fromArray([("key1", "value1"), ("key2", "value2")])
  let any = %raw(`{"key1":"value1","key2":"value2"}`)
  let invalidAny = %raw(`true`)
  let nestedInvalidAny = %raw(`{"key1":"value1","key2":true}`)
  let factory = () => S.dict(S.string)

  test("Successfully parses", t => {
    let schema = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(schema), Ok(value), ())
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(schema), Ok(any), ())
  })

  test("Fails to parse", t => {
    let schema = factory()

    t->U.assertErrorResult(
      invalidAny->S.parseAnyWith(schema),
      {
        code: InvalidType({expected: schema->S.toUnknown, received: invalidAny}),
        operation: Parsing,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse nested", t => {
    let schema = factory()

    t->U.assertErrorResult(
      nestedInvalidAny->S.parseAnyWith(schema),
      {
        code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`true`)}),
        operation: Parsing,
        path: S.Path.fromArray(["key2"]),
      },
    )
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#parse,
      `i=>{if(!i||i.constructor!==Object){e[1](i)}let v4={};for(let v0 in i){let v3;try{let v2=i[v0];if(typeof v2!=="string"){e[0](v2)}v3=v2}catch(v1){if(v1&&v1.s===s){v1.path=""+\'["\'+v0+\'"]\'+v1.path}throw v1}v4[v0]=v3}return v4}`,
    )
  })

  test("Compiled async parse code snapshot", t => {
    let schema = S.dict(S.unknown->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}))

    t->U.assertCompiledCode(
      ~schema,
      ~op=#parse,
      `i=>{if(!i||i.constructor!==Object){e[1](i)}let v4={},v9=()=>new Promise((v5,v6)=>{let v8=Object.keys(v4).length;for(let v0 in v4){v4[v0]().then(v7=>{v4[v0]=v7;if(v8--===1){v5(v4)}},v6)}});for(let v0 in i){let v3;try{let v2=e[0](i[v0]);v3=()=>{try{return v2().catch(v1=>{if(v1&&v1.s===s){v1.path=""+\'["\'+v0+\'"]\'+v1.path}throw v1})}catch(v1){if(v1&&v1.s===s){v1.path=""+\'["\'+v0+\'"]\'+v1.path}throw v1}}}catch(v1){if(v1&&v1.s===s){v1.path=""+\'["\'+v0+\'"]\'+v1.path}throw v1}v4[v0]=v3}return v9}`,
    )
  })

  test("Compiled serialize code snapshot", t => {
    let schema = S.dict(S.string)

    t->U.assertCompiledCodeIsNoop(~schema, ~op=#serialize)
  })

  test("Compiled serialize code snapshot with transform", t => {
    let schema = S.dict(S.option(S.string))

    t->U.assertCompiledCode(
      ~schema,
      ~op=#serialize,
      `i=>{let v1;v1={};for(let v0 in i){let v5;try{let v3=i[v0],v4;if(v3!==void 0){v4=e[0](v3)}v5=v4}catch(v2){if(v2&&v2.s===s){v2.path=""+\'["\'+v0+\'"]\'+v2.path}throw v2}v1[v0]=v5}return v1}`,
    )
  })
}

test("Successfully parses dict with int keys", t => {
  let schema = S.dict(S.string)

  t->Assert.deepEqual(
    %raw(`{1:"b",2:"d"}`)->S.parseAnyWith(schema),
    Ok(Dict.fromArray([("1", "b"), ("2", "d")])),
    (),
  )
})

test("Applies operation for each item on serializing", t => {
  let schema = S.dict(S.jsonString(S.int))

  t->Assert.deepEqual(
    Dict.fromArray([("a", 1), ("b", 2)])->S.serializeToUnknownWith(schema),
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
  let schema = S.dict(S.string->S.refine(s => _ => s.fail("User error")))

  t->Assert.deepEqual(
    Dict.fromArray([("a", "aa"), ("b", "bb")])->S.serializeToUnknownWith(schema),
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
  let schema = S.dict(S.option(S.string))

  t->Assert.deepEqual(
    %raw(`{"key1":"value1","key2":undefined}`)->S.parseAnyWith(schema),
    Ok(Dict.fromArray([("key1", Some("value1")), ("key2", None)])),
    (),
  )
})
