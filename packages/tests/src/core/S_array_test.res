open Ava
open RescriptCore

module CommonWithNested = {
  let value = ["Hello world!", ""]
  let any = %raw(`["Hello world!", ""]`)
  let invalidAny = %raw(`true`)
  let nestedInvalidAny = %raw(`["Hello world!", 1]`)
  let factory = () => S.array(S.string)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
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

  test("Compiled parse code snapshot", t => {
    let struct = factory()

    t->U.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v1;if(!Array.isArray(i)){e[1](i)}v1=[];for(let v0=0;v0<i.length;++v0){let v3;try{v3=i[v0];if(typeof v3!=="string"){e[0](v3)}}catch(v2){if(v2&&v2.s===s){v2.path=""+'["'+v0+'"]'+v2.path}throw v2}v1.push(v3)}return v1}`,
    )
  })

  test("Compiled async parse code snapshot", t => {
    let struct = S.array(S.unknown->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}))

    t->U.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v1,v5;if(!Array.isArray(i)){e[1](i)}v1=[];for(let v0=0;v0<i.length;++v0){let v3,v4;try{v3=e[0](i[v0]);v4=()=>{try{return v3().catch(v2=>{if(v2&&v2.s===s){v2.path=""+'["'+v0+'"]'+v2.path}throw v2})}catch(v2){if(v2&&v2.s===s){v2.path=""+'["'+v0+'"]'+v2.path}throw v2}};}catch(v2){if(v2&&v2.s===s){v2.path=""+'["'+v0+'"]'+v2.path}throw v2}v1.push(v4)}v5=()=>Promise.all(v1.map(t=>t()));return v5}`,
    )
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    // TODO: Improve compiled code
    t->U.assertCompiledCode(
      ~struct,
      ~op=#serialize,
      `i=>{let v1;v1=[];for(let v0=0;v0<i.length;++v0){let v3;try{v3=i[v0]}catch(v2){if(v2&&v2.s===s){v2.path=""+'["'+v0+'"]'+v2.path}throw v2}v1.push(v3)}return v1}`,
    )
  })
}

test("Successfully parses matrix", t => {
  let struct = S.array(S.array(S.string))

  t->Assert.deepEqual(
    %raw(`[["a", "b"], ["c", "d"]]`)->S.parseAnyWith(struct),
    Ok([["a", "b"], ["c", "d"]]),
    (),
  )
})

test("Fails to parse matrix", t => {
  let struct = S.array(S.array(S.string))

  t->Assert.deepEqual(
    %raw(`[["a", 1], ["c", "d"]]`)->S.parseAnyWith(struct),
    Error(
      U.error({
        code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`1`)}),
        operation: Parsing,
        path: S.Path.fromArray(["0", "1"]),
      }),
    ),
    (),
  )
})

test("Successfully parses array of optional items", t => {
  let struct = S.array(S.option(S.string))

  t->Assert.deepEqual(
    %raw(`["a", undefined, undefined, "b"]`)->S.parseAnyWith(struct),
    Ok([Some("a"), None, None, Some("b")]),
    (),
  )
})
