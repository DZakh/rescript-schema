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

let transform = (struct, ~parser as maybeParser=?, ~serializer as maybeSerializer=?) => {
  struct->S.transform(s => {
    {
      parser: ?switch maybeParser {
      | Some(parser) => Some(v => parser(v, s))
      | None => None
      },
      serializer: ?switch maybeSerializer {
      | Some(serializer) => Some(v => serializer(v, s))
      | None => None
      },
    }
  })
}

let refine = (struct, refiner) => {
  struct->S.refine(s => {
    v => refiner(v, s)
  })
}

let noop = a => a
let asyncParserRefine = (struct, refine) => {
  struct->S.transform(s => {
    {
      asyncParser: v => () => refine(v, s)->Stdlib.Promise.thenResolve(() => v),
      serializer: noop,
    }
  })
}

let optional = (struct, maybeOr) => {
  let struct = S.option(struct)
  switch maybeOr {
  | Some(or) if Js.typeof(or) === "function" => struct->S.Option.getOrWith(or->Obj.magic)->Obj.magic
  | Some(or) => struct->S.Option.getOr(or->Obj.magic)->Obj.magic
  | None => struct
  }
}

let tuple = structs => {
  S.tuple(s => {
    structs->Js.Array2.mapi((struct, idx) => {
      s.item(idx, struct)
    })
  })
}

let custom = (~name, ~parser as maybeParser=?, ~serializer as maybeSerializer=?, ()) => {
  S.custom(name, s => {
    {
      parser: ?switch maybeParser {
      | Some(parser) => Some(v => parser(v, s))
      | None => None
      },
      serializer: ?switch maybeSerializer {
      | Some(serializer) => Some(v => serializer(v, s))
      | None => None
      },
    }
  })
}

module Object = {
  type rec t = {strict: unit => t, strip: unit => t}

  let objectStructOperations = %raw("{}")

  @inline
  let toJsStruct = struct => {
    struct->Stdlib.Object.extendWith(objectStructOperations)->(Obj.magic: S.t<'value> => t)
  }

  let strict = () => {
    let struct = %raw("this")
    struct->S.Object.strict->toJsStruct
  }

  let strip = () => {
    let struct = %raw("this")
    struct->S.Object.strip->toJsStruct
  }

  let factory = definer => {
    S.object(s => {
      let definition = Js.Dict.empty()
      let fieldNames = definer->Js.Dict.keys
      for idx in 0 to fieldNames->Js.Array2.length - 1 {
        let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
        let struct = definer->Js.Dict.unsafeGet(fieldName)
        definition->Js.Dict.set(fieldName, s.field(fieldName, struct))
      }
      definition
    })->toJsStruct
  }

  objectStructOperations->Stdlib.Object.extendWith({
    strict,
    strip,
  })
}

let parse = (struct, data) => {
  try {
    data->S.parseAnyOrRaiseWith(struct)->Result.fromOk
  } catch {
  | S.Raised(error) => error->Error.make->Result.fromError
  }
}

let parseOrThrow = (struct, data) => {
  try {
    data->S.parseAnyOrRaiseWith(struct)
  } catch {
  | S.Raised(error) => error->Error.make->raise
  }
}

let parseAsync = (struct, data) => {
  data
  ->S.parseAnyAsyncWith(struct)
  ->Stdlib.Promise.thenResolve(result => {
    switch result {
    | Ok(value) => value->Result.fromOk
    | Error(error) => error->Error.make->Result.fromError
    }
  })
}

let serialize = (struct, value) => {
  try {
    value->S.serializeToUnknownOrRaiseWith(struct)->Obj.magic->Result.fromOk
  } catch {
  | S.Raised(error) => error->Error.make->Result.fromError
  }
}

let serializeOrThrow = (struct, value) => {
  try {
    value->S.serializeToUnknownOrRaiseWith(struct)->Obj.magic
  } catch {
  | S.Raised(error) => error->Error.make->raise
  }
}
