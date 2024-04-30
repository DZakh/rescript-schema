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
    let schema = factory()

    t->Assert.deepEqual(value->S.parseAnyWith(schema), Ok(value), ())
  })

  test("Fails to parse invalid", t => {
    let schema = factory()

    t->U.assertErrorResult(
      invalid->S.parseAnyWith(schema),
      {
        code: InvalidLiteral({
          expected: S.Literal.parse(Dict.fromArray([("foo", "bar")])),
          received: invalid,
        }),
        operation: Parsing,
        path: S.Path.empty,
      },
    )
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(value->S.serializeToUnknownWith(schema), Ok(value->U.castAnyToUnknown), ())
  })

  test("Fails to serialize invalid", t => {
    let schema = factory()

    t->U.assertErrorResult(
      invalid->S.serializeToUnknownWith(schema),
      {
        code: InvalidLiteral({
          expected: S.Literal.parse(Dict.fromArray([("foo", "bar")])),
          received: invalid->U.castAnyToUnknown,
        }),
        operation: Serializing,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse null", t => {
    let schema = factory()

    t->U.assertErrorResult(
      %raw(`null`)->S.parseAnyWith(schema),
      {
        code: InvalidLiteral({
          expected: S.Literal.parse(Dict.fromArray([("foo", "bar")])),
          received: %raw(`null`),
        }),
        operation: Parsing,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse value with excess fields", t => {
    let schema = factory()

    t->U.assertErrorResult(
      %raw(`{"foo": "bar","excess":true}`)->S.parseAnyWith(schema),
      {
        code: InvalidLiteral({
          expected: S.Literal.parse(Dict.fromArray([("foo", "bar")])),
          received: %raw(`{"foo": "bar","excess": true}`),
        }),
        operation: Parsing,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse non plain objects", t => {
    let schema = factory()

    t->U.assertErrorResult(
      makeNotPlainValue()->S.parseAnyWith(schema),
      {
        code: InvalidLiteral({
          expected: S.Literal.parse(Dict.fromArray([("foo", "bar")])),
          received: makeNotPlainValue()->U.castAnyToUnknown,
        }),
        operation: Parsing,
        path: S.Path.empty,
      },
    )
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#parse,
      `i=>{(i===e[0]||i&&i.constructor===Object&&Object.keys(i).length===1&&i["foo"]===e[1])||e[2](i);return i}`,
    )
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#serialize,
      `i=>{(i===e[0]||i&&i.constructor===Object&&Object.keys(i).length===1&&i["foo"]===e[1])||e[2](i);return i}`,
    )
  })
}
