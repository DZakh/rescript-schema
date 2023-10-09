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
}

type jsResult<'value>

let toJsResult = (result: result<'value, S_Core.error>): jsResult<'value> => {
  switch result {
  | Ok(value) => {"success": true, "value": value}->Obj.magic
  | Error(error) => {"success": false, "error": error}->Obj.magic
  }
}

let transform = (struct, ~parser as maybeParser=?, ~serializer as maybeSerializer=?) => {
  struct->S_Core.transform(s => {
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
  struct->S_Core.refine(s => {
    v => refiner(v, s)
  })
}

let noop = a => a
let asyncParserRefine = (struct, refine) => {
  struct->S_Core.transform(s => {
    {
      asyncParser: v => () => refine(v, s)->Stdlib.Promise.thenResolve(() => v),
      serializer: noop,
    }
  })
}

let optional = (struct, maybeOr) => {
  let struct = S_Core.option(struct)
  switch maybeOr {
  | Some(or) if Js.typeof(or) === "function" =>
    struct->S_Core.Option.getOrWith(or->Obj.magic)->Obj.magic
  | Some(or) => struct->S_Core.Option.getOr(or->Obj.magic)->Obj.magic
  | None => struct
  }
}

let tuple = definer => {
  if Js.typeof(definer) === "function" {
    let definer = definer->(Obj.magic: unknown => S_Core.Tuple.ctx => 'a)
    S_Core.tuple(definer)
  } else {
    let structs = definer->(Obj.magic: unknown => array<S_Core.t<unknown>>)
    S_Core.tuple(s => {
      structs->Js.Array2.mapi((struct, idx) => {
        s.item(idx, struct)
      })
    })
  }
}

let custom = (~name, ~parser as maybeParser=?, ~serializer as maybeSerializer=?, ()) => {
  S_Core.custom(name, s => {
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

let object = definer => {
  if Js.typeof(definer) === "function" {
    let definer = definer->(Obj.magic: unknown => S_Core.Object.ctx => 'a)
    S_Core.object(definer)
  } else {
    let definer = definer->(Obj.magic: unknown => Js.Dict.t<S_Core.t<unknown>>)
    S_Core.object(s => {
      let definition = Js.Dict.empty()
      let fieldNames = definer->Js.Dict.keys
      for idx in 0 to fieldNames->Js.Array2.length - 1 {
        let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
        let struct = definer->Js.Dict.unsafeGet(fieldName)
        definition->Js.Dict.set(fieldName, s.field(fieldName, struct))
      }
      definition
    })
  }
}

let parse = (struct, data) => {
  data->S_Core.parseAnyWith(struct)->toJsResult
}

let parseOrThrow = (struct, data) => {
  data->S_Core.parseAnyOrRaiseWith(struct)
}

let parseAsync = (struct, data) => {
  data->S_Core.parseAnyAsyncWith(struct)->Stdlib.Promise.thenResolve(toJsResult)
}

let serialize = (struct, value) => {
  value->S_Core.serializeToUnknownWith(struct)->Obj.magic->toJsResult
}

let serializeOrThrow = (struct, value) => {
  value->S_Core.serializeToUnknownOrRaiseWith(struct)
}
