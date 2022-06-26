type never
type unknown

module Lib = {
  module Factory = {
    type t

    external fromUnknown: unknown => t = "%identity"

    @get external getName: t => string = "name"

    let factoryOf = (self: t, data: 'a): bool => {
      self->ignore
      data->ignore
      %raw(`data instanceof self`)
    }
  }

  module Url = {
    type t

    @new
    external make: string => t = "URL"

    @inline
    let test = string => {
      try {
        make(string)->ignore
        true
      } catch {
      | _ => false
      }
    }
  }

  module Fn = {
    let callWithArguments = fn => {
      fn->ignore
      %raw(`function(){return fn(arguments)}`)
    }
  }

  module Array = {
    @inline
    let toTuple = array =>
      array->Js.Array2.length <= 1 ? array->Js.Array2.unsafe_get(0)->Obj.magic : array->Obj.magic
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

  module Int = {
    @inline
    let plus = (int1: int, int2: int): int => {
      (int1->Js.Int.toFloat +. int2->Js.Int.toFloat)->Obj.magic
    }
  }
}

module Error = {
  %%raw(`class RescriptStructError extends Error {
    constructor(message) {
      super(message);
      this.name = "RescriptStructError";
    }
  }`)

  let raise = %raw(`function(message){
    throw new RescriptStructError(message);
  }`)

  type operation =
    | Serializing
    | Parsing
  type code =
    | OperationFailed(string)
    | MissingParser
    | MissingSerializer
    | UnexpectedType({expected: string, received: string})
    | UnexpectedValue({expected: string, received: string})
    | TupleSize({expected: int, received: int})
    | ExcessField(string)
  type t = {operation: operation, code: code, path: array<string>}

  module Internal = {
    type public = t
    type t = {
      @as("c")
      code: code,
      @as("p")
      path: array<string>,
    }

    @inline
    let make = code => {
      {code: code, path: []}
    }

    let toParseError = (self: t): public => {
      {operation: Parsing, code: self.code, path: self.path}
    }

    let toSerializeError = (self: t): public => {
      {operation: Serializing, code: self.code, path: self.path}
    }

    let fromPublic = (public: public): t => {
      {code: public.code, path: public.path}
    }

    let prependLocation = (error, location) => {
      {
        ...error,
        path: [location]->Js.Array2.concat(error.path),
      }
    }

    module UnexpectedValue = {
      let stringify = any => {
        switch any->Obj.magic {
        | Some(value) =>
          switch value->Js.Json.stringifyAny {
          | Some(string) => string
          | None => "???"
          }
        | None => "undefined"
        }
      }
      let make = (~expected, ~received) => {
        make(
          UnexpectedValue({
            expected: expected->stringify,
            received: received->stringify,
          }),
        )
      }
    }
  }

  module MissingParserAndSerializer = {
    let raise = location => raise(`For a ${location} either a parser, or a serializer is required`)
  }

  module UnknownKeysRequireRecord = {
    let raise = () => raise("Can't set up unknown keys strategy. The struct is not Record")
  }

  module UnionLackingStructs = {
    let raise = () => raise("A Union struct factory require at least two structs")
  }

  let formatPath = path => {
    if path->Js.Array2.length === 0 {
      "root"
    } else {
      path->Js.Array2.map(pathItem => `[${pathItem}]`)->Js.Array2.joinWith("")
    }
  }

  let prependLocation = (error, location) => {
    {
      ...error,
      path: [location]->Js.Array2.concat(error.path),
    }
  }

  let make = reason => {
    {
      // This function is only needed for super<Transform/Refine>, so operation doesn't matter
      operation: Parsing,
      code: OperationFailed(reason),
      path: [],
    }
  }

  let toString = error => {
    let prefix = `[ReScript Struct]`
    let operation = switch error.operation {
    | Serializing => "serializing"
    | Parsing => "parsing"
    }
    let pathText = error.path->formatPath
    let reason = switch error.code {
    | OperationFailed(reason) => reason
    | MissingParser => "Struct parser is missing"
    | MissingSerializer => "Struct serializer is missing"
    | ExcessField(fieldName) =>
      `Encountered disallowed excess key "${fieldName}" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely`
    | UnexpectedType({expected, received})
    | UnexpectedValue({expected, received}) =>
      `Expected ${expected}, received ${received}`
    | TupleSize({expected, received}) =>
      `Expected Tuple with ${expected->Js.Int.toString} items, received ${received->Js.Int.toString}`
    }
    `${prefix} Failed ${operation} at ${pathText}. Reason: ${reason}`
  }
}

type rec literal<'value> =
  | String(string): literal<string>
  | Int(int): literal<int>
  | Float(float): literal<float>
  | Bool(bool): literal<bool>
  | EmptyNull: literal<unit>
  | EmptyOption: literal<unit>
  | NaN: literal<unit>

type operation =
  | Serializing
  | Parsing
type mode = Safe | Unsafe
type recordUnknownKeys =
  | Strict
  | Strip

type rec t<'value> = {
  @as("t")
  tagged_t: tagged_t,
  @as("p")
  maybeParsers: option<effectsMap>,
  @as("s")
  maybeSerializers: option<effectsMap>,
  @as("m")
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
  | Instance(unknown): tagged_t
and field<'value> = (string, t<'value>)
and effectsMap = {
  @as("s")
  safe: array<effect>,
  @as("u")
  unsafe: array<effect>,
}
and effect = (. ~unknown: unknown, ~struct: t<unknown>, ~mode: mode) => effectResult<unknown>
and effectResult<'value> = Refined | Transformed('value) | Failed(Error.Internal.t)

external unsafeAnyToUnknown: 'any => unknown = "%identity"
external unsafeUnknownToAny: unknown => 'any = "%identity"

type payloadedVariant<'payload> = {_0: 'payload}
@inline
let unsafeGetVariantPayload: 'a => 'payload = v => (v->Obj.magic)._0

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
      | NaN => `NaN Literal (NaN)`
      }
    | Option(_) => "Option"
    | Null(_) => "Null"
    | Array(_) => "Array"
    | Tuple(_) => "Tuple"
    | Record(_) => "Record"
    | Dict(_) => "Dict"
    | Deprecated(_) => "Deprecated"
    | Default(_) => "Default"
    | Instance(instance) => `Instance (${instance->Lib.Factory.fromUnknown->Lib.Factory.getName})`
    }
  }
}

let makeUnexpectedTypeError = (~input: 'any, ~struct: t<'any2>) => {
  let typesTagged = input->Js.Types.classify
  let structTagged = struct->classify
  let received = switch typesTagged {
  | JSFalse | JSTrue => "Bool"
  | JSString(_) => "String"
  | JSNull => "Null"
  | JSNumber(number) if Js.Float.isNaN(number) => "NaN Literal (NaN)"
  | JSNumber(_) => "Float"
  | JSObject(_) => "Object"
  | JSFunction(_) => "Function"
  | JSUndefined => "Option"
  | JSSymbol(_) => "Symbol"
  }
  let expected = TaggedT.toString(structTagged)
  Error.Internal.make(UnexpectedType({expected: expected, received: received}))
}

@inline
let checkIsIntNumber = x => x < 2147483648. && x > -2147483649. && x === x->Js.Math.trunc

let processInner = (~operation: operation, ~input: 'input, ~mode: mode, ~struct: t<'value>) => {
  let maybeEffectsMap = switch operation {
  | Parsing => struct.maybeParsers
  | Serializing => struct.maybeSerializers
  }
  switch maybeEffectsMap {
  | Some(effectsMap) => {
      let effects = switch mode {
      | Safe => effectsMap.safe
      | Unsafe => effectsMap.unsafe
      }

      let idxRef = ref(0)
      let valueRef = ref(input->Obj.magic)
      let maybeErrorRef = ref(None)
      while idxRef.contents < effects->Js.Array2.length && maybeErrorRef.contents === None {
        let effect = effects->Js.Array2.unsafe_get(idxRef.contents)
        switch effect(. ~unknown=valueRef.contents, ~struct=struct->Obj.magic, ~mode) {
        | Refined => idxRef.contents = idxRef.contents->Lib.Int.plus(1)
        | Transformed(newValue) => {
            valueRef.contents = newValue
            idxRef.contents = idxRef.contents->Lib.Int.plus(1)
          }
        | Failed(error) => maybeErrorRef.contents = Some(error)
        }
      }
      switch maybeErrorRef.contents {
      | Some(error) => Error(error)
      | None => Ok(valueRef.contents->Obj.magic)
      }
    }
  | None =>
    switch operation {
    | Parsing => Error(Error.Internal.make(MissingParser))
    | Serializing => Error(Error.Internal.make(MissingSerializer))
    }
  }
}

@inline
let parseInner: (
  ~struct: t<'value>,
  ~any: 'any,
  ~mode: mode,
) => result<'value, Error.Internal.t> = (~struct, ~any, ~mode) => {
  processInner(~operation=Parsing, ~input=any, ~mode, ~struct)
}

let parseWith = (any, ~mode=Safe, struct) => {
  parseInner(~struct, ~any, ~mode)->Lib.Result.mapError(internalError =>
    internalError->Error.Internal.toParseError
  )
}

@inline
let serializeInner: (
  ~struct: t<'value>,
  ~value: 'value,
  ~mode: mode,
) => result<unknown, Error.Internal.t> = (~struct, ~value, ~mode) => {
  processInner(~operation=Serializing, ~input=value, ~mode, ~struct)
}

let serializeWith = (value, ~mode=Safe, struct) => {
  serializeInner(~struct, ~value, ~mode)->Lib.Result.mapError(internalError =>
    internalError->Error.Internal.toSerializeError
  )
}

module Effect = {
  external make: (
    (~input: 'input, ~struct: t<'value>, ~mode: mode) => effectResult<'newValue>
  ) => effect = "%identity"

  external fromResult: result<'newValue, Error.Internal.t> => effectResult<'newValue> = "%identity"

  let emptyArray: array<effect> = []
  let emptyMap: effectsMap = {safe: emptyArray, unsafe: emptyArray}

  let concatParser = (effects, effect) => {
    effects->Js.Array2.concat([effect])
  }

  let concatSerializer = (effects, effect) => {
    [effect]->Js.Array2.concat(effects)
  }
}

let refine: (
  t<'value>,
  ~parser: 'value => option<string>=?,
  ~serializer: 'value => option<string>=?,
  unit,
) => t<'value> = (
  struct,
  ~parser as maybeRefineParser=?,
  ~serializer as maybeRefineSerializer=?,
  (),
) => {
  if maybeRefineParser === None && maybeRefineSerializer === None {
    Error.MissingParserAndSerializer.raise(`struct factory Refine`)
  }

  {
    ...struct,
    maybeParsers: switch (struct.maybeParsers, maybeRefineParser) {
    | (Some(parsers), Some(refineParser)) =>
      {
        let effect = Effect.make((~input, ~struct as _, ~mode as _) => {
          switch (refineParser->Obj.magic)(. input) {
          | None => Refined
          | Some(reason) => Failed(Error.Internal.make(OperationFailed(reason)))
          }
        })
        {
          ...parsers,
          safe: parsers.safe->Effect.concatParser(effect),
        }
      }->Some
    | (_, _) => None
    },
    maybeSerializers: switch (struct.maybeSerializers, maybeRefineSerializer) {
    | (Some(serializers), Some(refineSerializer)) =>
      {
        let effect = Effect.make((~input, ~struct as _, ~mode as _) => {
          switch (refineSerializer->Obj.magic)(. input) {
          | None => Refined
          | Some(reason) => Failed(Error.Internal.make(OperationFailed(reason)))
          }
        })
        {
          ...serializers,
          safe: serializers.safe->Effect.concatSerializer(effect),
        }
      }->Some
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
    Error.MissingParserAndSerializer.raise(`struct factory Transform`)
  }

  {
    ...struct,
    maybeParsers: switch (struct.maybeParsers, maybeTransformationParser) {
    | (Some(parsers), Some(transformationParser)) =>
      {
        let effect = Effect.make((~input, ~struct as _, ~mode as _) => {
          switch (transformationParser->Obj.magic)(. input) {
          | Ok(_) as ok => ok->Effect.fromResult
          | Error(reason) => Failed(Error.Internal.make(OperationFailed(reason)))
          }
        })
        {
          unsafe: parsers.unsafe->Effect.concatParser(effect),
          safe: parsers.safe->Effect.concatParser(effect),
        }
      }->Some
    | (_, _) => None
    },
    maybeSerializers: switch (struct.maybeSerializers, maybeTransformationSerializer) {
    | (Some(serializers), Some(transformationSerializer)) =>
      {
        let effect = Effect.make((~input, ~struct as _, ~mode as _) => {
          switch (transformationSerializer->Obj.magic)(. input) {
          | Ok(_) as ok => ok->Effect.fromResult
          | Error(reason) => Failed(Error.Internal.make(OperationFailed(reason)))
          }
        })
        {
          unsafe: serializers.unsafe->Effect.concatSerializer(effect),
          safe: serializers.safe->Effect.concatSerializer(effect),
        }
      }->Some
    | (_, _) => None
    },
  }
}

let superTransform = (
  struct,
  ~parser as maybeTransformationParser=?,
  ~serializer as maybeTransformationSerializer=?,
  (),
) => {
  if maybeTransformationParser === None && maybeTransformationSerializer === None {
    Error.MissingParserAndSerializer.raise(`struct factory Transform`)
  }

  {
    ...struct,
    maybeParsers: switch (struct.maybeParsers, maybeTransformationParser) {
    | (Some(parsers), Some(transformationParser)) =>
      {
        let effect = Effect.make((~input, ~struct, ~mode) => {
          switch transformationParser(. ~value=input, ~struct, ~mode) {
          | Ok(_) as ok => ok->Effect.fromResult
          | Error(public) => Failed(public->Error.Internal.fromPublic)
          }
        })
        {
          unsafe: parsers.unsafe->Effect.concatParser(effect),
          safe: parsers.safe->Effect.concatParser(effect),
        }
      }->Some
    | (_, _) => None
    },
    maybeSerializers: switch (struct.maybeSerializers, maybeTransformationSerializer) {
    | (Some(serializers), Some(transformationSerializer)) =>
      {
        let effect = Effect.make((~input, ~struct, ~mode) => {
          switch transformationSerializer(. ~transformed=input, ~struct, ~mode) {
          | Ok(_) as ok => ok->Effect.fromResult
          | Error(public) => Failed(public->Error.Internal.fromPublic)
          }
        })
        {
          unsafe: serializers.unsafe->Effect.concatSerializer(effect),
          safe: serializers.safe->Effect.concatSerializer(effect),
        }
      }->Some
    | (_, _) => None
    },
  }
}

let custom = (~parser as maybeCustomParser=?, ~serializer as maybeCustomSerializer=?, ()) => {
  if maybeCustomParser === None && maybeCustomSerializer === None {
    Error.MissingParserAndSerializer.raise(`Custom struct factory`)
  }

  {
    tagged_t: Unknown,
    maybeMetadata: None,
    maybeParsers: maybeCustomParser->Lib.Option.map(customParser => {
      let effects = [
        Effect.make((~input, ~struct as _, ~mode) => {
          switch customParser(. ~unknown=input, ~mode) {
          | Ok(_) as ok => ok->Effect.fromResult
          | Error(public) => Failed(public->Error.Internal.fromPublic)
          }
        }),
      ]
      {
        safe: effects,
        unsafe: effects,
      }
    }),
    maybeSerializers: maybeCustomSerializer->Lib.Option.map(customSerializer => {
      let effects = [
        Effect.make((~input, ~struct as _, ~mode) => {
          switch customSerializer(. ~value=input, ~mode) {
          | Ok(_) as ok => ok->Effect.fromResult
          | Error(public) => Failed(public->Error.Internal.fromPublic)
          }
        }),
      ]
      {
        safe: effects,
        unsafe: effects,
      }
    }),
  }
}

module Literal = {
  module CommonOperations = {
    module Parser = {
      let literalValueRefinement = Effect.make((~input, ~struct, ~mode as _) => {
        let expectedValue = struct->classify->unsafeGetVariantPayload->unsafeGetVariantPayload
        switch expectedValue === input {
        | true => Refined
        | false =>
          Failed(Error.Internal.UnexpectedValue.make(~expected=expectedValue, ~received=input))
        }
      })
    }

    let transformToLiteralValue = Effect.make((~input as _, ~struct, ~mode as _) => {
      let literalValue = struct->classify->unsafeGetVariantPayload->unsafeGetVariantPayload
      Transformed(literalValue)
    })
  }

  module EmptyNull = {
    let parserRefinement = Effect.make((~input, ~struct, ~mode as _) => {
      switch input === Js.Null.empty {
      | true => Refined
      | false => Failed(makeUnexpectedTypeError(~input, ~struct))
      }
    })

    let serializerTransform = Effect.make((~input as _, ~struct as _, ~mode as _) => {
      Transformed(Js.Null.empty)
    })
  }

  module EmptyOption = {
    let parserRefinement = Effect.make((~input, ~struct, ~mode as _) => {
      switch input === Js.Undefined.empty {
      | true => Refined
      | false => Failed(makeUnexpectedTypeError(~input, ~struct))
      }
    })

    let serializerTransform = Effect.make((~input as _, ~struct as _, ~mode as _) => {
      Transformed(Js.Undefined.empty)
    })
  }

  module NaN = {
    let parserRefinement = Effect.make((~input, ~struct, ~mode as _) => {
      switch Js.Float.isNaN(input) {
      | true => Refined
      | false => Failed(makeUnexpectedTypeError(~input, ~struct))
      }
    })

    let serializerTransform = Effect.make((~input as _, ~struct as _, ~mode as _) => {
      Transformed(Js.Float._NaN)
    })
  }

  module Bool = {
    let parserRefinement = Effect.make((~input, ~struct, ~mode as _) => {
      switch input->Js.typeof === "boolean" {
      | true => Refined
      | false => Failed(makeUnexpectedTypeError(~input, ~struct))
      }
    })
  }

  module String = {
    let parserRefinement = Effect.make((~input, ~struct, ~mode as _) => {
      switch input->Js.typeof === "string" {
      | true => Refined
      | false => Failed(makeUnexpectedTypeError(~input, ~struct))
      }
    })
  }

  module Float = {
    let parserRefinement = Effect.make((~input, ~struct, ~mode as _) => {
      switch input->Js.typeof === "number" {
      | true => Refined
      | false => Failed(makeUnexpectedTypeError(~input, ~struct))
      }
    })
  }

  module Int = {
    let parserRefinement = Effect.make((~input, ~struct, ~mode as _) => {
      switch input->Js.typeof === "number" && checkIsIntNumber(input) {
      | true => Refined
      | false => Failed(makeUnexpectedTypeError(~input, ~struct))
      }
    })
  }

  module Variant = {
    let factory:
      type literalValue variant. (literal<literalValue>, variant) => t<variant> =
      (innerLiteral, variant) => {
        let tagged_t = Literal(innerLiteral)
        let parserTransform = Effect.make((~input as _, ~struct as _, ~mode as _) => {
          Transformed(variant)
        })
        let serializerRefinement = Effect.make((~input, ~struct as _, ~mode as _) => {
          switch input === variant {
          | true => Refined
          | false =>
            Failed(
              Error.Internal.UnexpectedValue.make(
                ~expected=variant->Obj.magic,
                ~received=input->Obj.magic,
              ),
            )
          }
        })
        switch innerLiteral {
        | EmptyNull => {
            tagged_t: tagged_t,
            maybeParsers: Some({
              safe: [EmptyNull.parserRefinement, parserTransform],
              unsafe: [parserTransform],
            }),
            maybeSerializers: Some({
              safe: [serializerRefinement, EmptyNull.serializerTransform],
              unsafe: [EmptyNull.serializerTransform],
            }),
            maybeMetadata: None,
          }
        | EmptyOption => {
            tagged_t: tagged_t,
            maybeParsers: Some({
              safe: [EmptyOption.parserRefinement, parserTransform],
              unsafe: [parserTransform],
            }),
            maybeSerializers: Some({
              safe: [serializerRefinement, EmptyOption.serializerTransform],
              unsafe: [EmptyOption.serializerTransform],
            }),
            maybeMetadata: None,
          }
        | NaN => {
            tagged_t: tagged_t,
            maybeParsers: Some({
              safe: [NaN.parserRefinement, parserTransform],
              unsafe: [parserTransform],
            }),
            maybeSerializers: Some({
              safe: [serializerRefinement, NaN.serializerTransform],
              unsafe: [NaN.serializerTransform],
            }),
            maybeMetadata: None,
          }
        | Bool(_) => {
            tagged_t: tagged_t,
            maybeParsers: Some({
              safe: [
                Bool.parserRefinement,
                CommonOperations.Parser.literalValueRefinement,
                parserTransform,
              ],
              unsafe: [parserTransform],
            }),
            maybeSerializers: Some({
              safe: [serializerRefinement, CommonOperations.transformToLiteralValue],
              unsafe: [CommonOperations.transformToLiteralValue],
            }),
            maybeMetadata: None,
          }
        | String(_) => {
            tagged_t: tagged_t,
            maybeParsers: Some({
              safe: [
                String.parserRefinement,
                CommonOperations.Parser.literalValueRefinement,
                parserTransform,
              ],
              unsafe: [parserTransform],
            }),
            maybeSerializers: Some({
              safe: [serializerRefinement, CommonOperations.transformToLiteralValue],
              unsafe: [CommonOperations.transformToLiteralValue],
            }),
            maybeMetadata: None,
          }
        | Float(_) => {
            tagged_t: tagged_t,
            maybeParsers: Some({
              safe: [
                Float.parserRefinement,
                CommonOperations.Parser.literalValueRefinement,
                parserTransform,
              ],
              unsafe: [parserTransform],
            }),
            maybeSerializers: Some({
              safe: [serializerRefinement, CommonOperations.transformToLiteralValue],
              unsafe: [CommonOperations.transformToLiteralValue],
            }),
            maybeMetadata: None,
          }
        | Int(_) => {
            tagged_t: tagged_t,
            maybeParsers: Some({
              safe: [
                Int.parserRefinement,
                CommonOperations.Parser.literalValueRefinement,
                parserTransform,
              ],
              unsafe: [parserTransform],
            }),
            maybeSerializers: Some({
              safe: [serializerRefinement, CommonOperations.transformToLiteralValue],
              unsafe: [CommonOperations.transformToLiteralValue],
            }),
            maybeMetadata: None,
          }
        }
      }
  }

  let factory:
    type value. literal<value> => t<value> =
    innerLiteral => {
      switch innerLiteral {
      | EmptyNull => Variant.factory(innerLiteral, ())
      | EmptyOption => Variant.factory(innerLiteral, ())
      | NaN => Variant.factory(innerLiteral, ())
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

  let parserTransform = Effect.make((~input, ~struct, ~mode) => {
    let maybeRefinementError = switch mode {
    | Safe =>
      switch input->getInternalClass === "[object Object]" {
      | true => None
      | false => Some(makeUnexpectedTypeError(~input, ~struct))
      }
    | Unsafe => None
    }
    switch maybeRefinementError {
    | None =>
      let {fields, fieldNames, unknownKeys} = struct->classify->Obj.magic

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
            idxRef.contents = idxRef.contents->Lib.Int.plus(1)
          }
        | Error(error) =>
          maybeErrorRef.contents = Some(error->Error.Internal.prependLocation(fieldName))
        }
      }
      if unknownKeys == Strict && mode == Safe {
        switch getMaybeExcessKey(. input, fields) {
        | Some(excessKey) =>
          maybeErrorRef.contents = Some(Error.Internal.make(ExcessField(excessKey)))
        | None => ()
        }
      }
      switch maybeErrorRef.contents {
      | Some(error) => Failed(error)
      | None => newArray->Lib.Array.toTuple->Transformed
      }
    | Some(error) => Failed(error)
    }
  })

  let parsers = {
    safe: [parserTransform],
    unsafe: [parserTransform],
  }

  let serializerTransform = Effect.make((~input, ~struct, ~mode) => {
    let {fields, fieldNames} = struct->classify->Obj.magic

    let unknown = Js.Dict.empty()
    let fieldValues = fieldNames->Js.Array2.length <= 1 ? [input]->Obj.magic : input->Obj.magic

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
          idxRef.contents = idxRef.contents->Lib.Int.plus(1)
        }
      | Error(error) =>
        maybeErrorRef.contents = Some(error->Error.Internal.prependLocation(fieldName))
      }
    }

    switch maybeErrorRef.contents {
    | Some(error) => Failed(error)
    | None => Transformed(unknown)
    }
  })

  let serializers = {
    safe: [serializerTransform],
    unsafe: [serializerTransform],
  }

  let innerFactory = fieldsArray => {
    let fields = fieldsArray->Js.Dict.fromArray

    {
      tagged_t: Record({fields: fields, fieldNames: fields->Js.Dict.keys, unknownKeys: Strict}),
      maybeParsers: Some(parsers),
      maybeSerializers: Some(serializers),
      maybeMetadata: None,
    }
  }

  let factory = Lib.Fn.callWithArguments(innerFactory)

  let strip = struct => {
    let tagged_t = struct->classify
    switch tagged_t {
    | Record({fields, fieldNames}) => {
        ...struct,
        tagged_t: Record({fields: fields, fieldNames: fieldNames, unknownKeys: Strip}),
      }
    | _ => Error.UnknownKeysRequireRecord.raise()
    }
  }

  let strict = struct => {
    let tagged_t = struct->classify
    switch tagged_t {
    | Record({fields, fieldNames}) => {
        ...struct,
        tagged_t: Record({fields: fields, fieldNames: fieldNames, unknownKeys: Strict}),
      }
    | _ => Error.UnknownKeysRequireRecord.raise()
    }
  }
}

module Never = {
  let effects = [
    Effect.make((~input, ~struct, ~mode as _) => {
      Failed(makeUnexpectedTypeError(~input, ~struct))
    }),
  ]

  let effectsMap = {
    safe: effects,
    unsafe: Effect.emptyArray,
  }

  let factory = () => {
    tagged_t: Never,
    maybeParsers: Some(effectsMap),
    maybeSerializers: Some(effectsMap),
    maybeMetadata: None,
  }
}

module Unknown = {
  let factory = () => {
    tagged_t: Unknown,
    maybeParsers: Some(Effect.emptyMap),
    maybeSerializers: Some(Effect.emptyMap),
    maybeMetadata: None,
  }
}

module String = {
  let cuidRegex = %re(`/^c[^\s-]{8,}$/i`)
  let uuidRegex = %re(`/^([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[a-f0-9]{4}-[a-f0-9]{12}|00000000-0000-0000-0000-000000000000)$/i`)
  let emailRegex = %re(`/^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i`)

  let parserRefinement = Effect.make((~input, ~struct, ~mode as _) => {
    switch input->Js.typeof === "string" {
    | true => Refined
    | false => Failed(makeUnexpectedTypeError(~input, ~struct))
    }
  })

  let parsers = {
    safe: [parserRefinement],
    unsafe: Effect.emptyArray,
  }

  let serializers = Effect.emptyMap

  let factory = () => {
    tagged_t: String,
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }

  let min = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      switch value->Js.String2.length < length {
      | true =>
        Some(
          maybeMessage->Belt.Option.getWithDefault(
            `String must be ${length->Js.Int.toString} or more characters long`,
          ),
        )
      | false => None
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let max = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      switch value->Js.String2.length > length {
      | true =>
        Some(
          maybeMessage->Belt.Option.getWithDefault(
            `String must be ${length->Js.Int.toString} or fewer characters long`,
          ),
        )
      | false => None
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let length = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      switch value->Js.String2.length === length {
      | false =>
        Some(
          maybeMessage->Belt.Option.getWithDefault(
            `String must be exactly ${length->Js.Int.toString} characters long`,
          ),
        )
      | true => None
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let email = (struct, ~message=`Invalid email address`, ()) => {
    let refiner = value =>
      switch emailRegex->Js.Re.test_(value) {
      | false => Some(message)
      | true => None
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let uuid = (struct, ~message=`Invalid UUID`, ()) => {
    let refiner = value =>
      switch uuidRegex->Js.Re.test_(value) {
      | false => Some(message)
      | true => None
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let cuid = (struct, ~message=`Invalid CUID`, ()) => {
    let refiner = value =>
      switch cuidRegex->Js.Re.test_(value) {
      | false => Some(message)
      | true => None
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let url = (struct, ~message=`Invalid url`, ()) => {
    let refiner = value =>
      switch value->Lib.Url.test {
      | false => Some(message)
      | true => None
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let pattern = (struct, ~message=`Invalid`, re) => {
    let refiner = value => {
      re->Js.Re.setLastIndex(0)
      switch re->Js.Re.test_(value) {
      | false => Some(message)
      | true => None
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let trimmed = (struct, ()) => {
    let transformer = value => value->Js.String2.trim->Ok
    struct->transform(~parser=transformer, ~serializer=transformer, ())
  }
}

module Bool = {
  let parserRefinement = Effect.make((~input, ~struct, ~mode as _) => {
    switch input->Js.typeof === "boolean" {
    | true => Refined
    | false => Failed(makeUnexpectedTypeError(~input, ~struct))
    }
  })

  let parsers = {
    safe: [parserRefinement],
    unsafe: Effect.emptyArray,
  }

  let factory = () => {
    tagged_t: Bool,
    maybeParsers: Some(parsers),
    maybeSerializers: Some(Effect.emptyMap),
    maybeMetadata: None,
  }
}

module Int = {
  let parserRefinement = Effect.make((~input, ~struct, ~mode as _) => {
    switch input->Js.typeof === "number" && checkIsIntNumber(input) {
    | true => Refined
    | false => Failed(makeUnexpectedTypeError(~input, ~struct))
    }
  })

  let parsers = {
    safe: [parserRefinement],
    unsafe: Effect.emptyArray,
  }

  let factory = () => {
    tagged_t: Int,
    maybeParsers: Some(parsers),
    maybeSerializers: Some(Effect.emptyMap),
    maybeMetadata: None,
  }

  let min = (struct, ~message as maybeMessage=?, thanValue) => {
    let refiner = value =>
      switch value >= thanValue {
      | false =>
        Some(
          maybeMessage->Belt.Option.getWithDefault(
            `Number must be greater than or equal to ${thanValue->Js.Int.toString}`,
          ),
        )
      | true => None
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let max = (struct, ~message as maybeMessage=?, thanValue) => {
    let refiner = value =>
      switch value <= thanValue {
      | false =>
        Some(
          maybeMessage->Belt.Option.getWithDefault(
            `Number must be lower than or equal to ${thanValue->Js.Int.toString}`,
          ),
        )
      | true => None
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }
}

module Float = {
  let parserRefinement = Effect.make((~input, ~struct, ~mode as _) => {
    switch input->Js.typeof === "number" {
    | true =>
      switch Js.Float.isNaN(input) {
      | true => Failed(makeUnexpectedTypeError(~input, ~struct))
      | false => Refined
      }
    | false => Failed(makeUnexpectedTypeError(~input, ~struct))
    }
  })

  let parsers = {
    safe: [parserRefinement],
    unsafe: Effect.emptyArray,
  }

  let factory = () => {
    tagged_t: Float,
    maybeParsers: Some(parsers),
    maybeSerializers: Some(Effect.emptyMap),
    maybeMetadata: None,
  }

  let min = Int.min->Obj.magic
  let max = Int.max->Obj.magic
}

module Date = {
  let parserRefinement = Effect.make((~input, ~struct, ~mode as _) => {
    let factory = struct->classify->unsafeGetVariantPayload
    switch factory->Lib.Factory.factoryOf(input) && !(input->Js.Date.getTime->Js.Float.isNaN) {
    | true => Refined
    | false => Failed(makeUnexpectedTypeError(~input, ~struct))
    }
  })

  let parsers = {
    safe: [parserRefinement],
    unsafe: Effect.emptyArray,
  }

  let factory = () => {
    tagged_t: Instance(%raw(`Date`)),
    maybeParsers: Some(parsers),
    maybeSerializers: Some(Effect.emptyMap),
    maybeMetadata: None,
  }
}

module Null = {
  let parserEffects = [
    Effect.make((~input, ~struct, ~mode) => {
      switch input->Js.Null.toOption {
      | Some(innerValue) =>
        let innerStruct = struct->classify->unsafeGetVariantPayload
        switch parseInner(~struct=innerStruct->Obj.magic, ~any=innerValue, ~mode) {
        | Ok(value) => Transformed(Some(value))
        | Error(_) as error => error->Effect.fromResult
        }
      | None => Transformed(None)
      }
    }),
  ]

  let parsers = {
    safe: parserEffects,
    unsafe: parserEffects,
  }

  let serializerEffects = [
    Effect.make((~input, ~struct, ~mode) => {
      switch input {
      | Some(value) =>
        let innerStruct = struct->classify->unsafeGetVariantPayload
        serializeInner(~struct=innerStruct->Obj.magic, ~value, ~mode)->Effect.fromResult
      | None => Js.Null.empty->unsafeAnyToUnknown->Transformed
      }
    }),
  ]

  let serializers = {
    safe: serializerEffects,
    unsafe: serializerEffects,
  }

  let factory = innerStruct => {
    tagged_t: Null(innerStruct),
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }
}

module Option = {
  let parserEffects = [
    Effect.make((~input, ~struct, ~mode) => {
      switch input {
      | Some(innerValue) =>
        let innerStruct = struct->classify->unsafeGetVariantPayload
        switch parseInner(~struct=innerStruct, ~any=innerValue, ~mode) {
        | Ok(v) => Transformed(Some(v))
        | Error(_) as error => error->Effect.fromResult
        }
      | None => Refined
      }
    }),
  ]

  let parsers = {
    safe: parserEffects,
    unsafe: parserEffects,
  }

  let serializerEffects = [
    Effect.make((~input, ~struct, ~mode) => {
      switch input {
      | Some(value) => {
          let innerStruct = struct->classify->unsafeGetVariantPayload
          serializeInner(~struct=innerStruct, ~value, ~mode)->Effect.fromResult
        }
      | None => Refined
      }
    }),
  ]

  let serializers = {
    safe: serializerEffects,
    unsafe: serializerEffects,
  }

  let factory = innerStruct => {
    tagged_t: Option(innerStruct),
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }
}

module Deprecated = {
  type payload<'value> = {struct: t<'value>}

  let parserEffects = [
    Effect.make((~input, ~struct, ~mode) => {
      switch input {
      | Some(innerValue) =>
        let {struct: innerStruct} = struct->classify->Obj.magic
        switch parseInner(~struct=innerStruct, ~any=innerValue, ~mode) {
        | Ok(v) => Transformed(Some(v))
        | Error(_) as error => error->Effect.fromResult
        }
      | None => Refined
      }
    }),
  ]

  let parsers = {
    safe: parserEffects,
    unsafe: parserEffects,
  }

  let serializerEffects = [
    Effect.make((~input, ~struct, ~mode) => {
      switch input {
      | Some(value) => {
          let {struct: innerStruct} = struct->classify->Obj.magic
          serializeInner(~struct=innerStruct, ~value, ~mode)->Effect.fromResult
        }
      | None => Refined
      }
    }),
  ]

  let serializers = {
    safe: serializerEffects,
    unsafe: serializerEffects,
  }

  let factory = (~message as maybeMessage=?, innerStruct) => {
    tagged_t: Deprecated({struct: innerStruct, maybeMessage: maybeMessage}),
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }
}

module Array = {
  let parserEffects = [
    Effect.make((~input, ~struct, ~mode) => {
      let maybeRefinementError = switch mode {
      | Safe =>
        switch Js.Array2.isArray(input) {
        | true => None
        | false => Some(makeUnexpectedTypeError(~input, ~struct))
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
                idxRef.contents = idxRef.contents->Lib.Int.plus(1)
              }
            | Error(error) =>
              maybeErrorRef.contents = Some(
                error->Error.Internal.prependLocation(idx->Js.Int.toString),
              )
            }
          }
          switch maybeErrorRef.contents {
          | Some(error) => Failed(error)
          | None => Transformed(newArray)
          }
        }
      | Some(error) => Failed(error)
      }
    }),
  ]

  let parsers = {
    safe: parserEffects,
    unsafe: parserEffects,
  }

  let serializerEffects = [
    Effect.make((~input, ~struct, ~mode) => {
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
            idxRef.contents = idxRef.contents->Lib.Int.plus(1)
          }
        | Error(error) =>
          maybeErrorRef.contents = Some(error->Error.Internal.prependLocation(idx->Js.Int.toString))
        }
      }
      switch maybeErrorRef.contents {
      | Some(error) => Failed(error)
      | None => Transformed(newArray)
      }
    }),
  ]

  let serializers = {
    safe: serializerEffects,
    unsafe: serializerEffects,
  }

  let factory = innerStruct => {
    tagged_t: Array(innerStruct),
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }

  let min = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      switch value->Js.Array2.length < length {
      | true =>
        Some(
          maybeMessage->Belt.Option.getWithDefault(
            `Array must be ${length->Js.Int.toString} or more items long`,
          ),
        )
      | false => None
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let max = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      switch value->Js.Array2.length > length {
      | true =>
        Some(
          maybeMessage->Belt.Option.getWithDefault(
            `Array must be ${length->Js.Int.toString} or fewer items long`,
          ),
        )
      | false => None
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let length = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      switch value->Js.Array2.length === length {
      | false =>
        Some(
          maybeMessage->Belt.Option.getWithDefault(
            `Array must be exactly ${length->Js.Int.toString} items long`,
          ),
        )
      | true => None
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }
}

module Dict = {
  let parserEffects = [
    Effect.make((~input, ~struct, ~mode) => {
      let maybeRefinementError = switch mode {
      | Safe =>
        switch input->getInternalClass === "[object Object]" {
        | true => None
        | false => Some(makeUnexpectedTypeError(~input, ~struct))
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
                idxRef.contents = idxRef.contents->Lib.Int.plus(1)
              }
            | Error(error) =>
              maybeErrorRef.contents = Some(error->Error.Internal.prependLocation(key))
            }
          }
          switch maybeErrorRef.contents {
          | Some(error) => Failed(error)
          | None => Transformed(newDict)
          }
        }
      | Some(error) => Failed(error)
      }
    }),
  ]

  let parsers = {
    safe: parserEffects,
    unsafe: parserEffects,
  }

  let serializerEffects = [
    Effect.make((~input, ~struct, ~mode) => {
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
            idxRef.contents = idxRef.contents->Lib.Int.plus(1)
          }
        | Error(error) => maybeErrorRef.contents = Some(error->Error.Internal.prependLocation(key))
        }
      }
      switch maybeErrorRef.contents {
      | Some(error) => Failed(error)
      | None => Transformed(newDict)
      }
    }),
  ]

  let serializers = {
    safe: serializerEffects,
    unsafe: serializerEffects,
  }

  let factory = innerStruct => {
    tagged_t: Dict(innerStruct),
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }
}

module Default = {
  type payload<'value> = {struct: t<option<'value>>, value: 'value}

  let parserEffects = [
    Effect.make((~input, ~struct, ~mode) => {
      let {struct: innerStruct, value} = struct->classify->Obj.magic
      switch parseInner(~struct=innerStruct, ~any=input, ~mode) {
      | Ok(maybeOutput) =>
        switch maybeOutput {
        | Some(output) => output
        | None => value
        }->Transformed
      | Error(_) as error => error->Effect.fromResult
      }
    }),
  ]

  let parsers = {
    safe: parserEffects,
    unsafe: parserEffects,
  }

  let serializerEffects = [
    Effect.make((~input, ~struct, ~mode) => {
      let {struct: innerStruct} = struct->classify->Obj.magic
      serializeInner(~struct=innerStruct, ~value=Some(input), ~mode)->Effect.fromResult
    }),
  ]

  let serializers = {
    safe: serializerEffects,
    unsafe: serializerEffects,
  }

  let factory = (innerStruct, defaultValue) => {
    tagged_t: Default({struct: innerStruct, value: defaultValue}),
    maybeParsers: Some(parsers),
    maybeSerializers: Some(serializers),
    maybeMetadata: None,
  }
}

module Tuple = {
  let parserEffects = [
    Effect.make((~input, ~struct, ~mode) => {
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
              Error.Internal.make(
                TupleSize({
                  expected: numberOfStructs,
                  received: numberOfInputItems,
                }),
              ),
            )
          }
        | false => Some(makeUnexpectedTypeError(~input, ~struct))
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
                idxRef.contents = idxRef.contents->Lib.Int.plus(1)
              }
            | Error(error) =>
              maybeErrorRef.contents = Some(
                error->Error.Internal.prependLocation(idx->Js.Int.toString),
              )
            }
          }
          switch maybeErrorRef.contents {
          | Some(error) => Failed(error)
          | None =>
            switch numberOfStructs {
            | 0 => ()->Obj.magic
            | 1 => newArray->Js.Array2.unsafe_get(0)->Obj.magic
            | _ => newArray
            }->Transformed
          }
        }
      | Some(error) => Failed(error)
      }
    }),
  ]

  let parsers = {
    safe: parserEffects,
    unsafe: parserEffects,
  }

  let serializerEffects = [
    Effect.make((~input, ~struct, ~mode) => {
      let innerStructs = struct->classify->unsafeGetVariantPayload
      let numberOfStructs = innerStructs->Js.Array2.length
      let inputArray = numberOfStructs === 1 ? [input->Obj.magic] : input

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
            idxRef.contents = idxRef.contents->Lib.Int.plus(1)
          }
        | Error(error) =>
          maybeErrorRef.contents = Some(error->Error.Internal.prependLocation(idx->Js.Int.toString))
        }
      }
      switch maybeErrorRef.contents {
      | Some(error) => Failed(error)
      | None => Transformed(newArray)
      }
    }),
  ]

  let serializers = {
    safe: serializerEffects,
    unsafe: serializerEffects,
  }

  let innerFactory = structs => {
    {
      tagged_t: Tuple(structs),
      maybeParsers: Some(parsers),
      maybeSerializers: Some(serializers),
      maybeMetadata: None,
    }
  }

  let factory = Lib.Fn.callWithArguments(innerFactory)
}

module Union = {
  let parserEffects = [
    Effect.make((~input, ~struct, ~mode as _) => {
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
            idxRef.contents = idxRef.contents->Lib.Int.plus(1)
          }
        }
      }
      switch maybeOkRef.contents {
      | Some(ok) => ok->Effect.fromResult
      | None =>
        switch maybeLastErrorRef.contents {
        | Some(error) => error->Effect.fromResult
        | None => %raw(`undefined`)
        }
      }
    }),
  ]

  let parsers = {
    safe: parserEffects,
    unsafe: parserEffects,
  }

  let serializerEffects = [
    Effect.make((~input, ~struct, ~mode as _) => {
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
            idxRef.contents = idxRef.contents->Lib.Int.plus(1)
          }
        }
      }
      switch maybeOkRef.contents {
      | Some(ok) => ok->Effect.fromResult
      | None =>
        switch maybeLastErrorRef.contents {
        | Some(error) => error->Effect.fromResult
        | None => %raw(`undefined`)
        }
      }
    }),
  ]

  let serializers = {
    safe: serializerEffects,
    unsafe: serializerEffects,
  }

  let factory = structs => {
    if structs->Js.Array2.length < 2 {
      Error.UnionLackingStructs.raise()
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
let date = Date.factory
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

let json = innerStruct => {
  string()->superTransform(
    ~parser=(. ~value, ~struct as _, ~mode) => {
      switch Js.Json.parseExn(value) {
      | json => Ok(json)
      | exception Js.Exn.Error(obj) =>
        Error(Error.make(obj->Js.Exn.message->Belt.Option.getWithDefault("Failed to parse JSON")))
      }->Lib.Result.flatMap(parsedJson => parsedJson->parseWith(~mode, innerStruct))
    },
    ~serializer=(. ~transformed, ~struct as _, ~mode) => {
      transformed
      ->serializeWith(~mode, innerStruct)
      ->Lib.Result.map(unknown => unknown->unsafeUnknownToAny->Js.Json.stringify)
    },
    (),
  )
}

module MakeMetadata = (
  Config: {
    type content
    let namespace: string
  },
) => {
  let get = (struct): option<Config.content> => {
    struct.maybeMetadata->Lib.Option.map(metadata => {
      metadata->Js.Dict.get(Config.namespace)->Obj.magic
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
      ...struct,
      maybeMetadata: Some(
        existingContent->dictUnsafeSet(Config.namespace, content->unsafeAnyToUnknown),
      ),
    }
  }
}

module Result = {
  let getExn = result => {
    switch result {
    | Ok(value) => value
    | Error(error) => Error.raise(error->Error.toString)
    }
  }

  let mapErrorToString = result => {
    result->Lib.Result.mapError(Error.toString)
  }
}
