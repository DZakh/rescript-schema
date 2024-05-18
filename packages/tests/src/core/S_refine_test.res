open Ava

test("Successfully refines on parsing", t => {
  let schema = S.int->S.refine(s => value =>
    if value < 0 {
      s.fail("Should be positive")
    })

  t->Assert.deepEqual(%raw(`12`)->S.parseAnyWith(schema), Ok(12), ())
  t->U.assertErrorResult(
    %raw(`-12`)->S.parseAnyWith(schema),
    {
      code: OperationFailed("Should be positive"),
      operation: Parsing,
      path: S.Path.empty,
    },
  )
})

test("Fails with custom path", t => {
  let schema = S.int->S.refine(s => value =>
    if value < 0 {
      s.fail(~path=S.Path.fromArray(["data", "myInt"]), "Should be positive")
    })

  t->U.assertErrorResult(
    %raw(`-12`)->S.parseAnyWith(schema),
    {
      code: OperationFailed("Should be positive"),
      operation: Parsing,
      path: S.Path.fromArray(["data", "myInt"]),
    },
  )
})

test("Successfully refines on serializing", t => {
  let schema = S.int->S.refine(s => value =>
    if value < 0 {
      s.fail("Should be positive")
    })

  t->Assert.deepEqual(12->S.serializeToUnknownWith(schema), Ok(%raw("12")), ())
  t->U.assertErrorResult(
    -12->S.serializeToUnknownWith(schema),
    {
      code: OperationFailed("Should be positive"),
      operation: Serializing,
      path: S.Path.empty,
    },
  )
})

test("Successfully parses simple object with empty refine", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.field("bar", S.bool),
    }
  )->S.refine(_ => _ => ())

  t->Assert.deepEqual(
    %raw(`{
      "foo": "string",
      "bar": true,
    }`)->S.parseAnyWith(schema),
    Ok({
      "foo": "string",
      "bar": true,
    }),
    (),
  )
})

test("Compiled parse code snapshot for simple object with refine", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.field("bar", S.bool),
    }
  )->S.refine(s => _ => s.fail("foo"))

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{if(!i||i.constructor!==Object){e[3](i)}let v0=i["foo"],v1=i["bar"],v2={"foo":v0,"bar":v1,};if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="boolean"){e[1](v1)}e[2](v2);return v2}`,
  )
})
