open Ava
open RescriptCore

module Common = {
  let value = None
  let any = %raw(`undefined`)
  let invalidAny = %raw(`123.45`)
  let factory = () => S.option(S.string)

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalidAny->S.parseAnyWith(struct),
      Error({
        code: InvalidType({expected: S.string->S.toUnknown, received: invalidAny}),
        operation: Parsing,
        path: S.Path.empty,
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
      `i=>{let v0;if(i!==void 0){if(typeof i!=="string"){e[0](i)}v0=e[1](i)}else{v0=i}return v0}`,
      (),
    )
  })

  test("Compiled async parse code snapshot", t => {
    let struct = S.option(S.unknown->S.asyncParserRefine(_ => _ => Promise.resolve()))

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v0;if(i!==void 0){let v1,v2,v3;v2=e[0](i);v1=()=>v2().then(_=>i);v3=()=>v1().then(e[1]);v0=v3}else{v0=()=>Promise.resolve(i)}return v0}`,
      (),
    )
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    t->TestUtils.assertCompiledCode(
      ~struct,
      ~op=#serialize,
      `i=>{let v0;if(i!==void 0){v0=e[0](i)}else{v0=void 0}return v0}`,
      (),
    )
  })
}

test("Successfully parses primitive", t => {
  let struct = S.option(S.bool)

  t->Assert.deepEqual(JSON.Encode.bool(true)->S.parseAnyWith(struct), Ok(Some(true)), ())
})

test("Fails to parse JS null", t => {
  let struct = S.option(S.bool)

  t->Assert.deepEqual(
    %raw(`null`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`null`)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to parse JS undefined when struct doesn't allow optional data", t => {
  let struct = S.bool

  t->Assert.deepEqual(
    %raw(`undefined`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: struct->S.toUnknown, received: %raw(`undefined`)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
