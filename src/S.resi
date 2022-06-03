type never
type unknown

type rec literal<'value> =
  | String(string): literal<string>
  | Int(int): literal<int>
  | Float(float): literal<float>
  | Bool(bool): literal<bool>
  | EmptyNull: literal<option<never>>
  | EmptyOption: literal<option<never>>

type mode = Safe | Unsafe

type recordUnknownKeys =
  | Strict
  | Strip

type rec t<'value>
and tagged_t =
  | Never: tagged_t
  | Unknown: tagged_t
  | String: tagged_t
  | Int: tagged_t
  | Float: tagged_t
  | Bool: tagged_t
  | Literal(literal<'value>): tagged_t
  | Option(t<'value>): tagged_t
  | Null(t<'value>): tagged_t
  | Array(t<'value>): tagged_t
  | Record({
      fields: Js.Dict.t<t<unknown>>,
      fieldNames: array<string>,
      unknownKeys: recordUnknownKeys,
    }): tagged_t
  | Dict(t<'value>): tagged_t
  | Deprecated({struct: t<'value>, maybeMessage: option<string>}): tagged_t
  | Default({struct: t<option<'value>>, value: 'value}): tagged_t
and field<'value> = (string, t<'value>)

let never: unit => t<never>
let unknown: unit => t<unknown>
let string: unit => t<string>
let bool: unit => t<bool>
let int: unit => t<int>
let float: unit => t<float>
let literal: literal<'value> => t<'value>
let array: t<'value> => t<array<'value>>
let dict: t<'value> => t<Js.Dict.t<'value>>
let option: t<'value> => t<option<'value>>
let null: t<'value> => t<option<'value>>
let deprecated: (~message: string=?, t<'value>) => t<option<'value>>
let default: (t<option<'value>>, 'value) => t<'value>
let json: t<'value> => t<string>

let record1: (
  ~fields: field<'v1>,
  ~constructor: 'v1 => result<'value, string>=?,
  ~destructor: 'value => result<'v1, string>=?,
  unit,
) => t<'value>
let record2: (
  ~fields: (field<'v1>, field<'v2>),
  ~constructor: (('v1, 'v2)) => result<'value, string>=?,
  ~destructor: 'value => result<('v1, 'v2), string>=?,
  unit,
) => t<'value>
let record3: (
  ~fields: (field<'v1>, field<'v2>, field<'v3>),
  ~constructor: (('v1, 'v2, 'v3)) => result<'value, string>=?,
  ~destructor: 'value => result<('v1, 'v2, 'v3), string>=?,
  unit,
) => t<'value>
let record4: (
  ~fields: (field<'v1>, field<'v2>, field<'v3>, field<'v4>),
  ~constructor: (('v1, 'v2, 'v3, 'v4)) => result<'value, string>=?,
  ~destructor: 'value => result<('v1, 'v2, 'v3, 'v4), string>=?,
  unit,
) => t<'value>
let record5: (
  ~fields: (field<'v1>, field<'v2>, field<'v3>, field<'v4>, field<'v5>),
  ~constructor: (('v1, 'v2, 'v3, 'v4, 'v5)) => result<'value, string>=?,
  ~destructor: 'value => result<('v1, 'v2, 'v3, 'v4, 'v5), string>=?,
  unit,
) => t<'value>
let record6: (
  ~fields: (field<'v1>, field<'v2>, field<'v3>, field<'v4>, field<'v5>, field<'v6>),
  ~constructor: (('v1, 'v2, 'v3, 'v4, 'v5, 'v6)) => result<'value, string>=?,
  ~destructor: 'value => result<('v1, 'v2, 'v3, 'v4, 'v5, 'v6), string>=?,
  unit,
) => t<'value>
let record7: (
  ~fields: (field<'v1>, field<'v2>, field<'v3>, field<'v4>, field<'v5>, field<'v6>, field<'v7>),
  ~constructor: (('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7)) => result<'value, string>=?,
  ~destructor: 'value => result<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7), string>=?,
  unit,
) => t<'value>
let record8: (
  ~fields: (
    field<'v1>,
    field<'v2>,
    field<'v3>,
    field<'v4>,
    field<'v5>,
    field<'v6>,
    field<'v7>,
    field<'v8>,
  ),
  ~constructor: (('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8)) => result<'value, string>=?,
  ~destructor: 'value => result<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8), string>=?,
  unit,
) => t<'value>
let record9: (
  ~fields: (
    field<'v1>,
    field<'v2>,
    field<'v3>,
    field<'v4>,
    field<'v5>,
    field<'v6>,
    field<'v7>,
    field<'v8>,
    field<'v9>,
  ),
  ~constructor: (('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8, 'v9)) => result<'value, string>=?,
  ~destructor: 'value => result<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8, 'v9), string>=?,
  unit,
) => t<'value>
let record10: (
  ~fields: (
    field<'v1>,
    field<'v2>,
    field<'v3>,
    field<'v4>,
    field<'v5>,
    field<'v6>,
    field<'v7>,
    field<'v8>,
    field<'v9>,
    field<'v10>,
  ),
  ~constructor: (('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8, 'v9, 'v10)) => result<'value, string>=?,
  ~destructor: 'value => result<('v1, 'v2, 'v3, 'v4, 'v5, 'v6, 'v7, 'v8, 'v9, 'v10), string>=?,
  unit,
) => t<'value>

let transform: (
  t<'value>,
  ~constructor: 'value => result<'transformedValue, string>=?,
  ~destructor: 'transformedValue => result<'value, string>=?,
  unit,
) => t<'transformedValue>

let transformUnknown: (
  t<unknown>,
  ~constructor: unknown => result<'transformedValue, string>=?,
  ~destructor: 'transformedValue => result<'any, string>=?,
  unit,
) => t<'transformedValue>

let refine: (
  t<'value>,
  ~constructor: 'value => option<string>=?,
  ~destructor: 'value => option<string>=?,
  unit,
) => t<'value>

let parseWith: ('any, ~mode: mode=?, t<'value>) => result<'value, string>

let serializeWith: ('value, ~mode: mode=?, t<'value>) => result<unknown, string>

module Record: {
  let factory: (
    ~fields: 'fields,
    ~constructor: 'fieldValues => result<'value, string>=?,
    ~destructor: 'value => result<'fieldValues, string>=?,
    unit,
  ) => t<'value>

  let strip: t<'value> => t<'value>
  let strict: t<'value> => t<'value>
}

let classify: t<'value> => tagged_t

module MakeMetadata: (
  Config: {
    type content
    let namespace: string
  },
) =>
{
  let get: t<'value> => option<Config.content>

  let set: (t<'value>, Config.content) => t<'value>
}
