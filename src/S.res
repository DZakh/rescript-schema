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

  module Object = {
    @inline
    let test = data => {
      data->Js.typeof == "object" && !Js.Array2.isArray(data) && data !== %raw(`null`)
    }
  }

  module Set = {
    type t<'value>

    @new
    external fromArray: array<'value> => t<'value> = "Set"

    @val("Array.from")
    external toArray: t<'value> => array<'value> = "from"
  }

  module Array = {
    @inline
    let toTuple = array =>
      array->Js.Array2.length <= 1 ? array->Js.Array2.unsafe_get(0)->Obj.magic : array->Obj.magic

    @inline
    let unique = array => array->Set.fromArray->Set.toArray

    @inline
    let set = (array: array<'value>, idx: int, value: 'value) => {
      array->Obj.magic->Js.Dict.set(idx->Obj.magic, value)
    }
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

    @inline
    let test = data => {
      let x = data->Obj.magic
      data->Js.typeof == "number" && x < 2147483648. && x > -2147483649. && x == x->Js.Math.trunc
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

  let panic = %raw(`function(message){
    throw new RescriptStructError(message);
  }`)

  type rec t = {operation: operation, code: code, path: array<string>}
  and code =
    | OperationFailed(string)
    | MissingParser
    | MissingSerializer
    | UnexpectedType({expected: string, received: string})
    | UnexpectedValue({expected: string, received: string})
    | TupleSize({expected: int, received: int})
    | ExcessField(string)
    | InvalidUnion(array<t>)
  and operation =
    | Serializing
    | Parsing

  module Internal = {
    type public = t
    type t = {
      code: code,
      path: array<string>,
    }

    exception Exception(t)

    let raise = code => {
      raise(Exception({code: code, path: []}))
    }

    let toParseError = (self: t): public => {
      {operation: Parsing, code: self.code, path: self.path}
    }

    let toSerializeError = (self: t): public => {
      {operation: Serializing, code: self.code, path: self.path}
    }

    external fromPublic: public => t = "%identity"

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

      let raise = (~expected, ~received) => {
        raise(
          UnexpectedValue({
            expected: expected->stringify,
            received: received->stringify,
          }),
        )
      }
    }
  }

  module MissingParserAndSerializer = {
    let panic = location => panic(`For a ${location} either a parser, or a serializer is required`)
  }

  module UnknownKeysRequireRecord = {
    let panic = () => panic("Can't set up unknown keys strategy. The struct is not Record")
  }

  module UnionLackingStructs = {
    let panic = () => panic("A Union struct factory require at least two structs")
  }

  let formatPath = path => {
    if path->Js.Array2.length == 0 {
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

  let rec toReason = (~nestedLevel=0, error) => {
    switch error.code {
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
    | InvalidUnion(errors) => {
        let lineBreak = `\n${" "->Js.String2.repeat(nestedLevel * 2)}`
        let reasons =
          errors
          ->Js.Array2.map(error => {
            let reason = error->toReason(~nestedLevel=nestedLevel->Lib.Int.plus(1))
            let location = switch error.path {
            | [] => ""
            | nonEmptyPath => `Failed at ${formatPath(nonEmptyPath)}. `
            }
            `- ${location}${reason}`
          })
          ->Lib.Array.unique
        `Invalid union with following errors${lineBreak}${reasons->Js.Array2.joinWith(lineBreak)}`
      }
    }
  }

  let toString = error => {
    let prefix = `[ReScript Struct]`
    let operation = switch error.operation {
    | Serializing => "serializing"
    | Parsing => "parsing"
    }
    let reason = error->toReason
    let pathText = error.path->formatPath
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

type parsingMode = Safe | Migration
type recordUnknownKeys =
  | Strict
  | Strip
type operation = Noop | Sync((. unknown) => unknown)
type parseOperations = {
  // Keys are the inlined mode variant
  @as("0")
  safe: operation,
  @as("1")
  migration: operation,
}

type rec t<'value> = {
  @as("t")
  tagged_t: tagged_t,
  @as("sp")
  safeParseActions: array<action>,
  @as("mp")
  migrationParseActions: array<action>,
  @as("sa")
  serializeActions: array<action>,
  @as("s")
  serialize: operation,
  @as("p")
  parseOperations: parseOperations,
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
and action =
  | Transform((. ~unknown: unknown, ~struct: t<unknown>, ~mode: parsingMode) => unknown)
  | Refine((. ~unknown: unknown, ~struct: t<unknown>, ~mode: parsingMode) => unit)

external unsafeAnyToUnknown: 'any => unknown = "%identity"
external unsafeUnknownToAny: unknown => 'any = "%identity"

type payloadedVariant<'payload> = {_0: 'payload}
@inline
let unsafeGetVariantPayload: 'a => 'payload = v => (v->Obj.magic)._0

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

let raiseUnexpectedTypeError = (~input: 'any, ~struct: t<'any2>) => {
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
  Error.Internal.raise(UnexpectedType({expected: expected, received: received}))
}

let processActions = (
  ~struct: t<'value>,
  ~actions: array<action>,
  ~mode: parsingMode,
  . input: 'input,
) => {
  let tempOuputRef = ref(input->Obj.magic)
  for idx in 0 to actions->Js.Array2.length - 1 {
    let action = actions->Js.Array2.unsafe_get(idx)
    switch action {
    | Transform(fn) =>
      let newValue = fn(. ~unknown=tempOuputRef.contents, ~struct=struct->Obj.magic, ~mode)
      tempOuputRef.contents = newValue
    | Refine(fn) => fn(. ~unknown=tempOuputRef.contents, ~struct=struct->Obj.magic, ~mode)
    }
  }
  tempOuputRef.contents->Obj.magic
}

let make = (
  ~tagged_t,
  ~safeParseActions,
  ~migrationParseActions,
  ~serializeActions,
  ~metadata as maybeMetadata=?,
  (),
) => {
  let struct = {
    tagged_t: tagged_t,
    safeParseActions: safeParseActions,
    migrationParseActions: migrationParseActions,
    serializeActions: serializeActions,
    serialize: %raw("undefined"),
    parseOperations: %raw("undefined"),
    maybeMetadata: maybeMetadata,
  }
  {
    ...struct,
    serialize: switch struct.serializeActions {
    | [] => Noop
    | actions => Sync(processActions(~actions, ~mode=Safe, ~struct))
    },
    parseOperations: {
      safe: switch struct.safeParseActions {
      | [] => Noop
      | actions => Sync(processActions(~actions, ~mode=Safe, ~struct))
      },
      migration: switch struct.migrationParseActions {
      | [] => Noop
      | actions => Sync(processActions(~actions, ~mode=Migration, ~struct))
      },
    },
  }
}

@inline
let getParseOperation = (struct, ~mode) => {
  struct.parseOperations->Obj.magic->Js.Dict.unsafeGet(mode->Obj.magic)
}

@inline
let parseInner: (~struct: t<'value>, ~any: 'any, ~mode: parsingMode) => 'value = (
  ~struct,
  ~any,
  ~mode,
) => {
  switch struct->getParseOperation(~mode) {
  | Noop => any->Obj.magic
  | Sync(fn) => fn(. any->Obj.magic)->Obj.magic
  }
}

let parseWith = (any, ~mode=Safe, struct) => {
  try {parseInner(~struct, ~any, ~mode)->Ok} catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  }
}

@inline
let serializeInner: (~struct: t<'value>, ~value: 'value) => unknown = (~struct, ~value) => {
  switch struct.serialize {
  | Noop => value->unsafeAnyToUnknown
  | Sync(fn) => fn(. value->unsafeAnyToUnknown)
  }
}

let serializeWith = (value, struct) => {
  try {
    serializeInner(~struct, ~value)->Ok
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toSerializeError->Error
  }
}

module Action = {
  let transform = (fn: (~input: 'input, ~struct: t<'value>, ~mode: parsingMode) => unknown) => {
    Transform(fn->Obj.magic)
  }

  let refine = (fn: (~input: 'value, ~struct: t<'value>, ~mode: parsingMode) => unit) => {
    Refine(fn->Obj.magic)
  }

  let emptyArray: array<action> = []

  let concatParser = (actions, action) => {
    actions->Js.Array2.concat([action])
  }

  let concatSerializer = (actions, action) => {
    [action]->Js.Array2.concat(actions)
  }

  let missingParser = refine((~input as _, ~struct as _, ~mode as _) => {
    Error.Internal.raise(MissingParser)
  })

  let missingSerializer = refine((~input as _, ~struct as _, ~mode as _) => {
    Error.Internal.raise(MissingSerializer)
  })
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
  if maybeRefineParser == None && maybeRefineSerializer == None {
    Error.MissingParserAndSerializer.panic(`struct factory Refine`)
  }

  make(
    ~tagged_t=struct.tagged_t,
    ~safeParseActions=switch maybeRefineParser {
    | Some(refineParser) =>
      struct.safeParseActions->Action.concatParser(
        Action.refine((~input, ~struct as _, ~mode as _) => {
          switch (refineParser->Obj.magic)(. input) {
          | None => ()
          | Some(reason) => Error.Internal.raise(OperationFailed(reason))
          }
        }),
      )
    | None => struct.safeParseActions
    },
    ~migrationParseActions=struct.migrationParseActions,
    ~serializeActions=switch maybeRefineSerializer {
    | Some(refineSerializer) =>
      struct.serializeActions->Action.concatSerializer(
        Action.refine((~input, ~struct as _, ~mode as _) => {
          switch (refineSerializer->Obj.magic)(. input) {
          | None => ()
          | Some(reason) => Error.Internal.raise(OperationFailed(reason))
          }
        }),
      )
    | None => struct.serializeActions
    },
    ~metadata=?struct.maybeMetadata,
    (),
  )
}

let transform = (
  struct,
  ~parser as maybeTransformationParser=?,
  ~serializer as maybeTransformationSerializer=?,
  (),
) => {
  if maybeTransformationParser == None && maybeTransformationSerializer == None {
    Error.MissingParserAndSerializer.panic(`struct factory Transform`)
  }
  let parseAction = switch maybeTransformationParser {
  | Some(transformationParser) =>
    Action.transform((~input, ~struct as _, ~mode as _) => {
      switch (transformationParser->Obj.magic)(. input) {
      | Ok(transformed) => transformed
      | Error(reason) => Error.Internal.raise(OperationFailed(reason))
      }
    })
  | None => Action.missingParser
  }
  make(
    ~tagged_t=struct.tagged_t,
    ~safeParseActions=struct.safeParseActions->Action.concatParser(parseAction),
    ~migrationParseActions=struct.migrationParseActions->Action.concatParser(parseAction),
    ~serializeActions=struct.serializeActions->Action.concatSerializer(
      switch maybeTransformationSerializer {
      | Some(transformationSerializer) =>
        Action.transform((~input, ~struct as _, ~mode as _) => {
          switch (transformationSerializer->Obj.magic)(. input) {
          | Ok(value) => value
          | Error(reason) => Error.Internal.raise(OperationFailed(reason))
          }
        })
      | None => Action.missingSerializer
      },
    ),
    ~metadata=?struct.maybeMetadata,
    (),
  )
}

let superTransform = (
  struct,
  ~parser as maybeTransformationParser=?,
  ~serializer as maybeTransformationSerializer=?,
  (),
) => {
  if maybeTransformationParser == None && maybeTransformationSerializer == None {
    Error.MissingParserAndSerializer.panic(`struct factory Transform`)
  }

  let parseAction = switch maybeTransformationParser {
  | Some(transformationParser) =>
    Action.transform((~input, ~struct, ~mode) => {
      switch (transformationParser->Obj.magic)(. ~value=input, ~struct, ~mode) {
      | Ok(transformed) => transformed
      | Error(public) => raise(Error.Internal.Exception(public->Error.Internal.fromPublic))
      }
    })
  | None => Action.missingParser
  }
  make(
    ~tagged_t=struct.tagged_t,
    ~safeParseActions=struct.safeParseActions->Action.concatParser(parseAction),
    ~migrationParseActions=struct.migrationParseActions->Action.concatParser(parseAction),
    ~serializeActions=struct.serializeActions->Action.concatSerializer(
      switch maybeTransformationSerializer {
      | Some(transformationSerializer) =>
        Action.transform((~input, ~struct as _, ~mode as _) => {
          switch (transformationSerializer->Obj.magic)(. ~transformed=input, ~struct) {
          | Ok(value) => value
          | Error(public) => raise(Error.Internal.Exception(public->Error.Internal.fromPublic))
          }
        })
      | None => Action.missingSerializer
      },
    ),
    ~metadata=?struct.maybeMetadata,
    (),
  )
}

let custom = (~parser as maybeCustomParser=?, ~serializer as maybeCustomSerializer=?, ()) => {
  if maybeCustomParser == None && maybeCustomSerializer == None {
    Error.MissingParserAndSerializer.panic(`Custom struct factory`)
  }

  let parseActions = [
    switch maybeCustomParser {
    | Some(customParser) =>
      Action.transform((~input, ~struct as _, ~mode) => {
        switch customParser(. ~unknown=input, ~mode) {
        | Ok(value) => value->unsafeAnyToUnknown
        | Error(public) => raise(Error.Internal.Exception(public->Error.Internal.fromPublic))
        }
      })
    | None => Action.missingParser
    },
  ]

  make(
    ~tagged_t=Unknown,
    ~migrationParseActions=parseActions,
    ~safeParseActions=parseActions,
    ~serializeActions=[
      switch maybeCustomSerializer {
      | Some(customSerializer) =>
        Action.transform((~input, ~struct as _, ~mode as _) => {
          switch customSerializer(. ~value=input) {
          | Ok(value) => value->unsafeAnyToUnknown
          | Error(public) => raise(Error.Internal.Exception(public->Error.Internal.fromPublic))
          }
        })
      | None => Action.missingSerializer
      },
    ],
    (),
  )
}

module Literal = {
  module CommonOperations = {
    module Parser = {
      let literalValueRefinement = Action.refine((~input, ~struct, ~mode as _) => {
        let expectedValue = struct->classify->unsafeGetVariantPayload->unsafeGetVariantPayload
        if expectedValue !== input {
          Error.Internal.UnexpectedValue.raise(~expected=expectedValue, ~received=input)
        }
      })
    }

    let transformToLiteralValue = Action.transform((~input as _, ~struct, ~mode as _) => {
      struct->classify->unsafeGetVariantPayload->unsafeGetVariantPayload
    })
  }

  module EmptyNull = {
    let parserRefinement = Action.refine((~input, ~struct, ~mode as _) => {
      if input !== Js.Null.empty {
        raiseUnexpectedTypeError(~input, ~struct)
      }
    })

    let serializerTransform = Action.transform((~input as _, ~struct as _, ~mode as _) => {
      Js.Null.empty->unsafeAnyToUnknown
    })
  }

  module EmptyOption = {
    let parserRefinement = Action.refine((~input, ~struct, ~mode as _) => {
      if input !== Js.Undefined.empty {
        raiseUnexpectedTypeError(~input, ~struct)
      }
    })

    let serializerTransform = Action.transform((~input as _, ~struct as _, ~mode as _) => {
      Js.Undefined.empty->unsafeAnyToUnknown
    })
  }

  module NaN = {
    let parserRefinement = Action.refine((~input, ~struct, ~mode as _) => {
      if !Js.Float.isNaN(input) {
        raiseUnexpectedTypeError(~input, ~struct)
      }
    })

    let serializerTransform = Action.transform((~input as _, ~struct as _, ~mode as _) => {
      Js.Float._NaN->unsafeAnyToUnknown
    })
  }

  module Bool = {
    let parserRefinement = Action.refine((~input, ~struct, ~mode as _) => {
      if input->Js.typeof !== "boolean" {
        raiseUnexpectedTypeError(~input, ~struct)
      }
    })
  }

  module String = {
    let parserRefinement = Action.refine((~input, ~struct, ~mode as _) => {
      if input->Js.typeof !== "string" {
        raiseUnexpectedTypeError(~input, ~struct)
      }
    })
  }

  module Float = {
    let parserRefinement = Action.refine((~input, ~struct, ~mode as _) => {
      if input->Js.typeof !== "number" {
        raiseUnexpectedTypeError(~input, ~struct)
      }
    })
  }

  module Int = {
    let parserRefinement = Action.refine((~input, ~struct, ~mode as _) => {
      if !Lib.Int.test(input) {
        raiseUnexpectedTypeError(~input, ~struct)
      }
    })
  }

  module Variant = {
    let factory:
      type literalValue variant. (literal<literalValue>, variant) => t<variant> =
      (innerLiteral, variant) => {
        let tagged_t = Literal(innerLiteral)
        let parserTransform = Action.transform((~input as _, ~struct as _, ~mode as _) => {
          variant->unsafeAnyToUnknown
        })
        let serializerRefinement = Action.refine((~input, ~struct as _, ~mode as _) => {
          if input !== variant {
            Error.Internal.UnexpectedValue.raise(
              ~expected=variant->Obj.magic,
              ~received=input->Obj.magic,
            )
          }
        })
        switch innerLiteral {
        | EmptyNull =>
          make(
            ~tagged_t,
            ~safeParseActions=[EmptyNull.parserRefinement, parserTransform],
            ~migrationParseActions=[parserTransform],
            ~serializeActions=[serializerRefinement, EmptyNull.serializerTransform],
            (),
          )
        | EmptyOption =>
          make(
            ~tagged_t,
            ~safeParseActions=[EmptyOption.parserRefinement, parserTransform],
            ~migrationParseActions=[parserTransform],
            ~serializeActions=[serializerRefinement, EmptyOption.serializerTransform],
            (),
          )
        | NaN =>
          make(
            ~tagged_t,
            ~safeParseActions=[NaN.parserRefinement, parserTransform],
            ~migrationParseActions=[parserTransform],
            ~serializeActions=[serializerRefinement, NaN.serializerTransform],
            (),
          )
        | Bool(_) =>
          make(
            ~tagged_t,
            ~safeParseActions=[
              Bool.parserRefinement,
              CommonOperations.Parser.literalValueRefinement,
              parserTransform,
            ],
            ~migrationParseActions=[parserTransform],
            ~serializeActions=[serializerRefinement, CommonOperations.transformToLiteralValue],
            (),
          )
        | String(_) =>
          make(
            ~tagged_t,
            ~safeParseActions=[
              String.parserRefinement,
              CommonOperations.Parser.literalValueRefinement,
              parserTransform,
            ],
            ~migrationParseActions=[parserTransform],
            ~serializeActions=[serializerRefinement, CommonOperations.transformToLiteralValue],
            (),
          )
        | Float(_) =>
          make(
            ~tagged_t,
            ~safeParseActions=[
              Float.parserRefinement,
              CommonOperations.Parser.literalValueRefinement,
              parserTransform,
            ],
            ~migrationParseActions=[parserTransform],
            ~serializeActions=[serializerRefinement, CommonOperations.transformToLiteralValue],
            (),
          )
        | Int(_) =>
          make(
            ~tagged_t,
            ~safeParseActions=[
              Int.parserRefinement,
              CommonOperations.Parser.literalValueRefinement,
              parserTransform,
            ],
            ~migrationParseActions=[parserTransform],
            ~serializeActions=[serializerRefinement, CommonOperations.transformToLiteralValue],
            (),
          )
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
      if (!Object.prototype.hasOwnProperty.call(innerStructsDict, key)) {
        return key
      }
    }
    return undefined
  }`)

  let serializeActions = [
    Action.transform((~input, ~struct, ~mode as _) => {
      let {fields, fieldNames} = struct->classify->Obj.magic

      let unknown = Js.Dict.empty()
      let fieldValues = fieldNames->Js.Array2.length <= 1 ? [input]->Obj.magic : input->Obj.magic
      for idx in 0 to fieldNames->Js.Array2.length - 1 {
        let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
        let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
        let fieldValue = fieldValues->Js.Array2.unsafe_get(idx)
        switch fieldStruct.serialize {
        | Noop => unknown->Js.Dict.set(fieldName, fieldValue)
        | Sync(fn) =>
          try {
            let fieldData = fn(. fieldValue)
            unknown->Js.Dict.set(fieldName, fieldData)
          } catch {
          | Error.Internal.Exception(internalError) =>
            raise(
              Error.Internal.Exception(internalError->Error.Internal.prependLocation(fieldName)),
            )
          }
        }
      }
      unknown->unsafeAnyToUnknown
    }),
  ]

  let innerFactory = fieldsArray => {
    let fields = fieldsArray->Js.Dict.fromArray
    let fieldNames = fields->Js.Dict.keys

    let makeParseActions = (~mode) => {
      let noopOps = []
      let syncOps = []
      for idx in 0 to fieldNames->Js.Array2.length - 1 {
        let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
        let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
        switch fieldStruct->getParseOperation(~mode) {
        | Noop => noopOps->Js.Array2.push((idx, fieldName))->ignore
        | Sync(fn) => syncOps->Js.Array2.push((idx, fieldName, fn))->ignore
        }
      }

      [
        Action.transform((~input, ~struct, ~mode) => {
          if mode == Safe && input->Lib.Object.test == false {
            raiseUnexpectedTypeError(~input, ~struct)
          }

          let {unknownKeys} = struct->classify->Obj.magic

          let newArray = []

          for idx in 0 to syncOps->Js.Array2.length - 1 {
            let (originalIdx, fieldName, fn) = syncOps->Js.Array2.unsafe_get(idx)
            let fieldData = input->Js.Dict.unsafeGet(fieldName)
            try {
              let value = fn(. fieldData)
              newArray->Lib.Array.set(originalIdx, value)
            } catch {
            | Error.Internal.Exception(internalError) =>
              raise(
                Error.Internal.Exception(internalError->Error.Internal.prependLocation(fieldName)),
              )
            }
          }

          for idx in 0 to noopOps->Js.Array2.length - 1 {
            let (originalIdx, fieldName) = noopOps->Js.Array2.unsafe_get(idx)
            let fieldData = input->Js.Dict.unsafeGet(fieldName)
            newArray->Lib.Array.set(originalIdx, fieldData)
          }

          if unknownKeys == Strict && mode == Safe {
            switch getMaybeExcessKey(. input, fields) {
            | Some(excessKey) => Error.Internal.raise(ExcessField(excessKey))
            | None => ()
            }
          }

          newArray->Lib.Array.toTuple
        }),
      ]
    }

    make(
      ~tagged_t=Record({fields: fields, fieldNames: fieldNames, unknownKeys: Strict}),
      ~safeParseActions=makeParseActions(~mode=Safe),
      ~migrationParseActions=makeParseActions(~mode=Migration),
      ~serializeActions,
      (),
    )
  }

  let factory = Lib.Fn.callWithArguments(innerFactory)

  let strip = struct => {
    let tagged_t = struct->classify
    switch tagged_t {
    | Record({fields, fieldNames}) =>
      make(
        ~tagged_t=Record({fields: fields, fieldNames: fieldNames, unknownKeys: Strip}),
        ~safeParseActions=struct.safeParseActions,
        ~migrationParseActions=struct.migrationParseActions,
        ~serializeActions=struct.serializeActions,
        ~metadata=?struct.maybeMetadata,
        (),
      )
    | _ => Error.UnknownKeysRequireRecord.panic()
    }
  }

  let strict = struct => {
    let tagged_t = struct->classify
    switch tagged_t {
    | Record({fields, fieldNames}) =>
      make(
        ~tagged_t=Record({fields: fields, fieldNames: fieldNames, unknownKeys: Strict}),
        ~safeParseActions=struct.safeParseActions,
        ~migrationParseActions=struct.migrationParseActions,
        ~serializeActions=struct.serializeActions,
        ~metadata=?struct.maybeMetadata,
        (),
      )
    | _ => Error.UnknownKeysRequireRecord.panic()
    }
  }
}

module Never = {
  let actions = [
    Action.refine((~input, ~struct, ~mode as _) => {
      raiseUnexpectedTypeError(~input, ~struct)
    }),
  ]

  let factory = () => {
    make(
      ~tagged_t=Never,
      ~safeParseActions=actions,
      ~migrationParseActions=Action.emptyArray,
      ~serializeActions=actions,
      (),
    )
  }
}

module Unknown = {
  let factory = () => {
    make(
      ~tagged_t=Unknown,
      ~safeParseActions=Action.emptyArray,
      ~migrationParseActions=Action.emptyArray,
      ~serializeActions=Action.emptyArray,
      (),
    )
  }
}

module String = {
  let cuidRegex = %re(`/^c[^\s-]{8,}$/i`)
  let uuidRegex = %re(`/^([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[a-f0-9]{4}-[a-f0-9]{12}|00000000-0000-0000-0000-000000000000)$/i`)
  let emailRegex = %re(`/^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i`)

  let parserRefinement = Action.refine((~input, ~struct, ~mode as _) => {
    if input->Js.typeof !== "string" {
      raiseUnexpectedTypeError(~input, ~struct)
    }
  })

  let factory = () => {
    make(
      ~tagged_t=String,
      ~safeParseActions=[parserRefinement],
      ~migrationParseActions=Action.emptyArray,
      ~serializeActions=Action.emptyArray,
      (),
    )
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
      switch value->Js.String2.length == length {
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
  let parserRefinement = Action.refine((~input, ~struct, ~mode as _) => {
    if input->Js.typeof !== "boolean" {
      raiseUnexpectedTypeError(~input, ~struct)
    }
  })

  let factory = () => {
    make(
      ~tagged_t=Bool,
      ~safeParseActions=[parserRefinement],
      ~migrationParseActions=Action.emptyArray,
      ~serializeActions=Action.emptyArray,
      (),
    )
  }
}

module Int = {
  let parserRefinement = Action.refine((~input, ~struct, ~mode as _) => {
    if !Lib.Int.test(input) {
      raiseUnexpectedTypeError(~input, ~struct)
    }
  })

  let factory = () => {
    make(
      ~tagged_t=Int,
      ~safeParseActions=[parserRefinement],
      ~migrationParseActions=Action.emptyArray,
      ~serializeActions=Action.emptyArray,
      (),
    )
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
  let parserRefinement = Action.refine((~input, ~struct, ~mode as _) => {
    switch input->Js.typeof == "number" {
    | true =>
      if Js.Float.isNaN(input) {
        raiseUnexpectedTypeError(~input, ~struct)
      }
    | false => raiseUnexpectedTypeError(~input, ~struct)
    }
  })

  let factory = () => {
    make(
      ~tagged_t=Float,
      ~safeParseActions=[parserRefinement],
      ~migrationParseActions=Action.emptyArray,
      ~serializeActions=Action.emptyArray,
      (),
    )
  }

  let min = Int.min->Obj.magic
  let max = Int.max->Obj.magic
}

module Date = {
  let parserRefinement = Action.refine((~input, ~struct, ~mode as _) => {
    let factory = struct->classify->unsafeGetVariantPayload
    if !(factory->Lib.Factory.factoryOf(input) && !(input->Js.Date.getTime->Js.Float.isNaN)) {
      raiseUnexpectedTypeError(~input, ~struct)
    }
  })

  let factory = () => {
    make(
      ~tagged_t=Instance(%raw(`Date`)),
      ~safeParseActions=[parserRefinement],
      ~migrationParseActions=Action.emptyArray,
      ~serializeActions=Action.emptyArray,
      (),
    )
  }
}

module Null = {
  let parseActions = [
    Action.transform((~input, ~struct, ~mode) => {
      switch input->Js.Null.toOption {
      | Some(innerData) =>
        let innerStruct = struct->classify->unsafeGetVariantPayload
        let value = parseInner(~struct=innerStruct->Obj.magic, ~any=innerData, ~mode)
        Some(value)
      | None => None
      }->unsafeAnyToUnknown
    }),
  ]

  let serializeActions = [
    Action.transform((~input, ~struct, ~mode as _) => {
      switch input {
      | Some(value) =>
        let innerStruct = struct->classify->unsafeGetVariantPayload
        serializeInner(~struct=innerStruct->Obj.magic, ~value)
      | None => Js.Null.empty->unsafeAnyToUnknown
      }
    }),
  ]

  let factory = innerStruct => {
    make(
      ~tagged_t=Null(innerStruct),
      ~safeParseActions=parseActions,
      ~migrationParseActions=parseActions,
      ~serializeActions,
      (),
    )
  }
}

module Option = {
  let parseActions = [
    Action.transform((~input, ~struct, ~mode) => {
      switch input {
      | Some(innerData) =>
        let innerStruct = struct->classify->unsafeGetVariantPayload
        let value = parseInner(~struct=innerStruct, ~any=innerData, ~mode)
        Some(value)
      | None => None
      }->unsafeAnyToUnknown
    }),
  ]

  let serializeActions = [
    Action.transform((~input, ~struct, ~mode as _) => {
      switch input {
      | Some(value) => {
          let innerStruct = struct->classify->unsafeGetVariantPayload
          serializeInner(~struct=innerStruct, ~value)
        }
      | None => Js.Undefined.empty->unsafeAnyToUnknown
      }
    }),
  ]

  let factory = innerStruct => {
    make(
      ~tagged_t=Option(innerStruct),
      ~safeParseActions=parseActions,
      ~migrationParseActions=parseActions,
      ~serializeActions,
      (),
    )
  }
}

module Deprecated = {
  type payload<'value> = {struct: t<'value>}

  let parseActions = [
    Action.transform((~input, ~struct, ~mode) => {
      switch input {
      | Some(innerData) =>
        let {struct: innerStruct} = struct->classify->Obj.magic
        let value = parseInner(~struct=innerStruct, ~any=innerData, ~mode)
        Some(value)
      | None => input
      }->unsafeAnyToUnknown
    }),
  ]

  let serializeActions = [
    Action.transform((~input, ~struct, ~mode as _) => {
      switch input {
      | Some(value) => {
          let {struct: innerStruct} = struct->classify->Obj.magic
          serializeInner(~struct=innerStruct, ~value)
        }
      | None => %raw(`undefined`)
      }
    }),
  ]

  let factory = (~message as maybeMessage=?, innerStruct) => {
    make(
      ~tagged_t=Deprecated({struct: innerStruct, maybeMessage: maybeMessage}),
      ~safeParseActions=parseActions,
      ~migrationParseActions=parseActions,
      ~serializeActions,
      (),
    )
  }
}

module Array = {
  let parseActions = [
    Action.transform((~input, ~struct, ~mode) => {
      if mode == Safe && Js.Array2.isArray(input) == false {
        raiseUnexpectedTypeError(~input, ~struct)
      }

      let innerStruct = struct->classify->unsafeGetVariantPayload

      let newArray = []
      for idx in 0 to input->Js.Array2.length - 1 {
        let innerData = input->Js.Array2.unsafe_get(idx)
        switch innerStruct->getParseOperation(~mode) {
        | Noop => newArray->Js.Array2.push(innerData)->ignore
        | Sync(fn) =>
          try {
            let value = fn(. innerData)
            newArray->Js.Array2.push(value)->ignore
          } catch {
          | Error.Internal.Exception(internalError) =>
            raise(
              Error.Internal.Exception(
                internalError->Error.Internal.prependLocation(idx->Js.Int.toString),
              ),
            )
          }
        }
      }
      newArray->unsafeAnyToUnknown
    }),
  ]

  let serializeActions = [
    Action.transform((~input, ~struct, ~mode as _) => {
      let innerStruct = struct->classify->unsafeGetVariantPayload

      let newArray = []
      for idx in 0 to input->Js.Array2.length - 1 {
        let innerData = input->Js.Array2.unsafe_get(idx)
        switch innerStruct.serialize {
        | Noop => newArray->Js.Array2.push(innerData)->ignore
        | Sync(fn) =>
          try {
            let value = fn(. innerData)
            newArray->Js.Array2.push(value)->ignore
          } catch {
          | Error.Internal.Exception(internalError) =>
            raise(
              Error.Internal.Exception(
                internalError->Error.Internal.prependLocation(idx->Js.Int.toString),
              ),
            )
          }
        }
      }
      newArray->unsafeAnyToUnknown
    }),
  ]

  let factory = innerStruct => {
    make(
      ~tagged_t=Array(innerStruct),
      ~safeParseActions=parseActions,
      ~migrationParseActions=parseActions,
      ~serializeActions,
      (),
    )
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
      switch value->Js.Array2.length == length {
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
  let parseActions = [
    Action.transform((~input, ~struct, ~mode) => {
      if mode == Safe && input->Lib.Object.test == false {
        raiseUnexpectedTypeError(~input, ~struct)
      }

      let innerStruct = struct->classify->unsafeGetVariantPayload

      let newDict = Js.Dict.empty()
      let keys = input->Js.Dict.keys
      for idx in 0 to keys->Js.Array2.length - 1 {
        let key = keys->Js.Array2.unsafe_get(idx)
        let innerData = input->Js.Dict.unsafeGet(key)
        switch innerStruct->getParseOperation(~mode) {
        | Noop => newDict->Js.Dict.set(key, innerData)->ignore
        | Sync(fn) =>
          try {
            let value = fn(. innerData)
            newDict->Js.Dict.set(key, value)->ignore
          } catch {
          | Error.Internal.Exception(internalError) =>
            raise(Error.Internal.Exception(internalError->Error.Internal.prependLocation(key)))
          }
        }
      }
      newDict->unsafeAnyToUnknown
    }),
  ]

  let serializeActions = [
    Action.transform((~input, ~struct, ~mode as _) => {
      let innerStruct = struct->classify->unsafeGetVariantPayload

      let newDict = Js.Dict.empty()
      let keys = input->Js.Dict.keys
      for idx in 0 to keys->Js.Array2.length - 1 {
        let key = keys->Js.Array2.unsafe_get(idx)
        let innerData = input->Js.Dict.unsafeGet(key)
        switch innerStruct.serialize {
        | Noop => newDict->Js.Dict.set(key, innerData)->ignore
        | Sync(fn) =>
          try {
            let value = fn(. innerData)
            newDict->Js.Dict.set(key, value)->ignore
          } catch {
          | Error.Internal.Exception(internalError) =>
            raise(Error.Internal.Exception(internalError->Error.Internal.prependLocation(key)))
          }
        }
      }
      newDict->unsafeAnyToUnknown
    }),
  ]

  let factory = innerStruct => {
    make(
      ~tagged_t=Dict(innerStruct),
      ~safeParseActions=parseActions,
      ~migrationParseActions=parseActions,
      ~serializeActions,
      (),
    )
  }
}

module Default = {
  type payload<'value> = {struct: t<option<'value>>, value: 'value}

  let parseActions = [
    Action.transform((~input, ~struct, ~mode) => {
      let {struct: innerStruct, value} = struct->classify->Obj.magic
      switch parseInner(~struct=innerStruct, ~any=input, ~mode) {
      | Some(output) => output
      | None => value
      }
    }),
  ]

  let serializeActions = [
    Action.transform((~input, ~struct, ~mode as _) => {
      let {struct: innerStruct} = struct->classify->Obj.magic
      serializeInner(~struct=innerStruct, ~value=Some(input))
    }),
  ]

  let factory = (innerStruct, defaultValue) => {
    make(
      ~tagged_t=Default({struct: innerStruct, value: defaultValue}),
      ~safeParseActions=parseActions,
      ~migrationParseActions=parseActions,
      ~serializeActions,
      (),
    )
  }
}

module Tuple = {
  let parseActions = [
    Action.transform((~input, ~struct, ~mode) => {
      let innerStructs = struct->classify->unsafeGetVariantPayload
      let numberOfStructs = innerStructs->Js.Array2.length
      if mode == Safe {
        switch Js.Array2.isArray(input) {
        | true =>
          let numberOfInputItems = input->Js.Array2.length
          if numberOfStructs !== numberOfInputItems {
            Error.Internal.raise(
              TupleSize({
                expected: numberOfStructs,
                received: numberOfInputItems,
              }),
            )
          }
        | false => raiseUnexpectedTypeError(~input, ~struct)
        }
      }

      let newArray = []
      for idx in 0 to numberOfStructs - 1 {
        let innerData = input->Js.Array2.unsafe_get(idx)
        let innerStruct = innerStructs->Js.Array2.unsafe_get(idx)
        switch innerStruct->getParseOperation(~mode) {
        | Noop => newArray->Js.Array2.push(innerData)->ignore
        | Sync(fn) =>
          try {
            let value = fn(. innerData)
            newArray->Js.Array2.push(value)->ignore
          } catch {
          | Error.Internal.Exception(internalError) =>
            raise(
              Error.Internal.Exception(
                internalError->Error.Internal.prependLocation(idx->Js.Int.toString),
              ),
            )
          }
        }
      }
      switch numberOfStructs {
      | 0 => ()->unsafeAnyToUnknown
      | 1 => newArray->Js.Array2.unsafe_get(0)->unsafeAnyToUnknown
      | _ => newArray->unsafeAnyToUnknown
      }
    }),
  ]

  let serializeActions = [
    Action.transform((~input, ~struct, ~mode as _) => {
      let innerStructs = struct->classify->unsafeGetVariantPayload
      let numberOfStructs = innerStructs->Js.Array2.length
      let inputArray = numberOfStructs == 1 ? [input->Obj.magic] : input

      let newArray = []
      for idx in 0 to numberOfStructs - 1 {
        let innerData = inputArray->Js.Array2.unsafe_get(idx)
        let innerStruct = innerStructs->Js.Array.unsafe_get(idx)
        switch innerStruct.serialize {
        | Noop => newArray->Js.Array2.push(innerData)->ignore
        | Sync(fn) =>
          try {
            let value = fn(. innerData)
            newArray->Js.Array2.push(value)->ignore
          } catch {
          | Error.Internal.Exception(internalError) =>
            raise(
              Error.Internal.Exception(
                internalError->Error.Internal.prependLocation(idx->Js.Int.toString),
              ),
            )
          }
        }
      }
      newArray->unsafeAnyToUnknown
    }),
  ]

  let innerFactory = structs => {
    make(
      ~tagged_t=Tuple(structs),
      ~safeParseActions=parseActions,
      ~migrationParseActions=parseActions,
      ~serializeActions,
      (),
    )
  }

  let factory = Lib.Fn.callWithArguments(innerFactory)
}

module Union = {
  let parseActions = [
    Action.transform((~input, ~struct, ~mode as _) => {
      let innerStructs = struct->classify->unsafeGetVariantPayload

      let idxRef = ref(0)
      let maybeErrorsRef = ref(None)
      let maybeNewValueRef = ref(None)
      while idxRef.contents < innerStructs->Js.Array2.length && maybeNewValueRef.contents == None {
        let idx = idxRef.contents
        let innerStruct = innerStructs->Js.Array2.unsafe_get(idx)
        switch innerStruct->getParseOperation(~mode=Safe) {
        | Noop => maybeNewValueRef.contents = Some(input)
        | Sync(fn) =>
          try {
            let newValue = fn(. input)
            maybeNewValueRef.contents = Some(newValue)
          } catch {
          | Error.Internal.Exception(internalError) => {
              let errors = switch maybeErrorsRef.contents {
              | Some(v) => v
              | None => {
                  let newErrosArray = []
                  maybeErrorsRef.contents = Some(newErrosArray)
                  newErrosArray
                }
              }
              errors->Js.Array2.push(internalError)->ignore
              idxRef.contents = idxRef.contents->Lib.Int.plus(1)
            }
          }
        }
      }
      switch maybeNewValueRef.contents {
      | Some(newValue) => newValue
      | None =>
        switch maybeErrorsRef.contents {
        | Some(errors) =>
          Error.Internal.raise(InvalidUnion(errors->Js.Array2.map(Error.Internal.toParseError)))
        | None => %raw(`undefined`)
        }
      }
    }),
  ]

  let serializeActions = [
    Action.transform((~input, ~struct, ~mode as _) => {
      let innerStructs = struct->classify->unsafeGetVariantPayload

      let idxRef = ref(0)
      let maybeLastErrorRef = ref(None)
      let maybeNewValueRef = ref(None)
      while idxRef.contents < innerStructs->Js.Array2.length && maybeNewValueRef.contents == None {
        let idx = idxRef.contents
        let innerStruct = innerStructs->Js.Array2.unsafe_get(idx)
        try {
          let newValue = serializeInner(~struct=innerStruct, ~value=input)
          maybeNewValueRef.contents = Some(newValue)
        } catch {
        | Error.Internal.Exception(internalError) => {
            maybeLastErrorRef.contents = Some(internalError)
            idxRef.contents = idxRef.contents->Lib.Int.plus(1)
          }
        }
      }
      switch maybeNewValueRef.contents {
      | Some(ok) => ok
      | None =>
        switch maybeLastErrorRef.contents {
        | Some(error) => raise(Error.Internal.Exception(error))
        | None => %raw(`undefined`)
        }
      }
    }),
  ]

  let factory = structs => {
    if structs->Js.Array2.length < 2 {
      Error.UnionLackingStructs.panic()
    }
    make(
      ~tagged_t=Union(structs),
      ~safeParseActions=parseActions,
      ~migrationParseActions=parseActions,
      ~serializeActions,
      (),
    )
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
    ~serializer=(. ~transformed, ~struct as _) => {
      transformed
      ->serializeWith(innerStruct)
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
    | Error(error) => Error.panic(error->Error.toString)
    }
  }

  let mapErrorToString = result => {
    result->Lib.Result.mapError(Error.toString)
  }
}
