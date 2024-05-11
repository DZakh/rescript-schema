open Ava
open RescriptCore

module CommonWithNested = {
  let value = ["Hello world!", ""]
  let any = %raw(`["Hello world!", ""]`)
  let invalidAny = %raw(`true`)
  let nestedInvalidAny = %raw(`["Hello world!", 1]`)
  let factory = () => S.array(S.string)

  test("Successfully parses", t => {
    let schema = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(schema), Ok(value), ())
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
        code: InvalidType({expected: S.string->S.toUnknown, received: 1->Obj.magic}),
        operation: Parsing,
        path: S.Path.fromArray(["1"]),
      },
    )
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(schema), Ok(any), ())
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#parse,
      `i=>{if(!Array.isArray(i)){e[1](i)}let v1;v1=[];for(let v0=0;v0<i.length;++v0){let v3;try{v3=i[v0];if(typeof v3!=="string"){e[0](v3)}}catch(v2){if(v2&&v2.s===s){v2.path=""+'["'+v0+'"]'+v2.path}throw v2}v1.push(v3)}return v1}`,
    )
  })

  test("Compiled async parse code snapshot", t => {
    let schema = S.array(S.unknown->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}))

    t->U.assertCompiledCode(
      ~schema,
      ~op=#parse,
      `i=>{if(!Array.isArray(i)){e[1](i)}let v1,v5;v1=[];for(let v0=0;v0<i.length;++v0){let v3,v4;try{v3=e[0](i[v0]);v4=()=>{try{return v3().catch(v2=>{if(v2&&v2.s===s){v2.path=""+\'["\'+v0+\'"]\'+v2.path}throw v2})}catch(v2){if(v2&&v2.s===s){v2.path=""+\'["\'+v0+\'"]\'+v2.path}throw v2}};}catch(v2){if(v2&&v2.s===s){v2.path=""+\'["\'+v0+\'"]\'+v2.path}throw v2}v1.push(v4)}v5=()=>Promise.all(v1.map(t=>t()));return v5}`,
    )
  })

  test("Compiled serialize code snapshot", t => {
    let schema = S.array(S.string)

    t->U.assertCompiledCodeIsNoop(~schema, ~op=#serialize)
  })

  test("Compiled serialize code snapshot with transform", t => {
    let schema = S.array(S.option(S.string))

    // TODO: Simplify
    t->U.assertCompiledCode(
      ~schema,
      ~op=#serialize,
      `i=>{let v1;v1=[];for(let v0=0;v0<i.length;++v0){let v3,v4;try{v3=i[v0];if(v3!==void 0){v4=e[0](v3)}else{v4=void 0}}catch(v2){if(v2&&v2.s===s){v2.path=""+'["'+v0+'"]'+v2.path}throw v2}v1.push(v4)}return v1}`,
    )
  })
}

test("Successfully parses matrix", t => {
  let schema = S.array(S.array(S.string))

  t->Assert.deepEqual(
    %raw(`[["a", "b"], ["c", "d"]]`)->S.parseAnyWith(schema),
    Ok([["a", "b"], ["c", "d"]]),
    (),
  )
})

test("Fails to parse matrix", t => {
  let schema = S.array(S.array(S.string))

  t->U.assertErrorResult(
    %raw(`[["a", 1], ["c", "d"]]`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`1`)}),
      operation: Parsing,
      path: S.Path.fromArray(["0", "1"]),
    },
  )
})

test("Successfully parses array of optional items", t => {
  let schema = S.array(S.option(S.string))

  t->Assert.deepEqual(
    %raw(`["a", undefined, undefined, "b"]`)->S.parseAnyWith(schema),
    Ok([Some("a"), None, None, Some("b")]),
    (),
  )
})
