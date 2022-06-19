open Ava

module Common = {
  let value = None
  let any = %raw(`null`)
  let wrongAny = %raw(`123.45`)
  let factory = () => S.null(S.string())

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Successfully parses without validation in Unsafe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongAny->S.parseWith(~mode=Unsafe, struct), Ok(wrongAny), ())
  })

  test("Fails to parse in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "String", received: "Float"}),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })
}

test("Successfully parses primitive", t => {
  let struct = S.null(S.bool())

  t->Assert.deepEqual(Js.Json.boolean(true)->S.parseWith(struct), Ok(Some(true)), ())
})

test("Fails to parse JS undefined", t => {
  let struct = S.null(S.bool())

  t->Assert.deepEqual(
    %raw(`undefined`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Bool", received: "Option"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Fails to parse record with missing field that marked as null", t => {
  let struct = S.record1(. ("nullableField", S.null(S.string())))

  t->Assert.deepEqual(
    %raw(`{}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "String", received: "Option"}),
      operation: Parsing,
      path: ["nullableField"],
    }),
    (),
  )
})

test("Fails to parse JS null when struct doesn't allow optional data", t => {
  let struct = S.bool()

  t->Assert.deepEqual(
    %raw(`null`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Bool", received: "Null"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully parses null and serializes it back for deprecated nullable struct", t => {
  let struct = S.deprecated(S.null(S.bool()))

  t->Assert.deepEqual(
    %raw(`null`)->S.parseWith(struct)->Belt.Result.map(S.serializeWith(_, struct)),
    Ok(Ok(%raw(`null`))),
    (),
  )
})

test("Successfully parses null and serializes it back for optional nullable struct", t => {
  let struct = S.option(S.null(S.bool()))

  t->Assert.deepEqual(
    %raw(`null`)->S.parseWith(struct)->Belt.Result.map(S.serializeWith(_, struct)),
    Ok(Ok(%raw(`null`))),
    (),
  )
})
