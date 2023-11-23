open Ava
open RescriptCore

test("Returns false for schema with NoOperation", t => {
  t->Assert.is(S.unknown->S.isAsyncParse, false, ())
})

test("Returns false for sync schema", t => {
  t->Assert.is(S.string->S.isAsyncParse, false, ())
})

test("Returns true for async schema", t => {
  let schema = S.string->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)})

  t->Assert.is(schema->S.isAsyncParse, true, ())
})

test("Returns true for async schema after running a serializer", t => {
  let schema =
    S.string->S.transform(_ => {asyncParser: i => () => Promise.resolve(i), serializer: i => i})
  t->Assert.deepEqual("abc"->S.serializeWith(schema), Ok(%raw(`"abc"`)), ())
  t->Assert.is(schema->S.isAsyncParse, true, ())
})

test("Returns true for schema with nested async", t => {
  let schema = S.tuple1(S.string->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}))

  t->Assert.is(schema->S.isAsyncParse, true, ())
})
