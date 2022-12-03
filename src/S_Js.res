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

let structOperations = %raw("{}")

let fromJsStruct: struct<'value> => S.t<'value> = Obj.magic

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
    data->S.parseOrRaiseWith(struct)
  } catch {
  | S.Raised(error) => error->S.Error.toString->Js.Exn.raiseError
  }
}

let parseAsync = data => {
  let struct = %raw("this")
  data
  ->S.parseAsyncWith(struct)
  ->Stdlib.Promise.thenResolve(result => {
    switch result {
    | Ok(value) => value
    | Error(error) => error->S.Error.toString->Js.Exn.raiseError
    }
  })
}

let serialize = value => {
  let struct = %raw("this")
  try {
    value->S.serializeOrRaiseWith(struct)
  } catch {
  | S.Raised(error) => error->S.Error.toString->Js.Exn.raiseError
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

let string = S.string->toJsStructFactory
let boolean = S.bool->toJsStructFactory
let integer = S.int->toJsStructFactory
let number = S.float->toJsStructFactory
let never = S.never->toJsStructFactory
let unknown = S.unknown->toJsStructFactory

let optional = struct => S.option(struct->fromJsStruct)->toJsStruct
let nullable = struct => S.null(struct->fromJsStruct)->toJsStruct
let array = struct => S.array(struct->fromJsStruct)->toJsStruct
let record = struct => S.dict(struct->fromJsStruct)->toJsStruct
let json = struct => S.json(struct->fromJsStruct)->toJsStruct

let custom = (~name, ~parser, ~serializer) => {
  S.custom(~name, ~parser, ~serializer, ())->toJsStruct
}

structOperations->Stdlib.Object.extendWith({
  parse,
  parseAsync,
  serialize,
  transform,
  refine,
  asyncRefine,
  optional: () => {
    %raw("this")->optional
  },
  nullable: () => {
    %raw("this")->nullable
  },
})

module Object = {
  type rec t = {strict: unit => t, strip: unit => t}

  let objectStructOperations = %raw("{}")

  @inline
  let toJsStruct = struct => {
    let castToJsStruct: S.t<'value> => t = Obj.magic
    struct->Stdlib.Object.extendWith(objectStructOperations)->castToJsStruct
  }

  let strict = () => {
    let struct = %raw("this")
    struct->fromJsStruct->S.Object.strict->toJsStruct
  }

  let strip = () => {
    let struct = %raw("this")
    struct->fromJsStruct->S.Object.strip->toJsStruct
  }

  let factory = definer => {
    S.object(o => {
      let definition = Js.Dict.empty()
      let fieldNames = definer->Js.Dict.keys
      for idx in 0 to fieldNames->Js.Array2.length - 1 {
        let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
        let struct = definer->Js.Dict.unsafeGet(fieldName)->fromJsStruct
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
