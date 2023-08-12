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
        code: InvalidType({expected: S.string->S.toUnknown, received: 1->Obj.magic}),
        operation: Parsing,
        path: S.Path.fromArray(["1"]),
      }),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(struct), Ok(any), ())
  })

  test("Compiled parse code snapshot", t => {
    let struct = factory()

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v1;if(!Array.isArray(i)){e[0](i)}v1=[];for(let v0=0;v0<i.length;++v0){let v2;v2=i[v0];try{if(typeof v2!=="string"){e[1](v2)}}catch(t){if(t&&t.s===s){t.p=""+'["'+v0+'"]'+t.p}throw t}v1.push(v2)}return v1}`,
      (),
    )
  })

  test("Compiled async parse code snapshot", t => {
    let struct = S.array(S.unknown->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}))

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v1,v5;if(!Array.isArray(i)){e[0](i)}v1=[];for(let v0=0;v0<i.length;++v0){let v2,v3,v4;v2=i[v0];try{v3=e[1](v2);v4=()=>{try{return v3().catch(t=>{if(t&&t.s===s){t.p=""+\'["\'+v0+\'"]\'+t.p}throw t})}catch(t){if(t&&t.s===s){t.p=""+\'["\'+v0+\'"]\'+t.p}throw t}};}catch(t){if(t&&t.s===s){t.p=""+\'["\'+v0+\'"]\'+t.p}throw t}v1.push(v4)}v5=()=>Promise.all(v1.map(t=>t()));return v5}`,
      (),
    )
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    // TODO: Improve compiled code
    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#serialize,
      `i=>{let v1;v1=[];for(let v0=0;v0<i.length;++v0){let v2;v2=i[v0];try{}catch(t){if(t&&t.s===s){t.p=""+'["'+v0+'"]'+t.p}throw t}v1.push(v2)}return v1}`,
      (),
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
    Error({
      operation: Parsing,
      code: InvalidType({expected: S.string->S.toUnknown, received: %raw(`1`)}),
      path: S.Path.fromArray(["0", "1"]),
    }),
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
