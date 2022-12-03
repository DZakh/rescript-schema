type any
type transformed
type rec struct<'value> = {
  parse: any => 'value,
  parseAsync: any => promise<'value>,
  serialize: 'value => S.unknown,
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

let object: Js.Dict.t<struct<'value>> => struct<Js.Dict.t<'value>>
