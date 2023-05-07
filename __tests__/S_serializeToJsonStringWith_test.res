open Ava

test("Successfully parses", t => {
  let struct = S.bool

  t->Assert.deepEqual(true->S.serializeToJsonStringWith(struct), Ok("true"), ())
})

test("Successfully parses object", t => {
  let struct = S.object(f =>
    {
      "id": f->S.field("id", S.string),
      "isDeleted": f->S.field("isDeleted", S.bool),
    }
  )

  t->Assert.deepEqual(
    {
      "id": "0",
      "isDeleted": true,
    }->S.serializeToJsonStringWith(struct),
    Ok(`{"id":"0","isDeleted":true}`),
    (),
  )
})

test("Successfully parses object with space", t => {
  let struct = S.object(f =>
    {
      "id": f->S.field("id", S.string),
      "isDeleted": f->S.field("isDeleted", S.bool),
    }
  )

  t->Assert.deepEqual(
    {
      "id": "0",
      "isDeleted": true,
    }->S.serializeToJsonStringWith(~space=2, struct),
    Ok(`{
  "id": "0",
  "isDeleted": true
}`),
    (),
  )
})

test("Fails to serialize Unknown struct", t => {
  t->Assert.deepEqual(
    Obj.magic(123)->S.serializeToJsonStringWith(S.unknown),
    Error({
      code: InvalidJsonStruct({received: "Unknown"}),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})
