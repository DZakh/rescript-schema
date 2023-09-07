open Ava

test("Successfully refines on parsing", t => {
  let struct = S.int->S.refine(s => value =>
    if value < 0 {
      s.fail("Should be positive")
    })

  t->Assert.deepEqual(%raw(`12`)->S.parseAnyWith(struct), Ok(12), ())
  t->Assert.deepEqual(
    %raw(`-12`)->S.parseAnyWith(struct),
    Error(
      U.error({
        code: OperationFailed("Should be positive"),
        operation: Parsing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Fails with custom path", t => {
  let struct = S.int->S.refine(s => value =>
    if value < 0 {
      s.fail(~path=S.Path.fromArray(["data", "myInt"]), "Should be positive")
    })

  t->Assert.deepEqual(
    %raw(`-12`)->S.parseAnyWith(struct),
    Error(
      U.error({
        code: OperationFailed("Should be positive"),
        operation: Parsing,
        path: S.Path.fromArray(["data", "myInt"]),
      }),
    ),
    (),
  )
})

test("Successfully refines on serializing", t => {
  let struct = S.int->S.refine(s => value =>
    if value < 0 {
      s.fail("Should be positive")
    })

  t->Assert.deepEqual(12->S.serializeToUnknownWith(struct), Ok(%raw("12")), ())
  t->Assert.deepEqual(
    -12->S.serializeToUnknownWith(struct),
    Error(
      U.error({
        code: OperationFailed("Should be positive"),
        operation: Serializing,
        path: S.Path.empty,
      }),
    ),
    (),
  )
})

test("Compiled parse code snapshot for simple object with refine", t => {
  let struct = S.object(s =>
    {
      "foo": s.field("foo", S.string),
      "bar": s.field("bar", S.bool),
    }
  )->S.refine(s => _ => s.fail("foo"))

  t->U.assertCompiledCode(
    ~struct,
    ~op=#parse,
    `i=>{let v0,v1,v2;if(!i||i.constructor!==Object){e[3](i)}v0=i["foo"];if(typeof v0!=="string"){e[0](v0)}v1=i["bar"];if(typeof v1!=="boolean"){e[1](v1)}v2={"foo":v0,"bar":v1,};e[2](v2);return v2}`,
    (),
  )
})
