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
  serialize: 'value => Result.t<S.unknown>,
  serializeOrThrow: 'value => S.unknown,
  transform: (
    ~parser: 'value => transformed,
    ~serializer: transformed => 'value,
  ) => struct<transformed>,
  refine: (~parser: 'value => unit, ~serializer: 'value => unit) => struct<'value>,
  asyncRefine: (~parser: 'value => promise<unit>) => struct<'value>,
  optional: unit => struct<option<'value>>,
  nullable: unit => struct<option<'value>>,
}

let string: unit => struct<string>
let boolean: unit => struct<bool>
let integer: unit => struct<int>
let number: unit => struct<float>
let never: unit => struct<S.never>
let unknown: unit => struct<S.unknown>

let optional: struct<'value> => struct<option<'value>>
let nullable: struct<'value> => struct<option<'value>>
let array: struct<'value> => struct<array<'value>>
let record: struct<'value> => struct<Js.Dict.t<'value>>
let json: struct<'value> => struct<'value>

let custom: (
  ~name: string,
  ~parser: (. ~unknown: S.unknown) => 'value,
  ~serializer: (. ~value: 'value) => 'any,
) => struct<'value>

module Object: {
  type rec t = {strict: unit => t, strip: unit => t}

  let factory: Js.Dict.t<struct<'value>> => t
}
