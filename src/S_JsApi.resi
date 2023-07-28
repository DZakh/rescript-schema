@@uncurried

module Error: {
  type t
}

module Result: {
  type t<'value>
}

type rec struct<'input, 'output> = {
  parse: 'a. 'a => Result.t<'output>,
  parseOrThrow: 'a. 'a => 'output,
  parseAsync: 'a. 'a => promise<Result.t<'output>>,
  serialize: 'output => Result.t<'input>,
  serializeOrThrow: 'output => 'input,
  transform: 'transformed. (
    ~parser: ('output, effectCtx<'input, 'transformed>) => 'transformed=?,
    ~serializer: ('transformed, effectCtx<'input, 'transformed>) => 'output=?,
  ) => struct<'input, 'transformed>,
  refine: (('output, effectCtx<'input, 'output>) => unit) => struct<'input, 'output>,
  asyncParserRefine: (('output, effectCtx<'input, 'output>) => promise<unit>) => struct<
    'input,
    'output,
  >,
  optional: unit => struct<option<'input>, option<'output>>,
  nullable: unit => struct<Js.null<'input>, option<'output>>,
  describe: string => struct<'input, 'output>,
  description: unit => option<string>,
  default: (unit => 'output) => struct<option<'input>, 'output>,
}
and effectCtx<'input, 'output> = {
  struct: struct<'input, 'output>,
  fail: 'a. string => 'a,
}

let string: struct<string, string>
let boolean: struct<bool, bool>
let integer: struct<int, int>
let number: struct<float, float>
let never: struct<S.never, S.never>
let unknown: struct<unknown, unknown>
let json: struct<Js.Json.t, Js.Json.t>
let nan: struct<float, unit>

let optional: struct<'input, 'output> => struct<option<'input>, option<'output>>
let nullable: struct<'input, 'output> => struct<Js.null<'input>, option<'output>>
let array: struct<'input, 'output> => struct<array<'input>, array<'output>>
let record: struct<'input, 'output> => struct<Js.Dict.t<'input>, Js.Dict.t<'output>>
let jsonString: struct<'input, 'output> => struct<string, 'output>
let union: array<struct<'input, 'output>> => struct<'input, 'output>
let literal: 'literal => struct<'literal, 'literal>
let tuple: array<struct<unknown, unknown>> => struct<array<unknown>, array<unknown>>

let custom: (
  ~name: string,
  ~parser: (unknown, effectCtx<'input, 'output>) => 'output=?,
  ~serializer: ('output, effectCtx<'input, 'output>) => 'input=?,
  unit,
) => struct<'input, 'output>

module Object: {
  type rec t = {strict: unit => t, strip: unit => t}

  let factory: Js.Dict.t<struct<'input, 'output>> => t
}
