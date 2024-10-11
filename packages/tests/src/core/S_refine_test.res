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
      operation: Parse,
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
      operation: Parse,
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
      operation: SerializeToUnknown,
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
    ~op=#Parse,
    `i=>{if(!i||i.constructor!==Object){e[3](i)}let v0=i["foo"],v1=i["bar"],v2;if(typeof v0!=="string"){e[0](v0)}if(typeof v1!=="boolean"){e[1](v1)}v2={"foo":v0,"bar":v1};e[2](v2);return v2}`,
  )
})

test("Reverse schema to the original schema", t => {
  let schema = S.int->S.refine(s => value =>
    if value < 0 {
      s.fail("Should be positive")
    })
  t->Assert.not(schema->S.reverse, schema->S.toUnknown, ())
  t->U.assertEqualSchemas(schema->S.reverse, S.int->S.toUnknown)
})

test("Succesfully uses reversed schema for parsing back to initial value", t => {
  let schema = S.int->S.refine(s => value =>
    if value < 0 {
      s.fail("Should be positive")
    })
  t->U.assertReverseParsesBack(schema, 12)
})

// https://github.com/DZakh/rescript-schema/issues/79
module Issue79 = {
  test("Successfully parses", t => {
    let schema = S.object(s => s.field("myField", S.nullable(S.string)))->S.refine(_ => _ => ())
    let jsonString = `{"myField": "test"}`

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Parse,
      `i=>{if(!i||i.constructor!==Object){e[2](i)}let v0=i["myField"],v3;if(v0!==void 0&&(v0!==null&&(typeof v0!=="string"))){e[0](v0)}let v2;if(v0!==void 0){let v1;if(v0!==null){v1=v0}else{v1=void 0}v2=v1}v3=v2;e[1](v3);return v3}`,
    )

    t->Assert.deepEqual(jsonString->S.parseJsonStringWith(schema), Ok(Some("test")), ())
  })
}
