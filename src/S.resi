module Error: {
  type rec t = {operation: operation, code: code, path: array<string>}
  and code =
    | OperationFailed(string)
    | MissingParser
    | MissingSerializer
    | UnexpectedType({expected: string, received: string})
    | UnexpectedValue({expected: string, received: string})
    | TupleSize({expected: int, received: int})
    | ExcessField(string)
    | InvalidUnion(array<t>)
  and operation =
    | Serializing
    | Parsing

  let prependLocation: (t, string) => t

  let make: string => t

  let toString: t => string
}

type never
type unknown

type rec literal<'value> =
  | String(string): literal<string>
  | Int(int): literal<int>
  | Float(float): literal<float>
  | Bool(bool): literal<bool>
  | EmptyNull: literal<unit>
  | EmptyOption: literal<unit>
  | NaN: literal<unit>

type parsingMode = Safe | Unsafe

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
  | Instance(unknown): tagged_t
and field<'value> = (string, t<'value>)

let never: unit => t<never>
let unknown: unit => t<unknown>
let string: unit => t<string>
let bool: unit => t<bool>
let int: unit => t<int>
let float: unit => t<float>
let date: unit => t<Js.Date.t>
let literal: literal<'value> => t<'value>
let literalVariant: (literal<'value>, 'variant) => t<'variant>
let array: t<'value> => t<array<'value>>
let dict: t<'value> => t<Js.Dict.t<'value>>
let option: t<'value> => t<option<'value>>
let null: t<'value> => t<option<'value>>
let deprecated: (~message: string=?, t<'value>) => t<option<'value>>
let default: (t<option<'value>>, 'value) => t<'value>
let json: t<'value> => t<'value>
let union: array<t<'value>> => t<'value>

let transform: (
  t<'value>,
  ~parser: 'value => result<'transformed, string>=?,
  ~serializer: 'transformed => result<'value, string>=?,
  unit,
) => t<'transformed>

let superTransform: (
  t<'value>,
  ~parser: (
    . ~value: 'value,
    ~struct: t<'value>,
    ~mode: parsingMode,
  ) => result<'transformed, Error.t>=?,
  ~serializer: (. ~transformed: 'transformed, ~struct: t<'value>) => result<'value, Error.t>=?,
  unit,
) => t<'transformed>

let custom: (
  ~parser: (. ~unknown: unknown, ~mode: parsingMode) => result<'value, Error.t>=?,
  ~serializer: (. ~value: 'value) => result<'any, Error.t>=?,
  unit,
) => t<'value>

let refine: (
  t<'value>,
  ~parser: 'value => option<string>=?,
  ~serializer: 'value => option<string>=?,
  unit,
) => t<'value>

let parseWith: ('any, ~mode: parsingMode=?, t<'value>) => result<'value, Error.t>

let serializeWith: ('value, t<'value>) => result<unknown, Error.t>

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

module String: {
  let min: (t<string>, ~message: string=?, int) => t<string>
  let max: (t<string>, ~message: string=?, int) => t<string>
  let length: (t<string>, ~message: string=?, int) => t<string>
  let email: (t<string>, ~message: string=?, unit) => t<string>
  let uuid: (t<string>, ~message: string=?, unit) => t<string>
  let cuid: (t<string>, ~message: string=?, unit) => t<string>
  let url: (t<string>, ~message: string=?, unit) => t<string>
  let pattern: (t<string>, ~message: string=?, Js.Re.t) => t<string>

  let trimmed: (t<string>, unit) => t<string>
}

module Int: {
  let min: (t<int>, ~message: string=?, int) => t<int>
  let max: (t<int>, ~message: string=?, int) => t<int>
}

module Float: {
  let min: (t<float>, ~message: string=?, float) => t<float>
  let max: (t<float>, ~message: string=?, float) => t<float>
}

module Array: {
  let min: (t<array<'a>>, ~message: string=?, int) => t<array<'a>>
  let max: (t<array<'a>>, ~message: string=?, int) => t<array<'a>>
  let length: (t<array<'a>>, ~message: string=?, int) => t<array<'a>>
}

module Result: {
  let getExn: result<'a, Error.t> => 'a

  let mapErrorToString: result<'a, Error.t> => result<'a, string>
}

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
