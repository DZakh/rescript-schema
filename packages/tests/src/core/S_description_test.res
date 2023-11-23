open Ava

test("S.description returns None for not described schemas", t => {
  let schema = S.string

  t->Assert.deepEqual(schema->S.description, None, ())
})

test("S.description returns Some for described schemas", t => {
  let schema = S.string->S.describe("A useful bit of text, if you know what to do with it.")

  t->Assert.deepEqual(
    schema->S.description,
    Some("A useful bit of text, if you know what to do with it."),
    (),
  )
})

test("Transforms don't remove description", t => {
  let schema =
    S.string->S.describe("A useful bit of text, if you know what to do with it.")->S.String.trim

  t->Assert.deepEqual(
    schema->S.description,
    Some("A useful bit of text, if you know what to do with it."),
    (),
  )
})
