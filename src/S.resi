module Path: {
  type t

  let empty: t

  external toString: t => string = "%identity"

  let toArray: t => array<string>

  let fromArray: array<string> => t

  let fromLocation: string => t

  let concat: (t, t) => t
}

module Error: {
  type rec t = {operation: operation, code: code, path: Path.t}
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
    | InvalidJsonStruct({received: string})
  and operation =
    | Serializing
    | Parsing

  let raiseCustom: t => 'a

  let raise: string => 'a

  let toString: t => string
}

exception Raised(Error.t)

type never

type rec literal<'value> =
  | String(string): literal<string>
  | Int(int): literal<int>
  | Float(float): literal<float>
  | Bool(bool): literal<bool>
  | EmptyNull: literal<unit>
  | EmptyOption: literal<unit>
  | NaN: literal<unit>

type taggedLiteral =
  | String(string)
  | Int(int)
  | Float(float)
  | Bool(bool)
  | EmptyNull
  | EmptyOption
  | NaN

type transformation<'input, 'output> =
  | Sync('input => 'output)
  | Async('input => promise<'output>)

type rec t<'value>
and tagged =
  | Never
  | Unknown
  | String
  | Int
  | Float
  | Bool
  | Literal(taggedLiteral)
  | Option(t<unknown>)
  | Null(t<unknown>)
  | Array(t<unknown>)
  | Object({fields: Js.Dict.t<t<unknown>>, fieldNames: array<string>})
  | Tuple(array<t<unknown>>)
  | Union(array<t<unknown>>)
  | Dict(t<unknown>)

let never: unit => t<never>
let unknown: unit => t<unknown>
let unit: unit => t<unit>
let string: unit => t<string>
let bool: unit => t<bool>
let int: unit => t<int>
let float: unit => t<float>
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

let describe: (t<'value>, string) => t<'value>
let description: t<'value> => option<string>

let transform: (
  t<'value>,
  ~parser: 'value => 'transformed=?,
  ~serializer: 'transformed => 'value=?,
  unit,
) => t<'transformed>

let advancedTransform: (
  t<'value>,
  ~parser: (~struct: t<'value>) => transformation<'value, 'transformed>=?,
  ~serializer: (~struct: t<'value>) => transformation<'transformed, 'value>=?,
  unit,
) => t<'transformed>

let advancedPreprocess: (
  t<'value>,
  ~parser: (~struct: t<'value>) => transformation<unknown, 'parserPreprocess>=?,
  ~serializer: (~struct: t<'value>) => transformation<unknown, 'serializerPreprocess>=?,
  unit,
) => t<'value>

let custom: (
  ~name: string,
  ~parser: (. ~unknown: unknown) => 'value=?,
  ~serializer: (. ~value: 'value) => 'any=?,
  unit,
) => t<'value>

let refine: (t<'value>, ~parser: 'value => unit=?, ~serializer: 'value => unit=?, unit) => t<'value>

let asyncRefine: (t<'value>, ~parser: 'value => promise<unit>, unit) => t<'value>

let parseWith: ('any, t<'value>) => result<'value, Error.t>

let parseOrRaiseWith: ('any, t<'value>) => 'value

let parseAsyncWith: ('any, t<'value>) => promise<result<'value, Error.t>>

let parseAsyncInStepsWith: (
  'any,
  t<'value>,
) => result<(. unit) => promise<result<'value, Error.t>>, Error.t>

let parseJsonWith: (Js.Json.t, t<'value>) => result<'value, Error.t>

let parseJsonStringWith: (string, t<'value>) => result<'value, Error.t>

let serializeWith: ('value, t<'value>) => result<unknown, Error.t>

let serializeOrRaiseWith: ('value, t<'value>) => unknown

let serializeToJsonWith: ('value, t<'value>) => result<Js.Json.t, Error.t>

let serializeToJsonStringWith: ('value, ~space: int=?, t<'value>) => result<string, Error.t>

let isAsyncParse: t<'value> => bool

let recursive: (t<'value> => t<'value>) => t<'value>
let asyncRecursive: (t<'value> => t<'value>) => t<'value>

let classify: t<'value> => tagged

let name: t<'value> => string

module Object: {
  type definerCtx

  module UnknownKeys: {
    type tagged = Strict | Strip

    let classify: t<'value> => tagged
  }

  let strip: t<'value> => t<'value>
  let strict: t<'value> => t<'value>
}

let object: (Object.definerCtx => 'value) => t<'value>
let field: (Object.definerCtx, string, t<'value>) => 'value

module Tuple: {
  let factory: 'factory
}

let tuple0: (. unit) => t<unit>
let tuple1: (. t<'value>) => t<'value>
let tuple2: (. t<'v1>, t<'v2>) => t<('v1, 'v2)>
let tuple3: (. t<'v1>, t<'v2>, t<'v3>) => t<('v1, 'v2, 'v3)>
let tuple4: (. t<'v1>, t<'v2>, t<'v3>, t<'v4>) => t<('v1, 'v2, 'v3, 'v4)>
let tuple5: (. t<'v1>, t<'v2>, t<'v3>, t<'v4>, t<'v5>) => t<('v1, 'v2, 'v3, 'v4, 'v5)>
let tuple6: (. t<'v1>, t<'v2>, t<'v3>, t<'v4>, t<'v5>, t<'v6>) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6)>
let tuple7: (
  . t<'v1>,
  t<'v2>,
  t<'v3>,
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
  t<'v5>,
  t<'v6>,
  t<'v7>,
  t<'v8>,
  t<'v9>,
  t<'v10>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8, 'v9, 'v10)>

module String: {
  module Refinement: {
    type kind =
      | Min({length: int})
      | Max({length: int})
      | Length({length: int})
      | Email
      | Uuid
      | Cuid
      | Url
      | Pattern({re: Js.Re.t})
    type t = {
      kind: kind,
      message: string,
    }
  }

  let refinements: t<'value> => array<Refinement.t>

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
  module Refinement: {
    type kind =
      | Min({value: int})
      | Max({value: int})
      | Port
    type t = {
      kind: kind,
      message: string,
    }
  }

  let refinements: t<'value> => array<Refinement.t>

  let min: (t<int>, ~message: string=?, int) => t<int>
  let max: (t<int>, ~message: string=?, int) => t<int>
  let port: (t<int>, ~message: string=?, unit) => t<int>
}

module Float: {
  module Refinement: {
    type kind =
      | Min({value: float})
      | Max({value: float})
    type t = {
      kind: kind,
      message: string,
    }
  }

  let refinements: t<'value> => array<Refinement.t>

  let min: (t<float>, ~message: string=?, float) => t<float>
  let max: (t<float>, ~message: string=?, float) => t<float>
}

module Array: {
  module Refinement: {
    type kind =
      | Min({length: int})
      | Max({length: int})
      | Length({length: int})
    type t = {
      kind: kind,
      message: string,
    }
  }

  let refinements: t<'value> => array<Refinement.t>

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

  let set: (t<'value>, ~id: Id.t<'metadata>, ~metadata: 'metadata) => t<'value>
}

let inline: t<'value> => string
