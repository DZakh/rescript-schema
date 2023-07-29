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

type rec struct<'input, 'output> = {
  parse: 'a. 'a => Result.t<'output>,
  parseOrThrow: 'a. 'a => 'output,
  parseAsync: 'a. 'a => promise<Result.t<'output>>,
  serialize: 'output => Result.t<'input>,
  serializeOrThrow: 'output => 'input,
  transform: 'transformed. (
    ~parser: ('output, effectCtx<'input, 'transformed>) => 'transformed=?,
    ~serializer: ('transformed, effectCtx<'input, 'transformed>) => 'output=?,
  ) => struct<'input, 'transformed>,
  refine: (('output, effectCtx<'input, 'output>) => unit) => struct<'input, 'output>,
  asyncParserRefine: (('output, effectCtx<'input, 'output>) => promise<unit>) => struct<
    'input,
    'output,
  >,
  optional: unit => struct<option<'input>, option<'output>>,
  nullable: unit => struct<Js.null<'input>, option<'output>>,
  describe: string => struct<'input, 'output>,
  description: unit => option<string>,
  default: (unit => 'output) => struct<option<'input>, 'output>,
}
and effectCtx<'input, 'output> = {
  struct: struct<'input, 'output>,
  fail: 'a. string => 'a,
}

let structOperations = %raw("{}")

let castToRescriptStruct: struct<'input, 'output> => S.t<'output> = Obj.magic
let castMultipleToRescriptStruct: array<struct<'input, 'output>> => array<S.t<'output>> = Obj.magic

@inline
let toJsStruct = struct => {
  let castToJsStruct: S.t<'output> => struct<'input, 'output> = Obj.magic
  struct->Stdlib.Object.extendWith(structOperations)->castToJsStruct
}

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

let transform: (
  ~parser: ('output, effectCtx<'input, 'transformed>) => 'transformed=?,
  ~serializer: ('transformed, effectCtx<'input, 'transformed>) => 'output=?,
) => struct<'input, 'transformed> = (
  ~parser as maybeParser=?,
  ~serializer as maybeSerializer=?,
) => {
  let struct = %raw("this")
  struct
  ->S.transform(s => {
    let effectCtx = {
      struct: s.struct->toJsStruct,
      fail: message => s.fail(message),
    }
    {
      parser: ?switch maybeParser {
      | Some(parser) => Some(v => parser(v, effectCtx))
      | None => None
      },
      serializer: ?switch maybeSerializer {
      | Some(serializer) => Some(v => serializer(v, effectCtx))
      | None => None
      },
    }
  })
  ->toJsStruct
}

let refine = refiner => {
  let struct = %raw("this")
  struct
  ->S.refine(s => {
    let effectCtx = {
      struct: s.struct->toJsStruct,
      fail: message => s.fail(message),
    }
    v => refiner(v, effectCtx)
  })
  ->toJsStruct
}

let asyncParserRefine = refiner => {
  let struct = %raw("this")
  struct
  ->S.asyncParserRefine(s => {
    let effectCtx = {
      struct: s.struct->toJsStruct,
      fail: message => s.fail(message),
    }
    v => refiner(v, effectCtx)
  })
  ->toJsStruct
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
  S.tuple(s => {
    structs->Js.Array2.mapi((struct, idx) => {
      s.item(idx, struct->castToRescriptStruct)
    })
  })->toJsStruct
}

let literal = (literal: 'literal): struct<'literal, 'literal> => {
  if literal->(Obj.magic: 'literal => float)->Js.Float.isNaN {
    Js.Exn.raiseError(`[rescript-struct] Failed to create a NaN literal struct. Use S.nan instead.`)
  } else {
    S.literal(literal)->toJsStruct
  }
}

let custom = (~name, ~parser as maybeParser=?, ~serializer as maybeSerializer=?, ()) => {
  S.custom(name, s => {
    let effectCtx = {
      struct: s.struct->toJsStruct,
      fail: message => s.fail(message),
    }
    {
      parser: ?switch maybeParser {
      | Some(parser) => Some(v => parser(v, effectCtx))
      | None => None
      },
      serializer: ?switch maybeSerializer {
      | Some(serializer) => Some(v => serializer(v, effectCtx))
      | None => None
      },
    }
  })->toJsStruct
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
