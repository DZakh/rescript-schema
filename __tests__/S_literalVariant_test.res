open Ava

module Common = {
  let value = "ReScript is Great!"
  let wrongValue = "Hello world!"
  let unknownAny = %raw(`"Ugly string"`)
  let any = %raw(`"ReScript is Great!"`)
  let wrongAny = %raw(`"Hello world!"`)
  let wrongTypeAny = %raw(`true`)
  let factory = () => S.literalVariant(String("Ugly string"), "ReScript is Great!")

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(unknownAny->S.parseWith(struct), Ok(value), ())
  })

  test("Successfully parses without validation in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongAny->S.parseWith(~mode=Unsafe, struct), Ok(any), ())
  })

  test("Fails to parse wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at root. Reason: Expected "Ugly string", got "Hello world!"`),
      (),
    )
  })

  test("Fails to parse wrong type", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongTypeAny->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at root. Reason: Expected String Literal ("Ugly string"), got Bool`),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(unknownAny), ())
  })

  test("Successfully serializes wrong value in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongValue->S.serializeWith(~mode=Unsafe, struct), Ok(unknownAny), ())
  })

  test("Fails to serialize wrong value in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongValue->S.serializeWith(struct),
      Error(`[ReScript Struct] Failed serializing at root. Reason: Expected "ReScript is Great!", got "Hello world!"`),
      (),
    )
  })
}

type variant = Apple

test("Successfully parses null to provided variant", t => {
  let struct = S.literalVariant(EmptyNull, Apple)

  t->Assert.deepEqual(%raw(`null`)->S.parseWith(struct), Ok(Apple), ())
})

test("Successfully parses undefined to provided variant", t => {
  let struct = S.literalVariant(EmptyOption, Apple)

  t->Assert.deepEqual(%raw(`undefined`)->S.parseWith(struct), Ok(Apple), ())
})

test("Successfully serializes variant to null", t => {
  let struct = S.literalVariant(EmptyNull, Apple)

  t->Assert.deepEqual(Apple->S.serializeWith(struct), Ok(%raw(`null`)), ())
})

test("Successfully serializes variant to undefined", t => {
  let struct = S.literalVariant(EmptyOption, Apple)

  t->Assert.deepEqual(Apple->S.serializeWith(struct), Ok(%raw(`undefined`)), ())
})
