open Ava

test("Successfully parses", t => {
  let schema = S.bool

  t->Assert.deepEqual(true->S.serializeToJsonStringWith(schema), Ok("true"), ())
})

test("Successfully parses object", t => {
  let schema = S.object(s =>
    {
      "id": s.field("id", S.string),
      "isDeleted": s.field("isDeleted", S.bool),
    }
  )

  t->Assert.deepEqual(
    {
      "id": "0",
      "isDeleted": true,
    }->S.serializeToJsonStringWith(schema),
    Ok(`{"id":"0","isDeleted":true}`),
    (),
  )
})

test("Successfully parses object with space", t => {
  let schema = S.object(s =>
    {
      "id": s.field("id", S.string),
      "isDeleted": s.field("isDeleted", S.bool),
    }
  )

  t->Assert.deepEqual(
    {
      "id": "0",
      "isDeleted": true,
    }->S.serializeToJsonStringWith(~space=2, schema),
    Ok(`{
  "id": "0",
  "isDeleted": true
}`),
    (),
  )
})

test("Fails to serialize Unknown schema", t => {
  let schema = S.unknown
  t->Assert.deepEqual(
    Obj.magic(123)->S.serializeToJsonStringWith(schema),
    Error(
      U.error({code: InvalidJsonStruct(schema), operation: SerializeToJson, path: S.Path.empty}),
    ),
    (),
  )
})
