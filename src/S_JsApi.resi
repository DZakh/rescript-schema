@@uncurried

type jsResult<'value>

let optional: (S.t<'v>, option<unknown>) => S.t<option<'v>>

let tuple: unknown => S.t<array<unknown>>

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

let object: unknown => S.t<Js.Dict.t<unknown>>

let parse: (S.t<'output>, 'a) => jsResult<'output>
let parseOrThrow: (S.t<'output>, 'a) => 'output
let parseAsync: (S.t<'output>, 'a) => promise<jsResult<'output>>
let serialize: (S.t<'output>, 'output) => jsResult<'input>
let serializeOrThrow: (S.t<'output>, 'output) => 'input
