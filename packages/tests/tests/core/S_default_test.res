open Ava
open RescriptCore

test("Uses default value when parsing optional unknown primitive", t => {
  let value = 123.
  let any = %raw(`undefined`)

  let struct = S.float->S.default(() => value)

  t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(value), ())
})

test("Successfully parses with default when provided JS undefined", t => {
  let struct = S.bool->S.default(() => false)

  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(struct), Ok(false), ())
})

test("Successfully parses with default when provided primitive", t => {
  let struct = S.bool->S.default(() => false)

  t->Assert.deepEqual(%raw(`true`)->S.parseAnyWith(struct), Ok(true), ())
})

test("Successfully parses nested option with default value", t => {
  let struct = S.option(S.bool)->S.default(() => Some(true))

  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(struct), Ok(Some(true)), ())
})

test("Fails to parse data with default", t => {
  let struct = S.bool->S.default(() => false)

  t->Assert.deepEqual(
    %raw(`"string"`)->S.parseAnyWith(struct),
    Error({
      code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"string"`)}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully serializes struct with transformation", t => {
  let struct = S.string->S.String.trim()->S.default(() => "default")

  t->Assert.deepEqual(" abc"->S.serializeToUnknownWith(struct), Ok(%raw(`"abc"`)), ())
})

test("Compiled parse code snapshot", t => {
  let struct = S.bool->S.default(() => false)

  t->TestUtils.assertCompiledCode(
    ~struct,
    ~op=#parse,
    `i=>{let v0;if(i!==void 0){let v1;if(i!==void 0){if(typeof i!=="boolean"){e[0](i)}v1=e[1](i)}else{v1=i}v0=e[2](v1)}else{v0=e[3]()}return v0}`,
    (),
  )
})

test("Compiled async parse code snapshot", t => {
  let struct = S.bool->S.asyncParserRefine(_ => _ => Promise.resolve())->S.default(() => false)

  t->TestUtils.assertCompiledCode(
    ~struct,
    ~op=#parse,
    `i=>{let v0;if(i!==void 0){let v1,v5;if(i!==void 0){let v2,v3,v4;if(typeof i!=="boolean"){e[0](i)}v3=e[1](i);v2=()=>v3().then(_=>i);v4=()=>v2().then(e[2]);v1=v4}else{v1=()=>Promise.resolve(i)}v5=()=>v1().then(e[3]);v0=v5}else{v0=()=>Promise.resolve(e[4]())}return v0}`,
    (),
  )
})

test("Compiled serialize code snapshot", t => {
  let struct = S.bool->S.default(() => false)

  t->TestUtils.assertCompiledCode(
    ~struct,
    ~op=#serialize,
    `i=>{let v0;if(i!==void 0){v0=e[0](i)}else{v0=void 0}return v0}`,
    (),
  )
})
