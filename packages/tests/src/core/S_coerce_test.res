open Ava

test("Coerce from string to string", t => {
  let schema = S.string->S.coerce(S.string)
  t->Assert.is(schema, S.string, ())
})

test("Coerce from string to bool", t => {
  let schema = S.string->S.coerce(S.bool)

  t->Assert.deepEqual("false"->S.parseOrThrow(schema), false, ())
  t->Assert.deepEqual("true"->S.parseOrThrow(schema), true, ())
  t->U.assertRaised(
    () => "tru"->S.parseOrThrow(schema),
    {
      code: InvalidType({
        expected: S.bool->S.toUnknown,
        received: %raw(`"tru"`),
      }),
      path: S.Path.empty,
      operation: Parse,
    },
  )
  t->Assert.deepEqual(false->S.reverseConvertOrThrow(schema), %raw(`"false"`), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}let v0;(v0=i===\"true\")||i===\"false\"||e[0](i);return v0}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Convert,
    `i=>{let v0;(v0=i==="true")||i==="false"||e[0](i);return v0}`,
  )
  t->U.assertCompiledCode(~schema, ~op=#ReverseConvert, `i=>{return \"\"+i}`)
})

test("Coerce from bool to string", t => {
  let schema = S.bool->S.coerce(S.string)

  t->Assert.deepEqual(false->S.parseOrThrow(schema), "false", ())
  t->Assert.deepEqual(true->S.parseOrThrow(schema), "true", ())
  t->U.assertRaised(
    () => "tru"->S.reverseConvertOrThrow(schema),
    {
      code: InvalidType({
        expected: S.bool->S.toUnknown,
        received: %raw(`"tru"`),
      }),
      path: S.Path.empty,
      operation: ReverseConvert,
    },
  )
  t->Assert.deepEqual("false"->S.reverseConvertOrThrow(schema), %raw(`false`), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="boolean"){e[1](i)}return \"\"+i}`,
  )
  t->U.assertCompiledCode(~schema, ~op=#Convert, `i=>{return \"\"+i}`)
  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0;(v0=i===\"true\")||i===\"false\"||e[0](i);return v0}`,
  )
})

test("Coerce from string to bool literal", t => {
  let schema = S.string->S.coerce(S.literal(false))

  t->Assert.deepEqual("false"->S.parseOrThrow(schema), false, ())
  t->U.assertRaised(
    () => "true"->S.parseOrThrow(schema),
    {
      code: InvalidType({
        expected: S.literal(false)->S.toUnknown,
        received: %raw(`"true"`),
      }),
      path: S.Path.empty,
      operation: Parse,
    },
  )
  t->Assert.deepEqual(false->S.reverseConvertOrThrow(schema), %raw(`"false"`), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}i==="false"||e[0](i);return false}`,
  )
  t->U.assertCompiledCode(~schema, ~op=#ReverseConvert, `i=>{if(i!==false){e[1](i)}return "false"}`)
})

test("Coerce from string to null literal", t => {
  let schema = S.string->S.coerce(S.literal(%raw(`null`)))

  t->Assert.deepEqual("null"->S.parseOrThrow(schema), %raw(`null`), ())
  t->U.assertRaised(
    () => "true"->S.parseOrThrow(schema),
    {
      code: InvalidType({
        expected: S.literal(%raw(`null`))->S.toUnknown,
        received: %raw(`"true"`),
      }),
      path: S.Path.empty,
      operation: Parse,
    },
  )
  t->Assert.deepEqual(%raw(`null`)->S.reverseConvertOrThrow(schema), %raw(`"null"`), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}i==="null"||e[0](i);return null}`,
  )
  t->U.assertCompiledCode(~schema, ~op=#ReverseConvert, `i=>{if(i!==null){e[1](i)}return "null"}`)
})

test("Coerce from string to undefined literal", t => {
  let schema = S.string->S.coerce(S.literal(%raw(`undefined`)))

  t->Assert.deepEqual("undefined"->S.parseOrThrow(schema), %raw(`undefined`), ())
  t->U.assertRaised(
    () => "true"->S.parseOrThrow(schema),
    {
      code: InvalidType({
        expected: S.literal(%raw(`undefined`))->S.toUnknown,
        received: %raw(`"true"`),
      }),
      path: S.Path.empty,
      operation: Parse,
    },
  )
  t->Assert.deepEqual(%raw(`undefined`)->S.reverseConvertOrThrow(schema), %raw(`"undefined"`), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}i==="undefined"||e[0](i);return undefined}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{if(i!==undefined){e[1](i)}return "undefined"}`,
  )
})

test("Coerce from string to NaN literal", t => {
  let schema = S.string->S.coerce(S.literal(%raw(`NaN`)))

  t->Assert.deepEqual("NaN"->S.parseOrThrow(schema), %raw(`NaN`), ())
  t->U.assertRaised(
    () => "true"->S.parseOrThrow(schema),
    {
      code: InvalidType({
        expected: S.literal(%raw(`NaN`))->S.toUnknown,
        received: %raw(`"true"`),
      }),
      path: S.Path.empty,
      operation: Parse,
    },
  )
  t->Assert.deepEqual(%raw(`NaN`)->S.reverseConvertOrThrow(schema), %raw(`"NaN"`), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}i==="NaN"||e[0](i);return NaN}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{if(!Number.isNaN(i)){e[1](i)}return "NaN"}`,
  )
})

test("Coerce from string to string literal", t => {
  let quotedString = `"'\``
  let schema = S.string->S.coerce(S.literal(quotedString))

  t->Assert.deepEqual(quotedString->S.parseOrThrow(schema), quotedString, ())
  t->U.assertRaised(
    () => "bar"->S.parseOrThrow(schema),
    {
      code: InvalidType({
        expected: S.literal(quotedString)->S.toUnknown,
        received: %raw(`"bar"`),
      }),
      path: S.Path.empty,
      operation: Parse,
    },
  )
  t->Assert.deepEqual(quotedString->S.reverseConvertOrThrow(schema), %raw(`quotedString`), ())
  t->U.assertRaised(
    () => "bar"->S.reverseConvertOrThrow(schema),
    {
      code: InvalidType({
        expected: S.literal(quotedString)->S.toUnknown,
        received: %raw(`"bar"`),
      }),
      path: S.Path.empty,
      operation: ReverseConvert,
    },
  )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}if(i!=="\\"\'\`"){e[0](i)}return i}`,
  )
  t->U.assertCompiledCode(~schema, ~op=#ReverseConvert, `i=>{if(i!=="\\"\'\`"){e[0](i)}return i}`)
})

test("Coerce from object shaped as string to float", t => {
  let schema = S.object(s => s.field("foo", S.string))->S.coerce(S.float)

  t->Assert.deepEqual({"foo": "123"}->S.parseOrThrow(schema), 123., ())
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="object"||!i){e[2](i)}let v0=i["foo"];if(typeof v0!=="string"){e[0](v0)}let v1=+v0;Number.isNaN(v1)&&e[1](v0);return v1}`,
  )

  t->Assert.deepEqual(123.->S.reverseConvertOrThrow(schema), %raw(`{"foo": "123"}`), ())
  t->U.assertCompiledCode(~schema, ~op=#ReverseConvert, `i=>{return {"foo":""+i,}}`)
})

test("Coerce to literal can be used as tag and automatically embeded on reverse operation", t => {
  let schema = S.object(s => {
    let _ = s.field("tag", S.string->S.coerce(S.literal(true)))
  })

  t->Assert.deepEqual(()->S.reverseConvertOrThrow(schema), %raw(`{"tag": "true"}`), ())
  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{if(i!==undefined){e[2](i)}return {"tag":"true",}}`,
  )

  t->Assert.deepEqual({"tag": "true"}->S.parseOrThrow(schema), (), ())
  t->U.assertRaised(
    () => {"tag": "false"}->S.parseOrThrow(schema),
    {
      code: InvalidType({
        expected: S.literal(true)->S.toUnknown,
        received: %raw(`"false"`),
      }),
      path: S.Path.fromLocation("tag"),
      operation: Parse,
    },
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="object"||!i){e[3](i)}let v0=i["tag"];if(typeof v0!=="string"){e[0](v0)}v0==="true"||e[1](v0);return e[2]}`,
  )
})

test("Coerce from string to float", t => {
  let schema = S.string->S.coerce(S.float)

  t->Assert.deepEqual("10"->S.parseOrThrow(schema), 10., ())
  t->Assert.deepEqual("10.2"->S.parseOrThrow(schema), 10.2, ())
  t->U.assertRaised(
    () => "tru"->S.parseOrThrow(schema),
    {
      code: InvalidType({
        expected: S.float->S.toUnknown,
        received: %raw(`"tru"`),
      }),
      path: S.Path.empty,
      operation: Parse,
    },
  )
  t->Assert.deepEqual(10.->S.reverseConvertOrThrow(schema), %raw(`"10"`), ())
  t->Assert.deepEqual(10.2->S.reverseConvertOrThrow(schema), %raw(`"10.2"`), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}let v0=+i;Number.isNaN(v0)&&e[0](i);return v0}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Convert,
    `i=>{let v0=+i;Number.isNaN(v0)&&e[0](i);return v0}`,
  )
  t->U.assertCompiledCode(~schema, ~op=#ReverseConvert, `i=>{return ""+i}`)
})

test("Coerce from string to int32", t => {
  let schema = S.string->S.coerce(S.int)

  t->Assert.deepEqual("10"->S.parseOrThrow(schema), 10, ())
  t->U.assertRaised(
    () => "10.2"->S.parseOrThrow(schema),
    {
      code: InvalidType({
        expected: S.int->S.toUnknown,
        received: %raw(`"10.2"`),
      }),
      path: S.Path.empty,
      operation: Parse,
    },
  )
  t->Assert.deepEqual(10->S.reverseConvertOrThrow(schema), %raw(`"10"`), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}let v0=+i;Number.isNaN(v0)||i>2147483647||i<-2147483648||i%1!==0&&e[0](i);return v0}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Convert,
    `i=>{let v0=+i;Number.isNaN(v0)||i>2147483647||i<-2147483648||i%1!==0&&e[0](i);return v0}`,
  )
  t->U.assertCompiledCode(~schema, ~op=#ReverseConvert, `i=>{return ""+i}`)
})

test("Coerce from string to bigint literal", t => {
  let schema = S.string->S.coerce(S.literal(10n))

  t->Assert.deepEqual("10"->S.parseOrThrow(schema), 10n, ())
  t->U.assertRaised(
    () => "11"->S.parseOrThrow(schema),
    {
      code: InvalidType({
        expected: S.literal(10n)->S.toUnknown,
        received: %raw(`"11"`),
      }),
      path: S.Path.empty,
      operation: Parse,
    },
  )
  t->Assert.deepEqual(10n->S.reverseConvertOrThrow(schema), %raw(`"10"`), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}i==="10"||e[0](i);return 10n}`,
  )
  t->U.assertCompiledCode(~schema, ~op=#Convert, `i=>{i==="10"||e[0](i);return 10n}`)
  t->U.assertCompiledCode(~schema, ~op=#ReverseConvert, `i=>{if(i!==10n){e[1](i)}return "10"}`)
})

test("Coerce from string to bigint", t => {
  let schema = S.string->S.coerce(S.bigint)

  t->Assert.deepEqual("10"->S.parseOrThrow(schema), 10n, ())
  t->U.assertRaised(
    () => "10.2"->S.parseOrThrow(schema),
    {
      code: InvalidType({
        expected: S.bigint->S.toUnknown,
        received: %raw(`"10.2"`),
      }),
      path: S.Path.empty,
      operation: Parse,
    },
  )
  t->Assert.deepEqual(10n->S.reverseConvertOrThrow(schema), %raw(`"10"`), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(typeof i!=="string"){e[1](i)}let v0;try{v0=BigInt(i)}catch(_){e[0](i)}return v0}`,
  )
  t->U.assertCompiledCode(
    ~schema,
    ~op=#Convert,
    `i=>{let v0;try{v0=BigInt(i)}catch(_){e[0](i)}return v0}`,
  )
  t->U.assertCompiledCode(~schema, ~op=#ReverseConvert, `i=>{return ""+i}`)
})

test("Coerce string after a transform", t => {
  t->Assert.throws(
    () => {
      S.string->S.transform(_ => {parser: v => v, serializer: v => v})->S.coerce(S.bool)
    },
    ~expectations={
      message: "[rescript-schema] S.coerce from unknown to boolean is not supported",
    },
    (),
  )
})

@unboxed
type numberOrBoolean = Number(float) | Boolean(bool)

test("Coerce string to unboxed union (each item separately)", t => {
  t->Assert.throws(
    () => {
      S.string->S.coerce(
        S.union([
          S.schema(s => Number(s.matches(S.float))),
          S.schema(s => Boolean(s.matches(S.bool))),
        ]),
      )
    },
    ~expectations={
      message: "[rescript-schema] S.coerce from string to number | boolean is not supported",
    },
    (),
  )
})

test("Keeps description of the schema we are coercing to", t => {
  let schema = S.string->S.coerce(S.string->S.describe("Keep"))
  t->Assert.is(schema->S.description, Some("Keep"), ())

  // There's no specific reason for it. Just wasn't needed for cases S.coerce initially designed
  let schema = S.string->S.describe("Don't keep")->S.coerce(S.string)
  t->Assert.is(schema->S.description, None, ())
})
