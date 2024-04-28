open Ava

test("Successfully parses valid data", t => {
  let schema = S.float->S.Float.max(1.)

  t->Assert.deepEqual(1->S.parseAnyWith(schema), Ok(1.), ())
  t->Assert.deepEqual(-1->S.parseAnyWith(schema), Ok(-1.), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.float->S.Float.max(1.)

  t->U.assertErrorResult(1234->S.parseAnyWith(schema), {
        code: OperationFailed("Number must be lower than or equal to 1"),
        operation: Parsing,
        path: S.Path.empty,
      })
})

test("Successfully serializes valid value", t => {
  let schema = S.float->S.Float.max(1.)

  t->Assert.deepEqual(1.->S.serializeToUnknownWith(schema), Ok(%raw(`1`)), ())
  t->Assert.deepEqual(-1.->S.serializeToUnknownWith(schema), Ok(%raw(`-1`)), ())
})

test("Fails to serialize invalid value", t => {
  let schema = S.float->S.Float.max(1.)

  t->U.assertErrorResult(1234.->S.serializeToUnknownWith(schema), {
        code: OperationFailed("Number must be lower than or equal to 1"),
        operation: Serializing,
        path: S.Path.empty,
      })
})

test("Returns custom error message", t => {
  let schema = S.float->S.Float.max(~message="Custom", 1.)

  t->Assert.deepEqual(
    12.->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parsing, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.float->S.Float.max(1.)

  t->Assert.deepEqual(
    schema->S.Float.refinements,
    [{kind: Max({value: 1.}), message: "Number must be lower than or equal to 1"}],
    (),
  )
})

test("Compiled parse code snapshot", t => {
  let schema = S.float->S.Float.max(~message="Custom", 1.)

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{if(typeof i!=="number"||Number.isNaN(i)){e[2](i)}if(i>e[0]){e[1]()}return i}`,
  )
})
