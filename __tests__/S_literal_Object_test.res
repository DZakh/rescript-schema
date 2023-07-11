open Ava

module Common = {
  let value = {"foo": "bar"}
  let invalid = %raw(`123`)
  let factory = () => S.literal({"foo": "bar"})

  %%raw(`
    export class NotPlainValue {
      constructor() {

        this.foo = "bar";
      }
    }
  `)

  @new
  external makeNotPlainValue: unit => {"foo": string} = "NotPlainValue"

  test("Successfully parses", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.parseAnyWith(struct), Ok(value), ())
  })

  test("Fails to parse invalid", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalid->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({
          expected: Dict(Js.Dict.fromArray([("foo", S.Literal.String("bar"))])),
          received: invalid,
        }),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(
      value->S.serializeToUnknownWith(struct),
      Ok(value->TestUtils.castAnyToUnknown),
      (),
    )
  })

  test("Fails to serialize invalid", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalid->S.serializeToUnknownWith(struct),
      Error({
        code: InvalidLiteral({
          expected: Dict(Js.Dict.fromArray([("foo", S.Literal.String("bar"))])),
          received: invalid->TestUtils.castAnyToUnknown,
        }),
        operation: Serializing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to parse null", t => {
    let struct = factory()

    t->Assert.deepEqual(
      %raw(`null`)->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({
          expected: Dict(Js.Dict.fromArray([("foo", S.Literal.String("bar"))])),
          received: %raw(`null`),
        }),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to parse value with excess fields", t => {
    let struct = factory()

    t->Assert.deepEqual(
      %raw(`{"foo": "bar","excess":true}`)->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({
          expected: Dict(Js.Dict.fromArray([("foo", S.Literal.String("bar"))])),
          received: %raw(`{"foo": "bar","excess": true}`),
        }),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })

  test("Fails to parse non plain objects", t => {
    let struct = factory()

    t->Assert.deepEqual(
      makeNotPlainValue()->S.parseAnyWith(struct),
      Error({
        code: InvalidLiteral({
          expected: Dict(Js.Dict.fromArray([("foo", S.Literal.String("bar"))])),
          received: makeNotPlainValue()->TestUtils.castAnyToUnknown,
        }),
        operation: Parsing,
        path: S.Path.empty,
      }),
      (),
    )
  })
}
