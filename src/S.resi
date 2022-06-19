type never
type unknown

type rec literal<'value> =
  | String(string): literal<string>
  | Int(int): literal<int>
  | Float(float): literal<float>
  | Bool(bool): literal<bool>
  | EmptyNull: literal<option<never>>
  | EmptyOption: literal<option<never>>

type mode = Safe | Unsafe

type recordUnknownKeys =
  | Strict
  | Strip

type rec t<'value>
and tagged_t =
  | Never: tagged_t
  | Unknown: tagged_t
  | String: tagged_t
  | Int: tagged_t
  | Float: tagged_t
  | Bool: tagged_t
  | Literal(literal<'value>): tagged_t
  | Option(t<'value>): tagged_t
  | Null(t<'value>): tagged_t
  | Array(t<'value>): tagged_t
  | Record({
      fields: Js.Dict.t<t<unknown>>,
      fieldNames: array<string>,
      unknownKeys: recordUnknownKeys,
    }): tagged_t
  | Tuple(array<t<unknown>>): tagged_t
  | Union(array<t<'value>>): tagged_t
  | Dict(t<'value>): tagged_t
  | Deprecated({struct: t<'value>, maybeMessage: option<string>}): tagged_t
  | Default({struct: t<option<'value>>, value: 'value}): tagged_t
and field<'value> = (string, t<'value>)

let never: unit => t<never>
let unknown: unit => t<unknown>
let string: unit => t<string>
let bool: unit => t<bool>
let int: unit => t<int>
let float: unit => t<float>
let literal: literal<'value> => t<'value>
let literalVariant: (literal<'value>, 'variant) => t<'variant>
let literalUnit: literal<'value> => t<unit>
let array: t<'value> => t<array<'value>>
let dict: t<'value> => t<Js.Dict.t<'value>>
let option: t<'value> => t<option<'value>>
let null: t<'value> => t<option<'value>>
let deprecated: (~message: string=?, t<'value>) => t<option<'value>>
let default: (t<option<'value>>, 'value) => t<'value>
let json: t<'value> => t<'value>

let transform: (
  t<'value>,
  ~parser: 'value => result<'transformedValue, string>=?,
  ~serializer: 'transformedValue => result<'value, string>=?,
  unit,
) => t<'transformedValue>

let union: array<t<'value>> => t<'value>

let transformUnknown: (
  t<unknown>,
  ~parser: unknown => result<'transformedValue, string>=?,
  ~serializer: 'transformedValue => result<'any, string>=?,
  unit,
) => t<'transformedValue>

let refine: (
  t<'value>,
  ~parser: 'value => option<string>=?,
  ~serializer: 'value => option<string>=?,
  unit,
) => t<'value>

let parseWith: ('any, ~mode: mode=?, t<'value>) => result<'value, string>

let serializeWith: ('value, ~mode: mode=?, t<'value>) => result<unknown, string>

module Record: {
  let factory: 'factory

  let strip: t<'value> => t<'value>
  let strict: t<'value> => t<'value>
}

let record0: (. unit) => t<unit>
let record1: (. field<'v1>) => t<'v1>
let record2: (. field<'v1>, field<'v2>) => t<('v1, 'v2)>
let record3: (. field<'v1>, field<'v2>, field<'v3>) => t<('v1, 'v2, 'v3)>
let record4: (. field<'v1>, field<'v2>, field<'v3>, field<'v4>) => t<('v1, 'v2, 'v3, 'v4)>
let record5: (
  . field<'v1>,
  field<'v2>,
  field<'v3>,
  field<'v4>,
  field<'v5>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5)>
let record6: (
  . field<'v1>,
  field<'v2>,
  field<'v3>,
  field<'v4>,
  field<'v5>,
  field<'v6>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6)>
let record7: (
  . field<'v1>,
  field<'v2>,
  field<'v3>,
  field<'v4>,
  field<'v5>,
  field<'v6>,
  field<'v7>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7)>
let record8: (
  . field<'v1>,
  field<'v2>,
  field<'v3>,
  field<'v4>,
  field<'v5>,
  field<'v6>,
  field<'v7>,
  field<'v8>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8)>
let record9: (
  . field<'v1>,
  field<'v2>,
  field<'v3>,
  field<'v4>,
  field<'v5>,
  field<'v6>,
  field<'v7>,
  field<'v8>,
  field<'v9>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8, 'v9)>
let record10: (
  . field<'v1>,
  field<'v2>,
  field<'v3>,
  field<'v4>,
  field<'v5>,
  field<'v6>,
  field<'v7>,
  field<'v8>,
  field<'v9>,
  field<'v10>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8, 'v9, 'v10)>

module Tuple: {
  let factory: 'factory
}

let tuple0: (. unit) => t<unit>
let tuple1: (. t<'value>) => t<'value>
let tuple2: (. t<'v1>, t<'v2>) => t<('v1, 'v2)>
let tuple3: (. t<'v1>, t<'v2>, t<'v3>) => t<('v1, 'v2, 'v3)>
let tuple4: (. t<'v1>, t<'v2>, t<'v3>, t<'v4>) => t<('v1, 'v2, 'v3, 'v4)>
let tuple5: (. t<'v1>, t<'v2>, t<'v3>, t<'v4>, t<'v4>) => t<('v1, 'v2, 'v3, 'v4, 'v5)>
let tuple6: (
  . t<'v1>,
  t<'v2>,
  t<'v3>,
  t<'v4>,
  t<'v4>,
  t<'v5>,
  t<'v6>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6)>
let tuple7: (
  . t<'v1>,
  t<'v2>,
  t<'v3>,
  t<'v4>,
  t<'v4>,
  t<'v5>,
  t<'v6>,
  t<'v7>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7)>
let tuple8: (
  . t<'v1>,
  t<'v2>,
  t<'v3>,
  t<'v4>,
  t<'v4>,
  t<'v5>,
  t<'v6>,
  t<'v7>,
  t<'v8>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8)>
let tuple9: (
  . t<'v1>,
  t<'v2>,
  t<'v3>,
  t<'v4>,
  t<'v4>,
  t<'v5>,
  t<'v6>,
  t<'v7>,
  t<'v8>,
  t<'v9>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8, 'v9)>
let tuple10: (
  . t<'v1>,
  t<'v2>,
  t<'v3>,
  t<'v4>,
  t<'v4>,
  t<'v5>,
  t<'v6>,
  t<'v7>,
  t<'v8>,
  t<'v9>,
  t<'v10>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8, 'v9, 'v10)>

let classify: t<'value> => tagged_t

module MakeMetadata: (
  Config: {
    type content
    let namespace: string
  },
) =>
{
  let get: t<'value> => option<Config.content>

  let set: (t<'value>, Config.content) => t<'value>
}
