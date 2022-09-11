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
    | UnexpectedAsync
  and operation =
    | Serializing
    | Parsing

  let prependLocation: (t, string) => t

  let raiseCustom: t => 'a

  let raise: string => 'a

  let toString: t => string
}

exception Raised(Error.t)

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

type action<'input, 'output> =
  | Sync('input => 'output)
  | Async('input => Js.Promise.t<'output>)

type rec t<'value>
and tagged =
  | Never
  | Unknown
  | String
  | Int
  | Float
  | Bool
  | Literal
  | Option(t<unknown>)
  | Null(t<unknown>)
  | Array(t<unknown>)
  | Object({fields: Js.Dict.t<t<unknown>>, fieldNames: array<string>})
  | Tuple(array<t<unknown>>)
  | Union(array<t<unknown>>)
  | Dict(t<unknown>)
  | Date
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
let json: t<'value> => t<'value>
let union: array<t<'value>> => t<'value>

let deprecated: (t<'value>, ~message: string=?, unit) => t<option<'value>>
let defaulted: (t<option<'value>>, 'value) => t<'value>

let transform: (
  t<'value>,
  ~parser: 'value => 'transformed=?,
  ~serializer: 'transformed => 'value=?,
  unit,
) => t<'transformed>

let advancedTransform: (
  t<'value>,
  ~parser: (~struct: t<'value>) => action<'value, 'transformed>=?,
  ~serializer: (~struct: t<'value>) => action<'transformed, 'value>=?,
  unit,
) => t<'transformed>

let advancedPreprocess: (
  t<'value>,
  ~parser: (~struct: t<'value>) => action<unknown, 'preprocessed>=?,
  ~serializer: (~struct: t<'value>) => action<'preprocessed, 'any>=?,
  unit,
) => t<'value>

let custom: (
  ~name: string,
  ~parser: (. ~unknown: unknown) => 'value=?,
  ~serializer: (. ~value: 'value) => 'any=?,
  unit,
) => t<'value>

let refine: (t<'value>, ~parser: 'value => unit=?, ~serializer: 'value => unit=?, unit) => t<'value>

let asyncRefine: (t<'value>, ~parser: 'value => Js.Promise.t<unit>, unit) => t<'value>

let parseWith: ('any, t<'value>) => result<'value, Error.t>

let parseOrRaiseWith: ('any, t<'value>) => 'value

let parseAsyncWith: ('any, t<'value>) => Js.Promise.t<result<'value, Error.t>>

let parseAsyncInStepsWith: (
  'any,
  t<'value>,
) => result<unit => Js.Promise.t<result<'value, Error.t>>, Error.t>

let serializeWith: ('value, t<'value>) => result<unknown, Error.t>

let serializeOrRaiseWith: ('value, t<'value>) => unknown

let isAsyncParse: t<'value> => bool

module Object: {
  module UnknownKeys: {
    type tagged = Strict | Strip

    let classify: t<'value> => tagged
  }

  let factory: 'factory

  let strip: t<'value> => t<'value>
  let strict: t<'value> => t<'value>
}

let object0: (. unit) => t<unit>
let object1: (. field<'v1>) => t<'v1>
let object2: (. field<'v1>, field<'v2>) => t<('v1, 'v2)>
let object3: (. field<'v1>, field<'v2>, field<'v3>) => t<('v1, 'v2, 'v3)>
let object4: (. field<'v1>, field<'v2>, field<'v3>, field<'v4>) => t<('v1, 'v2, 'v3, 'v4)>
let object5: (
  . field<'v1>,
  field<'v2>,
  field<'v3>,
  field<'v4>,
  field<'v5>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5)>
let object6: (
  . field<'v1>,
  field<'v2>,
  field<'v3>,
  field<'v4>,
  field<'v5>,
  field<'v6>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6)>
let object7: (
  . field<'v1>,
  field<'v2>,
  field<'v3>,
  field<'v4>,
  field<'v5>,
  field<'v6>,
  field<'v7>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7)>
let object8: (
  . field<'v1>,
  field<'v2>,
  field<'v3>,
  field<'v4>,
  field<'v5>,
  field<'v6>,
  field<'v7>,
  field<'v8>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8)>
let object9: (
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
let object10: (
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

let classify: t<'value> => tagged

let name: t<'value> => string

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

module Defaulted: {
  type tagged = WithDefaultValue(unknown)

  let classify: t<'value> => option<tagged>
}

module Deprecated: {
  type tagged = WithoutMessage | WithMessage(string)

  let classify: t<'value> => option<tagged>
}

module Literal: {
  type tagged =
    | String(string)
    | Int(int)
    | Float(float)
    | Bool(bool)
    | EmptyNull
    | EmptyOption
    | NaN

  let classify: t<'value> => option<tagged>
}

module Result: {
  let getExn: result<'a, Error.t> => 'a

  let mapErrorToString: result<'a, Error.t> => result<'a, string>
}

module Metadata: {
  module Id: {
    type t<'metadata>
    let make: (~namespace: string, ~name: string) => t<'metadata>
  }

  let get: (t<'value>, ~id: Id.t<'metadata>) => option<'metadata>

  let set: (
    t<'value>,
    ~id: Id.t<'metadata>,
    ~metadata: 'metadata,
    ~withParserUpdate: bool,
    ~withSerializerUpdate: bool,
  ) => t<'value>
}
