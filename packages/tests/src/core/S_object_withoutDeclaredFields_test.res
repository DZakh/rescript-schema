open Ava

test("Successfully parses empty object", t => {
  let schema = S.object(_ => ())

  t->Assert.deepEqual(%raw(`{}`)->S.parseOrThrow(schema), (), ())
})

test("Successfully parses object with excess keys", t => {
  let schema = S.object(_ => ())

  t->Assert.deepEqual(%raw(`{field:"bar"}`)->S.parseOrThrow(schema), (), ())
})

test("Successfully parses empty object when UnknownKeys are strict", t => {
  let schema = S.object(_ => ())->S.Object.strict

  t->Assert.deepEqual(%raw(`{}`)->S.parseOrThrow(schema), (), ())
})

test("Fails to parse object with excess keys when UnknownKeys are strict", t => {
  let schema = S.object(_ => ())->S.Object.strict

  t->U.assertRaised(
    () => %raw(`{field:"bar"}`)->S.parseOrThrow(schema),
    {code: ExcessField("field"), operation: Parse, path: S.Path.empty},
  )
})

test("Successfully parses object with excess keys and returns transformed value", t => {
  let transformedValue = {"bas": true}
  let schema = S.object(_ => transformedValue)

  t->Assert.deepEqual(%raw(`{field:"bar"}`)->S.parseOrThrow(schema), transformedValue, ())
})

test("Successfully serializes transformed value to empty object", t => {
  let transformedValue = {"bas": true}
  let schema = S.object(_ => transformedValue)

  t->Assert.deepEqual(transformedValue->S.reverseConvertOrThrow(schema), %raw("{}"), ())
})

test("Fails to parse array data", t => {
  let schema = S.object(_ => ())

  t->U.assertRaised(
    () => %raw(`[]`)->S.parseOrThrow(schema),
    {
      code: InvalidType({expected: schema->S.toUnknown, received: %raw(`[]`)}),
      operation: Parse,
      path: S.Path.empty,
    },
  )
})
