open Ava
open RescriptCore

test("Uses default value when parsing optional unknown primitive", t => {
  let value = 123.
  let any = %raw(`undefined`)

  let schema = S.float->S.option->S.Option.getOr(value)

  t->Assert.deepEqual(any->S.parseAnyWith(schema), Ok(value), ())
})

test("Uses default value when nullable optional unknown primitive", t => {
  let value = 123.
  let any = %raw(`null`)

  let schema = S.float->S.null->S.Option.getOr(value)

  t->Assert.deepEqual(any->S.parseAnyWith(schema), Ok(value), ())
})

test("Successfully parses with default when provided JS undefined", t => {
  let schema = S.bool->S.option->S.Option.getOr(false)

  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(schema), Ok(false), ())
})

test("Successfully parses with default when provided primitive", t => {
  let schema = S.bool->S.option->S.Option.getOr(false)

  t->Assert.deepEqual(%raw(`true`)->S.parseAnyWith(schema), Ok(true), ())
})

test("Successfully serializes nested option with default value", t => {
  let schema = S.option(
    S.option(S.option(S.option(S.option(S.option(S.bool)))->S.Option.getOr(Some(Some(true))))),
  )

  t->Assert.deepEqual(
    Some(Some(Some(Some(None))))->S.serializeToUnknownWith(schema),
    Ok(%raw(`undefined`)),
    (),
  )
  t->Assert.deepEqual(None->S.serializeToUnknownWith(schema), Ok(%raw(`undefined`)), ())
})

test("Fails to parse data with default", t => {
  let schema = S.bool->S.option->S.Option.getOr(false)

  t->Assert.deepEqual(
    %raw(`"string"`)->S.parseAnyWith(schema),
    Error(
      U.error({
        code: InvalidType({expected: schema->S.toUnknown, received: %raw(`"string"`)}),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Successfully parses schema with transformation", t => {
  let schema =
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

  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(schema), Ok("not positive"), ())
})

test("Successfully serializes schema with transformation", t => {
  let schema = S.string->S.String.trim->S.option->S.Option.getOr("default")

  t->Assert.deepEqual(" abc"->S.serializeToUnknownWith(schema), Ok(%raw(`"abc"`)), ())
})

test("Compiled parse code snapshot", t => {
  let schema = S.bool->S.option->S.Option.getOr(false)

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{let v0;if(i!==void 0&&(typeof i!=="boolean")){e[1](i)}if(i!==void 0){v0=i}else{v0=void 0}return v0===void 0?e[0]:v0}`,
  )
})

test("Compiled async parse code snapshot", t => {
  let schema =
    S.bool
    ->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)})
    ->S.option
    ->S.Option.getOr(false)

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{let v0,v3;if(i!==void 0&&(typeof i!=="boolean")){e[2](i)}if(i!==void 0){let v1;v1=e[0](i);v0=v1}else{v0=()=>Promise.resolve(void 0)}v3=()=>v0().then(v2=>{return v2===void 0?e[1]:v2});return v3}`,
  )
})

test("Compiled serialize code snapshot", t => {
  let schema = S.bool->S.option->S.Option.getOr(false)

  t->U.assertCompiledCode(
    ~schema,
    ~op=#serialize,
    `i=>{let v0;if(i!==void 0){v0=e[0](i)}else{v0=void 0}return v0}`,
  )
})
