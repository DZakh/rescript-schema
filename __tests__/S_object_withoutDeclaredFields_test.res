open Ava

test("Successfully parses empty object", t => {
  let struct = S.object(_ => ())

  t->Assert.deepEqual(%raw(`{}`)->S.parseAnyWith(struct), Ok(), ())
})

test("Successfully parses object with excess keys", t => {
  let struct = S.object(_ => ())

  t->Assert.deepEqual(%raw(`{field:"bar"}`)->S.parseAnyWith(struct), Ok(), ())
})

test("Successfully parses empty object when UnknownKeys are strict", t => {
  let struct = S.object(_ => ())->S.Object.strict

  t->Assert.deepEqual(%raw(`{}`)->S.parseAnyWith(struct), Ok(), ())
})

test("Fails to parse object with excess keys when UnknownKeys are strict", t => {
  let struct = S.object(_ => ())->S.Object.strict

  t->Assert.deepEqual(
    %raw(`{field:"bar"}`)->S.parseAnyWith(struct),
    Error({
      code: ExcessField("field"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully parses object with excess keys and returns transformed value", t => {
  let transformedValue = {"bas": true}
  let struct = S.object(_ => transformedValue)

  t->Assert.deepEqual(%raw(`{field:"bar"}`)->S.parseAnyWith(struct), Ok(transformedValue), ())
})

test("Successfully serializes transformed value to empty object", t => {
  let transformedValue = {"bas": true}
  let struct = S.object(_ => transformedValue)

  t->Assert.deepEqual(transformedValue->S.serializeToUnknownWith(struct), Ok(%raw("{}")), ())
})

test("Fails to parse array data", t => {
  let struct = S.object(_ => ())

  t->Assert.deepEqual(
    %raw(`[]`)->S.parseAnyWith(struct),
    Error({
      code: UnexpectedType({expected: "Object", received: "Array"}),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})
