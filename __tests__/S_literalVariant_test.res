open Ava

module Common = {
  let value = "ReScript is Great!"
  let wrongValue = "Hello world!"
  let unknownAny = %raw(`"Ugly string"`)
  let any = %raw(`"ReScript is Great!"`)
  let wrongAny = %raw(`"Hello world!"`)
  let wrongTypeAny = %raw(`true`)
  let factory = () => S.literalVariant(String("Ugly string"), "ReScript is Great!")

  ava->test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(unknownAny->S.parseWith(struct), Ok(value), ())
  })

  ava->test("Fails to parse wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error({
        code: UnexpectedValue({expected: `"Ugly string"`, received: `"Hello world!"`}),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  ava->test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: `String Literal ("Ugly string")`, received: "Bool"}),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  ava->test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(unknownAny), ())
  })

  ava->test("Fails to serialize wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongValue->S.serializeWith(struct),
      Error({
        code: UnexpectedValue({expected: `"ReScript is Great!"`, received: `"Hello world!"`}),
        operation: Serializing,
        path: [],
      }),
      (),
    )
  })
}

type variant = Apple

ava->test("Successfully parses null to provided variant", t => {
  let struct = S.literalVariant(EmptyNull, Apple)

  t->Assert.deepEqual(%raw(`null`)->S.parseWith(struct), Ok(Apple), ())
})

ava->test("Successfully parses undefined to provided variant", t => {
  let struct = S.literalVariant(EmptyOption, Apple)

  t->Assert.deepEqual(%raw(`undefined`)->S.parseWith(struct), Ok(Apple), ())
})

ava->test("Successfully serializes variant to null", t => {
  let struct = S.literalVariant(EmptyNull, Apple)

  t->Assert.deepEqual(Apple->S.serializeWith(struct), Ok(%raw(`null`)), ())
})

ava->test("Successfully serializes variant to undefined", t => {
  let struct = S.literalVariant(EmptyOption, Apple)

  t->Assert.deepEqual(Apple->S.serializeWith(struct), Ok(%raw(`undefined`)), ())
})
