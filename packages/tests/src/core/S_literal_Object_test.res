open Ava
open RescriptCore

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
      Error(
        U.error({
          code: InvalidLiteral({
            expected: Dict(Dict.fromArray([("foo", S.Literal.String("bar"))])),
            received: invalid,
          }),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(struct), Ok(value->U.castAnyToUnknown), ())
  })

  test("Fails to serialize invalid", t => {
    let struct = factory()

    t->Assert.deepEqual(
      invalid->S.serializeToUnknownWith(struct),
      Error(
        U.error({
          code: InvalidLiteral({
            expected: Dict(Dict.fromArray([("foo", S.Literal.String("bar"))])),
            received: invalid->U.castAnyToUnknown,
          }),
          operation: Serializing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Fails to parse null", t => {
    let struct = factory()

    t->Assert.deepEqual(
      %raw(`null`)->S.parseAnyWith(struct),
      Error(
        U.error({
          code: InvalidLiteral({
            expected: Dict(Dict.fromArray([("foo", S.Literal.String("bar"))])),
            received: %raw(`null`),
          }),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Fails to parse value with excess fields", t => {
    let struct = factory()

    t->Assert.deepEqual(
      %raw(`{"foo": "bar","excess":true}`)->S.parseAnyWith(struct),
      Error(
        U.error({
          code: InvalidLiteral({
            expected: Dict(Dict.fromArray([("foo", S.Literal.String("bar"))])),
            received: %raw(`{"foo": "bar","excess": true}`),
          }),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Fails to parse non plain objects", t => {
    let struct = factory()

    t->Assert.deepEqual(
      makeNotPlainValue()->S.parseAnyWith(struct),
      Error(
        U.error({
          code: InvalidLiteral({
            expected: Dict(Dict.fromArray([("foo", S.Literal.String("bar"))])),
            received: makeNotPlainValue()->U.castAnyToUnknown,
          }),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ),
      (),
    )
  })

  test("Compiled parse code snapshot", t => {
    let struct = factory()

    t->U.assertCompiledCode(
      ~struct,
      ~op=#parse,
      `i=>{(i===e[0]||i&&i.constructor===Object&&Object.keys(i).length===1&&i["foo"]===e[1])||e[2](i);return i}`,
    )
  })

  test("Compiled serialize code snapshot", t => {
    let struct = factory()

    t->U.assertCompiledCode(
      ~struct,
      ~op=#serialize,
      `i=>{(i===e[0]||i&&i.constructor===Object&&Object.keys(i).length===1&&i["foo"]===e[1])||e[2](i);return i}`,
    )
  })
}
