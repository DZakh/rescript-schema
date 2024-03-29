@@uncurried

type never

module Literal: {
  type rec t =
    | String(string)
    | Number(float)
    | Boolean(bool)
    | BigInt(Js.Types.bigint_val)
    | Symbol(Js.Types.symbol)
    | Array(array<t>)
    | Dict(Js.Dict.t<t>)
    | Function(Js.Types.function_val)
    | Object(Js.Types.obj_val)
    | Null
    | Undefined
    | NaN

  let classify: 'a => t

  let value: t => unknown

  let isJsonable: t => bool

  let toText: t => string
}

module Path: {
  type t

  let empty: t
  let dynamic: t

  external toString: t => string = "%identity"

  let toArray: t => array<string>

  let fromArray: array<string> => t

  let fromLocation: string => t

  let concat: (t, t) => t
}

type rec t<'value>
and tagged =
  | Never
  | Unknown
  | String
  | Int
  | Float
  | Bool
  | Literal(Literal.t)
  | Option(t<unknown>)
  | Null(t<unknown>)
  | Array(t<unknown>)
  | Object({fields: Js.Dict.t<t<unknown>>, fieldNames: array<string>, unknownKeys: unknownKeys})
  | Tuple(array<t<unknown>>)
  | Union(array<t<unknown>>)
  | Dict(t<unknown>)
  | JSON
and schema<'value> = t<'value>
and error = private {operation: operation, code: errorCode, path: Path.t}
and errorCode =
  | OperationFailed(string)
  | InvalidOperation({description: string})
  | InvalidType({expected: schema<unknown>, received: unknown})
  | InvalidLiteral({expected: Literal.t, received: unknown})
  | InvalidTupleSize({expected: int, received: int})
  | ExcessField(string)
  | InvalidUnion(array<error>)
  | UnexpectedAsync
  | InvalidJsonStruct(schema<unknown>)
and operation =
  | Parsing
  | Serializing
and unknownKeys = Strip | Strict
type exn += private Raised(error)

type effectCtx<'value> = {
  schema: t<'value>,
  fail: 'a. (string, ~path: Path.t=?) => 'a,
  failWithError: 'a. error => 'a,
}

module Error: {
  type class

  let class: class

  let make: (~code: errorCode, ~operation: operation, ~path: Path.t) => error

  let raise: error => 'a

  let message: error => string

  let reason: error => string
}

let never: t<never>
let unknown: t<unknown>
let unit: t<unit>
let string: t<string>
let bool: t<bool>
let int: t<int>
let float: t<float>
let json: t<Js.Json.t>

let literal: 'value => t<'value>
let array: t<'value> => t<array<'value>>
let list: t<'value> => t<list<'value>>
let dict: t<'value> => t<Js.Dict.t<'value>>
let option: t<'value> => t<option<'value>>
let null: t<'value> => t<option<'value>>
let nullable: t<'value> => t<option<'value>>
let jsonString: (t<'value>, ~space: int=?) => t<'value>
let union: array<t<'value>> => t<'value>

type catchCtx<'value> = {
  @as("e") error: error,
  @as("i") input: unknown,
  @as("s") schema: t<'value>,
  @as("f") fail: 'a. (string, ~path: Path.t=?) => 'a,
  @as("w") failWithError: 'a. error => 'a,
}
let catch: (t<'value>, catchCtx<'value> => 'value) => t<'value>

let describe: (t<'value>, string) => t<'value>
let description: t<'value> => option<string>

let deprecate: (t<'value>, string) => t<'value>
let deprecation: t<'value> => option<string>

type transformDefinition<'input, 'output> = {
  @as("p")
  parser?: 'input => 'output,
  @as("a")
  asyncParser?: 'input => unit => promise<'output>,
  @as("s")
  serializer?: 'output => 'input,
}
let transform: (t<'input>, effectCtx<'output> => transformDefinition<'input, 'output>) => t<'output>

type preprocessDefinition<'input, 'output> = {
  @as("p")
  parser?: unknown => 'output,
  @as("a")
  asyncParser?: unknown => unit => promise<'output>,
  @as("s")
  serializer?: unknown => 'input,
}
let preprocess: (t<'value>, effectCtx<'value> => preprocessDefinition<'input, 'output>) => t<'value>

type customDefinition<'input, 'output> = {
  @as("p")
  parser?: unknown => 'output,
  @as("a")
  asyncParser?: unknown => unit => promise<'output>,
  @as("s")
  serializer?: 'output => 'input,
}
let custom: (string, effectCtx<'output> => customDefinition<'input, 'output>) => t<'output>

let refine: (t<'value>, effectCtx<'value> => 'value => unit) => t<'value>

let variant: (t<'value>, 'value => 'variant) => t<'variant>

let parseWith: (Js.Json.t, t<'value>) => result<'value, error>

let parseAnyWith: ('any, t<'value>) => result<'value, error>

let parseJsonStringWith: (string, t<'value>) => result<'value, error>

let parseOrRaiseWith: (Js.Json.t, t<'value>) => 'value

let parseAnyOrRaiseWith: ('any, t<'value>) => 'value

let parseAsyncWith: (Js.Json.t, t<'value>) => promise<result<'value, error>>

let parseAnyAsyncWith: ('any, t<'value>) => promise<result<'value, error>>

let parseAsyncInStepsWith: (
  Js.Json.t,
  t<'value>,
) => result<unit => promise<result<'value, error>>, error>

let parseAnyAsyncInStepsWith: (
  'any,
  t<'value>,
) => result<unit => promise<result<'value, error>>, error>

let serializeWith: ('value, t<'value>) => result<Js.Json.t, error>

let serializeToUnknownWith: ('value, t<'value>) => result<unknown, error>

let serializeToJsonStringWith: ('value, t<'value>, ~space: int=?) => result<string, error>

let serializeOrRaiseWith: ('value, t<'value>) => Js.Json.t

let serializeToUnknownOrRaiseWith: ('value, t<'value>) => unknown

let isAsyncParse: t<'value> => bool

let recursive: (t<'value> => t<'value>) => t<'value>

let classify: t<'value> => tagged

@send
external name: t<'value> => string = "n"

let setName: (t<'value>, string) => t<'value>

external toUnknown: t<'any> => t<unknown> = "%identity"

type schemaCtx = {matches: 'value. t<'value> => 'value}
let schema: (schemaCtx => 'value) => t<'value>

module Object: {
  type ctx = {
    @as("f") field: 'value. (string, t<'value>) => 'value,
    @as("o") fieldOr: 'value. (string, t<'value>, 'value) => 'value,
    @as("t") tag: 'value. (string, 'value) => unit,
  }

  /* The same as S.object. Expose only for PPX since the object is a reserved name in OCaml */
  let factory: (ctx => 'value) => t<'value>

  let strip: t<'value> => t<'value>
  let strict: t<'value> => t<'value>
}

let object: (Object.ctx => 'value) => t<'value>

module Tuple: {
  type ctx = {
    @as("i") item: 'value. (int, t<'value>) => 'value,
    @as("t") tag: 'value. (int, 'value) => unit,
  }
}

let tuple: (Tuple.ctx => 'value) => t<'value>
let tuple1: t<'value> => t<'value>
let tuple2: (t<'v1>, t<'v2>) => t<('v1, 'v2)>
let tuple3: (t<'v1>, t<'v2>, t<'v3>) => t<('v1, 'v2, 'v3)>

module Option: {
  type default = Value(unknown) | Callback(unit => unknown)

  let default: t<'value> => option<default>

  let getOr: (t<option<'value>>, 'value) => t<'value>
  let getOrWith: (t<option<'value>>, unit => 'value) => t<'value>
}

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
      | Datetime
    type t = {
      kind: kind,
      message: string,
    }
  }

  let refinements: t<'value> => array<Refinement.t>

  let min: (t<string>, int, ~message: string=?) => t<string>
  let max: (t<string>, int, ~message: string=?) => t<string>
  let length: (t<string>, int, ~message: string=?) => t<string>
  let email: (t<string>, ~message: string=?) => t<string>
  let uuid: (t<string>, ~message: string=?) => t<string>
  let cuid: (t<string>, ~message: string=?) => t<string>
  let url: (t<string>, ~message: string=?) => t<string>
  let pattern: (t<string>, Js.Re.t, ~message: string=?) => t<string>
  let datetime: (t<string>, ~message: string=?) => t<Js.Date.t>
  let trim: t<string> => t<string>
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

  let min: (t<int>, int, ~message: string=?) => t<int>
  let max: (t<int>, int, ~message: string=?) => t<int>
  let port: (t<int>, ~message: string=?) => t<int>
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

  let min: (t<float>, float, ~message: string=?) => t<float>
  let max: (t<float>, float, ~message: string=?) => t<float>
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

  let min: (t<array<'a>>, int, ~message: string=?) => t<array<'a>>
  let max: (t<array<'a>>, int, ~message: string=?) => t<array<'a>>
  let length: (t<array<'a>>, int, ~message: string=?) => t<array<'a>>
}

module Metadata: {
  module Id: {
    type t<'metadata>
    let make: (~namespace: string, ~name: string) => t<'metadata>
  }

  let get: (t<'value>, ~id: Id.t<'metadata>) => option<'metadata>

  let set: (t<'value>, ~id: Id.t<'metadata>, 'metadata) => t<'value>
}

let inline: t<'value> => string
