@@uncurried

module Error: {
  type t
}

module Result: {
  type t<'value>
}

let optional: (S.t<'v>, option<unknown>) => S.t<option<'v>>

let tuple: array<S.t<unknown>> => S.t<array<unknown>>

let custom: (
  ~name: string,
  ~parser: (unknown, S.effectCtx<'output>) => 'output=?,
  ~serializer: ('output, S.effectCtx<'output>) => 'input=?,
  unit,
) => S.t<'output>

let asyncParserRefine: (
  S.t<'output>,
  ('output, S.effectCtx<'output>) => promise<unit>,
) => S.t<'output>
let refine: (S.t<'output>, ('output, S.effectCtx<'output>) => unit) => S.t<'output>

let transform: (
  S.t<'output>,
  ~parser: ('output, S.effectCtx<'transformed>) => 'transformed=?,
  ~serializer: ('transformed, S.effectCtx<'transformed>) => 'output=?,
) => S.t<'transformed>

let object: Js.Dict.t<S.t<'value>> => S.t<Js.Dict.t<'value>>

let parse: (S.t<'output>, 'a) => Result.t<'output>
let parseOrThrow: (S.t<'output>, 'a) => 'output
let parseAsync: (S.t<'output>, 'a) => promise<Result.t<'output>>
let serialize: (S.t<'output>, 'output) => Result.t<'input>
let serializeOrThrow: (S.t<'output>, 'output) => 'input
