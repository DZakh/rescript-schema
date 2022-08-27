open Ava

module Common = {
  let value = "ReScript is Great!"
  let wrongValue = "Hello world!"
  let any = %raw(`"ReScript is Great!"`)
  let wrongAny = %raw(`"Hello world!"`)
  let wrongTypeAny = %raw(`true`)
  let factory = () => S.literal(String("ReScript is Great!"))

  ava->test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  ava->test("Fails to parse wrong value", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error({
        code: UnexpectedValue({expected: `"ReScript is Great!"`, received: `"Hello world!"`}),
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
        code: UnexpectedType({expected: `String Literal ("ReScript is Great!")`, received: "Bool"}),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  ava->test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
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
