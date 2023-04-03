open Ava

module Common = {
  let value = "ReScript is Great!"
  let wrongValue = "Hello world!"
  let unknownAny = %raw(`"Ugly string"`)
  let any = %raw(`"ReScript is Great!"`)
  let wrongAny = %raw(`"Hello world!"`)
  let wrongTypeAny = %raw(`true`)
  let factory = () => S.literalVariant(String("Ugly string"), "ReScript is Great!")

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(unknownAny->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseAnyWith(struct),
      Error({
        code: UnexpectedValue({expected: `"Ugly string"`, received: `"Hello world!"`}),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseAnyWith(struct),
      Error({
        code: UnexpectedType({expected: `String Literal ("Ugly string")`, received: "Bool"}),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(struct), Ok(unknownAny), ())
  })

  test("Fails to serialize wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongValue->S.serializeToUnknownWith(struct),
      Error({
        code: UnexpectedValue({expected: `"ReScript is Great!"`, received: `"Hello world!"`}),
        operation: Serializing,
        path: S.Path.empty,
      }),
      (),
    )
  })
}

type variant = Apple

test("Successfully parses null to provided variant", t => {
  let struct = S.literalVariant(EmptyNull, Apple)

  t->Assert.deepEqual(%raw(`null`)->S.parseAnyWith(struct), Ok(Apple), ())
})

test("Successfully parses undefined to provided variant", t => {
  let struct = S.literalVariant(EmptyOption, Apple)

  t->Assert.deepEqual(%raw(`undefined`)->S.parseAnyWith(struct), Ok(Apple), ())
})

test("Successfully serializes variant to null", t => {
  let struct = S.literalVariant(EmptyNull, Apple)

  t->Assert.deepEqual(Apple->S.serializeToUnknownWith(struct), Ok(%raw(`null`)), ())
})

test("Successfully serializes variant to undefined", t => {
  let struct = S.literalVariant(EmptyOption, Apple)

  t->Assert.deepEqual(Apple->S.serializeToUnknownWith(struct), Ok(%raw(`undefined`)), ())
})
