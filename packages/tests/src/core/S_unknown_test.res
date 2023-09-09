open Ava

module Common = {
  let any = %raw(`"Hello world!"`)
  let factory = () => S.unknown

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(struct), Ok(any), ())
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.serializeToUnknownWith(struct), Ok(any), ())
  })

  test("Compiled parse code snapshot", t => {
    let struct = factory()

    t->U.assertCompiledCodeIsNoop(~struct, ~op=#parse)
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    t->U.assertCompiledCodeIsNoop(~struct, ~op=#serialize)
  })
}

test("Doesn't return refinements", t => {
  let struct = S.unknown
  t->Assert.deepEqual(struct->S.String.refinements, [], ())
  t->Assert.deepEqual(struct->S.Array.refinements, [], ())
  t->Assert.deepEqual(struct->S.Int.refinements, [], ())
  t->Assert.deepEqual(struct->S.Float.refinements, [], ())
})
