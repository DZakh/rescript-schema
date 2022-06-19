external unsafeToAny: 'a => 'b = "%identity"

module Inline = {
  module Fn = {
    let callWithArguments = fn => {
      fn->ignore
      %raw(`function(){return fn(arguments)}`)
    }
  }

  module Array = {
    @inline
    let toTuple = array =>
      array->Js.Array2.length <= 1
        ? array->Js.Array2.unsafe_get(0)->unsafeToAny
        : array->unsafeToAny
  }

  module Result: {
    let mapError: (result<'ok, 'error1>, 'error1 => 'error2) => result<'ok, 'error2>
    let map: (result<'ok1, 'error>, 'ok1 => 'ok2) => result<'ok2, 'error>
    let flatMap: (result<'ok1, 'error>, 'ok1 => result<'ok2, 'error>) => result<'ok2, 'error>
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
  maybeParsers: option<array<operation>>,
  maybeSerializers: option<array<operation>>,
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
  | Tuple(array<t<unknown>>): tagged_t
  | Union(array<t<'value>>): tagged_t
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

type payloadedVariant<'payload> = {_0: 'payload}
@inline
let unsafeGetVariantPayload: 'a => 'payload = v => (v->unsafeToAny)._0

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
    | Union(_) => "Union"
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
    | Tuple(_) => "Tuple"
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
  switch struct.maybeParsers {
  | Some(parsers) =>
    applyOperations(
      ~operations=parsers,
      ~initial=any->unsafeAnyToUnknown,
      ~mode,
      ~struct=struct->unsafeToAny,
    )
    ->unsafeAnyToUnknown
    ->unsafeUnknownToAny
  | None => Error(RescriptStruct_Error.MissingParser.make())
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
  switch struct.maybeSerializers {
  | Some(serializers) =>
    applyOperations(
      ~operations=serializers,
      ~initial=value->unsafeAnyToUnknown,
      ~mode,
      ~struct=struct->unsafeToAny,
    )
  | None => Error(RescriptStruct_Error.MissingSerializer.make())
  }
}

let serializeWith = (value, ~mode=Safe, struct) => {
  serializeInner(~struct, ~value, ~mode)->Inline.Result.mapError(RescriptStruct_Error.toString)
}

module Operation = {
  let transform = (
    fn: (
      ~input: 'input,
      ~struct: t<'value>,
      ~mode: mode,
    ) => result<'output, RescriptStruct_Error.t>,
  ) => {
    Transform(fn->unsafeToAny)
  }

  let refinement = (fn: (~input: 'value, ~struct: t<'value>) => option<RescriptStruct_Error.t>) => {
    Refinement(fn->unsafeToAny)
  }

  let empty: array<operation> = []
}

module Literal = {
  module CommonOperations = {
    module Parser = {
      let literalValueRefinement = Operation.refinement((~input, ~struct) => {
        let expectedValue = struct->classify->unsafeGetVariantPayload->unsafeGetVariantPayload
        switch expectedValue === input {
        | true => None
        | false =>
          Some(
            RescriptStruct_Error.UnexpectedValue.make(
              ~expectedValue,
              ~gotValue=input,
              ~operation=Parsing,
            ),
          )
        }
      })
    }

    let transformToLiteralValue = Operation.transform((~input as _, ~struct, ~mode as _) => {
      let literalValue = struct->classify->unsafeGetVariantPayload->unsafeGetVariantPayload
      Ok(literalValue)
    })
  }

  module EmptyNull = {
    let parserRefinement = Operation.refinement((~input, ~struct) => {
      switch input === Js.Null.empty {
      | true => None
      | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
      }
    })

    let serializerTransform = Operation.transform((~input as _, ~struct as _, ~mode as _) => {
      Ok(Js.Null.empty)
    })
  }

  module EmptyOption = {
    let parserRefinement = Operation.refinement((~input, ~struct) => {
      switch input === Js.Undefined.empty {
      | true => None
      | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
      }
    })

    let serializerTransform = Operation.transform((~input as _, ~struct as _, ~mode as _) => {
      Ok(Js.Undefined.empty)
    })
  }

  module Bool = {
    let parserRefinement = Operation.refinement((~input, ~struct) => {
      switch input->Js.typeof === "boolean" {
      | true => None
      | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
      }
    })
  }

  module String = {
    let parserRefinement = Operation.refinement((~input, ~struct) => {
      switch input->Js.typeof === "string" {
      | true => None
      | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
      }
    })
  }

  module Float = {
    let parserRefinement = Operation.refinement((~input, ~struct) => {
      switch input->Js.typeof === "number" {
      | true => None
      | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
      }
    })
  }

  module Int = {
    let parserRefinement = Operation.refinement((~input, ~struct) => {
      switch input->Js.typeof === "number" && checkIsIntNumber(input) {
      | true => None
      | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
      }
    })
  }

  module Variant = {
    let factory:
      type literalValue variant. (literal<literalValue>, variant) => t<variant> =
      (innerLiteral, variant) => {
        let tagged_t = Literal(innerLiteral)
        let parserTransform = Operation.transform((~input as _, ~struct as _, ~mode as _) => {
          Ok(variant)
        })
        let serializerRefinement = Operation.refinement((~input, ~struct as _) => {
          switch input === variant {
          | true => None
          | false =>
            Some(
              RescriptStruct_Error.UnexpectedValue.make(
                ~expectedValue=variant,
                ~gotValue=input,
                ~operation=Serializing,
              ),
            )
          }
        })
        switch innerLiteral {
        | EmptyNull => {
            tagged_t: tagged_t,
            maybeParsers: Some([EmptyNull.parserRefinement, parserTransform]),
            maybeSerializers: Some([serializerRefinement, EmptyNull.serializerTransform]),
            maybeMetadata: None,
          }
        | EmptyOption => {
            tagged_t: tagged_t,
            maybeParsers: Some([EmptyOption.parserRefinement, parserTransform]),
            maybeSerializers: Some([serializerRefinement, EmptyOption.serializerTransform]),
            maybeMetadata: None,
          }
        | Bool(_) => {
            tagged_t: tagged_t,
            maybeParsers: Some([
              Bool.parserRefinement,
              CommonOperations.Parser.literalValueRefinement,
              parserTransform,
            ]),
            maybeSerializers: Some([
              serializerRefinement,
              CommonOperations.transformToLiteralValue,
            ]),
            maybeMetadata: None,
          }
        | String(_) => {
            tagged_t: tagged_t,
            maybeParsers: Some([
              String.parserRefinement,
              CommonOperations.Parser.literalValueRefinement,
              parserTransform,
            ]),
            maybeSerializers: Some([
              serializerRefinement,
              CommonOperations.transformToLiteralValue,
            ]),
            maybeMetadata: None,
          }
        | Float(_) => {
            tagged_t: tagged_t,
            maybeParsers: Some([
              Float.parserRefinement,
              CommonOperations.Parser.literalValueRefinement,
              parserTransform,
            ]),
            maybeSerializers: Some([
              serializerRefinement,
              CommonOperations.transformToLiteralValue,
            ]),
            maybeMetadata: None,
          }
        | Int(_) => {
            tagged_t: tagged_t,
            maybeParsers: Some([
              Int.parserRefinement,
              CommonOperations.Parser.literalValueRefinement,
              parserTransform,
            ]),
            maybeSerializers: Some([
              serializerRefinement,
              CommonOperations.transformToLiteralValue,
            ]),
            maybeMetadata: None,
          }
        }
      }
  }

  module Unit = {
    let factory = innerLiteral => {
      Variant.factory(innerLiteral, ())
    }
  }

  let factory:
    type value. literal<value> => t<value> =
    innerLiteral => {
      switch innerLiteral {
      | EmptyNull => Variant.factory(innerLiteral, None)
      | EmptyOption => Variant.factory(innerLiteral, None)
      | Bool(value) => Variant.factory(innerLiteral, value)
      | String(value) => Variant.factory(innerLiteral, value)
      | Float(value) => Variant.factory(innerLiteral, value)
      | Int(value) => Variant.factory(innerLiteral, value)
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

  let parsers = [
    Operation.transform((~input, ~struct, ~mode) => {
      let maybeRefinementError = switch mode {
      | Safe =>
        switch input->getInternalClass === "[object Object]" {
        | true => None
        | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
        }
      | Unsafe => None
      }
      switch maybeRefinementError {
      | None =>
        let {fields, fieldNames, unknownKeys} = struct->classify->unsafeToAny

        let newArray = []
        let idxRef = ref(0)
        let maybeErrorRef = ref(None)
        while idxRef.contents < fieldNames->Js.Array2.length && maybeErrorRef.contents === None {
          let idx = idxRef.contents
          let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
          let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
          switch parseInner(~struct=fieldStruct, ~any=input->Js.Dict.unsafeGet(fieldName), ~mode) {
          | Ok(value) => {
              newArray->Js.Array2.push(value)->ignore
              idxRef.contents = idxRef.contents + 1
            }
          | Error(error) =>
            maybeErrorRef.contents = Some(error->RescriptStruct_Error.prependField(fieldName))
          }
        }
        if unknownKeys == Strict && mode == Safe {
          switch getMaybeExcessKey(. input, fields) {
          | Some(excessKey) =>
            maybeErrorRef.contents = Some(
              RescriptStruct_Error.ExcessField.make(~fieldName=excessKey),
            )
          | None => ()
          }
        }
        switch maybeErrorRef.contents {
        | Some(error) => Error(error)
        | None => newArray->Inline.Array.toTuple->Ok
        }
      | Some(error) => Error(error)
      }
    }),
  ]

  let serializers = [
    Operation.transform((~input, ~struct, ~mode) => {
      let {fields, fieldNames} = struct->classify->unsafeToAny

      let unknown = Js.Dict.empty()
      let fieldValues =
        fieldNames->Js.Array2.length <= 1 ? [input]->unsafeToAny : input->unsafeToAny

      let idxRef = ref(0)
      let maybeErrorRef = ref(None)
      while idxRef.contents < fieldNames->Js.Array2.length && maybeErrorRef.contents === None {
        let idx = idxRef.contents
        let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
        let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
        let fieldValue = fieldValues->Js.Array2.unsafe_get(idx)
        switch serializeInner(~struct=fieldStruct, ~value=fieldValue, ~mode) {
        | Ok(unknownFieldValue) => {
            unknown->Js.Dict.set(fieldName, unknownFieldValue)
            idxRef.contents = idxRef.contents + 1
          }
        | Error(error) =>
          maybeErrorRef.contents = Some(error->RescriptStruct_Error.prependField(fieldName))
        }
      }

      switch maybeErrorRef.contents {
      | Some(error) => Error(error)
      | None => Ok(unknown)
      }
    }),
  ]

  let innerFactory = fieldsArray => {
    let fields = fieldsArray->Js.Dict.fromArray

    {
      tagged_t: Record({fields: fields, fieldNames: fields->Js.Dict.keys, unknownKeys: Strict}),
      maybeParsers: Some(parsers),
      maybeSerializers: Some(serializers),
      maybeMetadata: None,
    }
  }

  let factory = Inline.Fn.callWithArguments(innerFactory)

  let strip = struct => {
    let tagged_t = struct->classify
    switch tagged_t {
    | Record({fields, fieldNames}) => {
        tagged_t: Record({fields: fields, fieldNames: fieldNames, unknownKeys: Strip}),
        maybeParsers: struct.maybeParsers,
        maybeSerializers: struct.maybeSerializers,
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
        maybeParsers: struct.maybeParsers,
        maybeSerializers: struct.maybeSerializers,
        maybeMetadata: struct.maybeMetadata,
      }
    | _ => RescriptStruct_Error.UnknownKeysRequireRecord.raise()
    }
  }
}

module Never = {
  let parsers = [
    Operation.refinement((~input, ~struct) => {
      Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
    }),
  ]

  let factory = () => {
    tagged_t: Never,
    maybeParsers: Some(parsers),
    maybeSerializers: Some(Operation.empty),
    maybeMetadata: None,
  }
}

module Unknown = {
  let factory = () => {
    tagged_t: Unknown,
    maybeParsers: Some(Operation.empty),
    maybeSerializers: Some(Operation.empty),
    maybeMetadata: None,
  }
}

module String = {
  let parsers = [
    Operation.refinement((~input, ~struct) => {
      switch input->Js.typeof === "string" {
      | true => None
      | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
      }
    }),
  ]
  let serializers = Operation.empty

  let factory = () => {
    tagged_t: String,
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }
}

module Bool = {
  let parsers = [
    Operation.refinement((~input, ~struct) => {
      switch input->Js.typeof === "boolean" {
      | true => None
      | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
      }
    }),
  ]

  let factory = () => {
    tagged_t: Bool,
    maybeParsers: Some(parsers),
    maybeSerializers: Some(Operation.empty),
    maybeMetadata: None,
  }
}

module Int = {
  let parsers = [
    Operation.refinement((~input, ~struct) => {
      switch input->Js.typeof === "number" && checkIsIntNumber(input) {
      | true => None
      | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
      }
    }),
  ]

  let factory = () => {
    tagged_t: Int,
    maybeParsers: Some(parsers),
    maybeSerializers: Some(Operation.empty),
    maybeMetadata: None,
  }
}

module Float = {
  let parsers = [
    Operation.refinement((~input, ~struct) => {
      switch input->Js.typeof === "number" {
      | true => None
      | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
      }
    }),
  ]

  let factory = () => {
    tagged_t: Float,
    maybeParsers: Some(parsers),
    maybeSerializers: Some(Operation.empty),
    maybeMetadata: None,
  }
}

module Null = {
  let parsers = [
    Operation.transform((~input, ~struct, ~mode) => {
      switch input->Js.Null.toOption {
      | Some(innerValue) =>
        let innerStruct = struct->classify->unsafeGetVariantPayload
        parseInner(
          ~struct=innerStruct->unsafeToAny,
          ~any=innerValue,
          ~mode,
        )->Inline.Result.map(value => Some(value))
      | None => Ok(None)
      }
    }),
  ]
  let serializers = [
    Operation.transform((~input, ~struct, ~mode) => {
      switch input {
      | Some(value) =>
        let innerStruct = struct->classify->unsafeGetVariantPayload
        serializeInner(~struct=innerStruct->unsafeToAny, ~value, ~mode)
      | None => Js.Null.empty->unsafeAnyToUnknown->Ok
      }
    }),
  ]

  let factory = innerStruct => {
    tagged_t: Null(innerStruct),
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }
}

module Option = {
  let parsers = [
    Operation.transform((~input, ~struct, ~mode) => {
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
  let serializers = [
    Operation.transform((~input, ~struct, ~mode) => {
      switch input {
      | Some(value) => {
          let innerStruct = struct->classify->unsafeGetVariantPayload
          serializeInner(~struct=innerStruct, ~value, ~mode)
        }
      | None => Ok(None->unsafeAnyToUnknown)
      }
    }),
  ]

  let factory = innerStruct => {
    tagged_t: Option(innerStruct),
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }
}

module Deprecated = {
  type payload<'value> = {struct: t<'value>}

  let parsers = [
    Operation.transform((~input, ~struct, ~mode) => {
      switch input {
      | Some(innerValue) =>
        let {struct: innerStruct} = struct->classify->unsafeToAny
        parseInner(~struct=innerStruct, ~any=innerValue, ~mode)->Inline.Result.map(value => Some(
          value,
        ))
      | None => Ok(None)
      }
    }),
  ]
  let serializers = [
    Operation.transform((~input, ~struct, ~mode) => {
      switch input {
      | Some(value) => {
          let {struct: innerStruct} = struct->classify->unsafeToAny
          serializeInner(~struct=innerStruct, ~value, ~mode)
        }
      | None => Ok(None->unsafeAnyToUnknown)
      }
    }),
  ]

  let factory = (~message as maybeMessage=?, innerStruct) => {
    tagged_t: Deprecated({struct: innerStruct, maybeMessage: maybeMessage}),
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }
}

module Array = {
  let parsers = [
    Operation.transform((~input, ~struct, ~mode) => {
      let maybeRefinementError = switch mode {
      | Safe =>
        switch Js.Array2.isArray(input) {
        | true => None
        | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
        }
      | Unsafe => None
      }
      switch maybeRefinementError {
      | None => {
          let innerStruct = struct->classify->unsafeGetVariantPayload

          let newArray = []
          let idxRef = ref(0)
          let maybeErrorRef = ref(None)
          while idxRef.contents < input->Js.Array2.length && maybeErrorRef.contents === None {
            let idx = idxRef.contents
            let innerValue = input->Js.Array2.unsafe_get(idx)
            switch parseInner(~struct=innerStruct, ~any=innerValue, ~mode) {
            | Ok(value) => {
                newArray->Js.Array2.push(value)->ignore
                idxRef.contents = idxRef.contents + 1
              }
            | Error(error) =>
              maybeErrorRef.contents = Some(error->RescriptStruct_Error.prependIndex(idx))
            }
          }
          switch maybeErrorRef.contents {
          | Some(error) => Error(error)
          | None => Ok(newArray)
          }
        }
      | Some(error) => Error(error)
      }
    }),
  ]
  let serializers = [
    Operation.transform((~input, ~struct, ~mode) => {
      let innerStruct = struct->classify->unsafeGetVariantPayload

      let newArray = []
      let idxRef = ref(0)
      let maybeErrorRef = ref(None)
      while idxRef.contents < input->Js.Array2.length && maybeErrorRef.contents === None {
        let idx = idxRef.contents
        let innerValue = input->Js.Array2.unsafe_get(idx)
        switch serializeInner(~struct=innerStruct, ~value=innerValue, ~mode) {
        | Ok(value) => {
            newArray->Js.Array2.push(value)->ignore
            idxRef.contents = idxRef.contents + 1
          }
        | Error(error) =>
          maybeErrorRef.contents = Some(error->RescriptStruct_Error.prependIndex(idx))
        }
      }
      switch maybeErrorRef.contents {
      | Some(error) => Error(error)
      | None => Ok(newArray)
      }
    }),
  ]

  let factory = innerStruct => {
    tagged_t: Array(innerStruct),
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }
}

module Dict = {
  let parsers = [
    Operation.transform((~input, ~struct, ~mode) => {
      let maybeRefinementError = switch mode {
      | Safe =>
        switch input->getInternalClass === "[object Object]" {
        | true => None
        | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
        }
      | Unsafe => None
      }
      switch maybeRefinementError {
      | None => {
          let innerStruct = struct->classify->unsafeGetVariantPayload

          let newDict = Js.Dict.empty()
          let keys = input->Js.Dict.keys
          let idxRef = ref(0)
          let maybeErrorRef = ref(None)
          while idxRef.contents < keys->Js.Array2.length && maybeErrorRef.contents === None {
            let idx = idxRef.contents
            let key = keys->Js.Array2.unsafe_get(idx)
            let innerValue = input->Js.Dict.unsafeGet(key)
            switch parseInner(~struct=innerStruct, ~any=innerValue, ~mode) {
            | Ok(value) => {
                newDict->Js.Dict.set(key, value)->ignore
                idxRef.contents = idxRef.contents + 1
              }
            | Error(error) =>
              maybeErrorRef.contents = Some(error->RescriptStruct_Error.prependField(key))
            }
          }
          switch maybeErrorRef.contents {
          | Some(error) => Error(error)
          | None => Ok(newDict)
          }
        }
      | Some(error) => Error(error)
      }
    }),
  ]
  let serializers = [
    Operation.transform((~input, ~struct, ~mode) => {
      let innerStruct = struct->classify->unsafeGetVariantPayload

      let newDict = Js.Dict.empty()
      let keys = input->Js.Dict.keys
      let idxRef = ref(0)
      let maybeErrorRef = ref(None)
      while idxRef.contents < keys->Js.Array2.length && maybeErrorRef.contents === None {
        let idx = idxRef.contents
        let key = keys->Js.Array2.unsafe_get(idx)
        let innerValue = input->Js.Dict.unsafeGet(key)
        switch serializeInner(~struct=innerStruct, ~value=innerValue, ~mode) {
        | Ok(value) => {
            newDict->Js.Dict.set(key, value)->ignore
            idxRef.contents = idxRef.contents + 1
          }
        | Error(error) =>
          maybeErrorRef.contents = Some(error->RescriptStruct_Error.prependField(key))
        }
      }
      switch maybeErrorRef.contents {
      | Some(error) => Error(error)
      | None => Ok(newDict)
      }
    }),
  ]

  let factory = innerStruct => {
    tagged_t: Dict(innerStruct),
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }
}

module Default = {
  type payload<'value> = {struct: t<option<'value>>, value: 'value}

  let parsers = [
    Operation.transform((~input, ~struct, ~mode) => {
      let {struct: innerStruct, value} = struct->classify->unsafeToAny
      parseInner(~struct=innerStruct, ~any=input, ~mode)->Inline.Result.map(maybeOutput => {
        switch maybeOutput {
        | Some(output) => output
        | None => value
        }
      })
    }),
  ]
  let serializers = [
    Operation.transform((~input, ~struct, ~mode) => {
      let {struct: innerStruct} = struct->classify->unsafeToAny
      serializeInner(~struct=innerStruct, ~value=Some(input), ~mode)
    }),
  ]

  let factory = (innerStruct, defaultValue) => {
    tagged_t: Default({struct: innerStruct, value: defaultValue}),
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }
}

module Tuple = {
  let parsers = [
    Operation.transform((~input, ~struct, ~mode) => {
      let innerStructs = struct->classify->unsafeGetVariantPayload
      let numberOfStructs = innerStructs->Js.Array2.length
      let maybeRefinementError = switch mode {
      | Safe =>
        switch Js.Array2.isArray(input) {
        | true =>
          let numberOfInputItems = input->Js.Array2.length
          switch numberOfStructs === numberOfInputItems {
          | true => None
          | false =>
            Some(
              RescriptStruct_Error.ParsingFailed.make(
                `Expected Tuple with ${numberOfStructs->Js.Int.toString} items, but received ${numberOfInputItems->Js.Int.toString}`,
              ),
            )
          }
        | false => Some(makeUnexpectedTypeError(~input, ~struct, ~operation=Parsing))
        }
      | Unsafe => None
      }
      switch maybeRefinementError {
      | None => {
          let newArray = []
          let idxRef = ref(0)
          let maybeErrorRef = ref(None)
          while idxRef.contents < numberOfStructs && maybeErrorRef.contents === None {
            let idx = idxRef.contents
            let innerValue = input->Js.Array2.unsafe_get(idx)
            let innerStruct = innerStructs->Js.Array2.unsafe_get(idx)
            switch parseInner(~struct=innerStruct, ~any=innerValue, ~mode) {
            | Ok(value) => {
                newArray->Js.Array2.push(value)->ignore
                idxRef.contents = idxRef.contents + 1
              }
            | Error(error) =>
              maybeErrorRef.contents = Some(error->RescriptStruct_Error.prependIndex(idx))
            }
          }
          switch maybeErrorRef.contents {
          | Some(error) => Error(error)
          | None =>
            switch numberOfStructs {
            | 0 => ()->unsafeToAny
            | 1 => newArray->Js.Array2.unsafe_get(0)->unsafeToAny
            | _ => newArray
            }->Ok
          }
        }
      | Some(error) => Error(error)
      }
    }),
  ]

  let serializers = [
    Operation.transform((~input, ~struct, ~mode) => {
      let innerStructs = struct->classify->unsafeGetVariantPayload
      let numberOfStructs = innerStructs->Js.Array2.length
      let inputArray = numberOfStructs === 1 ? [input->unsafeToAny] : input

      let newArray = []
      let idxRef = ref(0)
      let maybeErrorRef = ref(None)
      while idxRef.contents < numberOfStructs && maybeErrorRef.contents === None {
        let idx = idxRef.contents
        let innerValue = inputArray->Js.Array2.unsafe_get(idx)
        let innerStruct = innerStructs->Js.Array.unsafe_get(idx)
        switch serializeInner(~struct=innerStruct, ~value=innerValue, ~mode) {
        | Ok(value) => {
            newArray->Js.Array2.push(value)->ignore
            idxRef.contents = idxRef.contents + 1
          }
        | Error(error) =>
          maybeErrorRef.contents = Some(error->RescriptStruct_Error.prependIndex(idx))
        }
      }
      switch maybeErrorRef.contents {
      | Some(error) => Error(error)
      | None => Ok(newArray)
      }
    }),
  ]

  let innerFactory = structs => {
    {
      tagged_t: Tuple(structs),
      maybeParsers: Some(parsers),
      maybeSerializers: Some(serializers),
      maybeMetadata: None,
    }
  }

  let factory = Inline.Fn.callWithArguments(innerFactory)
}

module Union = {
  let parsers = [
    Operation.transform((~input, ~struct, ~mode as _) => {
      let innerStructs = struct->classify->unsafeGetVariantPayload

      let idxRef = ref(0)
      let maybeLastErrorRef = ref(None)
      let maybeOkRef = ref(None)
      while idxRef.contents < innerStructs->Js.Array2.length && maybeOkRef.contents === None {
        let idx = idxRef.contents
        let innerStruct = innerStructs->Js.Array2.unsafe_get(idx)
        switch parseInner(~struct=innerStruct, ~any=input, ~mode=Safe) {
        | Ok(_) as ok => maybeOkRef.contents = Some(ok)
        | Error(_) as error => {
            maybeLastErrorRef.contents = Some(error)
            idxRef.contents = idxRef.contents + 1
          }
        }
      }
      switch maybeOkRef.contents {
      | Some(ok) => ok
      | None =>
        switch maybeLastErrorRef.contents {
        | Some(error) => error
        | None => %raw(`undefined`)
        }
      }
    }),
  ]

  let serializers = [
    Operation.transform((~input, ~struct, ~mode as _) => {
      let innerStructs = struct->classify->unsafeGetVariantPayload

      let idxRef = ref(0)
      let maybeLastErrorRef = ref(None)
      let maybeOkRef = ref(None)
      while idxRef.contents < innerStructs->Js.Array2.length && maybeOkRef.contents === None {
        let idx = idxRef.contents
        let innerStruct = innerStructs->Js.Array2.unsafe_get(idx)
        switch serializeInner(~struct=innerStruct, ~value=input, ~mode=Safe) {
        | Ok(_) as ok => maybeOkRef.contents = Some(ok)
        | Error(_) as error => {
            maybeLastErrorRef.contents = Some(error)
            idxRef.contents = idxRef.contents + 1
          }
        }
      }
      switch maybeOkRef.contents {
      | Some(ok) => ok
      | None =>
        switch maybeLastErrorRef.contents {
        | Some(error) => error
        | None => %raw(`undefined`)
        }
      }
    }),
  ]

  let factory = structs => {
    if structs->Js.Array2.length < 2 {
      RescriptStruct_Error.UnionLackingStructs.raise()
    }

    {
      tagged_t: Union(structs),
      maybeParsers: Some(parsers),
      maybeSerializers: Some(serializers),
      maybeMetadata: None,
    }
  }
}

let record0 = Record.factory
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
let never = Never.factory
let unknown = Unknown.factory
let string = String.factory
let bool = Bool.factory
let int = Int.factory
let float = Float.factory
let null = Null.factory
let option = Option.factory
let deprecated = Deprecated.factory
let array = Array.factory
let dict = Dict.factory
let default = Default.factory
let literal = Literal.factory
let literalVariant = Literal.Variant.factory
let literalUnit = Literal.Unit.factory
let tuple0 = Tuple.factory
let tuple1 = Tuple.factory
let tuple2 = Tuple.factory
let tuple3 = Tuple.factory
let tuple4 = Tuple.factory
let tuple5 = Tuple.factory
let tuple6 = Tuple.factory
let tuple7 = Tuple.factory
let tuple8 = Tuple.factory
let tuple9 = Tuple.factory
let tuple10 = Tuple.factory
let union = Union.factory

let json = struct => {
  tagged_t: String,
  maybeParsers: Some(
    Js.Array2.concat(
      String.parsers,
      [
        Operation.transform((~input, ~struct as _, ~mode) => {
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
  maybeSerializers: Some(
    Js.Array2.concat(
      [
        Operation.transform((~input, ~struct as _, ~mode) => {
          serializeInner(~struct, ~value=input, ~mode)->Inline.Result.map(unknown =>
            unknown->unsafeUnknownToAny->Js.Json.stringify
          )
        }),
      ],
      String.serializers,
    ),
  ),
  maybeMetadata: None,
}

let refine = (
  struct,
  ~parser as maybeParserRefine=?,
  ~serializer as maybeSerializerRefine=?,
  (),
) => {
  if maybeParserRefine === None && maybeSerializerRefine === None {
    RescriptStruct_Error.MissingParserAndSerializer.raise(`struct factory Refine`)
  }

  {
    tagged_t: struct.tagged_t,
    maybeMetadata: struct.maybeMetadata,
    maybeParsers: switch (struct.maybeParsers, maybeParserRefine) {
    | (Some(parsers), Some(parserRefine)) =>
      parsers
      ->Js.Array2.concat([
        Operation.refinement((~input, ~struct as _) => {
          (parserRefine->unsafeToAny)(. input)->Inline.Option.map(
            RescriptStruct_Error.ParsingFailed.make,
          )
        }),
      ])
      ->Some
    | (_, _) => None
    },
    maybeSerializers: switch (struct.maybeSerializers, maybeSerializerRefine) {
    | (Some(serializers), Some(serializerRefine)) =>
      [
        Operation.refinement((~input, ~struct as _) => {
          (serializerRefine->unsafeToAny)(. input)->Inline.Option.map(
            RescriptStruct_Error.SerializingFailed.make,
          )
        }),
      ]
      ->Js.Array2.concat(serializers)
      ->Some
    | (_, _) => None
    },
  }
}

let transform = (
  struct,
  ~parser as maybeTransformationParser=?,
  ~serializer as maybeTransformationSerializer=?,
  (),
) => {
  if maybeTransformationParser === None && maybeTransformationSerializer === None {
    RescriptStruct_Error.MissingParserAndSerializer.raise(`struct factory Transform`)
  }

  {
    tagged_t: struct.tagged_t,
    maybeMetadata: struct.maybeMetadata,
    maybeParsers: switch (struct.maybeParsers, maybeTransformationParser) {
    | (Some(parsers), Some(transformationParser)) =>
      parsers
      ->Js.Array2.concat([
        Operation.transform((~input, ~struct as _, ~mode as _) => {
          (transformationParser->unsafeToAny)(. input)->Inline.Result.mapError(
            RescriptStruct_Error.ParsingFailed.make,
          )
        }),
      ])
      ->Some
    | (_, _) => None
    },
    maybeSerializers: switch (struct.maybeSerializers, maybeTransformationSerializer) {
    | (Some(serializers), Some(transformationSerializer)) =>
      [
        Operation.transform((~input, ~struct as _, ~mode as _) => {
          (transformationSerializer->unsafeToAny)(. input)->Inline.Result.mapError(
            RescriptStruct_Error.SerializingFailed.make,
          )
        }),
      ]
      ->Js.Array2.concat(serializers)
      ->Some
    | (_, _) => None
    },
  }
}
let transformUnknown = transform

module MakeMetadata = (
  Config: {
    type content
    let namespace: string
  },
) => {
  let get = (struct): option<Config.content> => {
    struct.maybeMetadata->Inline.Option.map(metadata => {
      metadata->Js.Dict.get(Config.namespace)->unsafeToAny
    })
  }

  let dictUnsafeSet = (dict: Js.Dict.t<'any>, key: string, value: 'any): Js.Dict.t<'any> => {
    ignore(dict)
    ignore(key)
    ignore(value)
    %raw(`{
      ...dict,
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
      maybeParsers: struct.maybeParsers,
      maybeSerializers: struct.maybeSerializers,
      maybeMetadata: Some(
        existingContent->dictUnsafeSet(Config.namespace, content->unsafeAnyToUnknown),
      ),
    }
  }
}
