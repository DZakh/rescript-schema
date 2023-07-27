@@uncurried

type never

type rec transformation<'input, 'output> =
  | Noop: transformation<'input, 'input>
  | Sync('input => 'output)
  | Async('input => promise<'output>)

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
  | Object({fields: Js.Dict.t<t<unknown>>, fieldNames: array<string>})
  | Tuple(array<t<unknown>>)
  | Union(array<t<unknown>>)
  | Dict(t<unknown>)
  | JSON
and struct<'value> = t<'value>
and error = {operation: operation, code: errorCode, path: Path.t}
and errorCode =
  | OperationFailed(string)
  | InvalidOperation({description: string})
  | InvalidType({expected: struct<unknown>, received: unknown})
  | InvalidLiteral({expected: Literal.t, received: unknown})
  | InvalidTupleSize({expected: int, received: int})
  | ExcessField(string)
  | InvalidUnion(array<error>)
  | UnexpectedAsync
  | InvalidJsonStruct(struct<unknown>)
and operation =
  | Serializing
  | Parsing

type effectCtx<'value> = {
  @as("s") struct: t<'value>,
  @as("f") fail: 'a. (~path: Path.t=?, string) => 'a,
  @as("e") failWithError: 'a. error => 'a,
}

module Error: {
  let toString: error => string
}

exception Raised(error)

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
let jsonString: t<'value> => t<'value>
let union: array<t<'value>> => t<'value>

let default: (t<'value>, unit => 'value) => t<'value>

type catchCtx = {
  error: error,
  input: unknown,
}
let catch: (t<'value>, catchCtx => 'value) => t<'value>

let describe: (t<'value>, string) => t<'value>
let description: t<'value> => option<string>

let deprecate: (t<'value>, string) => t<'value>
let deprecation: t<'value> => option<string>

type transformDefinition<'value, 'transformed> = {
  @as("p")
  parser?: 'value => 'transformed,
  @as("a")
  asyncParser?: 'value => unit => promise<'transformed>,
  @as("s")
  serializer?: 'transformed => 'value,
}
let transform: (
  t<'value>,
  effectCtx<'transformed> => transformDefinition<'value, 'transformed>,
) => t<'transformed>

let advancedPreprocess: (
  t<'value>,
  ~parser: (~struct: t<'value>) => transformation<unknown, 'parserPreprocess>=?,
  ~serializer: (~struct: t<'value>) => transformation<unknown, 'serializerPreprocess>=?,
  unit,
) => t<'value>

let custom: (
  ~name: string,
  ~parser: unknown => 'value=?,
  ~asyncParser: unknown => promise<'value>=?,
  ~serializer: 'value => 'any=?,
  unit,
) => t<'value>

let refine: (t<'value>, effectCtx<'value> => 'value => unit) => t<'value>
let asyncParserRefine: (t<'value>, effectCtx<'value> => 'value => promise<unit>) => t<'value>

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

let serializeToJsonStringWith: ('value, ~space: int=?, t<'value>) => result<string, error>

let serializeOrRaiseWith: ('value, t<'value>) => Js.Json.t

let serializeToUnknownOrRaiseWith: ('value, t<'value>) => unknown

let isAsyncParse: t<'value> => bool

let recursive: (t<'value> => t<'value>) => t<'value>

let classify: t<'value> => tagged

let name: t<'value> => string
let setName: (t<'value>, string) => t<'value>

external toUnknown: t<'any> => t<unknown> = "%identity"

let fail: (~path: Path.t=?, string) => 'a

let advancedFail: error => 'a

module Object: {
  type ctx = {
    @as("f") field: 'value. (string, t<'value>) => 'value,
    @as("t") tag: 'value. (string, 'value) => unit,
  }

  module UnknownKeys: {
    type tagged = Strict | Strip

    let classify: t<'value> => tagged
  }

  /* The same as S.object. Expose only for PPX since the object is a reserved name in OCaml */
  let factory: (ctx => 'value) => t<'value>

  let strip: t<'value> => t<'value>
  let strict: t<'value> => t<'value>
}

let object: (Object.ctx => 'value) => t<'value>

module Tuple: {
  let factory: array<t<unknown>> => t<array<unknown>>
}

let tuple0: unit => t<unit>
let tuple1: t<'value> => t<'value>
let tuple2: (t<'v1>, t<'v2>) => t<('v1, 'v2)>
let tuple3: (t<'v1>, t<'v2>, t<'v3>) => t<('v1, 'v2, 'v3)>
let tuple4: (t<'v1>, t<'v2>, t<'v3>, t<'v4>) => t<('v1, 'v2, 'v3, 'v4)>
let tuple5: (t<'v1>, t<'v2>, t<'v3>, t<'v4>, t<'v5>) => t<('v1, 'v2, 'v3, 'v4, 'v5)>
let tuple6: (t<'v1>, t<'v2>, t<'v3>, t<'v4>, t<'v5>, t<'v6>) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6)>
let tuple7: (
  t<'v1>,
  t<'v2>,
  t<'v3>,
  t<'v4>,
  t<'v5>,
  t<'v6>,
  t<'v7>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7)>
let tuple8: (
  t<'v1>,
  t<'v2>,
  t<'v3>,
  t<'v4>,
  t<'v5>,
  t<'v6>,
  t<'v7>,
  t<'v8>,
) => t<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8)>
let tuple9: (
  t<'v1>,
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
  t<'v1>,
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
      | Datetime
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
  let datetime: (t<string>, ~message: string=?, unit) => t<Js.Date.t>
  let trim: (t<string>, unit) => t<string>
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

module Default: {
  let classify: t<'value> => option<unknown>
}

module Result: {
  let getExn: result<'a, error> => 'a

  let mapErrorToString: result<'a, error> => result<'a, string>
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
