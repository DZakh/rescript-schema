%%raw(`class RestructError extends Error {}`)
let raiseRestructError = %raw(`function(message){
  throw new RestructError(message);
}`)

let _mapTupleToUnsafeArray = %raw(`function(tuple){
  var isSingleField = typeof tuple[0] === "string";
  return isSingleField ? [tuple] : tuple;
}`)

module ResultX = {
  let mapError = (result, fn) =>
    switch result {
    | Ok(_) as ok => ok
    | Error(error) => Error(fn(error))
    }

  module Array = {
    let mapi = (array: array<'a>, cb: ('a, int) => result<'b, 'e>): result<array<'b>, 'e> => {
      let newArray = []
      let maybeErrorRef = ref(None)
      array
      ->Js.Array2.findi((item, idx) => {
        switch cb(item, idx) {
        | Ok(value) => {
            newArray->Js.Array2.push(value)->ignore
            false
          }
        | Error(error) => {
            maybeErrorRef.contents = Some(error)
            true
          }
        }
      })
      ->ignore
      switch maybeErrorRef.contents {
      | Some(error) => Error(error)
      | None => Ok(newArray)
      }
    }
  }

  module Dict = {
    let map = (dict: Js.Dict.t<'a>, cb: ('a, string) => result<'b, 'e>): result<
      Js.Dict.t<'b>,
      'e,
    > => {
      let newDict = Js.Dict.empty()
      let maybeErrorRef = ref(None)
      dict
      ->Js.Dict.keys
      ->Js.Array2.find(key => {
        let item = dict->Js.Dict.unsafeGet(key)
        switch cb(item, key) {
        | Ok(value) => {
            newDict->Js.Dict.set(key, value)->ignore
            false
          }
        | Error(error) => {
            maybeErrorRef.contents = Some(error)
            true
          }
        }
      })
      ->ignore
      switch maybeErrorRef.contents {
      | Some(error) => Error(error)
      | None => Ok(newDict)
      }
    }
  }
}

module Error = {
  type locationComponent = Field(string) | Index(int)

  type location = array<locationComponent>

  type rec t = {kind: kind, mutable location: location}
  and kind =
    | MissingConstructor
    | MissingDestructor
    | ConstructingFailed(string)
    | DestructingFailed(string)

  module MissingConstructor = {
    let make = () => {
      {kind: MissingConstructor, location: []}
    }
  }

  module MissingDestructor = {
    let make = () => {
      {kind: MissingDestructor, location: []}
    }
  }

  module ConstructingFailed = {
    let make = reason => {
      {kind: ConstructingFailed(reason), location: []}
    }
  }

  module DestructingFailed = {
    let make = reason => {
      {kind: DestructingFailed(reason), location: []}
    }
  }

  let formatLocation = location =>
    "." ++
    location
    ->Js.Array2.map(s =>
      switch s {
      | Field(field) => `"` ++ field ++ `"`
      | Index(index) => `[` ++ index->Js.Int.toString ++ `]`
      }
    )
    ->Js.Array2.joinWith(".")

  let prependLocation = (error, location) => {
    error.location = [location]->Js.Array2.concat(error.location)
    error
  }

  let toString = error => {
    let withLocationInfo = error.location->Js.Array2.length !== 0
    switch (error.kind, withLocationInfo) {
    | (MissingConstructor, true) =>
      `Struct missing constructor at ${error.location->formatLocation}`
    | (MissingConstructor, false) => `Struct missing constructor at root`
    | (MissingDestructor, true) => `Struct missing destructor at ${error.location->formatLocation}`
    | (MissingDestructor, false) => `Struct missing destructor at root`
    | (ConstructingFailed(reason), true) =>
      `Struct construction failed at ${error.location->formatLocation}. Reason: ${reason}`
    | (ConstructingFailed(reason), false) => `Struct construction failed at root. Reason: ${reason}`
    | (DestructingFailed(reason), true) =>
      `Struct destruction failed at ${error.location->formatLocation}. Reason: ${reason}`
    | (DestructingFailed(reason), false) => `Struct destruction failed at root. Reason: ${reason}`
    }
  }
}

type unknown = Js.Json.t

external unsafeToUnknown: 'unknown => unknown = "%identity"
external unsafeFromUnknown: unknown => 'value = "%identity"
external unsafeUnknownToArray: unknown => array<unknown> = "%identity"
external unsafeArrayToUnknown: array<unknown> => unknown = "%identity"
external unsafeUnknownToDict: unknown => Js.Dict.t<unknown> = "%identity"
external unsafeDictToUnknown: Js.Dict.t<unknown> => unknown = "%identity"
external unsafeUnknownToOption: unknown => option<unknown> = "%identity"
external unsafeOptionToUnknown: option<unknown> => unknown = "%identity"

type rec t<'value> = {
  kind: kind,
  constructor: option<unknown => result<'value, Error.t>>,
  destructor: option<'value => result<unknown, Error.t>>,
  metadata: Js.Dict.t<unknown>,
}
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

let make = (~kind, ~constructor=?, ~destructor=?, ()): t<'value> => {
  {kind: kind, constructor: constructor, destructor: destructor, metadata: Js.Dict.empty()}
}

let _construct = (struct, unknown) => {
  switch struct.constructor {
  | Some(constructor) => unknown->constructor
  | None => Error.MissingConstructor.make()->Error
  }
}
let constructWith = (unknown, struct) => {
  _construct(struct, unknown)->ResultX.mapError(Error.toString)
}

let _destruct = (struct, unknown) => {
  switch struct.destructor {
  | Some(destructor) => unknown->destructor
  | None => Error.MissingDestructor.make()->Error
  }
}
let destructWith = (unknown, struct) => {
  _destruct(struct, unknown)->ResultX.mapError(Error.toString)
}

module Record = {
  exception HackyAbort(Error.t)

  let _constructor = %raw(`function(fields, recordConstructor, construct) {
    var isSingleField = typeof fields[0] === "string";
    if (isSingleField) {
      return function(unknown) {
        var fieldName = fields[0],
          fieldStruct = fields[1],
          fieldValue = construct(fieldStruct, fieldName, unknown[fieldName]);
        return recordConstructor(fieldValue);
      }
    }
    return function(unknown) {
      var fieldValues = [];
      fields.forEach(function (field) {
        var fieldName = field[0],
          fieldStruct = field[1],
          fieldValue = construct(fieldStruct, fieldName, unknown[fieldName]);
        fieldValues.push(fieldValue);
      })
      return recordConstructor(fieldValues);
    }
  }`)

  let _destructor = %raw(`function(fields, recordDestructor, destruct) {
    var isSingleField = typeof fields[0] === "string";
    if (isSingleField) {
      return function(value) {
        var fieldName = fields[0],
          fieldStruct = fields[1],
          fieldValue = recordDestructor(value),
          unknownFieldValue = destruct(fieldStruct, fieldName, fieldValue);
        return {
          [fieldName]: unknownFieldValue,
        };
      }
    }
    return function(value) {
      var unknown = {},
        fieldValuesTuple = recordDestructor(value);
      fields.forEach(function (field, idx) {
        var fieldName = field[0],
          fieldStruct = field[1],
          fieldValue = fieldValuesTuple[idx],
          unknownFieldValue = destruct(fieldStruct, fieldName, fieldValue);
        unknown[fieldName] = unknownFieldValue;
      })
      return unknown;
    }
  }`)

  let factory = (
    ~fields: 'fields,
    ~constructor as maybeRecordConstructor: option<'fieldValues => result<'value, string>>=?,
    ~destructor as maybeRecordDestructor: option<'value => result<'fieldValues, string>>=?,
    (),
  ): t<'value> => {
    if maybeRecordConstructor->Belt.Option.isNone && maybeRecordDestructor->Belt.Option.isNone {
      raiseRestructError("For a Record struct either a constructor, or a destructor is required")
    }

    make(
      ~kind=Record(_mapTupleToUnsafeArray(fields)),
      ~constructor=?maybeRecordConstructor->Belt.Option.map(recordConstructor => {
        unknown => {
          try {
            _constructor(~fields, ~recordConstructor, ~construct=(
              struct,
              fieldName,
              unknownFieldValue,
            ) => {
              switch _construct(struct, unknownFieldValue) {
              | Ok(value) => value
              | Error(error) =>
                raise(HackyAbort(error->Error.prependLocation(Error.Field(fieldName))))
              }
            })(unknown)->ResultX.mapError(Error.ConstructingFailed.make)
          } catch {
          | HackyAbort(error) => Error(error)
          }
        }
      }),
      ~destructor=?maybeRecordDestructor->Belt.Option.map(recordDestructor => {
        value => {
          try {
            _destructor(
              ~fields,
              ~recordDestructor=value => {
                switch recordDestructor(value) {
                | Ok(fieldValuesTuple) => fieldValuesTuple
                | Error(reason) => raise(HackyAbort(Error.DestructingFailed.make(reason)))
                }
              },
              ~destruct=(struct, fieldName, fieldValue) => {
                switch _destruct(struct, fieldValue) {
                | Ok(unknown) => unknown
                | Error(error) =>
                  raise(HackyAbort(error->Error.prependLocation(Error.Field(fieldName))))
                }
              },
            )(value)->Ok
          } catch {
          | HackyAbort(error) => Error(error)
          }
        }
      }),
      (),
    )
  }
}

module Primitive = {
  module Factory = {
    let make = (~kind) => {
      () =>
        make(
          ~kind,
          ~constructor=unknown => {
            unknown->unsafeFromUnknown->Ok
          },
          ~destructor=value => {
            value->unsafeToUnknown->Ok
          },
          (),
        )
    }
  }
}

module Optional = {
  module Factory = {
    let make = (~kind, ~struct) => {
      make(
        ~kind,
        ~constructor=unknown => {
          switch unknown->unsafeUnknownToOption {
          | Some(unknown') => _construct(struct, unknown')->Belt.Result.map(known => Some(known))
          | None => Ok(None)
          }
        },
        ~destructor=optionalValue => {
          switch optionalValue {
          | Some(value) => _destruct(struct, value)
          | None => Ok(None->unsafeOptionToUnknown)
          }
        },
        (),
      )
    }
  }
}

let string = Primitive.Factory.make(~kind=String)

let bool = Primitive.Factory.make(~kind=Bool)

let int = Primitive.Factory.make(~kind=Int)

let float = Primitive.Factory.make(~kind=Float)

let array = struct =>
  make(
    ~kind=Array(struct),
    ~constructor=unknown => {
      unknown
      ->unsafeUnknownToArray
      ->ResultX.Array.mapi((unknownItem, idx) => {
        struct
        ->_construct(unknownItem)
        ->ResultX.mapError(Error.prependLocation(_, Error.Index(idx)))
      })
    },
    ~destructor=array => {
      array
      ->ResultX.Array.mapi((item, idx) => {
        struct->_destruct(item)->ResultX.mapError(Error.prependLocation(_, Error.Index(idx)))
      })
      ->Belt.Result.map(unsafeArrayToUnknown)
    },
    (),
  )

let dict = struct =>
  make(
    ~kind=Dict(struct),
    ~constructor=unknown => {
      // TODO: Think about validating that keys are actually strings
      let unknownDict = unknown->unsafeUnknownToDict
      unknownDict->ResultX.Dict.map((unknownItem, key) => {
        struct
        ->_construct(unknownItem)
        ->ResultX.mapError(Error.prependLocation(_, Error.Field(key)))
      })
    },
    ~destructor=dict => {
      dict
      ->ResultX.Dict.map((item, key) => {
        struct->_destruct(item)->ResultX.mapError(Error.prependLocation(_, Error.Field(key)))
      })
      ->Belt.Result.map(unsafeDictToUnknown)
    },
    (),
  )

let option = struct => {
  Optional.Factory.make(~kind=Option(struct), ~struct)
}
let deprecated = (~message as maybeMessage=?, struct) => {
  Optional.Factory.make(~kind=Deprecated({struct: struct, maybeMessage: maybeMessage}), ~struct)
}

let default = (struct, value) => {
  make(
    ~kind=Default({struct: struct, value: value}),
    ~constructor=unknown => {
      _construct(struct, unknown)->Belt.Result.map(Belt.Option.getWithDefault(_, value))
    },
    ~destructor=value => {
      _destruct(struct, Some(value))
    },
    (),
  )
}

let record1 = Record.factory
let record2 = Record.factory
let record3 = Record.factory
let record4 = Record.factory
let record5 = Record.factory
let record6 = Record.factory
let record7 = Record.factory
let record8 = Record.factory
let record9 = Record.factory
let record10 = Record.factory

let coerce = (
  struct,
  ~constructor as maybeCoercionConstructor=?,
  ~destructor as maybeCoercionDestructor=?,
  (),
) => {
  if maybeCoercionConstructor->Belt.Option.isNone && maybeCoercionDestructor->Belt.Option.isNone {
    raiseRestructError("For coercion either a constructor, or a destructor is required")
  }
  {
    kind: struct.kind,
    metadata: struct.metadata,
    constructor: switch (struct.constructor, maybeCoercionConstructor) {
    | (Some(structConstructor), Some(coercionConstructor)) =>
      {
        unknown => {
          let structConstructorResult = structConstructor(unknown)
          structConstructorResult->Belt.Result.flatMap(originalValue => {
            coercionConstructor(originalValue)->ResultX.mapError(Error.ConstructingFailed.make)
          })
        }
      }->Some
    | (_, _) => None
    },
    destructor: switch (struct.destructor, maybeCoercionDestructor) {
    | (Some(structDestructor), Some(coercionDestructor)) =>
      {
        value => {
          switch coercionDestructor(value) {
          | Ok(primitive) => structDestructor(primitive)
          | Error(reason) => Error.DestructingFailed.make(reason)->Error
          }
        }
      }->Some
    | (_, _) => None
    },
  }
}

let custom = (
  ~constructor as maybeCustomConstructor=?,
  ~destructor as maybeCustomDestructor=?,
  (),
) => {
  if maybeCustomConstructor->Belt.Option.isNone && maybeCustomDestructor->Belt.Option.isNone {
    raiseRestructError("For a Custom struct either a constructor, or a destructor is required")
  }

  make(
    ~kind=Custom,
    ~constructor=?maybeCustomConstructor->Belt.Option.map(customConstructor => {
      unknown => {
        customConstructor(unknown)->ResultX.mapError(Error.ConstructingFailed.make)
      }
    }),
    ~destructor=?maybeCustomDestructor->Belt.Option.map(customDestructor => {
      value => {
        customDestructor(value)->ResultX.mapError(Error.DestructingFailed.make)
      }
    }),
    (),
  )
}

let classify = struct => struct.kind

module MakeMetadata = (
  Details: {
    type content
    let namespace: string
  },
) => {
  let extract = (struct): option<Details.content> => {
    struct.metadata->Js.Dict.get(Details.namespace)->Belt.Option.map(unsafeFromUnknown)
  }

  let mixin = (struct, metadata: Details.content) => {
    struct.metadata->Js.Dict.set(Details.namespace, metadata->unsafeToUnknown)
    struct
  }
}
