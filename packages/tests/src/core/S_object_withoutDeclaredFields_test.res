open Ava

test("Successfully parses empty object", t => {
  let schema = S.object(_ => ())

  t->Assert.deepEqual(%raw(`{}`)->S.parseAnyWith(schema), Ok(), ())
})

test("Successfully parses object with excess keys", t => {
  let schema = S.object(_ => ())

  t->Assert.deepEqual(%raw(`{field:"bar"}`)->S.parseAnyWith(schema), Ok(), ())
})

test("Successfully parses empty object when UnknownKeys are strict", t => {
  let schema = S.object(_ => ())->S.Object.strict

  t->Assert.deepEqual(%raw(`{}`)->S.parseAnyWith(schema), Ok(), ())
})

test("Fails to parse object with excess keys when UnknownKeys are strict", t => {
  let schema = S.object(_ => ())->S.Object.strict

  t->Assert.deepEqual(
    %raw(`{field:"bar"}`)->S.parseAnyWith(schema),
    Error(U.error({code: ExcessField("field"), operation: Parse, path: S.Path.empty})),
    (),
  )
})

test("Successfully parses object with excess keys and returns transformed value", t => {
  let transformedValue = {"bas": true}
  let schema = S.object(_ => transformedValue)

  t->Assert.deepEqual(%raw(`{field:"bar"}`)->S.parseAnyWith(schema), Ok(transformedValue), ())
})

test("Successfully serializes transformed value to empty object", t => {
  let transformedValue = {"bas": true}
  let schema = S.object(_ => transformedValue)

  t->Assert.deepEqual(transformedValue->S.reverseConvertWith(schema), %raw("{}"), ())
})

test("Fails to parse array data", t => {
  let schema = S.object(_ => ())

  t->U.assertErrorResult(
    %raw(`[]`)->S.parseAnyWith(schema),
    {
      code: InvalidType({expected: schema->S.toUnknown, received: %raw(`[]`)}),
      operation: Parse,
      path: S.Path.empty,
    },
  )
})
