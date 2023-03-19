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

  module Fn = {
    type fn<'arg, 'return> = 'arg => 'return

    @send
    external apply: (fn<'arg, 'return>, @as(json`null`) _, array<'arg>) => 'return = "apply"
  }
}

module Error = {
  type t = exn

  %%raw(`
    class RescriptStructError extends Error {
      constructor(message) {
        super(message);
        this.name = "RescriptStructError";
      }
    }
    exports.RescriptStructError = RescriptStructError 
  `)

  @new
  external _make: string => t = "RescriptStructError"

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
  refine: (~parser: 'value => unit, ~serializer: 'value => unit) => struct<'value>,
  asyncRefine: (~parser: 'value => promise<unit>) => struct<'value>,
  optional: unit => struct<option<'value>>,
  nullable: unit => struct<option<'value>>,
  describe: string => struct<'value>,
  description: unit => option<string>,
}

let structOperations = %raw("{}")

let castToRescriptStruct: struct<'value> => S.t<'value> = Obj.magic
let castMultipleToRescriptStruct: array<struct<'value>> => array<S.t<'value>> = Obj.magic

@inline
let toJsStruct = struct => {
  let castToJsStruct: S.t<'value> => struct<'value> = Obj.magic
  struct->Stdlib.Object.extendWith(structOperations)->castToJsStruct
}

@inline
let toJsStructFactory = factory => {
  () => factory()->toJsStruct
}

let parse = data => {
  let struct = %raw("this")
  try {
    data->S.parseOrRaiseWith(struct)->Result.fromOk
  } catch {
  | S.Raised(error) => error->Error.make->Result.fromError
  }
}

let parseOrThrow = data => {
  let struct = %raw("this")
  try {
    data->S.parseOrRaiseWith(struct)
  } catch {
  | S.Raised(error) => error->Error.make->raise
  }
}

let parseAsync = data => {
  let struct = %raw("this")
  data
  ->S.parseAsyncWith(struct)
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
    value->S.serializeOrRaiseWith(struct)->Result.fromOk
  } catch {
  | S.Raised(error) => error->Error.make->Result.fromError
  }
}

let serializeOrThrow = value => {
  let struct = %raw("this")
  try {
    value->S.serializeOrRaiseWith(struct)
  } catch {
  | S.Raised(error) => error->Error.make->raise
  }
}

let transform = (~parser, ~serializer) => {
  let struct = %raw("this")
  struct->S.transform(~parser, ~serializer, ())->toJsStruct
}

let refine = (~parser, ~serializer) => {
  let struct = %raw("this")
  struct->S.refine(~parser, ~serializer, ())->toJsStruct
}

let asyncRefine = (~parser) => {
  let struct = %raw("this")
  struct->S.asyncRefine(~parser, ())->toJsStruct
}

let describe = description => {
  let struct = %raw("this")
  struct->castToRescriptStruct->S.describe(description)->toJsStruct
}
let description = () => {
  let struct = %raw("this")
  struct->castToRescriptStruct->S.description
}

let string = S.string->toJsStructFactory
let boolean = S.bool->toJsStructFactory
let integer = S.int->toJsStructFactory
let number = S.float->toJsStructFactory
let never = S.never->toJsStructFactory
let unknown = S.unknown->toJsStructFactory

let optional = struct => S.option(struct->castToRescriptStruct)->toJsStruct
let nullable = struct => S.null(struct->castToRescriptStruct)->toJsStruct
let array = struct => S.array(struct->castToRescriptStruct)->toJsStruct
let record = struct => S.dict(struct->castToRescriptStruct)->toJsStruct
let json = struct => S.json(struct->castToRescriptStruct)->toJsStruct
let union = structs => S.union(structs->castMultipleToRescriptStruct)->toJsStruct
let defaulted = (struct, value) => S.defaulted(struct->castToRescriptStruct, value)->toJsStruct
let tuple = structs => {
  let structs = structs->castMultipleToRescriptStruct
  S.Tuple.factory->Stdlib.Fn.apply(structs)->toJsStruct
}

let literal = (value: 'value): struct<'value> => {
  let taggedLiteral: S.taggedLiteral = {
    if Js.typeof(value) === "string" {
      String(value->Obj.magic)
    } else if Js.typeof(value) === "boolean" {
      Bool(value->Obj.magic)
    } else if Js.typeof(value) === "number" {
      let value = value->Obj.magic
      if value->Js.Float.isNaN {
        Js.Exn.raiseError(`[rescript-struct] Failed to create a NaN literal struct. Use S.nan instead.`)
      } else {
        Float(value)
      }
    } else if value === %raw("null") {
      EmptyNull
    } else if value === %raw("undefined") {
      EmptyOption
    } else {
      Js.Exn.raiseError(`[rescript-struct] The value provided to literal struct factory is not supported.`)
    }
  }
  S.literal(taggedLiteral->(Obj.magic: S.taggedLiteral => S.literal<'value>))->toJsStruct
}

let nan = () => S.literal(NaN)->toJsStruct

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
  asyncRefine,
  optional: () => {
    %raw("this")->optional
  },
  nullable: () => {
    %raw("this")->nullable
  },
  describe,
  description,
})

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
    S.object(o => {
      let definition = Js.Dict.empty()
      let fieldNames = definer->Js.Dict.keys
      for idx in 0 to fieldNames->Js.Array2.length - 1 {
        let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
        let struct = definer->Js.Dict.unsafeGet(fieldName)->castToRescriptStruct
        definition->Js.Dict.set(fieldName, o->S.field(fieldName, struct))
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
