@@uncurried

module Error: {
  type t
}

module Result: {
  type t<'value>
}

type any
type transformed
type rec struct<'value> = {
  parse: any => Result.t<'value>,
  parseOrThrow: any => 'value,
  parseAsync: any => promise<Result.t<'value>>,
  serialize: 'value => Result.t<unknown>,
  serializeOrThrow: 'value => unknown,
  transform: (
    ~parser: 'value => transformed,
    ~serializer: transformed => 'value,
  ) => struct<transformed>,
  refine: (effectCtx<'value> => 'value => unit) => struct<'value>,
  asyncParserRefine: (effectCtx<'value> => 'value => promise<unit>) => struct<'value>,
  optional: unit => struct<option<'value>>,
  nullable: unit => struct<option<'value>>,
  describe: string => struct<'value>,
  description: unit => option<string>,
  default: (unit => unknown) => struct<unknown>,
}
and effectCtx<'value> = {
  struct: struct<'value>,
  fail: 'a. string => 'a,
}

let fail: string => 'a

let string: struct<string>
let boolean: struct<bool>
let integer: struct<int>
let number: struct<float>
let never: struct<S.never>
let unknown: struct<unknown>
let json: struct<Js.Json.t>
let nan: struct<unit>

let optional: struct<'value> => struct<option<'value>>
let nullable: struct<'value> => struct<option<'value>>
let array: struct<'value> => struct<array<'value>>
let record: struct<'value> => struct<Js.Dict.t<'value>>
let jsonString: struct<'value> => struct<'value>
let union: array<struct<unknown>> => struct<unknown>
let literal: 'value => struct<'value>
let tuple: array<struct<unknown>> => struct<array<unknown>>

let custom: (
  ~name: string,
  ~parser: unknown => 'value,
  ~serializer: 'value => 'any,
) => struct<'value>

module Object: {
  type rec t = {strict: unit => t, strip: unit => t}

  let factory: Js.Dict.t<struct<'value>> => t
}
