open Ava
open RescriptCore

module Common = {
  let value = None
  let any = %raw(`undefined`)
  let invalidAny = %raw(`123.45`)
  let factory = () => S.option(S.string)

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

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(schema), Ok(any), ())
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#parse,
      `i=>{if(i!==void 0&&(typeof i!=="string")){e[0](i)}let v0;if(i!==void 0){v0=i}return v0}`,
    )
  })

  test("Compiled async parse code snapshot", t => {
    let schema = S.option(S.unknown->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}))

    t->U.assertCompiledCode(
      ~schema,
      ~op=#parse,
      `i=>{let v0;if(i!==void 0){v0=e[0](i)}else{v0=()=>Promise.resolve(void 0)}return v0}`,
    )
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#serialize,
      `i=>{let v0;if(i!==void 0){v0=e[0](i)}return v0}`,
    )
  })
}

test("Successfully parses primitive", t => {
  let schema = S.option(S.bool)

  t->Assert.deepEqual(JSON.Encode.bool(true)->S.parseAnyWith(schema), Ok(Some(true)), ())
})

test("Fails to parse JS null", t => {
  let schema = S.option(S.bool)

  t->U.assertErrorResult(
    %raw(`null`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: schema->S.toUnknown, received: %raw(`null`)}),
      operation: Parsing,
      path: S.Path.empty,
    },
  )
})

test("Fails to parse JS undefined when schema doesn't allow optional data", t => {
  let schema = S.bool

  t->U.assertErrorResult(
    %raw(`undefined`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: schema->S.toUnknown, received: %raw(`undefined`)}),
      operation: Parsing,
      path: S.Path.empty,
    },
  )
})

test("Parses option nested in null as None instead of Some(None)", t => {
  let schema = S.null(S.option(S.bool))

  t->Assert.deepEqual(%raw(`null`)->S.parseAnyWith(schema), Ok(None), ())
  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(schema), Ok(None), ())
})

test("Serializes Some(None) to undefined for option nested in null", t => {
  let schema = S.null(S.option(S.bool))

  t->Assert.deepEqual(Some(None)->S.serializeToUnknownWith(schema), Ok(%raw(`undefined`)), ())
  t->Assert.deepEqual(None->S.serializeToUnknownWith(schema), Ok(%raw(`null`)), ())
})
