open Ava
open RescriptCore

test("Uses default value when parsing optional unknown primitive", t => {
  let value = 123.
  let any = %raw(`undefined`)

  let struct = S.float->S.option->S.Option.getOr(value)

  t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
})

test("Uses default value when nullable optional unknown primitive", t => {
  let value = 123.
  let any = %raw(`null`)

  let struct = S.float->S.null->S.Option.getOr(value)

  t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
})

test("Successfully parses with default when provided JS undefined", t => {
  let struct = S.bool->S.option->S.Option.getOr(false)

  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(struct), Ok(false), ())
})

test("Successfully parses with default when provided primitive", t => {
  let struct = S.bool->S.option->S.Option.getOr(false)

  t->Assert.deepEqual(%raw(`true`)->S.parseAnyWith(struct), Ok(true), ())
})

test("Successfully serializes nested option with default value", t => {
  let struct = S.option(
    S.option(S.option(S.option(S.option(S.option(S.bool)))->S.Option.getOr(Some(Some(true))))),
  )

  t->Assert.deepEqual(
    Some(Some(Some(Some(None))))->S.serializeToUnknownWith(struct),
    Ok(%raw(`undefined`)),
    (),
  )
  t->Assert.deepEqual(None->S.serializeToUnknownWith(struct), Ok(%raw(`undefined`)), ())
})

test("Fails to parse data with default", t => {
  let struct = S.bool->S.option->S.Option.getOr(false)

  t->Assert.deepEqual(
    %raw(`"string"`)->S.parseAnyWith(struct),
    Error(
      U.error({
        code: InvalidType({expected: struct->S.toUnknown, received: %raw(`"string"`)}),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Successfully parses struct with transformation", t => {
  let struct =
    S.option(S.float)
    ->S.Option.getOr(-123.)
    ->S.transform(_ => {
      parser: number =>
        if number > 0. {
          Some("positive")
        } else {
          None
        },
    })
    ->S.Option.getOr("not positive")

  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(struct), Ok("not positive"), ())
})

test("Successfully serializes struct with transformation", t => {
  let struct = S.string->S.String.trim->S.option->S.Option.getOr("default")

  t->Assert.deepEqual(" abc"->S.serializeToUnknownWith(struct), Ok(%raw(`"abc"`)), ())
})

test("Compiled parse code snapshot", t => {
  let struct = S.bool->S.option->S.Option.getOr(false)

  t->U.assertCompiledCode(
    ~struct,
    ~op=#parse,
    `i=>{let v0;if(i!==void 0&&typeof i!=="boolean"){e[1](i)}if(i!==void 0){v0=i}else{v0=void 0}return v0===void 0?e[0]:v0}`,
    (),
  )
})

test("Compiled async parse code snapshot", t => {
  let struct =
    S.bool
    ->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)})
    ->S.option
    ->S.Option.getOr(false)

  t->U.assertCompiledCode(
    ~struct,
    ~op=#parse,
    `i=>{let v0,v3;if(i!==void 0&&typeof i!=="boolean"){e[2](i)}if(i!==void 0){let v1;v1=e[0](i);v0=v1}else{v0=()=>Promise.resolve(void 0)}v3=()=>v0().then(v2=>{return v2===void 0?e[1]:v2});return v3}`,
    (),
  )
})

test("Compiled serialize code snapshot", t => {
  let struct = S.bool->S.option->S.Option.getOr(false)

  t->U.assertCompiledCode(
    ~struct,
    ~op=#serialize,
    `i=>{let v0;if(i!==void 0){v0=e[0](i)}else{v0=void 0}return v0}`,
    (),
  )
})
