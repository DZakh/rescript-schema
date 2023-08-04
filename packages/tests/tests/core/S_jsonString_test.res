open Ava
open RescriptCore

test("Successfully parses JSON", t => {
  let struct = S.string

  t->Assert.deepEqual(`"Foo"`->S.parseAnyWith(S.jsonString(struct)), Ok("Foo"), ())
})

test("Successfully serializes JSON", t => {
  let struct = S.string

  t->Assert.deepEqual(
    `Foo`->S.serializeToUnknownWith(S.jsonString(struct)),
    Ok(%raw(`'"Foo"'`)),
    (),
  )
})

test("Fails to create struct when passing non-jsonable struct to S.jsonString", t => {
  t->Assert.throws(
    () => {
      S.jsonString(S.object(s => s.field("foo", S.unknown)))
    },
    ~expectations={
      message: `[rescript-struct] The struct Object({"foo": Unknown}) passed to S.jsonString is not compatible with JSON`,
    },
    (),
  )
})

test("Compiled parse code snapshot", t => {
  let struct = S.jsonString(S.bool)

  t->TestUtils.assertCompiledCode(
    ~struct,
    ~op=#parse,
    `i=>{let v0;if(typeof i!=="string"){e[0](i)}try{v0=JSON.parse(i)}catch(t){e[1](t.message)}if(typeof v0!=="boolean"){e[2](v0)}return v0}`,
    (),
  )
})

test("Compiled async parse code snapshot", t => {
  let struct = S.jsonString(S.bool->S.asyncParserRefine(_ => _ => Promise.resolve()))

  t->TestUtils.assertCompiledCode(
    ~struct,
    ~op=#parse,
    `i=>{let v0,v1,v2;if(typeof i!=="string"){e[0](i)}try{v0=JSON.parse(i)}catch(t){e[1](t.message)}if(typeof v0!=="boolean"){e[2](v0)}v2=e[3](v0);v1=()=>v2().then(_=>v0);return v1}`,
    (),
  )
})

test("Compiled serialize code snapshot", t => {
  let struct = S.jsonString(S.bool)

  t->TestUtils.assertCompiledCode(~struct, ~op=#serialize, `i=>{return JSON.stringify(i)}`, ())
})
