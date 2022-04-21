type rec t<'value>
and kind =
  | String: kind
  | Int: kind
  | Float: kind
  | Bool: kind
  | Option(t<'value>): kind
  | Array(t<'value>): kind
  | Record('unsafeFieldsArray): kind
  | Custom: kind
  | Dict(t<'value>): kind
  | Deprecated({struct: t<'value>, maybeMessage: option<string>}): kind
  | Default({struct: t<option<'value>>, value: 'value}): kind
and field<'value> = (string, t<'value>)

let string: unit => t<string>
let coercedString: (
  ~constructor: string => result<'value, string>=?,
  ~destructor: 'value => result<string, string>=?,
  unit,
) => t<'value>

let bool: unit => t<bool>
let coercedBool: (
  ~constructor: bool => result<'value, string>=?,
  ~destructor: 'value => result<bool, string>=?,
  unit,
) => t<'value>

let int: unit => t<int>
let coercedInt: (
  ~constructor: int => result<'value, string>=?,
  ~destructor: 'value => result<int, string>=?,
  unit,
) => t<'value>

let float: unit => t<float>
let coercedFloat: (
  ~constructor: float => result<'value, string>=?,
  ~destructor: 'value => result<float, string>=?,
  unit,
) => t<'value>

let array: t<'value> => t<array<'value>>
let dict: t<'value> => t<Js.Dict.t<'value>>
let option: t<'value> => t<option<'value>>
let deprecated: (~message: string=?, t<'value>) => t<option<'value>>
let default: (t<option<'value>>, 'value) => t<'value>

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

let custom: (
  ~constructor: Js.Json.t => result<'value, string>=?,
  ~destructor: 'value => result<Js.Json.t, string>=?,
  unit,
) => t<'value>

let constructWith: (Js.Json.t, t<'value>) => result<'value, string>
let destructWith: ('value, t<'value>) => result<Js.Json.t, string>

module Record: {
  let factory: (
    ~fields: 'fields,
    ~constructor: 'fieldValues => result<'value, string>=?,
    ~destructor: 'value => result<'fieldValues, string>=?,
    unit,
  ) => t<'value>
}

let classify: t<'value> => kind

module MakeMetadata: (
  Details: {
    type content
    let namespace: string
  },
) =>
{
  let extract: t<'value> => option<Details.content>

  let mixin: (t<'value>, Details.content) => t<'value>
}
