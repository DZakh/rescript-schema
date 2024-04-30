open Ava
open RescriptCore

test("Successfully parses valid data", t => {
  let schema = S.string->S.String.datetime

  t->Assert.deepEqual(
    "2020-01-01T00:00:00Z"->S.parseAnyWith(schema),
    Ok(Date.fromString("2020-01-01T00:00:00Z")),
    (),
  )
  t->Assert.deepEqual(
    "2020-01-01T00:00:00.123Z"->S.parseAnyWith(schema),
    Ok(Date.fromString("2020-01-01T00:00:00.123Z")),
    (),
  )
  t->Assert.deepEqual(
    "2020-01-01T00:00:00.123456Z"->S.parseAnyWith(schema),
    Ok(Date.fromString("2020-01-01T00:00:00.123456Z")),
    (),
  )
})

test("Fails to parse non UTC date string", t => {
  let schema = S.string->S.String.datetime

  t->U.assertErrorResult(
    "Thu Apr 20 2023 10:45:48 GMT+0400"->S.parseAnyWith(schema),
    {
      code: OperationFailed("Invalid datetime string! Must be UTC"),
      operation: Parsing,
      path: S.Path.empty,
    },
  )
})

test("Fails to parse UTC date with timezone offset", t => {
  let schema = S.string->S.String.datetime

  t->U.assertErrorResult(
    "2020-01-01T00:00:00+02:00"->S.parseAnyWith(schema),
    {
      code: OperationFailed("Invalid datetime string! Must be UTC"),
      operation: Parsing,
      path: S.Path.empty,
    },
  )
})

test("Uses custom message on failure", t => {
  let schema = S.string->S.String.datetime(~message="Invalid date")

  t->Assert.deepEqual(
    "Thu Apr 20 2023 10:45:48 GMT+0400"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Invalid date"), operation: Parsing, path: S.Path.empty})),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.string->S.String.datetime

  t->Assert.deepEqual(
    Date.fromString("2020-01-01T00:00:00.123Z")->S.serializeToUnknownWith(schema),
    Ok(%raw(`"2020-01-01T00:00:00.123Z"`)),
    (),
  )
})

test("Trims precision to 3 digits when serializing", t => {
  let schema = S.string->S.String.datetime

  t->Assert.deepEqual(
    Date.fromString("2020-01-01T00:00:00.123456Z")->S.serializeToUnknownWith(schema),
    Ok(%raw(`"2020-01-01T00:00:00.123Z"`)),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.string->S.String.datetime

  t->Assert.deepEqual(
    schema->S.String.refinements,
    [{kind: Datetime, message: "Invalid datetime string! Must be UTC"}],
    (),
  )
})
