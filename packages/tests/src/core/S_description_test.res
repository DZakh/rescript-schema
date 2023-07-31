open Ava

test("S.description returns None for not described structs", t => {
  let struct = S.string

  t->Assert.deepEqual(struct->S.description, None, ())
})

test("S.description returns Some for described structs", t => {
  let struct = S.string->S.describe("A useful bit of text, if you know what to do with it.")

  t->Assert.deepEqual(
    struct->S.description,
    Some("A useful bit of text, if you know what to do with it."),
    (),
  )
})

test("Transforms don't remove description", t => {
  let struct =
    S.string->S.describe("A useful bit of text, if you know what to do with it.")->S.String.trim()

  t->Assert.deepEqual(
    struct->S.description,
    Some("A useful bit of text, if you know what to do with it."),
    (),
  )
})
