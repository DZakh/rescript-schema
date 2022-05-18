type never
type unknown

external unsafeAnyToUnknown: 'any => unknown = "%identity"
external unsafeUnknownToAny: unknown => 'any = "%identity"
external unsafeUnknownToArray: unknown => array<unknown> = "%identity"
external unsafeUnknownToDict: unknown => Js.Dict.t<unknown> = "%identity"
external unsafeJsonToUnknown: Js.Json.t => unknown = "%identity"
external unsafeUnknownToJson: unknown => Js.Json.t = "%identity"

type rec literal<'value> =
  | String(string): literal<string>
  | Int(int): literal<int>
  | Float(float): literal<float>
  | Bool(bool): literal<bool>
  | EmptyNull: literal<option<never>>
  | EmptyOption: literal<option<never>>

module Parser = {
  type t = Transform(unknown => result<unknown, RescriptStruct_Error.t>)

  let transform = (fn: 'input => result<'output, RescriptStruct_Error.t>) => {
    Transform(fn->unsafeAnyToUnknown->unsafeUnknownToAny)
  }
}

type rec t<'value> = {
  tagged_t: tagged_t,
  maybeConstructors: option<array<Parser.t>>,
  maybeDestructors: option<array<Parser.t>>,
  maybeMetadata: option<Js.Dict.t<unknown>>,
}
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
  | Record({fields: array<field<unknown>>, unknownKeys: recordUnknownKeys}): tagged_t
  | Dict(t<'value>): tagged_t
  // TODO: Move to refinements
  | Deprecated({struct: t<'value>, maybeMessage: option<string>}): tagged_t
  | Default({struct: t<option<'value>>, value: 'value}): tagged_t
and field<'value> = (string, t<'value>)
and recordUnknownKeys =
  | Strict
  | Strip

external unsafeAnyToFields: 'any => array<field<unknown>> = "%identity"

module TaggedT = {
  let toString = tagged_t => {
    switch tagged_t {
    | Never => "Never"
    | Unknown => "Unknown"
    | String => "String"
    | Int => "Int"
    | Float => "Float"
    | Bool => "Bool"
    | Literal(literal) =>
      switch literal {
      | String(value) => j`String Literal ("$value")`
      | Int(value) => j`Int Literal ($value)`
      | Float(value) => j`Float Literal ($value)`
      | Bool(value) => j`Bool Literal ($value)`
      | EmptyNull => `EmptyNull Literal (null)`
      | EmptyOption => `EmptyOption Literal (undefined)`
      }
    | Option(_) => "Option"
    | Null(_) => "Null"
    | Array(_) => "Array"
    | Record(_) => "Record"
    | Dict(_) => "Dict"
    | Deprecated(_) => "Deprecated"
    | Default(_) => "Default"
    }
  }
}

let _construct: (
  ~struct: t<'value>,
  ~unknown: unknown,
) => result<'value, RescriptStruct_Error.t> = (~struct, ~unknown) => {
  switch struct.maybeConstructors {
  | Some(constructors) => {
      let idxRef = ref(0)
      let valueRef = ref(unknown)
      let maybeErrorRef = ref(None)

      while idxRef.contents < constructors->Js.Array2.length && maybeErrorRef.contents == None {
        let constructor = constructors->Js.Array2.unsafe_get(idxRef.contents)
        switch constructor {
        | Transform(fn) =>
          switch fn(valueRef.contents) {
          | Ok(newValue) => {
              valueRef.contents = newValue
              idxRef.contents = idxRef.contents + 1
            }
          | Error(_) as error => maybeErrorRef.contents = Some(error)
          }
        }
      }

      switch maybeErrorRef.contents {
      | Some(error) => error
      | None => Ok(valueRef.contents->unsafeUnknownToAny)
      }
    }
  | None => Error(RescriptStruct_Error.MissingConstructor.make())
  }
}

let constructWith = (any, struct) => {
  _construct(~struct, ~unknown=any->unsafeAnyToUnknown)->RescriptStruct_ResultX.mapError(
    RescriptStruct_Error.toString,
  )
}

let _destruct: (~struct: t<'value>, ~value: 'value) => result<unknown, RescriptStruct_Error.t> = (
  ~struct,
  ~value,
) => {
  switch struct.maybeDestructors {
  | Some(constructors) => {
      let idxRef = ref(constructors->Js.Array2.length - 1)
      let unknownRef = ref(value->unsafeAnyToUnknown)
      let maybeErrorRef = ref(None)

      while idxRef.contents >= 0 && maybeErrorRef.contents == None {
        let constructor = constructors->Js.Array2.unsafe_get(idxRef.contents)
        switch constructor {
        | Transform(fn) =>
          switch fn(unknownRef.contents) {
          | Ok(newUnknown) => {
              unknownRef.contents = newUnknown
              idxRef.contents = idxRef.contents - 1
            }
          | Error(_) as error => maybeErrorRef.contents = Some(error)
          }
        }
      }

      switch maybeErrorRef.contents {
      | Some(error) => error
      | None => Ok(unknownRef.contents->unsafeAnyToUnknown)
      }
    }
  | None => Error(RescriptStruct_Error.MissingDestructor.make())
  }
}
let destructWith = (value, struct) => {
  _destruct(~struct, ~value)->RescriptStruct_ResultX.mapError(RescriptStruct_Error.toString)
}

module Record = {
  exception HackyAbort(RescriptStruct_Error.t)

  let _constructor = %raw(`function(fields, recordConstructor, construct) {
    var isSingleField = fields.length === 1;
    if (isSingleField) {
      var field = fields[0];
      return function(unknown) {
        var fieldName = field[0],
          fieldStruct = field[1],
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
    var isSingleField = fields.length === 1;
    if (isSingleField) {
      var field = fields[0];
      return function(value) {
        var fieldName = field[0],
          fieldStruct = field[1],
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
    ~fields as anyFields: 'fields,
    ~constructor as maybeRecordConstructor: option<'fieldValues => result<'value, string>>=?,
    ~destructor as maybeRecordDestructor: option<'value => result<'fieldValues, string>>=?,
    (),
  ): t<'value> => {
    if maybeRecordConstructor->Belt.Option.isNone && maybeRecordDestructor->Belt.Option.isNone {
      RescriptStruct_Error.MissingRecordConstructorAndDestructor.raise()
    }

    let fields = anyFields->unsafeAnyToFields

    {
      tagged_t: Record({fields: fields, unknownKeys: Strict}),
      maybeConstructors: switch maybeRecordConstructor {
      | Some(recordConstructor) =>
        {
          [
            Parser.transform(unknown => {
              try {
                _constructor(~fields, ~recordConstructor, ~construct=(
                  struct,
                  fieldName,
                  unknownFieldValue,
                ) => {
                  switch _construct(~struct, ~unknown=unknownFieldValue) {
                  | Ok(value) => value
                  | Error(error) =>
                    raise(HackyAbort(error->RescriptStruct_Error.prependField(fieldName)))
                  }
                })(unknown)->RescriptStruct_ResultX.mapError(
                  RescriptStruct_Error.ConstructingFailed.make,
                )
              } catch {
              | HackyAbort(error) => Error(error)
              }
            }),
          ]
        }->Some
      | None => None
      },
      maybeDestructors: switch maybeRecordDestructor {
      | Some(recordDestructor) =>
        Some([
          Parser.transform(value => {
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
                    raise(HackyAbort(error->RescriptStruct_Error.prependField(fieldName)))
                  }
                },
              )(value)->Ok
            } catch {
            | HackyAbort(error) => Error(error)
            }
          }),
        ])
      | None => None
      },
      maybeMetadata: None,
    }
  }

  let strip = struct => {
    let tagged_t = struct.tagged_t
    switch tagged_t {
    | Record({fields}) => {
        tagged_t: Record({fields: fields, unknownKeys: Strip}),
        maybeConstructors: struct.maybeConstructors,
        maybeDestructors: struct.maybeDestructors,
        maybeMetadata: struct.maybeMetadata,
      }
    | _ => RescriptStruct_Error.UnknownKeysRequireRecord.raise()
    }
  }

  let strict = struct => {
    let tagged_t = struct.tagged_t
    switch tagged_t {
    | Record({fields}) => {
        tagged_t: Record({fields: fields, unknownKeys: Strict}),
        maybeConstructors: struct.maybeConstructors,
        maybeDestructors: struct.maybeDestructors,
        maybeMetadata: struct.maybeMetadata,
      }
    | _ => RescriptStruct_Error.UnknownKeysRequireRecord.raise()
    }
  }
}

module Primitive = {
  module Factory = {
    let make = (~tagged_t) => {
      () => {
        tagged_t: tagged_t,
        maybeConstructors: Some([]),
        maybeDestructors: Some([]),
        maybeMetadata: None,
      }
    }
  }
}

module Optional = {
  module Factory = {
    let make = (~tagged_t, ~struct) => {
      {
        tagged_t: tagged_t,
        maybeConstructors: Some([
          Parser.transform(option => {
            switch option {
            | Some(innerValue) =>
              switch _construct(~struct, ~unknown=innerValue) {
              | Ok(value) => Ok(Some(value))
              | Error(_) as error => error
              }
            | None => Ok(None)
            }
          }),
        ]),
        maybeDestructors: Some([
          Parser.transform(optionalValue => {
            switch optionalValue {
            | Some(value) => _destruct(~struct, ~value)
            | None => Ok(None->unsafeAnyToUnknown)
            }
          }),
        ]),
        maybeMetadata: None,
      }
    }
  }
}

module Null = {
  let factory = struct => {
    tagged_t: Null(struct),
    maybeConstructors: Some([
      Parser.transform(null => {
        switch null->Js.Null.toOption {
        | Some(innerValue) =>
          switch _construct(~struct, ~unknown=innerValue) {
          | Ok(value) => Ok(Some(value))
          | Error(_) as error => error
          }
        | None => Ok(None)
        }
      }),
    ]),
    maybeDestructors: Some([
      Parser.transform(optionalValue => {
        switch optionalValue {
        | Some(value) => _destruct(~struct, ~value)
        | None => Js.Null.empty->unsafeAnyToUnknown->Ok
        }
      }),
    ]),
    maybeMetadata: None,
  }
}

let never = Primitive.Factory.make(~tagged_t=Never)

let unknown = Primitive.Factory.make(~tagged_t=Unknown)

let string = Primitive.Factory.make(~tagged_t=String)

let bool = Primitive.Factory.make(~tagged_t=Bool)

let int = Primitive.Factory.make(~tagged_t=Int)

let float = Primitive.Factory.make(~tagged_t=Float)

let array = struct => {
  tagged_t: Array(struct),
  maybeConstructors: Some([
    Parser.transform(array => {
      array->RescriptStruct_ResultX.Array.mapi((. innerValue, idx) => {
        switch _construct(~struct, ~unknown=innerValue) {
        | Ok(_) as ok => ok
        | Error(error) => Error(error->RescriptStruct_Error.prependIndex(idx))
        }
      })
    }),
  ]),
  maybeDestructors: Some([
    Parser.transform(array => {
      array->RescriptStruct_ResultX.Array.mapi((. innerValue, idx) => {
        switch _destruct(~struct, ~value=innerValue) {
        | Ok(_) as ok => ok
        | Error(error) => Error(error->RescriptStruct_Error.prependIndex(idx))
        }
      })
    }),
  ]),
  maybeMetadata: None,
}

let dict = struct => {
  tagged_t: Dict(struct),
  maybeConstructors: Some([
    Parser.transform(dict => {
      dict->RescriptStruct_ResultX.Dict.map((. innerValue, key) => {
        switch _construct(~struct, ~unknown=innerValue) {
        | Ok(_) as ok => ok
        | Error(error) => Error(RescriptStruct_Error.prependField(error, key))
        }
      })
    }),
  ]),
  maybeDestructors: Some([
    Parser.transform(dict => {
      dict->RescriptStruct_ResultX.Dict.map((. innerValue, key) => {
        switch _destruct(~struct, ~value=innerValue) {
        | Ok(_) as ok => ok
        | Error(error) => Error(RescriptStruct_Error.prependField(error, key))
        }
      })
    }),
  ]),
  maybeMetadata: None,
}

let literal:
  type value. literal<value> => t<value> =
  innerLiteral => {
    let tagged_t = Literal(innerLiteral)
    switch innerLiteral {
    | EmptyNull => {
        tagged_t: tagged_t,
        maybeConstructors: Some([Parser.transform(null => null->Js.Null.toOption->Ok)]),
        maybeDestructors: Some([
          Parser.transform(value => {
            value->Js.Null.fromOption->Ok
          }),
        ]),
        maybeMetadata: None,
      }
    | _ => {
        tagged_t: tagged_t,
        maybeConstructors: Some([]),
        maybeDestructors: Some([]),
        maybeMetadata: None,
      }
    }
  }

let null = Null.factory

let option = struct => {
  Optional.Factory.make(~tagged_t=Option(struct), ~struct)
}

let deprecated = (~message as maybeMessage=?, struct) => {
  Optional.Factory.make(~tagged_t=Deprecated({struct: struct, maybeMessage: maybeMessage}), ~struct)
}

let default = (struct, value) => {
  tagged_t: Default({struct: struct, value: value}),
  maybeConstructors: Some([
    Parser.transform(input => {
      switch _construct(~struct, ~unknown=input) {
      | Ok(maybeOutput) =>
        switch maybeOutput {
        | Some(output) => output
        | None => value
        }->Ok
      | Error(_) as error => error
      }
    }),
  ]),
  maybeDestructors: Some([
    Parser.transform(value => {
      _destruct(~struct, ~value=Some(value))
    }),
  ]),
  maybeMetadata: None,
}

let record1 = (~fields) => Record.factory(~fields=[fields])
let record2 = Record.factory
let record3 = Record.factory
let record4 = Record.factory
let record5 = Record.factory
let record6 = Record.factory
let record7 = Record.factory
let record8 = Record.factory
let record9 = Record.factory
let record10 = Record.factory

let transform = (
  struct,
  ~constructor as maybeTransformationConstructor=?,
  ~destructor as maybeTransformationDestructor=?,
  (),
) => {
  if (
    maybeTransformationConstructor->Belt.Option.isNone &&
      maybeTransformationDestructor->Belt.Option.isNone
  ) {
    RescriptStruct_Error.MissingTransformConstructorAndDestructor.raise()
  }
  {
    tagged_t: struct.tagged_t,
    maybeMetadata: struct.maybeMetadata,
    maybeConstructors: switch (struct.maybeConstructors, maybeTransformationConstructor) {
    | (Some(constructors), Some(transformationConstructor)) =>
      constructors
      ->Js.Array2.concat([
        Parser.transform(input => {
          switch transformationConstructor(input) {
          | Ok(_) as ok => ok
          | Error(reason) => Error(RescriptStruct_Error.ConstructingFailed.make(reason))
          }
        }),
      ])
      ->Some
    | (_, _) => None
    },
    maybeDestructors: switch (struct.maybeDestructors, maybeTransformationDestructor) {
    | (Some(destructors), Some(transformationDestructor)) =>
      destructors
      ->Js.Array2.concat([
        Parser.transform(value => {
          switch transformationDestructor(value) {
          | Ok(_) as ok => ok
          | Error(reason) => Error(RescriptStruct_Error.DestructingFailed.make(reason))
          }
        }),
      ])
      ->Some
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
    switch struct.maybeMetadata {
    | Some(metadata) =>
      metadata->Js.Dict.get(Details.namespace)->unsafeAnyToUnknown->unsafeUnknownToAny
    | None => None
    }
  }

  let dictUnsafeSet = (dict: Js.Dict.t<'any>, key: string, value: 'any): Js.Dict.t<'any> => {
    ignore(dict)
    ignore(key)
    ignore(value)
    %raw(`{
      ...obj,
      [key]: value,
    }`)
  }

  let mixin = (struct, metadata: Details.content) => {
    let structMetadata = switch struct.maybeMetadata {
    | Some(m) => m
    | None => Js.Dict.empty()
    }
    {
      tagged_t: struct.tagged_t,
      maybeConstructors: struct.maybeConstructors,
      maybeDestructors: struct.maybeDestructors,
      maybeMetadata: Some(
        structMetadata->dictUnsafeSet(Details.namespace, metadata->unsafeAnyToUnknown),
      ),
    }
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
  let expected = TaggedT.toString(structTagged)
  Error(RescriptStruct_Error.ParsingFailed.UnexpectedType.make(~expected, ~got))
}

let validateLiteral = (~expectedValue: 'value, ~gotValue: 'value) => {
  if expectedValue === gotValue {
    Ok()
  } else {
    Error(RescriptStruct_Error.ParsingFailed.UnexpectedValue.make(~expectedValue, ~gotValue))
  }
}

let checkIsIntNumber = x => x === x->Js.Math.trunc && x < 2147483648. && x > -2147483648.

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
    | (JSNull, Null(_))
    | (JSNull, Default(_))
    | (_, Unknown) =>
      Ok()
    | (JSFalse, Literal(Bool(expectedValue))) => validateLiteral(~expectedValue, ~gotValue=false)
    | (JSTrue, Literal(Bool(expectedValue))) => validateLiteral(~expectedValue, ~gotValue=true)
    | (JSString(gotValue), Literal(String(expectedValue))) =>
      validateLiteral(~expectedValue, ~gotValue)
    | (JSNumber(gotValue), Literal(Int(expectedValue))) if checkIsIntNumber(gotValue) =>
      validateLiteral(~expectedValue=expectedValue->Js.Int.toFloat, ~gotValue)
    | (JSNumber(gotValue), Literal(Float(expectedValue))) =>
      validateLiteral(~expectedValue, ~gotValue)
    | (JSNull, Literal(EmptyNull)) => Ok()
    | (JSUndefined, Literal(EmptyOption)) => Ok()
    | (JSNumber(x), Int) if checkIsIntNumber(x) => Ok()
    | (JSObject(obj_val), Array(innerStruct)) if Js.Array2.isArray(obj_val) =>
      obj_val
      ->unsafeAnyToUnknown
      ->unsafeUnknownToArray
      ->RescriptStruct_ResultX.Array.mapi((. innerValue, idx) => {
        validateNode(~unknown=innerValue, ~struct=innerStruct)->RescriptStruct_ResultX.mapError(
          RescriptStruct_Error.prependIndex(_, idx),
        )
      })
      ->Belt.Result.map(_ => ())
    | (JSObject(obj_val), Dict(innerStruct)) if !Js.Array2.isArray(obj_val) =>
      obj_val
      ->unsafeAnyToUnknown
      ->unsafeUnknownToDict
      ->RescriptStruct_ResultX.Dict.map((. innerValue, key) => {
        validateNode(~unknown=innerValue, ~struct=innerStruct)->RescriptStruct_ResultX.mapError(
          RescriptStruct_Error.prependField(_, key),
        )
      })
      ->Belt.Result.map(_ => ())
    | (JSObject(obj_val), Record({fields, unknownKeys})) if !Js.Array2.isArray(obj_val) =>
      let unknownDict = obj_val->unsafeAnyToUnknown->unsafeUnknownToDict

      switch unknownKeys {
      | Strip =>
        fields
        ->RescriptStruct_ResultX.Array.mapi((. (fieldName, fieldStruct), _) => {
          validateNode(
            ~unknown=unknownDict->Js.Dict.get(fieldName),
            ~struct=fieldStruct,
          )->RescriptStruct_ResultX.mapError(RescriptStruct_Error.prependField(_, fieldName))
        })
        ->Belt.Result.map(_ => ())
      | Strict => {
          let unknownKeysSet = unknownDict->Js.Dict.keys->RescriptStruct_Set.fromArray

          fields
          ->RescriptStruct_ResultX.Array.mapi((. (fieldName, fieldStruct), _) => {
            unknownKeysSet->RescriptStruct_Set.delete(fieldName)->ignore

            validateNode(
              ~unknown=unknownDict->Js.Dict.get(fieldName),
              ~struct=fieldStruct,
            )->RescriptStruct_ResultX.mapError(RescriptStruct_Error.prependField(_, fieldName))
          })
          ->Belt.Result.flatMap(_ => {
            if unknownKeysSet->RescriptStruct_Set.size === 0 {
              Ok()
            } else {
              Error(
                RescriptStruct_Error.ParsingFailed.DisallowedUnknownKeys.make(
                  ~unknownKeys=unknownKeysSet->RescriptStruct_Set.toArray,
                ),
              )
            }
          })
        }
      }
    | (_, Deprecated({struct: struct'})) => validateNode(~unknown, ~struct=struct')
    | (_, Default({struct: struct'})) => validateNode(~unknown, ~struct=struct')
    | (_, Option(struct')) => validateNode(~unknown, ~struct=struct')
    | (_, Null(struct')) => validateNode(~unknown, ~struct=struct')
    | (_, _) => makeUnexpectedTypeError(~typesTagged, ~structTagged)
    }
  }

let parseWith = (any, struct) => {
  let unknown = any->unsafeAnyToUnknown
  validateNode(~unknown, ~struct)
  ->Belt.Result.flatMap(() => {
    _construct(~struct, ~unknown)
  })
  ->RescriptStruct_ResultX.mapError(RescriptStruct_Error.toString)
}

let parseJsonWith = (string, struct) => {
  switch Js.Json.parseExn(string) {
  | json => Ok(json)
  | exception Js.Exn.Error(obj) =>
    let maybeMessage = Js.Exn.message(obj)
    Error(
      RescriptStruct_Error.ParsingFailed.make(
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

let serializeJsonWith = (value, struct) => {
  switch _destruct(~struct, ~value) {
  | Ok(unknown) => Ok(unknown->unsafeUnknownToJson->Js.Json.stringify)
  | Error(error) => Error(error->RescriptStruct_Error.toString)
  }
}
