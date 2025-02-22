open Ava

module Common = {
  let value = ("bar", true)
  let invalid = %raw(`123`)
  let factory = () => S.literal(("bar", true))

  test("Successfully parses", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.parseOrThrow(schema), value, ())
  })

  test("Fails to parse invalid", t => {
    let schema = factory()

    t->U.assertRaised(
      () => invalid->S.parseOrThrow(schema),
      {
        code: InvalidType({
          expected: S.literal(("bar", true))->S.toUnknown,
          received: invalid,
        }),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.reverseConvertOrThrow(schema), value->U.castAnyToUnknown, ())
  })

  test("Fails to serialize invalid", t => {
    let schema = factory()

    t->U.assertRaised(
      () => invalid->S.reverseConvertOrThrow(schema),
      {
        code: InvalidType({
          expected: S.literal(("bar", true))->S.toUnknown,
          received: invalid->U.castAnyToUnknown,
        }),
        operation: ReverseConvert,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse array like object", t => {
    let schema = factory()

    t->U.assertRaised(
      () => %raw(`{0: "bar",1:true}`)->S.parseOrThrow(schema),
      {
        code: InvalidType({
          expected: S.literal(("bar", true))->S.toUnknown,
          received: %raw(`{0: "bar",1:true}`),
        }),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse array with excess item", t => {
    let schema = factory()

    t->U.assertRaised(
      () => %raw(`["bar", true, false]`)->S.parseOrThrow(schema),
      {
        code: InvalidType({
          expected: S.literal(("bar", true))->S.toUnknown,
          received: %raw(`["bar", true, false]`),
        }),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Parse,
      `i=>{if(i!==e[0]&&(!Array.isArray(i)||i.length!==2||i[0]!=="bar"||i[1]!==true)){e[1](i)}return i}`,
    )
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#ReverseConvert,
      `i=>{if(i!==e[0]&&(!Array.isArray(i)||i.length!==2||i[0]!=="bar"||i[1]!==true)){e[1](i)}return i}`,
    )
  })

  test("Reverse schema to self", t => {
    let schema = factory()
    t->Assert.is(schema->S.reverse, schema->S.toUnknown, ())
  })

  test("Succesfully uses reversed schema for parsing back to initial value", t => {
    let schema = factory()
    t->U.assertReverseParsesBack(schema, ("bar", true))
  })
}

module EmptyArray = {
  let value: array<string> = []
  let invalid = ["abc"]
  let factory = () => S.literal([])

  test("Successfully parses empty array literal schema", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.parseOrThrow(schema), value, ())
  })

  test("Fails to parse empty array literal schema with invalid type", t => {
    let schema = factory()

    t->U.assertRaised(
      () => invalid->S.parseOrThrow(schema),
      {
        code: InvalidType({
          expected: S.literal([])->S.toUnknown,
          received: invalid->U.castAnyToUnknown,
        }),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Successfully serializes empty array literal schema", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.reverseConvertOrThrow(schema), value->U.castAnyToUnknown, ())
  })

  test("Fails to serialize empty array literal schema with invalid value", t => {
    let schema = factory()

    t->U.assertRaised(
      () => invalid->S.reverseConvertOrThrow(schema),
      {
        code: InvalidType({
          expected: S.literal([])->S.toUnknown,
          received: invalid->U.castAnyToUnknown,
        }),
        operation: ReverseConvert,
        path: S.Path.empty,
      },
    )
  })

  test("Compiled parse code snapshot of empty array literal schema", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Parse,
      `i=>{if(i!==e[0]&&(!Array.isArray(i)||i.length!==0)){e[1](i)}return i}`,
    )
  })

  test("Compiled serialize code snapshot of empty array literal schema", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#ReverseConvert,
      `i=>{if(i!==e[0]&&(!Array.isArray(i)||i.length!==0)){e[1](i)}return i}`,
    )
  })

  test("Reverse empty array literal schema to self", t => {
    let schema = factory()
    t->Assert.is(schema->S.reverse, schema->S.toUnknown, ())
  })

  test(
    "Succesfully uses reversed empty array literal schema for parsing back to initial value",
    t => {
      let schema = factory()
      t->U.assertReverseParsesBack(schema, value)
    },
  )
}
