@@uncurried

type jsResult<'value>

let optional: (S_Core.t<'v>, option<unknown>) => S_Core.t<option<'v>>

let tuple: unknown => S_Core.t<array<unknown>>

let custom: (
  ~name: string,
  ~parser: (unknown, S_Core.effectCtx<'output>) => 'output=?,
  ~serializer: ('output, S_Core.effectCtx<'output>) => 'input=?,
  unit,
) => S_Core.t<'output>

let asyncParserRefine: (
  S_Core.t<'output>,
  ('output, S_Core.effectCtx<'output>) => promise<unit>,
) => S_Core.t<'output>
let refine: (S_Core.t<'output>, ('output, S_Core.effectCtx<'output>) => unit) => S_Core.t<'output>

let transform: (
  S_Core.t<'output>,
  ~parser: ('output, S_Core.effectCtx<'transformed>) => 'transformed=?,
  ~serializer: ('transformed, S_Core.effectCtx<'transformed>) => 'output=?,
) => S_Core.t<'transformed>

let object: unknown => S_Core.t<Js.Dict.t<unknown>>

let parse: (S_Core.t<'output>, 'a) => jsResult<'output>
let parseOrThrow: (S_Core.t<'output>, 'a) => 'output
let parseAsync: (S_Core.t<'output>, 'a) => promise<jsResult<'output>>
let serialize: (S_Core.t<'output>, 'output) => jsResult<'input>
let serializeOrThrow: (S_Core.t<'output>, 'output) => unknown
