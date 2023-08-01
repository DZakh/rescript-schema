open Ava

test("Successfully parses valid data", t => {
  let struct = S.string->S.String.datetime()

  t->Assert.deepEqual(
    "2020-01-01T00:00:00Z"->S.parseAnyWith(struct),
    Ok(Date.fromString("2020-01-01T00:00:00Z")),
    (),
  )
  t->Assert.deepEqual(
    "2020-01-01T00:00:00.123Z"->S.parseAnyWith(struct),
    Ok(Date.fromString("2020-01-01T00:00:00.123Z")),
    (),
  )
  t->Assert.deepEqual(
    "2020-01-01T00:00:00.123456Z"->S.parseAnyWith(struct),
    Ok(Date.fromString("2020-01-01T00:00:00.123456Z")),
    (),
  )
})

test("Fails to parse non UTC date string", t => {
  let struct = S.string->S.String.datetime()

  t->Assert.deepEqual(
    "Thu Apr 20 2023 10:45:48 GMT+0400"->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Invalid datetime string! Must be UTC"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to parse UTC date with timezone offset", t => {
  let struct = S.string->S.String.datetime()

  t->Assert.deepEqual(
    "2020-01-01T00:00:00+02:00"->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Invalid datetime string! Must be UTC"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Uses custom message on failure", t => {
  let struct = S.string->S.String.datetime(~message="Invalid date", ())

  t->Assert.deepEqual(
    "Thu Apr 20 2023 10:45:48 GMT+0400"->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Invalid date"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.string->S.String.datetime()

  t->Assert.deepEqual(
    Date.fromString("2020-01-01T00:00:00.123Z")->S.serializeToUnknownWith(struct),
    Ok(%raw(`"2020-01-01T00:00:00.123Z"`)),
    (),
  )
})

test("Trims precision to 3 digits when serializing", t => {
  let struct = S.string->S.String.datetime()

  t->Assert.deepEqual(
    Date.fromString("2020-01-01T00:00:00.123456Z")->S.serializeToUnknownWith(struct),
    Ok(%raw(`"2020-01-01T00:00:00.123Z"`)),
    (),
  )
})

test("Returns refinement", t => {
  let struct = S.string->S.String.datetime()

  t->Assert.deepEqual(
    struct->S.String.refinements,
    [{kind: Datetime, message: "Invalid datetime string! Must be UTC"}],
    (),
  )
})
