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
        code: InvalidType({
          expected: S.literal(Dict.fromArray([("foo", "bar")]))->S.toUnknown,
          received: invalid,
        }),
        operation: Parse,
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
        code: InvalidType({
          expected: S.literal(Dict.fromArray([("foo", "bar")]))->S.toUnknown,
          received: invalid->U.castAnyToUnknown,
        }),
        operation: SerializeToUnknown,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse null", t => {
    let schema = factory()

    t->U.assertErrorResult(
      %raw(`null`)->S.parseAnyWith(schema),
      {
        code: InvalidType({
          expected: S.literal(Dict.fromArray([("foo", "bar")]))->S.toUnknown,
          received: %raw(`null`),
        }),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse value with excess fields", t => {
    let schema = factory()

    t->U.assertErrorResult(
      %raw(`{"foo": "bar","excess":true}`)->S.parseAnyWith(schema),
      {
        code: InvalidType({
          expected: S.literal(Dict.fromArray([("foo", "bar")]))->S.toUnknown,
          received: %raw(`{"foo": "bar","excess": true}`),
        }),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse non plain objects", t => {
    let schema = factory()

    t->U.assertErrorResult(
      makeNotPlainValue()->S.parseAnyWith(schema),
      {
        code: InvalidType({
          expected: S.literal(Dict.fromArray([("foo", "bar")]))->S.toUnknown,
          received: makeNotPlainValue()->U.castAnyToUnknown,
        }),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Parse,
      `i=>{if(i!==e[0]&&(!i||i.constructor!==Object||Object.keys(i).length!==1||i["foo"]!=="bar")){e[1](i)}return i}`,
    )
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCode(
      ~schema,
      ~op=#Serialize,
      `i=>{if(i!==e[0]&&(!i||i.constructor!==Object||Object.keys(i).length!==1||i["foo"]!=="bar")){e[1](i)}return i}`,
    )
  })
}
