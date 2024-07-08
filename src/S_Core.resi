@@uncurried
@@warning("-30")

type never

@tag("kind")
type rec literal =
  private
  | String({value: string})
  | Number({value: float})
  | Boolean({value: bool})
  | BigInt({value: bigint})
  | Symbol({value: Js.Types.symbol})
  | Array({value: array<unknown>, items: array<literal>})
  | Dict({value: dict<unknown>, items: dict<literal>})
  | Function({value: Js.Types.function_val})
  | Object({value: Js.Types.obj_val})
  | Null({value: Js.Types.null_val})
  | Undefined({value: unit})
  | NaN({value: unknown})

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
  private
  | Never
  | Unknown
  | String
  | Int
  | Float
  | Bool
  | Literal(literal)
  | Option(t<unknown>)
  | Null(t<unknown>)
  | Array(t<unknown>)
  | Object({items: array<item>, fields: dict<item>, unknownKeys: unknownKeys, definition: unknown})
  | Tuple({items: array<item>, definition: unknown})
  | Union(array<t<unknown>>)
  | Dict(t<unknown>)
  | JSON({validated: bool})
and item = {
  @as("t")
  schema: schema<unknown>,
  @as("p")
  path: Path.t,
  @as("l")
  location: string,
  @as("i")
  inlinedLocation: string,
  @as("s")
  symbol: Js.Types.symbol,
}
and schema<'value> = t<'value>
and error = private {operation: operation, code: errorCode, path: Path.t}
and errorCode =
  | OperationFailed(string)
  | InvalidOperation({description: string})
  | InvalidType({expected: schema<unknown>, received: unknown})
  | InvalidLiteral({expected: literal, received: unknown})
  | ExcessField(string)
  | InvalidUnion(array<error>)
  | UnexpectedAsync
  | InvalidJsonStruct(schema<unknown>)
and operation =
  | Parse
  | ParseAsync
  | SerializeToJson
  | SerializeToUnknown
  | Assert
and unknownKeys = Strip | Strict
type exn += private Raised(error)

type s<'value> = {
  schema: t<'value>,
  fail: 'a. (string, ~path: Path.t=?) => 'a,
}

module Error: {
  type class

  let class: class

  let make: (~code: errorCode, ~operation: operation, ~path: Path.t) => error

  let raise: error => 'a

  let message: error => string

  let reason: error => string
}

module Literal: {
  let parse: 'a => literal

  let value: literal => unknown

  let isJsonable: literal => bool

  let toString: literal => string
}

let never: t<never>
let unknown: t<unknown>
let unit: t<unit>
let string: t<string>
let bool: t<bool>
let int: t<int>
let float: t<float>

let json: (~validate: bool) => t<Js.Json.t>

let literal: 'value => t<'value>
let array: t<'value> => t<array<'value>>
let list: t<'value> => t<list<'value>>
let dict: t<'value> => t<dict<'value>>
let option: t<'value> => t<option<'value>>
let null: t<'value> => t<option<'value>>
let nullable: t<'value> => t<option<'value>>
let jsonString: (t<'value>, ~space: int=?) => t<'value>
let union: array<t<'value>> => t<'value>

module Catch: {
  type s<'value> = {
    @as("e") error: error,
    @as("i") input: unknown,
    @as("s") schema: t<'value>,
    @as("f") fail: 'a. (string, ~path: Path.t=?) => 'a,
  }
}
let catch: (t<'value>, Catch.s<'value> => 'value) => t<'value>

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
let transform: (t<'input>, s<'output> => transformDefinition<'input, 'output>) => t<'output>

type preprocessDefinition<'input, 'output> = {
  @as("p")
  parser?: unknown => 'output,
  @as("a")
  asyncParser?: unknown => unit => promise<'output>,
  @as("s")
  serializer?: unknown => 'input,
}
let preprocess: (t<'value>, s<'value> => preprocessDefinition<'input, 'output>) => t<'value>

type customDefinition<'input, 'output> = {
  @as("p")
  parser?: unknown => 'output,
  @as("a")
  asyncParser?: unknown => unit => promise<'output>,
  @as("s")
  serializer?: 'output => 'input,
}
let custom: (string, s<'output> => customDefinition<'input, 'output>) => t<'output>

let refine: (t<'value>, s<'value> => 'value => unit) => t<'value>

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

let serializeToJsonStringOrRaiseWith: ('value, t<'value>, ~space: int=?) => string

let assertOrRaiseWith: ('any, t<'value>) => unit

let isAsyncParse: t<'value> => bool

let recursive: (t<'value> => t<'value>) => t<'value>

let classify: t<'value> => tagged

@send
external name: t<'value> => string = "n"

let setName: (t<'value>, string) => t<'value>

external toUnknown: t<'any> => t<unknown> = "%identity"

module Schema: {
  type s = {matches: 'value. t<'value> => 'value}
}
let schema: (Schema.s => 'value) => t<'value>

module Object: {
  type rec s = {
    @as("f") field: 'value. (string, t<'value>) => 'value,
    fieldOr: 'value. (string, t<'value>, 'value) => 'value,
    tag: 'value. (string, 'value) => unit,
    nestedField: 'value. (string, string, t<'value>) => 'value,
    flatten: 'value. t<'value> => 'value,
  }

  /* The same as S.object. Expose only for PPX since the object is a reserved name in OCaml */
  let factory: (s => 'value) => t<'value>

  let strip: t<'value> => t<'value>
  let strict: t<'value> => t<'value>
}

let object: (Object.s => 'value) => t<'value>

module Tuple: {
  type s = {
    item: 'value. (int, t<'value>) => 'value,
    tag: 'value. (int, 'value) => unit,
  }
}

let tuple: (Tuple.s => 'value) => t<'value>
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

// =============
// Built-in refinements
// =============

let intMin: (t<int>, int, ~message: string=?) => t<int>
let intMax: (t<int>, int, ~message: string=?) => t<int>
let port: (t<int>, ~message: string=?) => t<int>

let floatMin: (t<float>, float, ~message: string=?) => t<float>
let floatMax: (t<float>, float, ~message: string=?) => t<float>

let arrayMinLength: (t<array<'a>>, int, ~message: string=?) => t<array<'a>>
let arrayMaxLength: (t<array<'a>>, int, ~message: string=?) => t<array<'a>>
let arrayLength: (t<array<'a>>, int, ~message: string=?) => t<array<'a>>

let stringMinLength: (t<string>, int, ~message: string=?) => t<string>
let stringMaxLength: (t<string>, int, ~message: string=?) => t<string>
let stringLength: (t<string>, int, ~message: string=?) => t<string>
let email: (t<string>, ~message: string=?) => t<string>
let uuid: (t<string>, ~message: string=?) => t<string>
let cuid: (t<string>, ~message: string=?) => t<string>
let url: (t<string>, ~message: string=?) => t<string>
let pattern: (t<string>, Js.Re.t, ~message: string=?) => t<string>
let datetime: (t<string>, ~message: string=?) => t<Js.Date.t>
let trim: t<string> => t<string>

// =============
// JS/TS API
// =============

@@uncurried

@tag("success")
type jsResult<'value>

let js_optional: (t<'v>, option<unknown>) => t<option<'v>>

let js_tuple: unknown => t<array<unknown>>

let js_custom: (
  ~name: string,
  ~parser: (unknown, s<'output>) => 'output=?,
  ~serializer: ('output, s<'output>) => 'input=?,
  unit,
) => t<'output>

let js_asyncParserRefine: (t<'output>, ('output, s<'output>) => promise<unit>) => t<'output>
let js_refine: (t<'output>, ('output, s<'output>) => unit) => t<'output>

let js_transform: (
  t<'output>,
  ~parser: ('output, s<'transformed>) => 'transformed=?,
  ~serializer: ('transformed, s<'transformed>) => 'output=?,
) => t<'transformed>

let js_object: unknown => t<dict<unknown>>

let js_merge: (t<unknown>, t<unknown>) => t<unknown>

let js_name: t<'value> => string

let __internal_resetGlobal: unit => unit
