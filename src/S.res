%%raw(`class RestructError extends Error {}`)
let raiseRestructError = %raw(`function(message){
  throw new RestructError(message);
}`)

let _mapTupleToUnsafeArray = %raw(`function(tuple){
  var isSingleField = typeof tuple[0] === "string";
  return isSingleField ? [tuple] : tuple;
}`)

type unknown

external unsafeAnyToUnknown: 'any => unknown = "%identity"
external unsafeUnknownToAny: unknown => 'any = "%identity"
external unsafeUnknownToArray: unknown => array<unknown> = "%identity"
external unsafeArrayToUnknown: array<unknown> => unknown = "%identity"
external unsafeUnknownToDict: unknown => Js.Dict.t<unknown> = "%identity"
external unsafeDictToUnknown: Js.Dict.t<unknown> => unknown = "%identity"
external unsafeUnknownToNullable: unknown => Js.Nullable.t<unknown> = "%identity"
external unsafeOptionToUnknown: option<unknown> => unknown = "%identity"
external unsafeNullToUnknown: Js.null<unknown> => unknown = "%identity"
external unsafeJsonToUnknown: Js.Json.t => unknown = "%identity"
external unsafeUnknownToJson: unknown => Js.Json.t = "%identity"

type rec t<'value> = {
  tagged_t: tagged_t,
  constructor: option<unknown => result<'value, RescriptStruct_Error.t>>,
  destructor: option<'value => result<unknown, RescriptStruct_Error.t>>,
  metadata: Js.Dict.t<unknown>,
}
and tagged_t =
  | Unknown: tagged_t
  | String: tagged_t
  | Int: tagged_t
  | Float: tagged_t
  | Bool: tagged_t
  | Option(t<'value>): tagged_t
  | Nullable(t<'value>): tagged_t
  | Array(t<'value>): tagged_t
  | Record(array<field<unknown>>): tagged_t
  | Dict(t<'value>): tagged_t
  // TODO: Move to refinements
  | Deprecated({struct: t<'value>, maybeMessage: option<string>}): tagged_t
  | Default({struct: t<option<'value>>, value: 'value}): tagged_t
and field<'value> = (string, t<'value>)

let make = (~tagged_t, ~constructor=?, ~destructor=?, ()): t<'value> => {
  {
    tagged_t: tagged_t,
    constructor: constructor,
    destructor: destructor,
    metadata: Js.Dict.empty(),
  }
}

let _construct = (~struct, ~unknown) => {
  switch struct.constructor {
  | Some(constructor) => unknown->constructor
  | None => RescriptStruct_Error.MissingConstructor.make()->Error
  }
}
let constructWith = (any, struct) => {
  _construct(~struct, ~unknown=any->unsafeAnyToUnknown)->RescriptStruct_ResultX.mapError(
    RescriptStruct_Error.toString,
  )
}

let _destruct = (~struct, ~value) => {
  switch struct.destructor {
  | Some(destructor) => value->destructor
  | None => RescriptStruct_Error.MissingDestructor.make()->Error
  }
}
let destructWith = (value, struct) => {
  _destruct(~struct, ~value)->RescriptStruct_ResultX.mapError(RescriptStruct_Error.toString)
}

module Record = {
  exception HackyAbort(RescriptStruct_Error.t)

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
      ~tagged_t=Record(_mapTupleToUnsafeArray(fields)),
      ~constructor=?maybeRecordConstructor->Belt.Option.map(recordConstructor => {
        unknown => {
          try {
            _constructor(~fields, ~recordConstructor, ~construct=(
              struct,
              fieldName,
              unknownFieldValue,
            ) => {
              switch _construct(~struct, ~unknown=unknownFieldValue) {
              | Ok(value) => value
              | Error(error) =>
                raise(
                  HackyAbort(
                    error->RescriptStruct_Error.prependLocation(
                      RescriptStruct_Error.Field(fieldName),
                    ),
                  ),
                )
              }
            })(unknown)->RescriptStruct_ResultX.mapError(
              RescriptStruct_Error.ConstructingFailed.make,
            )
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
                | Error(reason) =>
                  raise(HackyAbort(RescriptStruct_Error.DestructingFailed.make(reason)))
                }
              },
              ~destruct=(struct, fieldName, fieldValue) => {
                switch _destruct(~struct, ~value=fieldValue) {
                | Ok(unknown) => unknown
                | Error(error) =>
                  raise(
                    HackyAbort(
                      error->RescriptStruct_Error.prependLocation(
                        RescriptStruct_Error.Field(fieldName),
                      ),
                    ),
                  )
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
    let make = (~tagged_t) => {
      () =>
        make(
          ~tagged_t,
          ~constructor=unknown => {
            unknown->unsafeUnknownToAny->Ok
          },
          ~destructor=value => {
            value->unsafeAnyToUnknown->Ok
          },
          (),
        )
    }
  }
}

module Optional = {
  module Factory = {
    let make = (~tagged_t, ~struct) => {
      make(
        ~tagged_t,
        ~constructor=unknown => {
          switch unknown->unsafeUnknownToNullable->Js.Nullable.toOption {
          | Some(unknown') =>
            _construct(~struct, ~unknown=unknown')->Belt.Result.map(known => Some(known))
          | None => Ok(None)
          }
        },
        ~destructor=optionalValue => {
          switch optionalValue {
          | Some(value) => _destruct(~struct, ~value)
          | None =>
            switch tagged_t {
            | Nullable(_) => Js.Null.empty->unsafeNullToUnknown
            | _ => None->unsafeOptionToUnknown
            }->Ok
          }
        },
        (),
      )
    }
  }
}

let unknown = Primitive.Factory.make(~tagged_t=Unknown)

let string = Primitive.Factory.make(~tagged_t=String)

let bool = Primitive.Factory.make(~tagged_t=Bool)

let int = Primitive.Factory.make(~tagged_t=Int)

let float = Primitive.Factory.make(~tagged_t=Float)

let array = struct =>
  make(
    ~tagged_t=Array(struct),
    ~constructor=unknown => {
      unknown
      ->unsafeUnknownToArray
      ->RescriptStruct_ResultX.Array.mapi((unknownItem, idx) => {
        _construct(~struct, ~unknown=unknownItem)->RescriptStruct_ResultX.mapError(
          RescriptStruct_Error.prependLocation(_, RescriptStruct_Error.Index(idx)),
        )
      })
    },
    ~destructor=array => {
      array
      ->RescriptStruct_ResultX.Array.mapi((item, idx) => {
        _destruct(~struct, ~value=item)->RescriptStruct_ResultX.mapError(
          RescriptStruct_Error.prependLocation(_, RescriptStruct_Error.Index(idx)),
        )
      })
      ->Belt.Result.map(unsafeArrayToUnknown)
    },
    (),
  )

let dict = struct =>
  make(
    ~tagged_t=Dict(struct),
    ~constructor=unknown => {
      let unknownDict = unknown->unsafeUnknownToDict
      unknownDict->RescriptStruct_ResultX.Dict.map((unknownItem, key) => {
        _construct(~struct, ~unknown=unknownItem)->RescriptStruct_ResultX.mapError(
          RescriptStruct_Error.prependLocation(_, RescriptStruct_Error.Field(key)),
        )
      })
    },
    ~destructor=dict => {
      dict
      ->RescriptStruct_ResultX.Dict.map((item, key) => {
        _destruct(~struct, ~value=item)->RescriptStruct_ResultX.mapError(
          RescriptStruct_Error.prependLocation(_, RescriptStruct_Error.Field(key)),
        )
      })
      ->Belt.Result.map(unsafeDictToUnknown)
    },
    (),
  )

let option = struct => {
  Optional.Factory.make(~tagged_t=Option(struct), ~struct)
}
let nullable = struct => {
  Optional.Factory.make(~tagged_t=Nullable(struct), ~struct)
}
let deprecated = (~message as maybeMessage=?, struct) => {
  Optional.Factory.make(~tagged_t=Deprecated({struct: struct, maybeMessage: maybeMessage}), ~struct)
}

let default = (struct, value) => {
  make(
    ~tagged_t=Default({struct: struct, value: value}),
    ~constructor=unknown => {
      _construct(~struct, ~unknown)->Belt.Result.map(Belt.Option.getWithDefault(_, value))
    },
    ~destructor=value => {
      _destruct(~struct, ~value=Some(value))
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
    tagged_t: struct.tagged_t,
    metadata: struct.metadata,
    constructor: switch (struct.constructor, maybeCoercionConstructor) {
    | (Some(structConstructor), Some(coercionConstructor)) =>
      {
        unknown => {
          let structConstructorResult = structConstructor(unknown)
          structConstructorResult->Belt.Result.flatMap(originalValue => {
            coercionConstructor(originalValue)->RescriptStruct_ResultX.mapError(
              RescriptStruct_Error.ConstructingFailed.make,
            )
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
          | Error(reason) => RescriptStruct_Error.DestructingFailed.make(reason)->Error
          }
        }
      }->Some
    | (_, _) => None
    },
  }
}

let classify = struct => struct.tagged_t

module MakeMetadata = (
  Details: {
    type content
    let namespace: string
  },
) => {
  let extract = (struct): option<Details.content> => {
    struct.metadata->Js.Dict.get(Details.namespace)->Belt.Option.map(unsafeUnknownToAny)
  }

  let mixin = (struct, metadata: Details.content) => {
    struct.metadata->Js.Dict.set(Details.namespace, metadata->unsafeAnyToUnknown)
    struct
  }
}

let structTaggedToString = tagged_t => {
  switch tagged_t {
  | Unknown => "Unknown"
  | String => "String"
  | Int => "Int"
  | Float => "Float"
  | Bool => "Bool"
  | Option(_) => "Option"
  | Nullable(_) => "Nullable"
  | Array(_) => "Array"
  | Record(_) => "Record"
  | Dict(_) => "Dict"
  | Deprecated(_) => "Deprecated"
  | Default(_) => "Default"
  }
}

let makeUnexpectedTypeError = (~typesTagged: Js.Types.tagged_t, ~structTagged: tagged_t) => {
  let got = switch typesTagged {
  | JSFalse | JSTrue => "Bool"
  | JSString(_) => "String"
  | JSNull => "Null"
  | JSNumber(_) => "Float"
  | JSObject(_) => "Object"
  | JSFunction(_) => "Function"
  | JSUndefined => "Option"
  | JSSymbol(_) => "Symbol"
  }
  let expected = structTaggedToString(structTagged)
  Error(RescriptStruct_Error.DecodingFailed.UnexpectedType.make(~expected, ~got))
}

let rec validateNode:
  type value unknown. (
    ~unknown: unknown,
    ~struct: t<value>,
  ) => result<unit, RescriptStruct_Error.t> =
  (~unknown, ~struct) => {
    let typesTagged = unknown->Js.Types.classify
    let structTagged = struct->classify

    switch (typesTagged, structTagged) {
    | (JSFalse, Bool)
    | (JSTrue, Bool)
    | (JSString(_), String)
    | (JSNumber(_), Float)
    | (JSUndefined, Option(_))
    | (JSUndefined, Deprecated(_))
    | (JSUndefined, Default(_))
    | (JSNull, Nullable(_))
    | (JSNull, Deprecated(_))
    | (JSNull, Default(_))
    | (_, Unknown) =>
      Ok()
    | (JSNumber(x), Int) if x == x->Js.Math.trunc && x > -2147483648. && x < 2147483648. =>
      if x == x->Js.Math.trunc && x > -2147483648. && x < 2147483648. {
        Ok()
      } else {
        makeUnexpectedTypeError(~typesTagged, ~structTagged)
      }
    | (JSObject(obj_val), Array(itemStruct)) if Js.Array2.isArray(obj_val) =>
      obj_val
      ->unsafeAnyToUnknown
      ->unsafeUnknownToArray
      ->RescriptStruct_ResultX.Array.mapi((unknownItem, idx) => {
        validateNode(~unknown=unknownItem, ~struct=itemStruct)->RescriptStruct_ResultX.mapError(
          RescriptStruct_Error.prependLocation(_, RescriptStruct_Error.Index(idx)),
        )
      })
      ->Belt.Result.map(_ => ())
    | (JSObject(obj_val), Dict(itemStruct)) if !Js.Array2.isArray(obj_val) =>
      obj_val
      ->unsafeAnyToUnknown
      ->unsafeUnknownToDict
      ->RescriptStruct_ResultX.Dict.map((unknownItem, key) => {
        validateNode(~unknown=unknownItem, ~struct=itemStruct)->RescriptStruct_ResultX.mapError(
          RescriptStruct_Error.prependLocation(_, RescriptStruct_Error.Field(key)),
        )
      })
      ->Belt.Result.map(_ => ())
    | (JSObject(obj_val), Record(fieldsArray)) if !Js.Array2.isArray(obj_val) =>
      let unknownDict = obj_val->unsafeAnyToUnknown->unsafeUnknownToDict
      let unknownKeysSet = unknownDict->Js.Dict.keys->RescriptStruct_Set.fromArray

      fieldsArray
      ->RescriptStruct_ResultX.Array.mapi(((fieldName, fieldStruct), _) => {
        unknownKeysSet->RescriptStruct_Set.delete(fieldName)->ignore

        validateNode(
          ~unknown=unknownDict->Js.Dict.get(fieldName),
          ~struct=fieldStruct,
        )->RescriptStruct_ResultX.mapError(
          RescriptStruct_Error.prependLocation(_, RescriptStruct_Error.Field(fieldName)),
        )
      })
      ->Belt.Result.flatMap(_ => {
        if unknownKeysSet->RescriptStruct_Set.size === 0 {
          Ok()
        } else {
          Error(
            RescriptStruct_Error.DecodingFailed.ExtraProperties.make(
              ~properties=unknownKeysSet->RescriptStruct_Set.toArray,
            ),
          )
        }
      })
    | (_, Deprecated({struct: struct'})) => validateNode(~unknown, ~struct=struct')
    | (_, Default({struct: struct'})) => validateNode(~unknown, ~struct=struct')
    | (_, Option(struct')) => validateNode(~unknown, ~struct=struct')
    | (_, Nullable(struct')) => validateNode(~unknown, ~struct=struct')
    | (_, _) => makeUnexpectedTypeError(~typesTagged, ~structTagged)
    }
  }

let decodeWith = (any, struct) => {
  let unknown = any->unsafeAnyToUnknown
  validateNode(~unknown, ~struct)
  ->Belt.Result.flatMap(() => {
    _construct(~struct, ~unknown)
  })
  ->RescriptStruct_ResultX.mapError(RescriptStruct_Error.toString)
}

let decodeJsonWith = (string, struct) => {
  switch Js.Json.parseExn(string) {
  | json => Ok(json)
  | exception Js.Exn.Error(obj) =>
    let maybeMessage = Js.Exn.message(obj)
    Error(
      RescriptStruct_Error.DecodingFailed.make(
        maybeMessage->Belt.Option.getWithDefault("Syntax error"),
      ),
    )
  }
  ->Belt.Result.flatMap(json => {
    let unknown = json->unsafeJsonToUnknown
    validateNode(~unknown, ~struct)->Belt.Result.flatMap(() => {
      _construct(~struct, ~unknown)
    })
  })
  ->RescriptStruct_ResultX.mapError(RescriptStruct_Error.toString)
}

let encodeWith = destructWith

let encodeJsonWith = (value, struct) => {
  switch _destruct(~struct, ~value) {
  | Ok(unknown) => Ok(unknown->unsafeUnknownToJson->Js.Json.stringify)
  | Error(error) => Error(error->RescriptStruct_Error.toString)
  }
}
