open Ava
open RescriptCore

module Common = {
  let value = None
  let any = %raw(`null`)
  let invalidAny = %raw(`123.45`)
  let factory = () => S.null(S.string)

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

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(struct), Ok(any), ())
  })

  test("Compiled parse code snapshot", t => {
    let struct = factory()

    t->U.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v0;if(i!==null&&typeof i!=="string"){e[0](i)}if(i!==null){v0=i}else{v0=void 0}return v0}`,
      (),
    )
  })

  test("Compiled async parse code snapshot", t => {
    let struct = S.null(S.unknown->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}))

    t->U.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{let v0;if(i!==null){let v1;v1=e[0](i);v0=v1}else{v0=()=>Promise.resolve(void 0)}return v0}`,
      (),
    )
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    t->U.assertCompiledCode(
      ~struct,
      ~op=#serialize,
      `i=>{let v0;if(i!==void 0){v0=e[0](i)}else{v0=null}return v0}`,
      (),
    )
  })
}

test("Successfully parses primitive", t => {
  let struct = S.null(S.bool)

  t->Assert.deepEqual(JSON.Encode.bool(true)->S.parseAnyWith(struct), Ok(Some(true)), ())
})

test("Fails to parse JS undefined", t => {
  let struct = S.null(S.bool)

  t->Assert.deepEqual(
    %raw(`undefined`)->S.parseAnyWith(struct),
    Error(
      U.error({
        code: InvalidType({expected: struct->S.toUnknown, received: %raw(`undefined`)}),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Fails to parse object with missing field that marked as null", t => {
  let fieldStruct = S.null(S.string)
  let struct = S.object(s => s.field("nullableField", fieldStruct))

  t->Assert.deepEqual(
    %raw(`{}`)->S.parseAnyWith(struct),
    Error(
      U.error({
        code: InvalidType({expected: fieldStruct->S.toUnknown, received: %raw(`undefined`)}),
        operation: Parsing,
        path: S.Path.fromArray(["nullableField"]),
      }),
    ),
    (),
  )
})

test("Fails to parse JS null when struct doesn't allow optional data", t => {
  let struct = S.bool

  t->Assert.deepEqual(
    %raw(`null`)->S.parseAnyWith(struct),
    Error(
      U.error({
        code: InvalidType({expected: struct->S.toUnknown, received: %raw(`null`)}),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Successfully parses null and serializes it back for deprecated nullable struct", t => {
  let struct = S.null(S.bool)->S.deprecate("Deprecated")

  t->Assert.deepEqual(
    %raw(`null`)->S.parseAnyWith(struct)->Result.map(S.serializeToUnknownWith(_, struct)),
    Ok(Ok(%raw(`null`))),
    (),
  )
})

test("Parses null nested in option as None instead of Some(None)", t => {
  let struct = S.option(S.null(S.bool))

  t->Assert.deepEqual(%raw(`null`)->S.parseAnyWith(struct), Ok(None), ())
  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(struct), Ok(None), ())
})

test("Serializes Some(None) to null for null nested in option", t => {
  let struct = S.option(S.null(S.bool))

  t->Assert.deepEqual(Some(None)->S.serializeToUnknownWith(struct), Ok(%raw(`null`)), ())
  t->Assert.deepEqual(None->S.serializeToUnknownWith(struct), Ok(%raw(`undefined`)), ())
})
