module Inline = {
  module Result: {
    let mapError: (result<'ok, 'error1>, 'error1 => 'error2) => result<'ok, 'error2>
    let map: (result<'ok1, 'error>, 'ok1 => 'ok2) => result<'ok2, 'error>
    let flatMap: (result<'ok1, 'error>, 'ok1 => result<'ok2, 'error>) => result<'ok2, 'error>
    module Array: {
      let mapi: (array<'a>, (. 'a, int) => result<'b, 'e>) => result<array<'b>, 'e>
    }
    module Dict: {
      let map: (Js.Dict.t<'a>, (. 'a, string) => result<'b, 'e>) => result<Js.Dict.t<'b>, 'e>
    }
  } = {
    @inline
    let mapError = (result, fn) =>
      switch result {
      | Ok(_) as ok => ok
      | Error(error) => Error(fn(error))
      }

    @inline
    let map = (result, fn) =>
      switch result {
      | Ok(value) => Ok(fn(value))
      | Error(_) as error => error
      }

    @inline
    let flatMap = (result, fn) =>
      switch result {
      | Ok(value) => fn(value)
      | Error(_) as error => error
      }

    module Array = {
      let mapi = (array, fn) => {
        let newArray = []
        let idxRef = ref(0)
        let maybeErrorRef = ref(None)

        while idxRef.contents < array->Js.Array2.length && maybeErrorRef.contents === None {
          let idx = idxRef.contents
          let item = array->Js.Array2.unsafe_get(idx)
          switch fn(. item, idx) {
          | Ok(value) => {
              newArray->Js.Array2.push(value)->ignore
              idxRef.contents = idxRef.contents + 1
            }
          | Error(_) as error => maybeErrorRef.contents = Some(error)
          }
        }

        switch maybeErrorRef.contents {
        | Some(error) => error
        | None => Ok(newArray)
        }
      }
    }

    module Dict = {
      let map = (dict, fn) => {
        let newDict = Js.Dict.empty()
        let keys = dict->Js.Dict.keys
        let idxRef = ref(0)
        let maybeErrorRef = ref(None)

        while idxRef.contents < keys->Js.Array2.length && maybeErrorRef.contents === None {
          let idx = idxRef.contents
          let key = keys->Js.Array2.unsafe_get(idx)
          let item = dict->Js.Dict.unsafeGet(key)
          switch fn(. item, key) {
          | Ok(value) => {
              newDict->Js.Dict.set(key, value)->ignore
              idxRef.contents = idxRef.contents + 1
            }
          | Error(_) as error => maybeErrorRef.contents = Some(error)
          }
        }

        switch maybeErrorRef.contents {
        | Some(error) => error
        | None => Ok(newDict)
        }
      }
    }
  }

  module Option: {
    let map: (option<'value1>, 'value1 => 'value2) => option<'value2>
  } = {
    @inline
    let map = (option, fn) =>
      switch option {
      | Some(value) => Some(fn(value))
      | None => None
      }
  }
}

type never
type unknown

type rec literal<'value> =
  | String(string): literal<string>
  | Int(int): literal<int>
  | Float(float): literal<float>
  | Bool(bool): literal<bool>
  | EmptyNull: literal<option<never>>
  | EmptyOption: literal<option<never>>

type mode = Safe | Unsafe
type recordUnknownKeys =
  | Strict
  | Strip

type rec t<'value> = {
  tagged_t: tagged_t,
  maybeConstructors: option<array<operation>>,
  maybeDestructors: option<array<operation>>,
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
  | Record({
      fields: Js.Dict.t<t<unknown>>,
      fieldNames: array<string>,
      unknownKeys: recordUnknownKeys,
    }): tagged_t
  | Dict(t<'value>): tagged_t
  | Deprecated({struct: t<'value>, maybeMessage: option<string>}): tagged_t
  | Default({struct: t<option<'value>>, value: 'value}): tagged_t
and field<'value> = (string, t<'value>)
and operation =
  | Transform(
      (
        . ~unknown: unknown,
        ~struct: t<unknown>,
        ~mode: mode,
      ) => result<unknown, RescriptStruct_Error.t>,
    )
  | Refinement((. ~unknown: unknown, ~struct: t<unknown>) => option<RescriptStruct_Error.t>)

external unsafeAnyToUnknown: 'any => unknown = "%identity"
external unsafeUnknownToAny: unknown => 'any = "%identity"
external unsafeAnyToFields: 'any => array<field<unknown>> = "%identity"

type payloadedVariant<'payload> = {_0: 'payload}
@inline
let unsafeGetVariantPayload: tagged_t => 'payload = v =>
  (v->unsafeAnyToUnknown->unsafeUnknownToAny)._0

@val external getInternalClass: 'a => string = "Object.prototype.toString.call"

@inline
let classify = struct => struct.tagged_t

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

let makeUnexpectedTypeError = (~input: 'any, ~struct: t<'any2>) => {
  let typesTagged = input->Js.Types.classify
  let structTagged = struct->classify
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
  RescriptStruct_Error.UnexpectedType.make(~expected, ~got)
}

// TODO: Test that it's the correct logic
// TODO: Write tests for NaN
// TODO: Handle NaN for float
@inline
let checkIsIntNumber = x => x < 2147483648. && x > -2147483649. && x === x->Js.Math.trunc

let applyOperations = (
  ~operations: array<operation>,
  ~initial: unknown,
  ~mode: mode,
  ~struct: t<unknown>,
) => {
  let idxRef = ref(0)
  let valueRef = ref(initial)
  let maybeErrorRef = ref(None)
  let shouldSkipRefinements = switch mode {
  | Unsafe => true
  | Safe => false
  }
  while idxRef.contents < operations->Js.Array2.length && maybeErrorRef.contents === None {
    let operation = operations->Js.Array2.unsafe_get(idxRef.contents)
    switch operation {
    | Transform(fn) =>
      switch fn(. ~unknown=valueRef.contents, ~struct, ~mode) {
      | Ok(newValue) => {
          valueRef.contents = newValue
          idxRef.contents = idxRef.contents + 1
        }
      | Error(error) => maybeErrorRef.contents = Some(error)
      }
    | Refinement(fn) =>
      if shouldSkipRefinements {
        idxRef.contents = idxRef.contents + 1
      } else {
        switch fn(. ~unknown=valueRef.contents, ~struct) {
        | None => idxRef.contents = idxRef.contents + 1
        | Some(_) as someError => maybeErrorRef.contents = someError
        }
      }
    }
  }
  switch maybeErrorRef.contents {
  | Some(error) => Error(error)
  | None => Ok(valueRef.contents)
  }
}

let parseInner: (
  ~struct: t<'value>,
  ~any: 'any,
  ~mode: mode,
) => result<'value, RescriptStruct_Error.t> = (~struct, ~any, ~mode) => {
  switch struct.maybeConstructors {
  | Some(constructors) =>
    applyOperations(
      ~operations=constructors,
      ~initial=any->unsafeAnyToUnknown,
      ~mode,
      ~struct=struct->unsafeAnyToUnknown->unsafeUnknownToAny,
    )
    ->unsafeAnyToUnknown
    ->unsafeUnknownToAny
  | None => Error(RescriptStruct_Error.MissingConstructor.make())
  }
}

let parseWith = (any, ~mode=Safe, struct) => {
  parseInner(~struct, ~any, ~mode)->Inline.Result.mapError(RescriptStruct_Error.toString)
}

let serializeInner: (
  ~struct: t<'value>,
  ~value: 'value,
  ~mode: mode,
) => result<unknown, RescriptStruct_Error.t> = (~struct, ~value, ~mode) => {
  switch struct.maybeDestructors {
  | Some(destructors) =>
    applyOperations(
      ~operations=destructors,
      ~initial=value->unsafeAnyToUnknown,
      ~mode,
      ~struct=struct->unsafeAnyToUnknown->unsafeUnknownToAny,
    )
  | None => Error(RescriptStruct_Error.MissingDestructor.make())
  }
}

let serializeWith = (value, ~mode=Safe, struct) => {
  serializeInner(~struct, ~value, ~mode)->Inline.Result.mapError(RescriptStruct_Error.toString)
}

module Operations = {
  let transform = (
    fn: (
      ~input: 'input,
      ~struct: t<'value>,
      ~mode: mode,
    ) => result<'output, RescriptStruct_Error.t>,
  ) => {
    Transform(fn->unsafeAnyToUnknown->unsafeUnknownToAny)
  }

  let refinement = (fn: (~input: 'value, ~struct: t<'value>) => option<RescriptStruct_Error.t>) => {
    Refinement(fn->unsafeAnyToUnknown->unsafeUnknownToAny)
  }

  module Never = {
    let constructors = [
      refinement((~input, ~struct) => {
        Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
      }),
    ]
    let destructors = []
  }

  module Unknown = {
    let constructors = []
    let destructors = []
  }

  module String = {
    let constructors = [
      refinement((~input, ~struct) => {
        switch input->Js.typeof === "string" {
        | true => None
        | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
        }
      }),
    ]
    let destructors = []
  }

  module Bool = {
    let constructors = [
      refinement((~input, ~struct) => {
        switch input->Js.typeof === "boolean" {
        | true => None
        | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
        }
      }),
    ]
    let destructors = []
  }

  module Float = {
    let constructors = [
      refinement((~input, ~struct) => {
        switch input->Js.typeof === "number" {
        | true => None
        | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
        }
      }),
    ]
    let destructors = []
  }

  module Int = {
    let constructors = [
      refinement((~input, ~struct) => {
        switch input->Js.typeof === "number" && checkIsIntNumber(input) {
        | true => None
        | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
        }
      }),
    ]
    let destructors = []
  }

  module Null = {
    let constructors = [
      transform((~input, ~struct, ~mode) => {
        switch input->Js.Null.toOption {
        | Some(innerValue) =>
          let innerStruct = struct->classify->unsafeGetVariantPayload
          parseInner(
            ~struct=innerStruct->unsafeAnyToUnknown->unsafeUnknownToAny,
            ~any=innerValue,
            ~mode,
          )->Inline.Result.map(value => Some(value))
        | None => Ok(None)
        }
      }),
    ]
    let destructors = [
      transform((~input, ~struct, ~mode) => {
        switch input {
        | Some(value) =>
          let innerStruct = struct->classify->unsafeGetVariantPayload
          serializeInner(~struct=innerStruct->unsafeAnyToUnknown->unsafeUnknownToAny, ~value, ~mode)
        | None => Js.Null.empty->unsafeAnyToUnknown->Ok
        }
      }),
    ]
  }

  module Option = {
    let constructors = [
      transform((~input, ~struct, ~mode) => {
        switch input {
        | Some(innerValue) =>
          let innerStruct = struct->classify->unsafeGetVariantPayload
          parseInner(~struct=innerStruct, ~any=innerValue, ~mode)->Inline.Result.map(value => Some(
            value,
          ))
        | None => Ok(None)
        }
      }),
    ]
    let destructors = [
      transform((~input, ~struct, ~mode) => {
        switch input {
        | Some(value) => {
            let innerStruct = struct->classify->unsafeGetVariantPayload
            serializeInner(~struct=innerStruct, ~value, ~mode)
          }
        | None => Ok(None->unsafeAnyToUnknown)
        }
      }),
    ]
  }

  module Deprecated = {
    type payload<'value> = {struct: t<'value>}
    let constructors = [
      transform((~input, ~struct, ~mode) => {
        switch input {
        | Some(innerValue) =>
          let {struct: innerStruct} = struct->classify->unsafeAnyToUnknown->unsafeUnknownToAny
          parseInner(~struct=innerStruct, ~any=innerValue, ~mode)->Inline.Result.map(value => Some(
            value,
          ))
        | None => Ok(None)
        }
      }),
    ]
    let destructors = [
      transform((~input, ~struct, ~mode) => {
        switch input {
        | Some(value) => {
            let {struct: innerStruct} = struct->classify->unsafeAnyToUnknown->unsafeUnknownToAny
            serializeInner(~struct=innerStruct, ~value, ~mode)
          }
        | None => Ok(None->unsafeAnyToUnknown)
        }
      }),
    ]
  }

  module Array = {
    let constructors = [
      transform((~input, ~struct, ~mode) => {
        let maybeRefinementError = switch mode {
        | Safe =>
          switch Js.Array2.isArray(input) {
          | true => None
          | _ => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
          }
        | Unsafe => None
        }
        switch maybeRefinementError {
        | None => {
            let innerStruct = struct->classify->unsafeGetVariantPayload
            input->Inline.Result.Array.mapi((. innerValue, idx) => {
              parseInner(~struct=innerStruct, ~any=innerValue, ~mode)->Inline.Result.mapError(
                RescriptStruct_Error.prependIndex(_, idx),
              )
            })
          }
        | Some(error) => Error(error)
        }
      }),
    ]
    let destructors = [
      transform((~input, ~struct, ~mode) => {
        let innerStruct = struct->classify->unsafeGetVariantPayload
        input->Inline.Result.Array.mapi((. innerValue, idx) => {
          serializeInner(~struct=innerStruct, ~value=innerValue, ~mode)->Inline.Result.mapError(
            RescriptStruct_Error.prependIndex(_, idx),
          )
        })
      }),
    ]
  }

  module Dict = {
    let constructors = [
      transform((~input, ~struct, ~mode) => {
        let maybeRefinementError = switch mode {
        | Safe =>
          switch input->getInternalClass === "[object Object]" {
          | true => None
          | _ => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
          }
        | Unsafe => None
        }
        switch maybeRefinementError {
        | None => {
            let innerStruct = struct->classify->unsafeGetVariantPayload
            input->Inline.Result.Dict.map((. innerValue, key) => {
              parseInner(~struct=innerStruct, ~any=innerValue, ~mode)->Inline.Result.mapError(
                RescriptStruct_Error.prependField(_, key),
              )
            })
          }
        | Some(error) => Error(error)
        }
      }),
    ]
    let destructors = [
      transform((~input, ~struct, ~mode) => {
        let innerStruct = struct->classify->unsafeGetVariantPayload
        input->Inline.Result.Dict.map((. innerValue, key) => {
          serializeInner(~struct=innerStruct, ~value=innerValue, ~mode)->Inline.Result.mapError(
            RescriptStruct_Error.prependField(_, key),
          )
        })
      }),
    ]
  }

  module Default = {
    type payload<'value> = {struct: t<option<'value>>, value: 'value}

    let constructors = [
      transform((~input, ~struct, ~mode) => {
        let {struct: innerStruct, value} = struct->classify->unsafeAnyToUnknown->unsafeUnknownToAny
        parseInner(~struct=innerStruct, ~any=input, ~mode)->Inline.Result.map(maybeOutput => {
          switch maybeOutput {
          | Some(output) => output
          | None => value
          }
        })
      }),
    ]
    let destructors = [
      transform((~input, ~struct, ~mode) => {
        let {struct: innerStruct} = struct->classify->unsafeAnyToUnknown->unsafeUnknownToAny
        serializeInner(~struct=innerStruct, ~value=Some(input), ~mode)
      }),
    ]
  }

  module Literal = {
    module WithExpectedValue = {
      module Constructors = {
        let make = (~checkType) => {
          [
            transform((~input, ~struct, ~mode) => {
              let expectedValue = struct->classify->unsafeGetVariantPayload->unsafeGetVariantPayload
              let ok = Ok(expectedValue)
              if mode === Safe {
                if !checkType(. input) {
                  Error(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
                } else if expectedValue !== input {
                  Error(
                    RescriptStruct_Error.UnexpectedValue.make(
                      ~expectedValue,
                      ~gotValue=input,
                      ~operation=Parsing,
                    ),
                  )
                } else {
                  ok
                }
              } else {
                ok
              }
            }),
          ]
        }
      }
      let destructors = [
        transform((~input, ~struct, ~mode) => {
          let expectedValue = struct->classify->unsafeGetVariantPayload->unsafeGetVariantPayload
          if mode === Safe && expectedValue !== input {
            Error(
              RescriptStruct_Error.UnexpectedValue.make(
                ~expectedValue,
                ~gotValue=input,
                ~operation=Serializing,
              ),
            )
          } else {
            Ok(expectedValue)
          }
        }),
      ]
    }

    module EmptyNull = {
      let constructors = [
        transform((~input, ~struct, ~mode) => {
          if mode === Safe && input !== Js.Null.empty {
            Error(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
          } else {
            Ok(None)
          }
        }),
      ]
      let destructors = [
        transform((~input, ~struct, ~mode) => {
          if mode === Safe && input !== None {
            Error(makeUnexpectedTypeError(~input, ~struct, ~operation=Serializing))
          } else {
            Ok(Js.Null.empty)
          }
        }),
      ]
    }

    module EmptyOption = {
      let constructors = WithExpectedValue.Constructors.make(~checkType=(. input) =>
        input === Js.Undefined.empty
      )
      let destructors = [
        transform((~input, ~struct, ~mode) => {
          if mode === Safe && input !== None {
            Error(makeUnexpectedTypeError(~input, ~struct, ~operation=Serializing))
          } else {
            Ok(Js.Undefined.empty)
          }
        }),
      ]
    }

    module Bool = {
      let constructors = WithExpectedValue.Constructors.make(~checkType=(. input) =>
        input->Js.typeof === "boolean"
      )
      let destructors = WithExpectedValue.destructors
    }

    module String = {
      let constructors = WithExpectedValue.Constructors.make(~checkType=(. input) =>
        input->Js.typeof === "string"
      )
      let destructors = WithExpectedValue.destructors
    }

    module Float = {
      let constructors = WithExpectedValue.Constructors.make(~checkType=(. input) =>
        input->Js.typeof === "number"
      )
      let destructors = WithExpectedValue.destructors
    }

    module Int = {
      let constructors = WithExpectedValue.Constructors.make(~checkType=(. input) =>
        input->Js.typeof === "number" && checkIsIntNumber(input)
      )
      let destructors = WithExpectedValue.destructors
    }
  }
}

module Record = {
  type payload = {
    fields: Js.Dict.t<t<unknown>>,
    fieldNames: array<string>,
    unknownKeys: recordUnknownKeys,
  }

  let getMaybeExcessKey: (
    . Js.Dict.t<unknown>,
    Js.Dict.t<t<unknown>>,
  ) => option<string> = %raw(`function(object, innerStructsDict) {
    for (var key in object) {
      if (!(key in innerStructsDict)) {
        return key
      }
    }
    return undefined
  }`)

  module Constructors = {
    let make = (~recordConstructor) => {
      [
        Operations.transform((~input, ~struct, ~mode) => {
          let maybeRefinementError = switch mode {
          | Safe =>
            switch input->getInternalClass === "[object Object]" {
            | true => None
            | _ => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
            }
          | Unsafe => None
          }
          switch maybeRefinementError {
          | None =>
            let {fields, fieldNames, unknownKeys} =
              struct->classify->unsafeAnyToUnknown->unsafeUnknownToAny
            let fieldValuesResult = {
              let newArray = []
              let idxRef = ref(0)
              let maybeErrorRef = ref(None)
              while (
                idxRef.contents < fieldNames->Js.Array2.length && maybeErrorRef.contents === None
              ) {
                let idx = idxRef.contents
                let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
                let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
                switch parseInner(
                  ~struct=fieldStruct,
                  ~any=input->Js.Dict.unsafeGet(fieldName),
                  ~mode,
                ) {
                | Ok(value) => {
                    newArray->Js.Array2.push(value)->ignore
                    idxRef.contents = idxRef.contents + 1
                  }
                | Error(error) =>
                  maybeErrorRef.contents = Some(error->RescriptStruct_Error.prependField(fieldName))
                }
              }
              switch maybeErrorRef.contents {
              | Some(error) => Error(error)
              | None => Ok(newArray)
              }
            }
            switch (unknownKeys, mode) {
            | (Strict, Safe) =>
              fieldValuesResult->Inline.Result.flatMap(_ => {
                switch getMaybeExcessKey(. input, fields) {
                | Some(excessKey) =>
                  Error(RescriptStruct_Error.ExcessField.make(~fieldName=excessKey))
                | None => fieldValuesResult
                }
              })
            | (_, _) => fieldValuesResult
            }->Inline.Result.flatMap(fieldValues => {
              let fieldValuesTuple =
                fieldValues->Js.Array2.length === 1
                  ? fieldValues->Js.Array2.unsafe_get(0)->unsafeAnyToUnknown->unsafeUnknownToAny
                  : fieldValues->unsafeAnyToUnknown->unsafeUnknownToAny
              recordConstructor(fieldValuesTuple)->Inline.Result.mapError(
                RescriptStruct_Error.ParsingFailed.make,
              )
            })
          | Some(error) => Error(error)
          }
        }),
      ]
    }
  }

  module Destructors = {
    let make = (~recordDestructor) => {
      [
        Operations.transform((~input, ~struct, ~mode) => {
          let {fields, fieldNames} = struct->classify->unsafeAnyToUnknown->unsafeUnknownToAny
          recordDestructor(input)
          ->Inline.Result.mapError(RescriptStruct_Error.SerializingFailed.make)
          ->Inline.Result.flatMap(fieldValuesTuple => {
            let unknown = Js.Dict.empty()
            let fieldValues =
              fieldNames->Js.Array2.length === 1
                ? [fieldValuesTuple]->unsafeAnyToUnknown->unsafeUnknownToAny
                : fieldValuesTuple->unsafeAnyToUnknown->unsafeUnknownToAny

            fieldNames
            ->Inline.Result.Array.mapi((. fieldName, idx) => {
              let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
              let fieldValue = fieldValues->Js.Array2.unsafe_get(idx)
              switch serializeInner(~struct=fieldStruct, ~value=fieldValue, ~mode) {
              | Ok(unknownFieldValue) => {
                  unknown->Js.Dict.set(fieldName, unknownFieldValue)
                  Ok()
                }
              | Error(error) => Error(error->RescriptStruct_Error.prependField(fieldName))
              }
            })
            ->Inline.Result.map(_ => unknown)
          })
        }),
      ]
    }
  }

  let factory = (
    ~fields as fieldsArray: 'fields,
    ~constructor as maybeRecordConstructor: option<'fieldValues => result<'value, string>>=?,
    ~destructor as maybeRecordDestructor: option<'value => result<'fieldValues, string>>=?,
    (),
  ): t<'value> => {
    if maybeRecordConstructor === None && maybeRecordDestructor === None {
      RescriptStruct_Error.MissingRecordConstructorAndDestructor.raise()
    }

    let fields = fieldsArray->unsafeAnyToFields->Js.Dict.fromArray

    {
      tagged_t: Record({fields: fields, fieldNames: fields->Js.Dict.keys, unknownKeys: Strict}),
      maybeConstructors: maybeRecordConstructor->Inline.Option.map(recordConstructor => {
        Constructors.make(~recordConstructor)
      }),
      maybeDestructors: maybeRecordDestructor->Inline.Option.map(recordDestructor => {
        Destructors.make(~recordDestructor)
      }),
      maybeMetadata: None,
    }
  }

  let strip = struct => {
    let tagged_t = struct->classify
    switch tagged_t {
    | Record({fields, fieldNames}) => {
        tagged_t: Record({fields: fields, fieldNames: fieldNames, unknownKeys: Strip}),
        maybeConstructors: struct.maybeConstructors,
        maybeDestructors: struct.maybeDestructors,
        maybeMetadata: struct.maybeMetadata,
      }
    | _ => RescriptStruct_Error.UnknownKeysRequireRecord.raise()
    }
  }

  let strict = struct => {
    let tagged_t = struct->classify
    switch tagged_t {
    | Record({fields, fieldNames}) => {
        tagged_t: Record({fields: fields, fieldNames: fieldNames, unknownKeys: Strict}),
        maybeConstructors: struct.maybeConstructors,
        maybeDestructors: struct.maybeDestructors,
        maybeMetadata: struct.maybeMetadata,
      }
    | _ => RescriptStruct_Error.UnknownKeysRequireRecord.raise()
    }
  }
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

module MakeMetadata = (
  Config: {
    type content
    let namespace: string
  },
) => {
  let get = (struct): option<Config.content> => {
    struct.maybeMetadata->Inline.Option.map(metadata => {
      metadata->Js.Dict.get(Config.namespace)->unsafeAnyToUnknown->unsafeUnknownToAny
    })
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

  let set = (struct, content: Config.content) => {
    let existingContent = switch struct.maybeMetadata {
    | Some(currentContent) => currentContent
    | None => Js.Dict.empty()
    }
    {
      tagged_t: struct.tagged_t,
      maybeConstructors: struct.maybeConstructors,
      maybeDestructors: struct.maybeDestructors,
      maybeMetadata: Some(
        existingContent->dictUnsafeSet(Config.namespace, content->unsafeAnyToUnknown),
      ),
    }
  }
}

let never = () => {
  tagged_t: Never,
  maybeConstructors: Some(Operations.Never.constructors),
  maybeDestructors: Some(Operations.Never.destructors),
  maybeMetadata: None,
}

let unknown = () => {
  tagged_t: Unknown,
  maybeConstructors: Some(Operations.Unknown.constructors),
  maybeDestructors: Some(Operations.Unknown.destructors),
  maybeMetadata: None,
}

let string = () => {
  tagged_t: String,
  maybeConstructors: Some(Operations.String.constructors),
  maybeDestructors: Some(Operations.String.destructors),
  maybeMetadata: None,
}

let bool = () => {
  tagged_t: Bool,
  maybeConstructors: Some(Operations.Bool.constructors),
  maybeDestructors: Some(Operations.Bool.destructors),
  maybeMetadata: None,
}

let int = () => {
  tagged_t: Int,
  maybeConstructors: Some(Operations.Int.constructors),
  maybeDestructors: Some(Operations.Int.destructors),
  maybeMetadata: None,
}

let float = () => {
  tagged_t: Float,
  maybeConstructors: Some(Operations.Float.constructors),
  maybeDestructors: Some(Operations.Float.destructors),
  maybeMetadata: None,
}

let null = innerStruct => {
  tagged_t: Null(innerStruct),
  maybeConstructors: Some(Operations.Null.constructors),
  maybeDestructors: Some(Operations.Null.destructors),
  maybeMetadata: None,
}

let option = innerStruct => {
  tagged_t: Option(innerStruct),
  maybeConstructors: Some(Operations.Option.constructors),
  maybeDestructors: Some(Operations.Option.destructors),
  maybeMetadata: None,
}

let deprecated = (~message as maybeMessage=?, innerStruct) => {
  tagged_t: Deprecated({struct: innerStruct, maybeMessage: maybeMessage}),
  maybeConstructors: Some(Operations.Deprecated.constructors),
  maybeDestructors: Some(Operations.Deprecated.destructors),
  maybeMetadata: None,
}

let array = innerStruct => {
  tagged_t: Array(innerStruct),
  maybeConstructors: Some(Operations.Array.constructors),
  maybeDestructors: Some(Operations.Array.destructors),
  maybeMetadata: None,
}

let dict = innerStruct => {
  tagged_t: Dict(innerStruct),
  maybeConstructors: Some(Operations.Dict.constructors),
  maybeDestructors: Some(Operations.Dict.destructors),
  maybeMetadata: None,
}

let default = (innerStruct, defaultValue) => {
  tagged_t: Default({struct: innerStruct, value: defaultValue}),
  maybeConstructors: Some(Operations.Default.constructors),
  maybeDestructors: Some(Operations.Default.destructors),
  maybeMetadata: None,
}

let literal:
  type value. literal<value> => t<value> =
  innerLiteral => {
    let tagged_t = Literal(innerLiteral)
    switch innerLiteral {
    | EmptyNull => {
        tagged_t: tagged_t,
        maybeConstructors: Some(Operations.Literal.EmptyNull.constructors),
        maybeDestructors: Some(Operations.Literal.EmptyNull.destructors),
        maybeMetadata: None,
      }
    | EmptyOption => {
        tagged_t: tagged_t,
        maybeConstructors: Some(Operations.Literal.EmptyOption.constructors),
        maybeDestructors: Some(Operations.Literal.EmptyOption.destructors),
        maybeMetadata: None,
      }
    | Bool(_) => {
        tagged_t: tagged_t,
        maybeConstructors: Some(Operations.Literal.Bool.constructors),
        maybeDestructors: Some(Operations.Literal.Bool.destructors),
        maybeMetadata: None,
      }
    | String(_) => {
        tagged_t: tagged_t,
        maybeConstructors: Some(Operations.Literal.String.constructors),
        maybeDestructors: Some(Operations.Literal.String.destructors),
        maybeMetadata: None,
      }
    | Float(_) => {
        tagged_t: tagged_t,
        maybeConstructors: Some(Operations.Literal.Float.constructors),
        maybeDestructors: Some(Operations.Literal.Float.destructors),
        maybeMetadata: None,
      }
    | Int(_) => {
        tagged_t: tagged_t,
        maybeConstructors: Some(Operations.Literal.Int.constructors),
        maybeDestructors: Some(Operations.Literal.Int.destructors),
        maybeMetadata: None,
      }
    }
  }

let json = struct => {
  tagged_t: String,
  maybeConstructors: Some(
    Js.Array2.concat(
      Operations.String.constructors,
      [
        Operations.transform((~input, ~struct as _, ~mode) => {
          switch Js.Json.parseExn(input) {
          | json => Ok(json)
          | exception Js.Exn.Error(obj) =>
            let maybeMessage = Js.Exn.message(obj)
            Error(
              RescriptStruct_Error.ParsingFailed.make(
                maybeMessage->Belt.Option.getWithDefault("Syntax error"),
              ),
            )
          }->Inline.Result.flatMap(parsedJson => parseInner(~any=parsedJson, ~struct, ~mode))
        }),
      ],
    ),
  ),
  maybeDestructors: Some(
    Js.Array2.concat(
      [
        Operations.transform((~input, ~struct as _, ~mode) => {
          serializeInner(~struct, ~value=input, ~mode)->Inline.Result.map(unknown =>
            unknown->unsafeUnknownToAny->Js.Json.stringify
          )
        }),
      ],
      Operations.String.destructors,
    ),
  ),
  maybeMetadata: None,
}

let refine = (
  struct,
  ~constructor as maybeConstructorRefine=?,
  ~destructor as maybeDestructorRefine=?,
  (),
) => {
  if maybeConstructorRefine === None && maybeDestructorRefine === None {
    RescriptStruct_Error.MissingConstructorAndDestructorRefine.raise()
  }

  {
    tagged_t: struct.tagged_t,
    maybeMetadata: struct.maybeMetadata,
    maybeConstructors: switch (struct.maybeConstructors, maybeConstructorRefine) {
    | (Some(constructors), Some(constructorRefine)) =>
      constructors
      ->Js.Array2.concat([
        Operations.refinement((~input, ~struct as _) => {
          constructorRefine(input)->Inline.Option.map(RescriptStruct_Error.ParsingFailed.make)
        }),
      ])
      ->Some
    | (_, _) => None
    },
    maybeDestructors: switch (struct.maybeDestructors, maybeDestructorRefine) {
    | (Some(destructors), Some(destructorRefine)) =>
      [
        Operations.refinement((~input, ~struct as _) => {
          destructorRefine(input)->Inline.Option.map(RescriptStruct_Error.SerializingFailed.make)
        }),
      ]
      ->Js.Array2.concat(destructors)
      ->Some
    | (_, _) => None
    },
  }
}

let transform = (
  struct,
  ~constructor as maybeTransformationConstructor=?,
  ~destructor as maybeTransformationDestructor=?,
  (),
) => {
  if maybeTransformationConstructor === None && maybeTransformationDestructor === None {
    RescriptStruct_Error.MissingTransformConstructorAndDestructor.raise()
  }
  {
    tagged_t: struct.tagged_t,
    maybeMetadata: struct.maybeMetadata,
    maybeConstructors: switch (struct.maybeConstructors, maybeTransformationConstructor) {
    | (Some(constructors), Some(transformationConstructor)) =>
      constructors
      ->Js.Array2.concat([
        Operations.transform((~input, ~struct as _, ~mode as _) => {
          transformationConstructor(input)->Inline.Result.mapError(
            RescriptStruct_Error.ParsingFailed.make,
          )
        }),
      ])
      ->Some
    | (_, _) => None
    },
    maybeDestructors: switch (struct.maybeDestructors, maybeTransformationDestructor) {
    | (Some(destructors), Some(transformationDestructor)) =>
      [
        Operations.transform((~input, ~struct as _, ~mode as _) => {
          transformationDestructor(input)->Inline.Result.mapError(
            RescriptStruct_Error.SerializingFailed.make,
          )
        }),
      ]
      ->Js.Array2.concat(destructors)
      ->Some
    | (_, _) => None
    },
  }
}
let transformUnknown = transform
