@@uncurried

module Obj = {
  external magic: 'a => 'b = "%identity"
}

module Stdlib = {
  module Promise = {
    type t<+'a> = promise<'a>

    @send
    external thenResolve: (t<'a>, 'a => 'b) => t<'b> = "then"
  }

  module Object = {
    @val
    external extendWith: ('target, 'extend) => 'target = "Object.assign"
  }
}

module Error = {
  type t = exn

  %%raw(`
    export class RescriptStructError extends Error {
      constructor(message) {
        super(message);
        this.name = "RescriptStructError";
      }
    }
  `)

  @new
  external _make: string => t = "RescriptStructError"

  @inline
  let make = error => {
    error->S.Error.toString->_make
  }
}

module Result = {
  type t<'value>

  let fromOk = (value: 'value): t<'value> =>
    {
      "success": true,
      "value": value,
    }->Obj.magic

  let fromError = (error: Error.t): t<'value> =>
    {
      "success": false,
      "error": error,
    }->Obj.magic
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
  refine: ('value => unit) => struct<'value>,
  asyncParserRefine: ('value => promise<unit>) => struct<'value>,
  optional: unit => struct<option<'value>>,
  nullable: unit => struct<option<'value>>,
  describe: string => struct<'value>,
  description: unit => option<string>,
  default: (unit => unknown) => struct<unknown>,
}

let structOperations = %raw("{}")

let castToRescriptStruct: struct<'value> => S.t<'value> = Obj.magic
let castMultipleToRescriptStruct: array<struct<'value>> => array<S.t<'value>> = Obj.magic

@inline
let toJsStruct = struct => {
  let castToJsStruct: S.t<'value> => struct<'value> = Obj.magic
  struct->Stdlib.Object.extendWith(structOperations)->castToJsStruct
}

let fail = reason => S.fail(reason)

let parse = data => {
  let struct = %raw("this")
  try {
    data->S.parseAnyOrRaiseWith(struct)->Result.fromOk
  } catch {
  | S.Raised(error) => error->Error.make->Result.fromError
  }
}

let parseOrThrow = data => {
  let struct = %raw("this")
  try {
    data->S.parseAnyOrRaiseWith(struct)
  } catch {
  | S.Raised(error) => error->Error.make->raise
  }
}

let parseAsync = data => {
  let struct = %raw("this")
  data
  ->S.parseAnyAsyncWith(struct)
  ->Stdlib.Promise.thenResolve(result => {
    switch result {
    | Ok(value) => value->Result.fromOk
    | Error(error) => error->Error.make->Result.fromError
    }
  })
}

let serialize = value => {
  let struct = %raw("this")
  try {
    value->S.serializeToUnknownOrRaiseWith(struct)->Result.fromOk
  } catch {
  | S.Raised(error) => error->Error.make->Result.fromError
  }
}

let serializeOrThrow = value => {
  let struct = %raw("this")
  try {
    value->S.serializeToUnknownOrRaiseWith(struct)
  } catch {
  | S.Raised(error) => error->Error.make->raise
  }
}

let transform = (~parser, ~serializer) => {
  let struct = %raw("this")
  struct->S.transform(~parser, ~serializer, ())->toJsStruct
}

let refine = refiner => {
  let struct = %raw("this")
  struct->S.refine(refiner)->toJsStruct
}

let asyncParserRefine = refiner => {
  let struct = %raw("this")
  struct->S.asyncParserRefine(refiner)->toJsStruct
}

let describe = description => {
  let struct = %raw("this")
  struct->castToRescriptStruct->S.describe(description)->toJsStruct
}
let description = () => {
  let struct = %raw("this")
  struct->castToRescriptStruct->S.description
}

let default = def => {
  let struct = %raw("this")
  struct->castToRescriptStruct->S.default(def)->toJsStruct
}

let optional = struct => S.option(struct->castToRescriptStruct)->toJsStruct
let nullable = struct => S.null(struct->castToRescriptStruct)->toJsStruct
let array = struct => S.array(struct->castToRescriptStruct)->toJsStruct
let record = struct => S.dict(struct->castToRescriptStruct)->toJsStruct
let jsonString = struct => S.jsonString(struct->castToRescriptStruct)->toJsStruct
let union = structs => S.union(structs->castMultipleToRescriptStruct)->toJsStruct
let tuple = structs => {
  let structs = structs->(Obj.magic: array<struct<'value>> => array<S.t<unknown>>)
  S.Tuple.factory(structs)->toJsStruct
}

let literal = (value: 'value): struct<'value> => {
  if value->(Obj.magic: 'value => float)->Js.Float.isNaN {
    Js.Exn.raiseError(`[rescript-struct] Failed to create a NaN literal struct. Use S.nan instead.`)
  } else {
    S.literal(value)->toJsStruct
  }
}

let custom = (~name, ~parser, ~serializer) => {
  S.custom(~name, ~parser, ~serializer, ())->toJsStruct
}

structOperations->Stdlib.Object.extendWith({
  parse,
  parseOrThrow,
  parseAsync,
  serialize,
  serializeOrThrow,
  transform,
  refine,
  asyncParserRefine,
  optional: () => {
    %raw("this")->optional
  },
  nullable: () => {
    %raw("this")->nullable
  },
  describe,
  description,
  default,
})

let string = S.string->toJsStruct
let boolean = S.bool->toJsStruct
let integer = S.int->toJsStruct
let number = S.float->toJsStruct
let never = S.never->toJsStruct
let unknown = S.unknown->toJsStruct
let json = S.json->toJsStruct
let nan = S.literal(Js.Float._NaN)->S.variant(_ => ())->toJsStruct

module Object = {
  type rec t = {strict: unit => t, strip: unit => t}

  let objectStructOperations = %raw("{}")

  @inline
  let toJsStruct = struct => {
    struct->Stdlib.Object.extendWith(objectStructOperations)->(Obj.magic: S.t<'value> => t)
  }

  let strict = () => {
    let struct = %raw("this")
    struct->castToRescriptStruct->S.Object.strict->toJsStruct
  }

  let strip = () => {
    let struct = %raw("this")
    struct->castToRescriptStruct->S.Object.strip->toJsStruct
  }

  let factory = definer => {
    S.object(s => {
      let definition = Js.Dict.empty()
      let fieldNames = definer->Js.Dict.keys
      for idx in 0 to fieldNames->Js.Array2.length - 1 {
        let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
        let struct = definer->Js.Dict.unsafeGet(fieldName)->castToRescriptStruct
        definition->Js.Dict.set(fieldName, s.field(fieldName, struct))
      }
      definition
    })->toJsStruct
  }

  objectStructOperations->Stdlib.Object.extendWith(structOperations)
  objectStructOperations->Stdlib.Object.extendWith({
    strict,
    strip,
  })
}
