type never

module Stdlib = {
  module Promise = {
    type t<+'a> = promise<'a>

    @send
    external thenResolve: (t<'a>, 'a => 'b) => t<'b> = "then"

    @send external then: (t<'a>, 'a => t<'b>) => t<'b> = "then"

    @send
    external thenResolveWithCatch: (t<'a>, @uncurry ('a => 'b), @uncurry (exn => 'b)) => t<'b> =
      "then"

    @val @scope("Promise")
    external resolve: 'a => t<'a> = "resolve"

    @send
    external catch: (t<'a>, @uncurry (exn => 'a)) => t<'a> = "catch"

    @scope("Promise") @val
    external all: array<t<'a>> => t<array<'a>> = "all"
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
    @inline
    let getArguments = (): array<'a> => {
      %raw(`Array.from(arguments)`)
    }

    @inline
    let call1 = (fn: 'arg1 => 'return, arg1: 'arg1): 'return => {
      Obj.magic(fn)(. arg1)
    }

    @inline
    let castToCurried = (fn: (. 'a) => 'b): ('a => 'b) => fn->Obj.magic
  }

  module Object = {
    @inline
    let test = data => {
      data->Js.typeof === "object" && data !== %raw(`null`) && !Js.Array2.isArray(data)
    }

    @val
    external overrideWith: ('object, 'object) => unit = "Object.assign"
  }

  module Set = {
    type t<'value>

    @new
    external empty: unit => t<'value> = "Set"

    @send
    external has: (t<'value>, 'value) => bool = "has"

    @send
    external add: (t<'value>, 'value) => t<'value> = "add"

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

    @send
    external append: (array<'a>, 'a) => array<'a> = "concat"
  }

  module Result = {
    @inline
    let mapError = (result, fn) =>
      switch result {
      | Ok(_) as ok => ok
      | Error(error) => Error(fn(error))
      }
  }

  module Option = {
    @inline
    let flatMap = (option, fn) =>
      switch option {
      | Some(value) => fn(value)
      | None => None
      }
  }

  module Exn = {
    type error

    @new
    external makeError: string => error = "Error"

    let raiseError = (error: error): 'a => error->Obj.magic->raise

    @inline
    let raiseEmpty = (): 'a => ()->Obj.magic->raise
  }

  module Int = {
    @inline
    let plus = (int1: int, int2: int): int => {
      (int1->Js.Int.toFloat +. int2->Js.Int.toFloat)->Obj.magic
    }

    @inline
    let test = data => {
      let x = data->Obj.magic
      data->Js.typeof === "number" && x < 2147483648. && x > -2147483649. && mod(x, 1) === 0
    }
  }

  module Dict = {
    @val
    external immutableShallowMerge: (
      @as(json`{}`) _,
      Js.Dict.t<'a>,
      Js.Dict.t<'a>,
    ) => Js.Dict.t<'a> = "Object.assign"

    @send
    external has: (Js.Dict.t<'a>, string) => bool = "hasOwnProperty"
  }

  module Bool = {
    @send external toString: bool => string = "toString"
  }

  module Function = {
    @variadic @new
    external _make: array<string> => 'function = "Function"

    @inline
    let make1 = (~ctxVarName1, ~ctxVarValue1, ~inlinedFunction) => {
      _make([ctxVarName1, `return ${inlinedFunction}`])(. ctxVarValue1)
    }

    @inline
    let make4 = (
      ~ctxVarName1,
      ~ctxVarValue1,
      ~ctxVarName2,
      ~ctxVarValue2,
      ~ctxVarName3,
      ~ctxVarValue3,
      ~ctxVarName4,
      ~ctxVarValue4,
      ~inlinedFunction,
    ) => {
      _make([ctxVarName1, ctxVarName2, ctxVarName3, ctxVarName4, `return ${inlinedFunction}`])(.
        ctxVarValue1,
        ctxVarValue2,
        ctxVarValue3,
        ctxVarValue4,
      )
    }

    @inline
    let make7 = (
      ~ctxVarName1,
      ~ctxVarValue1,
      ~ctxVarName2,
      ~ctxVarValue2,
      ~ctxVarName3,
      ~ctxVarValue3,
      ~ctxVarName4,
      ~ctxVarValue4,
      ~ctxVarName5,
      ~ctxVarValue5,
      ~ctxVarName6,
      ~ctxVarValue6,
      ~ctxVarName7,
      ~ctxVarValue7,
      ~inlinedFunction,
    ) => {
      _make([
        ctxVarName1,
        ctxVarName2,
        ctxVarName3,
        ctxVarName4,
        ctxVarName5,
        ctxVarName6,
        ctxVarName7,
        `return ${inlinedFunction}`,
      ])(.
        ctxVarValue1,
        ctxVarValue2,
        ctxVarValue3,
        ctxVarValue4,
        ctxVarValue5,
        ctxVarValue6,
        ctxVarValue7,
      )
    }
  }

  module Inlined = {
    module Constant = {
      @inline
      let errorVar = "e"
      @inline
      let inputVar = "v"
    }

    module NewPromise = {
      @inline
      let make = (~resolveVar, ~rejectVar, ~content) => {
        `new Promise(function(${resolveVar},${rejectVar}){${content}})`
      }
    }

    module Value = {
      @inline
      let stringify = any => {
        if any === %raw("undefined") {
          "undefined"
        } else {
          any->Js.Json.stringifyAny->Obj.magic
        }
      }

      @inline
      let fromString = (string: string): string => string->Js.Json.stringifyAny->Obj.magic
    }

    module Fn = {
      @inline
      let make = (~arguments, ~content) => {
        `function(${arguments}){${content}}`
      }
    }

    module If = {
      @inline
      let make = (~condition, ~content) => {
        `if(${condition}){${content}}`
      }
    }

    module TryCatch = {
      @inline
      let make = (~tryContent, ~catchContent) => {
        `try{${tryContent}}catch(${Constant.errorVar}){${catchContent}}`
      }
    }
  }
}

module Path = {
  type t = string

  external toString: t => string = "%identity"

  @inline
  let empty = ""

  let toArray = path => {
    switch path {
    | "" => []
    | _ =>
      path
      ->Js.String2.split(`"]["`)
      ->Js.Array2.joinWith(`","`)
      ->Js.Json.parseExn
      ->(Obj.magic: Js.Json.t => array<string>)
    }
  }

  @inline
  let fromLocation = location => `[${location->Stdlib.Inlined.Value.fromString}]`

  let fromArray = array => {
    switch array {
    | [] => ""
    | [location] => fromLocation(location)
    | _ =>
      "[" ++ array->Js.Array2.map(Stdlib.Inlined.Value.fromString)->Js.Array2.joinWith("][") ++ "]"
    }
  }

  let concat = (path, concatedPath) => path ++ concatedPath
}

module Error = {
  @inline
  let panic = message => Stdlib.Exn.raiseError(Stdlib.Exn.makeError(`[rescript-struct] ${message}`))

  type rec t = {operation: operation, code: code, path: Path.t}
  and code =
    | OperationFailed(string)
    | MissingParser
    | MissingSerializer
    | UnexpectedType({expected: string, received: string})
    | UnexpectedValue({expected: string, received: string})
    | TupleSize({expected: int, received: int})
    | ExcessField(string)
    | InvalidUnion(array<t>)
    | UnexpectedAsync
    | InvalidJsonStruct({received: string})
  and operation =
    | Serializing
    | Parsing

  module Internal = {
    type public = t
    type t = {
      @as("c")
      code: code,
      @as("p")
      path: Path.t,
    }

    exception Exception(t)

    module UnexpectedValue = {
      let raise = (~expected, ~received, ~initialPath=Path.empty, ()) => {
        raise(
          Exception({
            code: UnexpectedValue({
              expected: expected->Stdlib.Inlined.Value.stringify,
              received: received->Stdlib.Inlined.Value.stringify,
            }),
            path: initialPath,
          }),
        )
      }
    }

    let raise = code => {
      raise(Exception({code, path: Path.empty}))
    }

    let toParseError = (internalError: t): public => {
      {
        operation: Parsing,
        code: internalError.code,
        path: internalError.path,
      }
    }

    let toSerializeError = (internalError: t): public => {
      operation: Serializing,
      code: internalError.code,
      path: internalError.path,
    }

    @inline
    let fromPublic = (publicError: public): t => {
      code: publicError.code,
      path: publicError.path,
    }

    let prependPath = (error, path) => {
      {
        ...error,
        path: Path.concat(path, error.path),
      }
    }
    let prependLocation = (error, location) => {
      error->prependPath(location->Path.fromLocation)
    }
  }

  module MissingParserAndSerializer = {
    let panic = location => panic(`For a ${location} either a parser, or a serializer is required`)
  }

  module Unreachable = {
    let panic = () => panic("Unreachable")
  }

  let raiseCustom = error => {
    raise(Internal.Exception(error->Internal.fromPublic))
  }

  let raise = message => {
    raise(Internal.Exception({code: OperationFailed(message), path: Path.empty}))
  }

  let rec toReason = (~nestedLevel=0, error) => {
    switch error.code {
    | OperationFailed(reason) => reason
    | MissingParser => "Struct parser is missing"
    | MissingSerializer => "Struct serializer is missing"
    | UnexpectedAsync => "Encountered unexpected asynchronous transform or refine. Use parseAsyncWith instead of parseWith"
    | ExcessField(fieldName) =>
      `Encountered disallowed excess key "${fieldName}" on an object. Use Deprecated to ignore a specific field, or S.Object.strip to ignore excess keys completely`
    | UnexpectedType({expected, received})
    | UnexpectedValue({expected, received}) =>
      `Expected ${expected}, received ${received}`
    | InvalidJsonStruct({received}) => `The struct ${received} is not compatible with JSON`
    | TupleSize({expected, received}) =>
      `Expected Tuple with ${expected->Js.Int.toString} items, received ${received->Js.Int.toString}`
    | InvalidUnion(errors) => {
        let lineBreak = `\n${" "->Js.String2.repeat(nestedLevel * 2)}`
        let reasons =
          errors
          ->Js.Array2.map(error => {
            let reason = error->toReason(~nestedLevel=nestedLevel->Stdlib.Int.plus(1))
            let location = switch error.path {
            | "" => ""
            | nonEmptyPath => `Failed at ${nonEmptyPath}. `
            }
            `- ${location}${reason}`
          })
          ->Stdlib.Array.unique
        `Invalid union with following errors${lineBreak}${reasons->Js.Array2.joinWith(lineBreak)}`
      }
    }
  }

  let toString = error => {
    let operation = switch error.operation {
    | Serializing => "serializing"
    | Parsing => "parsing"
    }
    let reason = error->toReason
    let pathText = switch error.path {
    | "" => "root"
    | nonEmptyPath => nonEmptyPath
    }
    `Failed ${operation} at ${pathText}. Reason: ${reason}`
  }
}

exception Raised(Error.t)

type rec literal<'value> =
  | String(string): literal<string>
  | Int(int): literal<int>
  | Float(float): literal<float>
  | Bool(bool): literal<bool>
  | EmptyNull: literal<unit>
  | EmptyOption: literal<unit>
  | NaN: literal<unit>
type taggedLiteral =
  | String(string)
  | Int(int)
  | Float(float)
  | Bool(bool)
  | EmptyNull
  | EmptyOption
  | NaN
type operation =
  | NoOperation
  | SyncOperation((. unknown) => unknown)
  | AsyncOperation((. unknown) => (. unit) => promise<unknown>)

module ParseOperationState = {
  type t

  @inline
  let empty = (): t => 0->Obj.magic

  @inline
  let asyncEmpty = (): t => 1->Obj.magic

  @inline
  let syncCompiling = (): t => 2->Obj.magic

  @inline
  let asyncCompiling = (): t => 3->Obj.magic

  @inline
  let toCompiling = (operationState): t => {
    if operationState === asyncEmpty() {
      asyncCompiling()
    } else {
      syncCompiling()
    }
  }
  let operation: operation => t = Obj.magic

  @inline
  let isSyncCompiling = operationState => {
    operationState === syncCompiling()
  }

  @inline
  let isAsyncCompiling = operationState => {
    operationState === asyncCompiling()
  }

  @inline
  let isReady = operationState => {
    Js.typeof(operationState) !== "number"
  }

  let unsafeToOperation: t => operation = Obj.magic
}

module SerializeOperationState = {
  type t
  type operation = option<(. unknown) => unknown>

  @inline
  let empty = (): t => 0->Obj.magic

  @inline
  let compiling = (): t => 1->Obj.magic

  let operation: operation => t = Obj.magic

  @inline
  let isCompiling = operationState => {
    operationState === compiling()
  }

  @inline
  let isReady = operationState => {
    Js.typeof(operationState) !== "number"
  }

  let unsafeToOperation: t => operation = Obj.magic
}

type rec t<'value> = {
  @as("n")
  name: string,
  @as("t")
  tagged: tagged,
  @as("pf")
  parseTransformationFactory: internalTransformationFactory,
  @as("sf")
  serializeTransformationFactory: internalTransformationFactory,
  @as("r")
  mutable parseOperationState: ParseOperationState.t,
  @as("e")
  mutable serializeOperationState: SerializeOperationState.t,
  @as("s")
  mutable serialize: (. unknown) => unknown,
  @as("j")
  mutable serializeToJson: (. unknown) => Js.Json.t,
  @as("p")
  mutable parse: (. unknown) => unknown,
  @as("a")
  mutable parseAsync: (. unknown) => (. unit) => promise<unknown>,
  @as("i")
  maybeInlinedRefinement: option<string>,
  @as("m")
  maybeMetadataDict: option<Js.Dict.t<unknown>>,
}
and tagged =
  | Never
  | Unknown
  | String
  | Int
  | Float
  | Bool
  | Literal(taggedLiteral)
  | Option(t<unknown>)
  | Null(t<unknown>)
  | Array(t<unknown>)
  | Object({fields: Js.Dict.t<t<unknown>>, fieldNames: array<string>})
  | Tuple(array<t<unknown>>)
  | Union(array<t<unknown>>)
  | Dict(t<unknown>)
and transformation<'input, 'output> =
  | Sync('input => 'output)
  | Async('input => promise<'output>)
and internalTransformationFactoryCtxPhase = NoTransformation | OnlySync | OnlyAsync | SyncAndAsync
and internalTransformationFactoryCtx = {
  @as("p")
  mutable phase: internalTransformationFactoryCtxPhase,
  @as("s")
  mutable syncTransformation: (. unknown) => unknown,
  @as("a")
  mutable asyncTransformation: (. unknown) => promise<unknown>,
}
and internalTransformationFactory = (
  . ~ctx: internalTransformationFactoryCtx,
  ~struct: t<unknown>,
) => unit

type payloadedVariant<'payload> = {_0: 'payload}
let unsafeGetVariantPayload = variant => (variant->Obj.magic)._0

external castAnyToUnknown: 'any => unknown = "%identity"
external castUnknownToAny: unknown => 'any = "%identity"
external castUnknownStructToAnyStruct: t<unknown> => t<'any> = "%identity"
external castAnyStructToUnknownStruct: t<'any> => t<unknown> = "%identity"
external castToTaggedLiteral: literal<'a> => taggedLiteral = "%identity"
external castPublicTransformationFactoryToUncurried: (
  (~struct: t<'value>) => transformation<'input, 'output>,
  . ~struct: t<unknown>,
) => transformation<unknown, unknown> = "%identity"

module TransformationFactory = {
  module Ctx = {
    @inline
    let make = () => {
      {
        phase: NoTransformation,
        syncTransformation: %raw("undefined"),
        asyncTransformation: %raw("undefined"),
      }
    }

    @inline
    let makeSyncTransformation = (fn: 'a => 'b): ((. unknown) => unknown) => fn->Obj.magic

    @inline
    let makeAsyncTransformation = (fn: 'a => promise<'b>): ((. unknown) => promise<unknown>) =>
      fn->Obj.magic

    let planSyncTransformation = (ctx, transformation) => {
      let prevSyncTransformation = ctx.syncTransformation
      let prevAsyncTransformation = ctx.asyncTransformation
      let nextSyncTransformation = makeSyncTransformation(transformation)
      switch ctx.phase {
      | NoTransformation => {
          ctx.phase = OnlySync
          ctx.syncTransformation = nextSyncTransformation
        }

      | OnlySync =>
        ctx.syncTransformation = (. input) =>
          nextSyncTransformation(. prevSyncTransformation(. input))

      | OnlyAsync
      | SyncAndAsync =>
        ctx.asyncTransformation = (. input) =>
          prevAsyncTransformation(. input)->Stdlib.Promise.thenResolve(
            nextSyncTransformation->Stdlib.Fn.castToCurried,
          )
      }
    }

    let planAsyncTransformation = (ctx, transformation) => {
      let prevAsyncTransformation = ctx.asyncTransformation
      let nextAsyncTransformation = makeAsyncTransformation(transformation)
      switch ctx.phase {
      | NoTransformation => {
          ctx.phase = OnlyAsync
          ctx.asyncTransformation = nextAsyncTransformation
        }

      | OnlySync => {
          ctx.phase = SyncAndAsync
          ctx.asyncTransformation = nextAsyncTransformation
        }

      | OnlyAsync
      | SyncAndAsync =>
        ctx.asyncTransformation = (. input) =>
          prevAsyncTransformation(. input)->Stdlib.Promise.then(
            nextAsyncTransformation->Stdlib.Fn.castToCurried,
          )
      }
    }

    let planMissingParserTransformation = ctx => {
      ctx->planSyncTransformation(_ => Error.Internal.raise(MissingParser))
    }

    let planMissingSerializerTransformation = ctx => {
      ctx->planSyncTransformation(_ => Error.Internal.raise(MissingSerializer))
    }
  }

  external make: (
    (. ~ctx: internalTransformationFactoryCtx, ~struct: t<'value>) => unit
  ) => internalTransformationFactory = "%identity"

  let empty = make((. ~ctx as _, ~struct as _) => ())

  let compile = (transformationFactory, ~struct) => {
    let ctx = Ctx.make()
    transformationFactory(. ~ctx, ~struct)
    switch ctx.phase {
    | NoTransformation => NoOperation
    | OnlySync => SyncOperation(ctx.syncTransformation)
    | OnlyAsync => AsyncOperation((. input) => (. ()) => ctx.asyncTransformation(. input))
    | SyncAndAsync =>
      AsyncOperation(
        (. input) => {
          let syncOutput = ctx.syncTransformation(. input)
          (. ()) => ctx.asyncTransformation(. syncOutput)
        },
      )
    }
  }
}

@inline
let classify = struct => struct.tagged

@inline
let name = struct => struct.name

let getParseOperation = struct => {
  let parseOperationState = struct.parseOperationState
  if parseOperationState->ParseOperationState.isReady {
    parseOperationState->ParseOperationState.unsafeToOperation
  } else if parseOperationState->ParseOperationState.isSyncCompiling {
    SyncOperation((. input) => struct.parse(. input))
  } else if parseOperationState->ParseOperationState.isAsyncCompiling {
    AsyncOperation((. input) => struct.parseAsync(. input))
  } else {
    struct.parseOperationState = parseOperationState->ParseOperationState.toCompiling
    let compiledParseOperation =
      struct.parseTransformationFactory->TransformationFactory.compile(~struct)
    struct.parseOperationState = ParseOperationState.operation(compiledParseOperation)
    compiledParseOperation
  }
}

let getSerializeOperation = struct => {
  let serializeOperationState = struct.serializeOperationState
  if serializeOperationState->SerializeOperationState.isReady {
    serializeOperationState->SerializeOperationState.unsafeToOperation
  } else if serializeOperationState->SerializeOperationState.isCompiling {
    Some((. input) => struct.serialize(. input))
  } else {
    struct.serializeOperationState = SerializeOperationState.compiling()
    let compiledSerializeOperation = switch struct.serializeTransformationFactory->TransformationFactory.compile(
      ~struct,
    ) {
    | NoOperation => None
    | SyncOperation(fn) => Some(fn)
    | AsyncOperation(_) => Error.Unreachable.panic()
    }
    struct.serializeOperationState = SerializeOperationState.operation(compiledSerializeOperation)
    compiledSerializeOperation
  }
}

@inline
let isAsyncParse = struct => {
  let struct = struct->castAnyStructToUnknownStruct
  switch struct->getParseOperation {
  | AsyncOperation(_) => true
  | NoOperation
  | SyncOperation(_) => false
  }
}

let raiseUnexpectedTypeError = (~input: 'any, ~struct: t<'any2>) => {
  Error.Internal.raise(
    UnexpectedType({
      expected: struct.name,
      received: switch input->Js.Types.classify {
      | JSFalse | JSTrue => "Bool"
      | JSString(_) => "String"
      | JSNull => "Null"
      | JSNumber(number) if Js.Float.isNaN(number) => "NaN Literal (NaN)"
      | JSNumber(_) => "Float"
      | JSObject(object) if Js.Array2.isArray(object) => "Array"
      | JSObject(_) => "Object"
      | JSFunction(_) => "Function"
      | JSUndefined => "Option"
      | JSSymbol(_) => "Symbol"
      | JSBigInt(_) => "BigInt"
      },
    }),
  )
}

let noOperation = (. input) => input

let initialSerialize = (. input) => {
  let struct = %raw("this")
  let compiledSerialize = switch struct->getSerializeOperation {
  | None => noOperation
  | Some(fn) => fn
  }
  struct.serialize = compiledSerialize
  compiledSerialize(. input)
}

let rec validateJsonStruct = struct => {
  switch struct->classify {
  | String
  | Int
  | Float
  | Bool
  | Never
  | Literal(String(_))
  | Literal(Int(_))
  | Literal(Float(_))
  | Literal(Bool(_))
  | Literal(EmptyNull) => ()
  | Dict(childStruct)
  | Null(childStruct)
  | Array(childStruct) =>
    childStruct->validateJsonStruct
  | Object({fieldNames, fields}) =>
    for idx in 0 to fieldNames->Js.Array2.length - 1 {
      let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
      let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
      try {
        fieldStruct->validateJsonStruct
      } catch {
      | Error.Internal.Exception(e) =>
        raise(Error.Internal.Exception(e->Error.Internal.prependLocation(fieldName)))
      }
    }

  | Tuple(childrenStructs) =>
    childrenStructs->Js.Array2.forEachi((childStruct, i) => {
      try {
        childStruct->validateJsonStruct
      } catch {
      | Error.Internal.Exception(e) =>
        raise(Error.Internal.Exception(e->Error.Internal.prependLocation(i->Js.Int.toString)))
      }
    })
  | Union(childrenStructs) => childrenStructs->Js.Array2.forEach(validateJsonStruct)
  | Option(_)
  | Unknown
  | Literal(EmptyOption)
  | Literal(NaN) =>
    Error.Internal.raise(InvalidJsonStruct({received: struct->name}))
  }
}

let initialSerializeToJson = (. input) => {
  let struct = %raw("this")
  try {
    validateJsonStruct(struct)
    if struct.serialize === initialSerialize {
      let compiledSerialize = switch struct->getSerializeOperation {
      | None => noOperation
      | Some(fn) => fn
      }
      struct.serialize = compiledSerialize
    }
    struct.serializeToJson =
      struct.serialize->(Obj.magic: ((. unknown) => unknown) => (. unknown) => Js.Json.t)
  } catch {
  | Error.Internal.Exception(_) as exn => struct.serializeToJson = (. _) => raise(exn)
  }
  struct.serializeToJson(. input)
}

let intitialParse = (. input) => {
  let struct = %raw("this")
  let compiledParse = switch struct->getParseOperation {
  | NoOperation => noOperation
  | SyncOperation(fn) => fn
  | AsyncOperation(_) => (. _) => Error.Internal.raise(UnexpectedAsync)
  }
  struct.parse = compiledParse
  compiledParse(. input)
}

let asyncNoopOperation = (. input) => (. ()) => input->Stdlib.Promise.resolve

let intitialParseAsync = (. input) => {
  let struct = %raw("this")
  let compiledParseAsync = switch struct->getParseOperation {
  | NoOperation => asyncNoopOperation
  | SyncOperation(fn) =>
    (. input) => {
      let syncValue = fn(. input)
      (. ()) => syncValue->Stdlib.Promise.resolve
    }
  | AsyncOperation(fn) => fn
  }
  struct.parseAsync = compiledParseAsync
  compiledParseAsync(. input)
}

@inline
let make = (
  ~name,
  ~tagged,
  ~parseTransformationFactory,
  ~serializeTransformationFactory,
  ~inlinedRefinement as maybeInlinedRefinement=?,
  ~metadataDict as maybeMetadataDict=?,
  (),
) => {
  name,
  tagged,
  parseTransformationFactory,
  serializeTransformationFactory,
  parseOperationState: ParseOperationState.empty(),
  serializeOperationState: SerializeOperationState.empty(),
  serialize: initialSerialize,
  serializeToJson: initialSerializeToJson,
  parse: intitialParse,
  parseAsync: intitialParseAsync,
  maybeInlinedRefinement,
  maybeMetadataDict,
}

let parseWith = (any, struct) => {
  try {
    struct.parse(. any->castAnyToUnknown)->castUnknownToAny->Ok
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  }
}

let parseOrRaiseWith = (any, struct) => {
  try {
    struct.parse(. any->castAnyToUnknown)->castUnknownToAny
  } catch {
  | Error.Internal.Exception(internalError) =>
    raise(Raised(internalError->Error.Internal.toParseError))
  }
}

let asyncPrepareOk = value => Ok(value->castUnknownToAny)

let asyncPrepareError = exn => {
  switch exn {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  | _ => raise(exn)
  }
}

let parseAsyncWith = (any, struct) => {
  try {
    struct.parseAsync(. any->castAnyToUnknown)(.)->Stdlib.Promise.thenResolveWithCatch(
      asyncPrepareOk,
      asyncPrepareError,
    )
  } catch {
  | Error.Internal.Exception(internalError) =>
    internalError->Error.Internal.toParseError->Error->Stdlib.Promise.resolve
  }
}

let parseAsyncInStepsWith = (any, struct) => {
  try {
    let asyncFn = struct.parseAsync(. any->castAnyToUnknown)

    (
      (. ()) => asyncFn(.)->Stdlib.Promise.thenResolveWithCatch(asyncPrepareOk, asyncPrepareError)
    )->Ok
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  }
}

let serializeWith = (value, struct) => {
  try {
    struct.serialize(. value->castAnyToUnknown)->Ok
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toSerializeError->Error
  }
}

let serializeOrRaiseWith = (value, struct) => {
  try {
    struct.serialize(. value->castAnyToUnknown)
  } catch {
  | Error.Internal.Exception(internalError) =>
    raise(Raised(internalError->Error.Internal.toSerializeError))
  }
}

let serializeToJsonWith = (value, struct) => {
  try {
    struct.serializeToJson(. value->castAnyToUnknown)->Ok
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toSerializeError->Error
  }
}

let serializeToJsonStringWith = (value: 'value, ~space=0, struct: t<'value>): result<
  string,
  Error.t,
> => {
  switch value->serializeToJsonWith(struct) {
  | Ok(json) => Ok(json->Js.Json.stringifyWithSpace(space))
  | Error(_) as e => e
  }
}

let parseJsonWith: (Js.Json.t, t<'value>) => result<'value, Error.t> = parseWith

let parseJsonStringWith = (jsonString: string, struct: t<'value>): result<'value, Error.t> => {
  switch try {
    jsonString->Js.Json.parseExn->Ok
  } catch {
  | Js.Exn.Error(error) =>
    Error({
      Error.code: OperationFailed(error->Js.Exn.message->(Obj.magic: option<string> => string)),
      operation: Parsing,
      path: Path.empty,
    })
  } {
  | Ok(json) => json->parseJsonWith(struct)
  | Error(_) as e => e
  }
}

let recursive = fn => {
  let placeholder: t<'value> = %raw(`{}`)
  let struct = fn->Stdlib.Fn.call1(placeholder)
  placeholder->Stdlib.Object.overrideWith(struct)
  if placeholder->isAsyncParse {
    Error.panic(
      `The "${struct->name}" struct in the S.recursive has an async parser. To make it work, use S.asyncRecursive instead.`,
    )
  }
  placeholder
}

let asyncRecursive = fn => {
  let placeholder: t<'value> = %raw(`{}`)
  let struct = fn->Stdlib.Fn.call1(placeholder)
  placeholder->Stdlib.Object.overrideWith(struct)
  placeholder.parseOperationState = ParseOperationState.asyncEmpty()
  placeholder
}

module Metadata = {
  module Id: {
    type t<'metadata>
    let make: (~namespace: string, ~name: string) => t<'metadata>
    external toKey: t<'metadata> => string = "%identity"
  } = {
    type t<'metadata> = string

    let make = (~namespace, ~name) => {
      `${namespace}:${name}`
    }

    external toKey: t<'metadata> => string = "%identity"
  }

  module Change = {
    @inline
    let make = (~id: Id.t<'metadata>, ~metadata: 'metadata) => {
      let metadataChange = Js.Dict.empty()
      metadataChange->Js.Dict.set(id->Id.toKey, metadata)
      metadataChange->(Obj.magic: Js.Dict.t<'any> => Js.Dict.t<unknown>)
    }
  }

  let get = (struct, ~id: Id.t<'metadata>): option<'metadata> => {
    struct.maybeMetadataDict->Stdlib.Option.flatMap(metadataDict => {
      metadataDict->Js.Dict.get(id->Id.toKey)->Obj.magic
    })
  }

  let set = (struct, ~id: Id.t<'metadata>, ~metadata: 'metadata) => {
    make(
      ~name=struct.name,
      ~parseTransformationFactory=struct.parseTransformationFactory,
      ~serializeTransformationFactory=struct.serializeTransformationFactory,
      ~tagged=struct.tagged,
      ~metadataDict=Stdlib.Dict.immutableShallowMerge(
        struct.maybeMetadataDict->Obj.magic,
        Change.make(~id, ~metadata),
      ),
      (),
    )
  }
}

let refine: (
  t<'value>,
  ~parser: 'value => unit=?,
  ~serializer: 'value => unit=?,
  unit,
) => t<'value> = (
  struct,
  ~parser as maybeRefineParser=?,
  ~serializer as maybeRefineSerializer=?,
  (),
) => {
  if maybeRefineParser === None && maybeRefineSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Refine`)
  }

  let nextParseTransformationFactory = switch maybeRefineParser {
  | Some(refineParser) =>
    TransformationFactory.make((. ~ctx, ~struct as compilingStruct) => {
      struct.parseTransformationFactory(. ~ctx, ~struct=compilingStruct)
      ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
        let () = refineParser->Stdlib.Fn.call1(input)
        input
      })
    })
  | None => struct.parseTransformationFactory
  }

  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseTransformationFactory=nextParseTransformationFactory,
    ~serializeTransformationFactory=switch maybeRefineSerializer {
    | Some(refineSerializer) =>
      TransformationFactory.make((. ~ctx, ~struct as compilingStruct) => {
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          let () = refineSerializer->Stdlib.Fn.call1(input)
          input
        })
        struct.serializeTransformationFactory(. ~ctx, ~struct=compilingStruct)
      })
    | None => struct.serializeTransformationFactory
    },
    ~metadataDict=?struct.maybeMetadataDict,
    ~inlinedRefinement=?nextParseTransformationFactory === struct.parseTransformationFactory
      ? struct.maybeInlinedRefinement
      : None,
    (),
  )
}

let addRefinement = (struct, ~metadataId, ~refinement, ~refiner) => {
  struct
  ->Metadata.set(
    ~id=metadataId,
    ~metadata={
      switch struct->Metadata.get(~id=metadataId) {
      | Some(refinements) => refinements->Stdlib.Array.append(refinement)
      | None => [refinement]
      }
    },
  )
  ->refine(~parser=refiner, ~serializer=refiner, ())
}

let asyncRefine = (struct, ~parser, ()) => {
  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as compilingStruct) => {
      struct.parseTransformationFactory(. ~ctx, ~struct=compilingStruct)
      ctx->TransformationFactory.Ctx.planAsyncTransformation(input => {
        parser
        ->Stdlib.Fn.call1(input)
        ->Stdlib.Promise.thenResolve(
          () => {
            input
          },
        )
      })
    }),
    ~serializeTransformationFactory=struct.serializeTransformationFactory,
    ~metadataDict=?struct.maybeMetadataDict,
    (),
  )
}

let transform: (
  t<'value>,
  ~parser: 'value => 'transformed=?,
  ~serializer: 'transformed => 'value=?,
  unit,
) => t<'transformed> = (
  struct,
  ~parser as maybeTransformParser=?,
  ~serializer as maybeTransformSerializer=?,
  (),
) => {
  if maybeTransformParser === None && maybeTransformSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Transform`)
  }

  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as compilingStruct) => {
      struct.parseTransformationFactory(. ~ctx, ~struct=compilingStruct)
      switch maybeTransformParser {
      | Some(transformParser) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(transformParser)
      | None => ctx->TransformationFactory.Ctx.planMissingParserTransformation
      }
    }),
    ~serializeTransformationFactory=TransformationFactory.make((.
      ~ctx,
      ~struct as compilingStruct,
    ) => {
      switch maybeTransformSerializer {
      | Some(transformSerializer) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(transformSerializer)
      | None => ctx->TransformationFactory.Ctx.planMissingSerializerTransformation
      }
      struct.serializeTransformationFactory(. ~ctx, ~struct=compilingStruct)
    }),
    ~metadataDict=?struct.maybeMetadataDict,
    (),
  )
}

let advancedTransform: (
  t<'value>,
  ~parser: (~struct: t<'value>) => transformation<'value, 'transformed>=?,
  ~serializer: (~struct: t<'value>) => transformation<'transformed, 'value>=?,
  unit,
) => t<'transformed> = (
  struct,
  ~parser as maybeTransformParser=?,
  ~serializer as maybeTransformSerializer=?,
  (),
) => {
  if maybeTransformParser === None && maybeTransformSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Transform`)
  }

  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as compilingStruct) => {
      struct.parseTransformationFactory(. ~ctx, ~struct=compilingStruct)
      switch maybeTransformParser {
      | Some(transformParser) =>
        switch (transformParser->castPublicTransformationFactoryToUncurried)(.
          ~struct=compilingStruct->castUnknownStructToAnyStruct,
        ) {
        | Sync(syncTransformation) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(syncTransformation)
        | Async(asyncTransformation) =>
          ctx->TransformationFactory.Ctx.planAsyncTransformation(asyncTransformation)
        }
      | None => ctx->TransformationFactory.Ctx.planMissingParserTransformation
      }
    }),
    ~serializeTransformationFactory=TransformationFactory.make((.
      ~ctx,
      ~struct as compilingStruct,
    ) => {
      switch maybeTransformSerializer {
      | Some(transformSerializer) =>
        switch (transformSerializer->castPublicTransformationFactoryToUncurried)(.
          ~struct=compilingStruct->castUnknownStructToAnyStruct,
        ) {
        | Sync(syncTransformation) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(syncTransformation)
        | Async(asyncTransformation) =>
          ctx->TransformationFactory.Ctx.planAsyncTransformation(asyncTransformation)
        }
      | None => ctx->TransformationFactory.Ctx.planMissingSerializerTransformation
      }
      struct.serializeTransformationFactory(. ~ctx, ~struct=compilingStruct)
    }),
    ~metadataDict=?struct.maybeMetadataDict,
    (),
  )
}

let rec advancedPreprocess = (
  struct,
  ~parser as maybePreprocessParser=?,
  ~serializer as maybePreprocessSerializer=?,
  (),
) => {
  if maybePreprocessParser === None && maybePreprocessSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Preprocess`)
  }

  switch struct->classify {
  | Union(unionStructs) =>
    make(
      ~name=struct.name,
      ~tagged=Union(
        unionStructs->Js.Array2.map(unionStruct =>
          unionStruct
          ->castUnknownStructToAnyStruct
          ->advancedPreprocess(
            ~parser=?maybePreprocessParser,
            ~serializer=?maybePreprocessSerializer,
            (),
          )
          ->castAnyStructToUnknownStruct
        ),
      ),
      ~parseTransformationFactory=struct.parseTransformationFactory,
      ~serializeTransformationFactory=struct.serializeTransformationFactory,
      ~metadataDict=?struct.maybeMetadataDict,
      (),
    )
  | _ =>
    make(
      ~name=struct.name,
      ~tagged=struct.tagged,
      ~parseTransformationFactory=TransformationFactory.make((.
        ~ctx,
        ~struct as compilingStruct,
      ) => {
        switch maybePreprocessParser {
        | Some(preprocessParser) =>
          switch (preprocessParser->castPublicTransformationFactoryToUncurried)(.
            ~struct=compilingStruct->castUnknownStructToAnyStruct,
          ) {
          | Sync(syncTransformation) =>
            ctx->TransformationFactory.Ctx.planSyncTransformation(syncTransformation)
          | Async(asyncTransformation) =>
            ctx->TransformationFactory.Ctx.planAsyncTransformation(asyncTransformation)
          }
        | None => ctx->TransformationFactory.Ctx.planMissingParserTransformation
        }
        struct.parseTransformationFactory(. ~ctx, ~struct=compilingStruct)
      }),
      ~serializeTransformationFactory=TransformationFactory.make((.
        ~ctx,
        ~struct as compilingStruct,
      ) => {
        struct.serializeTransformationFactory(. ~ctx, ~struct=compilingStruct)
        switch maybePreprocessSerializer {
        | Some(preprocessSerializer) =>
          switch (preprocessSerializer->castPublicTransformationFactoryToUncurried)(.
            ~struct=compilingStruct->castUnknownStructToAnyStruct,
          ) {
          | Sync(syncTransformation) =>
            ctx->TransformationFactory.Ctx.planSyncTransformation(syncTransformation)
          | Async(asyncTransformation) =>
            ctx->TransformationFactory.Ctx.planAsyncTransformation(asyncTransformation)
          }
        | None => ctx->TransformationFactory.Ctx.planMissingSerializerTransformation
        }
      }),
      ~metadataDict=?struct.maybeMetadataDict,
      (),
    )
  }
}

let custom = (
  ~name,
  ~parser as maybeCustomParser=?,
  ~serializer as maybeCustomSerializer=?,
  (),
) => {
  if maybeCustomParser === None && maybeCustomSerializer === None {
    Error.MissingParserAndSerializer.panic(`Custom struct factory`)
  }

  make(
    ~name,
    ~tagged=Unknown,
    ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
      switch maybeCustomParser {
      | Some(customParser) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(customParser->Obj.magic)
      | None => ctx->TransformationFactory.Ctx.planMissingParserTransformation
      }
    }),
    ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
      switch maybeCustomSerializer {
      | Some(customSerializer) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(customSerializer->Obj.magic)
      | None => ctx->TransformationFactory.Ctx.planMissingSerializerTransformation
      }
    }),
    (),
  )
}

module Literal = {
  module Variant = {
    let factory:
      type literalValue variant. (literal<literalValue>, variant) => t<variant> =
      (innerLiteral, variant) => {
        let tagged = Literal(innerLiteral->castToTaggedLiteral)

        let makeParseTransformationFactory = (~literalValue, ~test) => {
          TransformationFactory.make((. ~ctx, ~struct) =>
            ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
              if test->Stdlib.Fn.call1(input) {
                if literalValue->castAnyToUnknown === input {
                  variant
                } else {
                  Error.Internal.UnexpectedValue.raise(~expected=literalValue, ~received=input, ())
                }
              } else {
                raiseUnexpectedTypeError(~input, ~struct)
              }
            })
          )
        }

        let makeSerializeTransformationFactory = output => {
          TransformationFactory.make((. ~ctx, ~struct as _) =>
            ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
              if input === variant {
                output
              } else {
                Error.Internal.UnexpectedValue.raise(~expected=variant, ~received=input, ())
              }
            })
          )
        }

        switch innerLiteral {
        | EmptyNull =>
          make(
            ~name="EmptyNull Literal (null)",
            ~tagged,
            ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
              ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
                if input === Js.Null.empty {
                  variant
                } else {
                  raiseUnexpectedTypeError(~input, ~struct)
                }
              })
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(Js.Null.empty),
            (),
          )
        | EmptyOption =>
          make(
            ~name="EmptyOption Literal (undefined)",
            ~tagged,
            ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
              ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
                if input === Js.Undefined.empty {
                  variant
                } else {
                  raiseUnexpectedTypeError(~input, ~struct)
                }
              })
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(Js.Undefined.empty),
            (),
          )
        | NaN =>
          make(
            ~name="NaN Literal (NaN)",
            ~tagged,
            ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
              ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
                if Js.Float.isNaN(input) {
                  variant
                } else {
                  raiseUnexpectedTypeError(~input, ~struct)
                }
              })
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(Js.Float._NaN),
            (),
          )
        | Bool(bool) =>
          make(
            ~name=`Bool Literal (${bool->Stdlib.Bool.toString})`,
            ~tagged,
            ~parseTransformationFactory=makeParseTransformationFactory(
              ~literalValue=bool,
              ~test=input => input->Js.typeof === "boolean",
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(bool),
            (),
          )
        | String(string) =>
          make(
            ~name=`String Literal ("${string}")`,
            ~tagged,
            ~parseTransformationFactory=makeParseTransformationFactory(
              ~literalValue=string,
              ~test=input => input->Js.typeof === "string",
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(string),
            (),
          )
        | Float(float) =>
          make(
            ~name=`Float Literal (${float->Js.Float.toString})`,
            ~tagged,
            ~parseTransformationFactory=makeParseTransformationFactory(
              ~literalValue=float,
              ~test=input => input->Js.typeof === "number",
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(float),
            (),
          )
        | Int(int) =>
          make(
            ~name=`Int Literal (${int->Js.Int.toString})`,
            ~tagged,
            ~parseTransformationFactory=makeParseTransformationFactory(
              ~literalValue=int,
              ~test=input => input->Stdlib.Int.test,
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(int),
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

module Object = {
  module UnknownKeys = {
    type tagged =
      | Strict
      | Strip

    let metadataId: Metadata.Id.t<tagged> = Metadata.Id.make(
      ~namespace="rescript-struct",
      ~name="Object_UnknownKeys",
    )

    let classify = struct => {
      switch struct->Metadata.get(~id=metadataId) {
      | Some(t) => t
      | None => Strip
      }
    }
  }

  module FieldDefinition = {
    type struct = t<unknown>
    type t = {
      @as("s")
      fieldStruct: struct,
      @as("i")
      inlinedFieldName: string,
      @as("n")
      fieldName: string,
      @as("p")
      mutable path: Path.t,
      @as("r")
      mutable isRegistered: bool,
    }
  }

  module ConstantDefinition = {
    type t = {@as("v") value: unknown, @as("p") path: Path.t}
  }

  module DefinerCtx = {
    type struct = t<unknown>
    type t = {
      @as("n")
      fieldNames: array<string>,
      @as("f")
      fields: Js.Dict.t<struct>,
      @as("d")
      fieldDefinitions: array<FieldDefinition.t>,
      @as("p")
      preparationPathes: array<Path.t>,
      @as("v")
      inlinedPreparationValues: array<string>,
      @as("c")
      constantDefinitions: array<ConstantDefinition.t>,
      @as("s")
      fieldDefinitionsSet: Stdlib.Set.t<FieldDefinition.t>,
    }

    @inline
    let make = () => {
      fieldNames: [],
      fields: Js.Dict.empty(),
      fieldDefinitions: [],
      preparationPathes: [],
      inlinedPreparationValues: [],
      constantDefinitions: [],
      fieldDefinitionsSet: Stdlib.Set.empty(),
    }
  }

  let rec analyzeDefinition = (definition, ~definerCtx: DefinerCtx.t, ~path) => {
    if (
      definerCtx.fieldDefinitionsSet->Stdlib.Set.has(
        definition->(Obj.magic: unknown => FieldDefinition.t),
      )
    ) {
      let fieldDefinition = definition->(Obj.magic: unknown => FieldDefinition.t)
      if fieldDefinition.isRegistered {
        Error.panic(
          `The field "${fieldDefinition.fieldName}" is registered multiple times. If you want to duplicate a field, use S.transform instead.`,
        )
      } else {
        fieldDefinition.path = path
        fieldDefinition.isRegistered = true
      }
    } else if definition->Js.typeof === "object" && definition !== %raw(`null`) {
      let definition: Js.Dict.t<unknown> = definition->Obj.magic
      definerCtx.preparationPathes->Js.Array2.push(path)->ignore
      definerCtx.inlinedPreparationValues
      ->Js.Array2.push(Js.Array2.isArray(definition) ? "[]" : "{}")
      ->ignore
      let definitionFieldNames = definition->Js.Dict.keys
      for idx in 0 to definitionFieldNames->Js.Array2.length - 1 {
        let definitionFieldName = definitionFieldNames->Js.Array2.unsafe_get(idx)
        let fieldDefinition = definition->Js.Dict.unsafeGet(definitionFieldName)
        fieldDefinition->analyzeDefinition(
          ~definerCtx,
          ~path=path->Path.concat(definitionFieldName->Path.fromLocation),
        )
      }
    } else {
      definerCtx.constantDefinitions
      ->Js.Array2.push({
        path,
        value: definition,
      })
      ->ignore
    }
  }

  module ParseTransformationFactory = {
    module Var = {
      @inline
      let originalObject = "o"
      @inline
      let fields = "f"
      @inline
      let transformedObject = "t"
      @inline
      let asyncTransformedObject = "a"
      @inline
      let asyncFieldsCounter = "y"
      @inline
      let fieldDefinitionIdx = "i"
      @inline
      let catchFieldError = "c"
      @inline
      let parseFnsByInstructionIdx = "p"
      @inline
      let constantDefinitions = "d"
      @inline
      let raiseUnexpectedOriginalObjectTypeError = "u"
      @inline
      let raiseUnexpectedTypeError = "s"
      @inline
      let raiseExcessFieldError = "x"
      @inline
      let prepareAsyncFieldError = "j"
    }

    @inline
    let make = (~instructions: DefinerCtx.t) => {
      TransformationFactory.make((. ~ctx, ~struct) => {
        let {
          fieldDefinitions,
          fields,
          inlinedPreparationValues,
          preparationPathes,
          constantDefinitions,
        } = instructions

        let withUnknownKeysRefinement = struct->UnknownKeys.classify === UnknownKeys.Strict

        let asyncFieldDefinitions = []
        let parseFnsByInstructionIdx = Js.Dict.empty()
        let withFieldDefinitions = fieldDefinitions->Js.Array2.length !== 0

        let inlinedParseFunction = {
          let refinement = Stdlib.Inlined.If.make(
            ~condition=`!(typeof ${Var.originalObject}==="object"&&${Var.originalObject}!==null&&!Array.isArray(${Var.originalObject}))`,
            ~content=`${Var.raiseUnexpectedOriginalObjectTypeError}(${Var.originalObject})`,
          )

          let preparation = {
            let stringRef = ref(`var ${Var.transformedObject};`)
            for idx in 0 to preparationPathes->Js.Array2.length - 1 {
              let preparationPath = preparationPathes->Js.Array2.unsafe_get(idx)
              let preparationInlinedValue = inlinedPreparationValues->Js.Array2.unsafe_get(idx)
              stringRef.contents =
                stringRef.contents ++
                `${Var.transformedObject}${preparationPath}=${preparationInlinedValue};`
            }
            stringRef.contents
          }

          let transformedObjectConstruction = withFieldDefinitions
            ? {
                let tryContent = {
                  let stringRef = ref("")
                  for idx in 0 to fieldDefinitions->Js.Array2.length - 1 {
                    let fieldDefinition = fieldDefinitions->Js.Array2.unsafe_get(idx)
                    let {fieldStruct, inlinedFieldName, isRegistered, path} = fieldDefinition

                    let inlinedIdx = idx->Js.Int.toString
                    let parseOperation = fieldStruct->getParseOperation
                    let maybeParseFn = switch parseOperation {
                    | NoOperation => None
                    | SyncOperation(fn) => Some(fn)
                    | AsyncOperation(fn) => Some(fn->Obj.magic)
                    }
                    let isAsync = switch parseOperation {
                    | AsyncOperation(_) => true
                    | _ => false
                    }

                    let inlinedInputData = `${Var.originalObject}[${inlinedFieldName}]`

                    let maybeInlinedDestination = if isAsync {
                      if asyncFieldDefinitions->Js.Array2.length === 0 {
                        stringRef.contents =
                          stringRef.contents ++ `var ${Var.asyncTransformedObject}={};`
                      }

                      if isRegistered {
                        stringRef.contents =
                          stringRef.contents ++ `${Var.transformedObject}${path}=undefined;`
                      }

                      let inlinedDestination = `${Var.asyncTransformedObject}[${asyncFieldDefinitions
                        ->Js.Array2.length
                        ->Js.Int.toString}]`

                      asyncFieldDefinitions->Js.Array2.push(fieldDefinition)->ignore

                      Some(inlinedDestination)
                    } else if isRegistered {
                      Some(`${Var.transformedObject}${path}`)
                    } else {
                      None
                    }

                    stringRef.contents =
                      stringRef.contents ++
                      switch (maybeParseFn, fieldStruct.maybeInlinedRefinement) {
                      | (None, _) =>
                        switch maybeInlinedDestination {
                        | Some(inlinedDestination) => `${inlinedDestination}=${inlinedInputData};`
                        | None => ""
                        }
                      | (Some(_), Some(inlinedRefinement)) =>
                        `var ${Stdlib.Inlined.Constant.inputVar}=${inlinedInputData};if(${inlinedRefinement}){${switch maybeInlinedDestination {
                          | Some(inlinedDestination) =>
                            `${inlinedDestination}=${Stdlib.Inlined.Constant.inputVar}`
                          | None => ""
                          }}}else{${Var.fieldDefinitionIdx}=${inlinedIdx};${Var.raiseUnexpectedTypeError}(${Stdlib.Inlined.Constant.inputVar},${Var.fields}[${inlinedFieldName}])}`
                      | (Some(fn), None) => {
                          parseFnsByInstructionIdx->Js.Dict.set(inlinedIdx, fn)
                          `${Var.fieldDefinitionIdx}=${inlinedIdx};${switch maybeInlinedDestination {
                            | Some(inlinedDestination) => `${inlinedDestination}=`
                            | None => ""
                            }}${Var.parseFnsByInstructionIdx}[${inlinedIdx}](${inlinedInputData});`
                        }
                      }
                  }
                  stringRef.contents
                }

                `var ${Var.fieldDefinitionIdx};` ++
                Stdlib.Inlined.TryCatch.make(
                  ~tryContent,
                  ~catchContent=`${Var.catchFieldError}(${Stdlib.Inlined.Constant.errorVar},${Var.fieldDefinitionIdx})`,
                )
              }
            : ""

          let unknownKeysRefinement = switch (withUnknownKeysRefinement, withFieldDefinitions) {
          | (true, true) => {
              let stringRef = ref(`for(var k in ${Var.originalObject}){if(!(`)
              for idx in 0 to fieldDefinitions->Js.Array2.length - 1 {
                let fieldDefinition = fieldDefinitions->Js.Array2.unsafe_get(idx)
                if idx !== 0 {
                  stringRef.contents = stringRef.contents ++ "||"
                }
                stringRef.contents = stringRef.contents ++ `k===${fieldDefinition.inlinedFieldName}`
              }
              stringRef.contents ++ `)){${Var.raiseExcessFieldError}(k)}}`
            }

          | (true, false) => `for(var k in ${Var.originalObject}){${Var.raiseExcessFieldError}(k)}`
          | _ => ""
          }

          let constants = {
            let stringRef = ref("")
            for idx in 0 to constantDefinitions->Js.Array2.length - 1 {
              let constantDefinition = constantDefinitions->Js.Array2.unsafe_get(idx)
              stringRef.contents =
                stringRef.contents ++
                `${Var.transformedObject}${constantDefinition.path}=${Var.constantDefinitions}[${idx->Js.Int.toString}].v;`
            }
            stringRef.contents
          }

          let returnValue =
            asyncFieldDefinitions->Js.Array2.length === 0
              ? Var.transformedObject
              : `${Var.asyncTransformedObject}.${Var.transformedObject}=${Var.transformedObject},${Var.asyncTransformedObject}`

          Stdlib.Inlined.Fn.make(
            ~arguments=Var.originalObject,
            ~content=`${refinement}${preparation}${transformedObjectConstruction}${unknownKeysRefinement}${constants}return ${returnValue}`,
          )
        }

        ctx->TransformationFactory.Ctx.planSyncTransformation(
          Stdlib.Function.make7(
            ~ctxVarName1=Var.catchFieldError,
            ~ctxVarValue1=(~exn, ~fieldDefinitionIdx) => {
              switch exn {
              | Error.Internal.Exception(internalError) =>
                Error.Internal.Exception(
                  internalError->Error.Internal.prependLocation(
                    (fieldDefinitions->Js.Array2.unsafe_get(fieldDefinitionIdx)).fieldName,
                  ),
                )

              | _ => exn
              }->raise
            },
            ~ctxVarName2=Var.parseFnsByInstructionIdx,
            ~ctxVarValue2=parseFnsByInstructionIdx,
            ~ctxVarName3=Var.fields,
            ~ctxVarValue3=fields,
            ~ctxVarName4=Var.constantDefinitions,
            ~ctxVarValue4=constantDefinitions,
            ~ctxVarName5=Var.raiseUnexpectedOriginalObjectTypeError,
            ~ctxVarValue5=(~input) => {
              raiseUnexpectedTypeError(~input, ~struct)
            },
            ~ctxVarName6=Var.raiseUnexpectedTypeError,
            ~ctxVarValue6=raiseUnexpectedTypeError,
            ~ctxVarName7=Var.raiseExcessFieldError,
            ~ctxVarValue7=exccessFieldName => Error.Internal.raise(ExcessField(exccessFieldName)),
            ~inlinedFunction=inlinedParseFunction,
          ),
        )

        if asyncFieldDefinitions->Js.Array2.length > 0 {
          let inlinedAsyncParseFunction = {
            let resolveVar = "rs"
            let rejectVar = "rj"

            let content = {
              let contentRef = ref(
                `var ${Var.asyncFieldsCounter}=${asyncFieldDefinitions
                  ->Js.Array2.length
                  ->Js.Int.toString},${Var.transformedObject}=${Var.asyncTransformedObject}.${Var.transformedObject};`,
              )
              for idx in 0 to asyncFieldDefinitions->Js.Array2.length - 1 {
                let fieldDefinition = asyncFieldDefinitions->Js.Array2.unsafe_get(idx)
                let {isRegistered, path} = fieldDefinition

                let inlinedIdx = idx->Js.Int.toString

                let onFieldSuccessInlinedFn = {
                  let fieldValueVar = "z"
                  let inlinedFieldValueAssignment = switch isRegistered {
                  | false => ""
                  | true => `${Var.transformedObject}${path}=${fieldValueVar}`
                  }
                  let inlinedIteration = Stdlib.Inlined.If.make(
                    ~condition=`${Var.asyncFieldsCounter}--===1`,
                    ~content=`${resolveVar}(${Var.transformedObject})`,
                  )
                  let onFieldSuccessInlinedFnContent = `${inlinedFieldValueAssignment};${inlinedIteration}`
                  Stdlib.Inlined.Fn.make(
                    ~arguments=fieldValueVar,
                    ~content=onFieldSuccessInlinedFnContent,
                  )
                }

                let onFieldErrorInlinedFn = {
                  let errorVar = "z"
                  Stdlib.Inlined.Fn.make(
                    ~arguments=errorVar,
                    ~content=`${rejectVar}(${Var.prepareAsyncFieldError}(${errorVar},${inlinedIdx}))`,
                  )
                }

                contentRef.contents =
                  contentRef.contents ++
                  `${Var.asyncTransformedObject}[${inlinedIdx}]().then(${onFieldSuccessInlinedFn},${onFieldErrorInlinedFn});`
              }
              contentRef.contents
            }

            Stdlib.Inlined.Fn.make(
              ~arguments=Var.asyncTransformedObject,
              ~content=`return ${Stdlib.Inlined.NewPromise.make(
                  ~resolveVar,
                  ~rejectVar,
                  ~content,
                )}`,
            )
          }

          ctx->TransformationFactory.Ctx.planAsyncTransformation(
            Stdlib.Function.make1(
              ~ctxVarName1=Var.prepareAsyncFieldError,
              ~ctxVarValue1=(exn, asyncFieldDefinitionIdx) => {
                switch exn {
                | Error.Internal.Exception(internalError) =>
                  Error.Internal.Exception(
                    internalError->Error.Internal.prependLocation(
                      (
                        asyncFieldDefinitions->Js.Array2.unsafe_get(asyncFieldDefinitionIdx)
                      ).fieldName,
                    ),
                  )

                | _ => exn
                }
              },
              ~inlinedFunction=inlinedAsyncParseFunction,
            ),
          )
        }
      })
    }
  }

  module SerializeTransformationFactory = {
    module Var = {
      @inline
      let serializeFnsByFieldDefinitionIdx = "s"
      @inline
      let constantDefinitions = "d"
      @inline
      let raiseDiscriminantError = "r"
      @inline
      let transformedObject = "t"
      @inline
      let fieldDefinitionIdx = "i"
      @inline
      let catchFieldError = "c"
    }

    let rec structToInlinedValue = struct => {
      switch struct->classify {
      | Literal(String(string)) => string->Stdlib.Inlined.Value.fromString
      | Literal(Int(int)) => int->Js.Int.toString
      | Literal(Float(float)) => float->Js.Float.toString
      | Literal(Bool(bool)) => bool->Stdlib.Bool.toString
      | Literal(EmptyOption) => "undefined"
      | Literal(EmptyNull) => "null"
      | Literal(NaN) => "NaN"
      | Union(unionStructs) => unionStructs->Js.Array2.unsafe_get(0)->structToInlinedValue
      | Tuple(tupleStructs) =>
        `[${tupleStructs->Js.Array2.map(structToInlinedValue)->Js.Array2.joinWith(",")}]`
      | Object({fieldNames, fields}) =>
        `{${fieldNames
          ->Js.Array2.map(fieldName => {
            `${fieldName->Stdlib.Inlined.Value.fromString}:${fields
              ->Js.Dict.unsafeGet(fieldName)
              ->structToInlinedValue}`
          })
          ->Js.Array2.joinWith(",")}}`

      | String
      | Int
      | Float
      | Bool
      | Option(_)
      | Null(_)
      | Never
      | Unknown
      | Array(_)
      | Dict(_) =>
        Stdlib.Exn.raiseEmpty()
      }
    }

    @inline
    let make = (~instructions: DefinerCtx.t) => {
      TransformationFactory.make((. ~ctx, ~struct as _) => {
        let inliningFieldNameRef = ref(%raw("undefined"))
        try {
          let {fieldDefinitions, constantDefinitions} = instructions

          let serializeFnsByFieldDefinitionIdx = Js.Dict.empty()

          let inlinedSerializeFunction = {
            let constants = {
              let stringRef = ref("")
              for idx in 0 to constantDefinitions->Js.Array2.length - 1 {
                let {path} = constantDefinitions->Js.Array2.unsafe_get(idx)
                stringRef.contents =
                  stringRef.contents ++
                  Stdlib.Inlined.If.make(
                    ~condition=`${Var.transformedObject}${path}!==${Var.constantDefinitions}[${idx->Js.Int.toString}].v`,
                    ~content=`${Var.raiseDiscriminantError}(${idx->Js.Int.toString},${Var.transformedObject}${path})`,
                  )
              }
              stringRef.contents
            }

            let originalObjectConstructionAndReturn = {
              let tryContent = {
                let contentRef = ref(`var ${Var.fieldDefinitionIdx};return{`)
                for idx in 0 to fieldDefinitions->Js.Array2.length - 1 {
                  let fieldDefinition = fieldDefinitions->Js.Array2.unsafe_get(idx)
                  let {
                    fieldStruct,
                    inlinedFieldName,
                    isRegistered,
                    path,
                    fieldName,
                  } = fieldDefinition
                  let inlinedIdx = idx->Js.Int.toString
                  contentRef.contents =
                    contentRef.contents ++
                    switch isRegistered {
                    | true =>
                      switch fieldStruct->getSerializeOperation {
                      | None => `${inlinedFieldName}:${Var.transformedObject}${path},`
                      | Some(fn) => {
                          serializeFnsByFieldDefinitionIdx->Js.Dict.set(inlinedIdx, fn)

                          `${inlinedFieldName}:(${Var.fieldDefinitionIdx}=${inlinedIdx},${Var.serializeFnsByFieldDefinitionIdx}[${inlinedIdx}](${Var.transformedObject}${path})),`
                        }
                      }

                    | false => {
                        inliningFieldNameRef.contents = fieldName
                        `${inlinedFieldName}:${fieldStruct->structToInlinedValue},`
                      }
                    }
                }
                contentRef.contents ++ "}"
              }

              Stdlib.Inlined.TryCatch.make(
                ~tryContent,
                ~catchContent=`${Var.catchFieldError}(${Stdlib.Inlined.Constant.errorVar},${Var.fieldDefinitionIdx})`,
              )
            }

            Stdlib.Inlined.Fn.make(
              ~arguments=Var.transformedObject,
              ~content=`${constants}${originalObjectConstructionAndReturn}`,
            )
          }

          ctx->TransformationFactory.Ctx.planSyncTransformation(
            Stdlib.Function.make4(
              ~ctxVarName1=Var.serializeFnsByFieldDefinitionIdx,
              ~ctxVarValue1=serializeFnsByFieldDefinitionIdx,
              ~ctxVarName2=Var.constantDefinitions,
              ~ctxVarValue2=constantDefinitions,
              ~ctxVarName3=Var.raiseDiscriminantError,
              ~ctxVarValue3=(~fieldDefinitionIdx, ~received) => {
                let {value, path} = constantDefinitions->Js.Array2.unsafe_get(fieldDefinitionIdx)
                Error.Internal.UnexpectedValue.raise(
                  ~expected=value,
                  ~received,
                  ~initialPath=path,
                  (),
                )
              },
              ~ctxVarName4=Var.catchFieldError,
              ~ctxVarValue4=(~exn, ~fieldDefinitionIdx) => {
                switch exn {
                | Error.Internal.Exception(internalError) => {
                    let {path} = fieldDefinitions->Js.Array2.unsafe_get(fieldDefinitionIdx)
                    Error.Internal.Exception(internalError->Error.Internal.prependPath(path))
                  }

                | _ => exn
                }->raise
              },
              ~inlinedFunction=inlinedSerializeFunction,
            ),
          )
        } catch {
        | _ =>
          let inliningOriginalFieldName = inliningFieldNameRef.contents
          ctx->TransformationFactory.Ctx.planSyncTransformation(_ =>
            raise(
              Error.Internal.Exception({
                code: MissingSerializer,
                path: Path.fromLocation(inliningOriginalFieldName),
              }),
            )
          )
        }
        ()
      })
    }
  }

  let factory = definer => {
    let instructions = {
      let definerCtx = DefinerCtx.make()
      let definition = definer->Stdlib.Fn.call1(definerCtx)->castAnyToUnknown
      definition->analyzeDefinition(~definerCtx, ~path=Path.empty)
      definerCtx
    }

    make(
      ~name="Object",
      ~tagged=Object({
        fields: instructions.fields,
        fieldNames: instructions.fieldNames,
      }),
      ~parseTransformationFactory=ParseTransformationFactory.make(~instructions),
      ~serializeTransformationFactory=SerializeTransformationFactory.make(~instructions),
      (),
    )
  }

  let field = (definerCtx: DefinerCtx.t, fieldName, struct) => {
    let struct = struct->castAnyStructToUnknownStruct
    switch definerCtx.fields->Stdlib.Dict.has(fieldName) {
    | true =>
      Error.panic(
        `The field "${fieldName}" is defined multiple times. If you want to duplicate a field, use S.transform instead.`,
      )
    | false => {
        let fieldDefinition: FieldDefinition.t = {
          fieldStruct: struct,
          fieldName,
          inlinedFieldName: fieldName->Stdlib.Inlined.Value.fromString,
          path: Path.empty,
          isRegistered: false,
        }
        definerCtx.fields->Js.Dict.set(fieldName, struct)
        definerCtx.fieldNames->Js.Array2.push(fieldName)->ignore
        definerCtx.fieldDefinitions->Js.Array2.push(fieldDefinition)->ignore
        definerCtx.fieldDefinitionsSet->Stdlib.Set.add(fieldDefinition)->ignore
        fieldDefinition->(Obj.magic: FieldDefinition.t => 'a)
      }
    }
  }

  let strip = struct => {
    struct->Metadata.set(~id=UnknownKeys.metadataId, ~metadata=UnknownKeys.Strip)
  }

  let strict = struct => {
    struct->Metadata.set(~id=UnknownKeys.metadataId, ~metadata=UnknownKeys.Strict)
  }

  type definerCtx = DefinerCtx.t
}

module Never = {
  let transformationFactory = TransformationFactory.make((. ~ctx, ~struct) =>
    ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
      raiseUnexpectedTypeError(~input, ~struct)
    })
  )

  let factory = () => {
    make(
      ~name=`Never`,
      ~tagged=Never,
      ~inlinedRefinement="false",
      ~parseTransformationFactory=transformationFactory,
      ~serializeTransformationFactory=transformationFactory,
      (),
    )
  }
}

module Unknown = {
  let factory = () => {
    make(
      ~name=`Unknown`,
      ~tagged=Unknown,
      ~parseTransformationFactory=TransformationFactory.empty,
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }
}

module String = {
  module Refinement = {
    type kind =
      | Min({length: int})
      | Max({length: int})
      | Length({length: int})
      | Email
      | Uuid
      | Cuid
      | Url
      | Pattern({re: Js.Re.t})
    type t = {
      kind: kind,
      message: string,
    }

    let metadataId: Metadata.Id.t<array<t>> = Metadata.Id.make(
      ~namespace="rescript-struct",
      ~name="String.refinements",
    )
  }

  let refinements = struct => {
    switch struct->Metadata.get(~id=Refinement.metadataId) {
    | Some(m) => m
    | None => []
    }
  }

  let cuidRegex = %re(`/^c[^\s-]{8,}$/i`)
  let uuidRegex = %re(`/^([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[a-f0-9]{4}-[a-f0-9]{12}|00000000-0000-0000-0000-000000000000)$/i`)
  let emailRegex = %re(`/^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i`)

  let parseTransformationFactory = TransformationFactory.make((. ~ctx, ~struct) =>
    ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
      if input->Js.typeof === "string" {
        input
      } else {
        raiseUnexpectedTypeError(~input, ~struct)
      }
    })
  )

  let factory = () => {
    make(
      ~name="String",
      ~tagged=String,
      ~inlinedRefinement=`typeof ${Stdlib.Inlined.Constant.inputVar}==="string"`,
      ~parseTransformationFactory,
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, length) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `String must be ${length->Js.Int.toString} or more characters long`
    }
    let refiner = value =>
      if value->Js.String2.length < length {
        Error.raise(message)
      }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Min({length: length}),
        message,
      },
    )
  }

  let max = (struct, ~message as maybeMessage=?, length) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `String must be ${length->Js.Int.toString} or fewer characters long`
    }
    let refiner = value =>
      if value->Js.String2.length > length {
        Error.raise(message)
      }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Max({length: length}),
        message,
      },
    )
  }

  let length = (struct, ~message as maybeMessage=?, length) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `String must be exactly ${length->Js.Int.toString} characters long`
    }
    let refiner = value =>
      if value->Js.String2.length !== length {
        Error.raise(message)
      }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Length({length: length}),
        message,
      },
    )
  }

  let email = (struct, ~message=`Invalid email address`, ()) => {
    let refiner = value => {
      if !(emailRegex->Js.Re.test_(value)) {
        Error.raise(message)
      }
    }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Email,
        message,
      },
    )
  }

  let uuid = (struct, ~message=`Invalid UUID`, ()) => {
    let refiner = value => {
      if !(uuidRegex->Js.Re.test_(value)) {
        Error.raise(message)
      }
    }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Uuid,
        message,
      },
    )
  }

  let cuid = (struct, ~message=`Invalid CUID`, ()) => {
    let refiner = value => {
      if !(cuidRegex->Js.Re.test_(value)) {
        Error.raise(message)
      }
    }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Cuid,
        message,
      },
    )
  }

  let url = (struct, ~message=`Invalid url`, ()) => {
    let refiner = value => {
      if !(value->Stdlib.Url.test) {
        Error.raise(message)
      }
    }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Url,
        message,
      },
    )
  }

  let pattern = (struct, ~message=`Invalid`, re) => {
    let refiner = value => {
      re->Js.Re.setLastIndex(0)
      if !(re->Js.Re.test_(value)) {
        Error.raise(message)
      }
    }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Pattern({re: re}),
        message,
      },
    )
  }

  let trimmed = (struct, ()) => {
    let transformer = Js.String2.trim
    struct->transform(~parser=transformer, ~serializer=transformer, ())
  }
}

module Json = {
  let factory = innerStruct => {
    let innerStruct = innerStruct->castAnyStructToUnknownStruct
    make(
      ~name=`Json`,
      ~tagged=String,
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) => {
        let process = switch innerStruct->getParseOperation {
        | NoOperation => Obj.magic
        | SyncOperation(fn) => fn->Obj.magic
        | AsyncOperation(fn) => fn->Obj.magic
        }
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          if input->Js.typeof === "string" {
            try input->Js.Json.parseExn catch {
            | Js.Exn.Error(obj) =>
              Error.raise(
                switch obj->Js.Exn.message {
                | Some(m) => m
                | None => "Failed to parse JSON"
                },
              )
            }->Stdlib.Fn.call1(process, _)
          } else {
            raiseUnexpectedTypeError(~input, ~struct)
          }
        })
        switch innerStruct->getParseOperation {
        | AsyncOperation(_) =>
          ctx->TransformationFactory.Ctx.planAsyncTransformation(asyncFn => {
            asyncFn(.)
          })
        | _ => ()
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        switch innerStruct->getSerializeOperation {
        | None =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            input->Obj.magic->Js.Json.stringify
          })
        | Some(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            fn(. input)->Obj.magic->Js.Json.stringify
          })
        }
      }),
      (),
    )
  }
}

module Bool = {
  let parseTransformationFactory = TransformationFactory.make((. ~ctx, ~struct) =>
    ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
      if input->Js.typeof === "boolean" {
        input
      } else {
        raiseUnexpectedTypeError(~input, ~struct)
      }
    })
  )

  let factory = () => {
    make(
      ~name="Bool",
      ~tagged=Bool,
      ~inlinedRefinement=`typeof ${Stdlib.Inlined.Constant.inputVar}==="boolean"`,
      ~parseTransformationFactory,
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }
}

module Int = {
  module Refinement = {
    type kind =
      | Min({value: int})
      | Max({value: int})
      | Port
    type t = {
      kind: kind,
      message: string,
    }

    let metadataId: Metadata.Id.t<array<t>> = Metadata.Id.make(
      ~namespace="rescript-struct",
      ~name="Int.refinements",
    )
  }

  let refinements = struct => {
    switch struct->Metadata.get(~id=Refinement.metadataId) {
    | Some(m) => m
    | None => []
    }
  }

  let parseTransformationFactory = TransformationFactory.make((. ~ctx, ~struct) =>
    ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
      if Stdlib.Int.test(input) {
        input
      } else {
        raiseUnexpectedTypeError(~input, ~struct)
      }
    })
  )

  let factory = () => {
    make(
      ~name="Int",
      ~tagged=Int,
      ~inlinedRefinement=`typeof ${Stdlib.Inlined.Constant.inputVar}==="number"&&${Stdlib.Inlined.Constant.inputVar}<2147483648&&${Stdlib.Inlined.Constant.inputVar}>-2147483649&&${Stdlib.Inlined.Constant.inputVar}%1===0`,
      ~parseTransformationFactory,
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, minValue) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Number must be greater than or equal to ${minValue->Js.Int.toString}`
    }
    let refiner = value => {
      if value < minValue {
        Error.raise(message)
      }
    }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Min({value: minValue}),
        message,
      },
    )
  }

  let max = (struct, ~message as maybeMessage=?, maxValue) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Number must be lower than or equal to ${maxValue->Js.Int.toString}`
    }
    let refiner = value => {
      if value > maxValue {
        Error.raise(message)
      }
    }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Max({value: maxValue}),
        message,
      },
    )
  }

  let port = (struct, ~message="Invalid port", ()) => {
    let refiner = value => {
      if value < 1 || value > 65535 {
        Error.raise(message)
      }
    }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Port,
        message,
      },
    )
  }
}

module Float = {
  module Refinement = {
    type kind =
      | Min({value: float})
      | Max({value: float})
    type t = {
      kind: kind,
      message: string,
    }

    let metadataId: Metadata.Id.t<array<t>> = Metadata.Id.make(
      ~namespace="rescript-struct",
      ~name="Float.refinements",
    )
  }

  let refinements = struct => {
    switch struct->Metadata.get(~id=Refinement.metadataId) {
    | Some(m) => m
    | None => []
    }
  }

  let parseTransformationFactory = TransformationFactory.make((. ~ctx, ~struct) =>
    ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
      switch input->Js.typeof === "number" {
      | true =>
        if Js.Float.isNaN(input) {
          raiseUnexpectedTypeError(~input, ~struct)
        } else {
          input
        }
      | false => raiseUnexpectedTypeError(~input, ~struct)
      }
    })
  )

  let factory = () => {
    make(
      ~name="Float",
      ~tagged=Float,
      ~inlinedRefinement=`typeof ${Stdlib.Inlined.Constant.inputVar}==="number"&&!Number.isNaN(${Stdlib.Inlined.Constant.inputVar})`,
      ~parseTransformationFactory,
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, minValue) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Number must be greater than or equal to ${minValue->Js.Float.toString}`
    }
    let refiner = value => {
      if value < minValue {
        Error.raise(message)
      }
    }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Min({value: minValue}),
        message,
      },
    )
  }

  let max = (struct, ~message as maybeMessage=?, maxValue) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Number must be lower than or equal to ${maxValue->Js.Float.toString}`
    }
    let refiner = value => {
      if value > maxValue {
        Error.raise(message)
      }
    }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Max({value: maxValue}),
        message,
      },
    )
  }
}

module Null = {
  let factory = innerStruct => {
    let innerStruct = innerStruct->castAnyStructToUnknownStruct
    make(
      ~name=`Null`,
      ~tagged=Null(innerStruct),
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        let planSyncTransformation = fn => {
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            switch input->Js.Null.toOption {
            | Some(innerData) => Some(fn(. innerData))
            | None => None
            }
          })
        }
        switch innerStruct->getParseOperation {
        | NoOperation => ctx->TransformationFactory.Ctx.planSyncTransformation(Js.Null.toOption)
        | SyncOperation(fn) => planSyncTransformation(fn)
        | AsyncOperation(fn) => {
            planSyncTransformation(fn)
            ctx->TransformationFactory.Ctx.planAsyncTransformation(input => {
              switch input {
              | Some(asyncFn) => asyncFn(.)->Stdlib.Promise.thenResolve(value => Some(value))
              | None => None->Stdlib.Promise.resolve
              }
            })
          }
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) =>
        switch innerStruct->getSerializeOperation {
        | Some(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            switch input {
            | Some(value) => fn(. value)
            | None => Js.Null.empty->castAnyToUnknown
            }
          })
        | None =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            switch input {
            | Some(value) => value
            | None => Js.Null.empty->castAnyToUnknown
            }
          })
        }
      ),
      (),
    )
  }
}

module Option = {
  let factory = innerStruct => {
    let innerStruct = innerStruct->castAnyStructToUnknownStruct
    make(
      ~name=`Option`,
      ~tagged=Option(innerStruct),
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        let planSyncTransformation = fn => {
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            switch input {
            | Some(innerData) => Some(fn(. innerData))
            | None => None
            }
          })
        }
        switch innerStruct->getParseOperation {
        | NoOperation => ()
        | SyncOperation(fn) => planSyncTransformation(fn)
        | AsyncOperation(fn) => {
            planSyncTransformation(fn)
            ctx->TransformationFactory.Ctx.planAsyncTransformation(input => {
              switch input {
              | Some(asyncFn) => asyncFn(.)->Stdlib.Promise.thenResolve(value => Some(value))
              | None => None->Stdlib.Promise.resolve
              }
            })
          }
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) =>
        switch innerStruct->getSerializeOperation {
        | Some(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            switch input {
            | Some(value) => fn(. value)
            | None => Js.Undefined.empty->castAnyToUnknown
            }
          })
        | None =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            switch input {
            | Some(value) => value
            | None => Js.Undefined.empty->castAnyToUnknown
            }
          })
        }
      ),
      (),
    )
  }
}

module Deprecated = {
  type tagged = WithoutMessage | WithMessage(string)

  let metadataId = Metadata.Id.make(~namespace="rescript-struct", ~name="Deprecated")

  let factory = (innerStruct, ~message as maybeMessage=?, ()) => {
    Option.factory(innerStruct)->Metadata.set(
      ~id=metadataId,
      ~metadata=switch maybeMessage {
      | Some(message) => WithMessage(message)
      | None => WithoutMessage
      },
    )
  }

  let classify = struct => struct->Metadata.get(~id=metadataId)
}

module Array = {
  module Refinement = {
    type kind =
      | Min({length: int})
      | Max({length: int})
      | Length({length: int})
    type t = {
      kind: kind,
      message: string,
    }

    let metadataId: Metadata.Id.t<array<t>> = Metadata.Id.make(
      ~namespace="rescript-struct",
      ~name="Array.refinements",
    )
  }

  let refinements = struct => {
    switch struct->Metadata.get(~id=Refinement.metadataId) {
    | Some(m) => m
    | None => []
    }
  }

  let factory = innerStruct => {
    let innerStruct = innerStruct->castAnyStructToUnknownStruct
    make(
      ~name=`Array`,
      ~tagged=Array(innerStruct->Obj.magic),
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) => {
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          if Js.Array2.isArray(input) === false {
            raiseUnexpectedTypeError(~input, ~struct)
          } else {
            input
          }
        })

        let planSyncTransformation = fn => {
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let newArray = []
            for idx in 0 to input->Js.Array2.length - 1 {
              let innerData = input->Js.Array2.unsafe_get(idx)
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
            newArray
          })
        }

        switch innerStruct->getParseOperation {
        | NoOperation => ()
        | SyncOperation(fn) => planSyncTransformation(fn)
        | AsyncOperation(fn) =>
          planSyncTransformation(fn)
          ctx->TransformationFactory.Ctx.planAsyncTransformation(input => {
            input
            ->Js.Array2.mapi(
              (asyncFn, idx) => {
                asyncFn(.)->Stdlib.Promise.catch(
                  exn => {
                    switch exn {
                    | Error.Internal.Exception(internalError) =>
                      Error.Internal.Exception(
                        internalError->Error.Internal.prependLocation(idx->Js.Int.toString),
                      )
                    | _ => exn
                    }->raise
                  },
                )
              },
            )
            ->Stdlib.Promise.all
            ->Obj.magic
          })
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        switch innerStruct->getSerializeOperation {
        | None => ()
        | Some(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let newArray = []
            for idx in 0 to input->Js.Array2.length - 1 {
              let innerData = input->Js.Array2.unsafe_get(idx)
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
            newArray
          })
        }
      }),
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, length) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Array must be ${length->Js.Int.toString} or more items long`
    }
    let refiner = value => {
      if value->Js.Array2.length < length {
        Error.raise(message)
      }
    }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Min({length: length}),
        message,
      },
    )
  }

  let max = (struct, ~message as maybeMessage=?, length) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Array must be ${length->Js.Int.toString} or fewer items long`
    }
    let refiner = value => {
      if value->Js.Array2.length > length {
        Error.raise(message)
      }
    }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Max({length: length}),
        message,
      },
    )
  }

  let length = (struct, ~message as maybeMessage=?, length) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Array must be exactly ${length->Js.Int.toString} items long`
    }
    let refiner = value => {
      if value->Js.Array2.length !== length {
        Error.raise(message)
      }
    }
    struct->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner,
      ~refinement={
        kind: Length({length: length}),
        message,
      },
    )
  }
}

module Dict = {
  let factory = innerStruct => {
    let innerStruct = innerStruct->castAnyStructToUnknownStruct
    make(
      ~name=`Dict`,
      ~tagged=Dict(innerStruct),
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) => {
        let planSyncTransformation = fn => {
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let newDict = Js.Dict.empty()
            let keys = input->Js.Dict.keys
            for idx in 0 to keys->Js.Array2.length - 1 {
              let key = keys->Js.Array2.unsafe_get(idx)
              let innerData = input->Js.Dict.unsafeGet(key)
              try {
                let value = fn(. innerData)
                newDict->Js.Dict.set(key, value)->ignore
              } catch {
              | Error.Internal.Exception(internalError) =>
                raise(Error.Internal.Exception(internalError->Error.Internal.prependLocation(key)))
              }
            }
            newDict
          })
        }

        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          if input->Stdlib.Object.test === false {
            raiseUnexpectedTypeError(~input, ~struct)
          } else {
            input
          }
        })

        switch innerStruct->getParseOperation {
        | NoOperation => ()
        | SyncOperation(fn) => planSyncTransformation(fn)
        | AsyncOperation(fn) =>
          planSyncTransformation(fn)
          ctx->TransformationFactory.Ctx.planAsyncTransformation(input => {
            let keys = input->Js.Dict.keys
            keys
            ->Js.Array2.map(
              key => {
                let asyncFn = input->Js.Dict.unsafeGet(key)
                try {
                  asyncFn(.)->Stdlib.Promise.catch(
                    exn => {
                      switch exn {
                      | Error.Internal.Exception(internalError) =>
                        Error.Internal.Exception(internalError->Error.Internal.prependLocation(key))
                      | _ => exn
                      }->raise
                    },
                  )
                } catch {
                | Error.Internal.Exception(internalError) =>
                  Error.Internal.Exception(
                    internalError->Error.Internal.prependLocation(key),
                  )->raise
                }
              },
            )
            ->Stdlib.Promise.all
            ->Stdlib.Promise.thenResolve(
              values => {
                let tempDict = Js.Dict.empty()
                values->Js.Array2.forEachi(
                  (value, idx) => {
                    let key = keys->Js.Array2.unsafe_get(idx)
                    tempDict->Js.Dict.set(key, value)
                  },
                )
                tempDict
              },
            )
          })
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        switch innerStruct->getSerializeOperation {
        | None => ()
        | Some(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let newDict = Js.Dict.empty()
            let keys = input->Js.Dict.keys
            for idx in 0 to keys->Js.Array2.length - 1 {
              let key = keys->Js.Array2.unsafe_get(idx)
              let innerData = input->Js.Dict.unsafeGet(key)
              try {
                let value = fn(. innerData)
                newDict->Js.Dict.set(key, value)->ignore
              } catch {
              | Error.Internal.Exception(internalError) =>
                raise(Error.Internal.Exception(internalError->Error.Internal.prependLocation(key)))
              }
            }
            newDict
          })
        }
      }),
      (),
    )
  }
}

module Defaulted = {
  type tagged = WithDefaultValue(unknown)

  let metadataId = Metadata.Id.make(~namespace="rescript-struct", ~name="Defaulted")

  let factory = (innerStruct, defaultValue) => {
    let innerStruct = innerStruct->castAnyStructToUnknownStruct
    make(
      ~name=innerStruct.name,
      ~tagged=innerStruct.tagged,
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        switch innerStruct->getParseOperation {
        | NoOperation =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            switch input->castUnknownToAny {
            | Some(v) => v
            | None => defaultValue
            }
          })
        | SyncOperation(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            switch fn(. input)->castUnknownToAny {
            | Some(v) => v
            | None => defaultValue
            }
          })
        | AsyncOperation(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(fn->Stdlib.Fn.castToCurried)
          ctx->TransformationFactory.Ctx.planAsyncTransformation(asyncFn => {
            asyncFn(.)->Stdlib.Promise.thenResolve(
              value => {
                switch value->castUnknownToAny {
                | Some(v) => v
                | None => defaultValue
                }
              },
            )
          })
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        switch innerStruct->getSerializeOperation {
        | Some(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let value = Some(input)->castAnyToUnknown
            fn(. value)
          })
        | None =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            Some(input)->castAnyToUnknown
          })
        }
      }),
      (),
    )->Metadata.set(~id=metadataId, ~metadata=WithDefaultValue(defaultValue->castAnyToUnknown))
  }

  let classify = struct => struct->Metadata.get(~id=metadataId)
}

module Tuple = {
  let factory = (
    () => {
      let structs = Stdlib.Fn.getArguments()
      let numberOfStructs = structs->Js.Array2.length

      make(
        ~name="Tuple",
        ~tagged=Tuple(structs),
        ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) => {
          let noopOps = []
          let syncOps = []
          let asyncOps = []
          for idx in 0 to structs->Js.Array2.length - 1 {
            let innerStruct = structs->Js.Array2.unsafe_get(idx)
            switch innerStruct->getParseOperation {
            | NoOperation => noopOps->Js.Array2.push(idx)->ignore
            | SyncOperation(fn) => syncOps->Js.Array2.push((idx, fn))->ignore
            | AsyncOperation(fn) => {
                syncOps->Js.Array2.push((idx, fn->Obj.magic))->ignore
                asyncOps->Js.Array2.push(idx)->ignore
              }
            }
          }
          let withAsyncOps = asyncOps->Js.Array2.length > 0

          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
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

            let newArray = []

            for idx in 0 to syncOps->Js.Array2.length - 1 {
              let (originalIdx, fn) = syncOps->Js.Array2.unsafe_get(idx)
              let innerData = input->Js.Array2.unsafe_get(originalIdx)
              try {
                let value = fn(. innerData)
                newArray->Stdlib.Array.set(originalIdx, value)
              } catch {
              | Error.Internal.Exception(internalError) =>
                raise(
                  Error.Internal.Exception(
                    internalError->Error.Internal.prependLocation(idx->Js.Int.toString),
                  ),
                )
              }
            }

            for idx in 0 to noopOps->Js.Array2.length - 1 {
              let originalIdx = noopOps->Js.Array2.unsafe_get(idx)
              let innerData = input->Js.Array2.unsafe_get(originalIdx)
              newArray->Stdlib.Array.set(originalIdx, innerData)
            }

            switch withAsyncOps {
            | true => newArray->castAnyToUnknown
            | false =>
              switch numberOfStructs {
              | 0 => ()->castAnyToUnknown
              | 1 => newArray->Js.Array2.unsafe_get(0)->castAnyToUnknown
              | _ => newArray->castAnyToUnknown
              }
            }
          })

          if withAsyncOps {
            ctx->TransformationFactory.Ctx.planAsyncTransformation(tempArray => {
              asyncOps
              ->Js.Array2.map(
                originalIdx => {
                  (
                    tempArray->castUnknownToAny->Js.Array2.unsafe_get(originalIdx)->Obj.magic
                  )(.)->Stdlib.Promise.catch(
                    exn => {
                      switch exn {
                      | Error.Internal.Exception(internalError) =>
                        Error.Internal.Exception(
                          internalError->Error.Internal.prependLocation(
                            originalIdx->Js.Int.toString,
                          ),
                        )
                      | _ => exn
                      }->raise
                    },
                  )
                },
              )
              ->Stdlib.Promise.all
              ->Stdlib.Promise.thenResolve(
                values => {
                  values->Js.Array2.forEachi(
                    (value, idx) => {
                      let originalIdx = asyncOps->Js.Array2.unsafe_get(idx)
                      tempArray->castUnknownToAny->Stdlib.Array.set(originalIdx, value)
                    },
                  )
                  tempArray->castUnknownToAny->Stdlib.Array.toTuple
                },
              )
            })
          }
        }),
        ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
          let serializeOperations = []
          for idx in 0 to structs->Js.Array2.length - 1 {
            serializeOperations
            ->Js.Array2.push(structs->Js.Array2.unsafe_get(idx)->getSerializeOperation)
            ->ignore
          }

          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let inputArray = numberOfStructs === 1 ? [input] : input->Obj.magic

            let newArray = []
            for idx in 0 to serializeOperations->Js.Array2.length - 1 {
              let innerData = inputArray->Js.Array2.unsafe_get(idx)
              let serializeOperation = serializeOperations->Js.Array.unsafe_get(idx)
              switch serializeOperation {
              | None => newArray->Js.Array2.push(innerData)->ignore
              | Some(fn) =>
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
            newArray
          })
        }),
        (),
      )
    }
  )->Obj.magic
}

module Union = {
  exception HackyValidValue(unknown)

  let factory = structs => {
    let structs: array<t<unknown>> = structs->Obj.magic

    if structs->Js.Array2.length < 2 {
      Error.panic("A Union struct factory require at least two structs.")
    }

    make(
      ~name=`Union`,
      ~tagged=Union(structs),
      ~parseTransformationFactory=TransformationFactory.make((.
        ~ctx,
        ~struct as compilingStruct,
      ) => {
        let structs = compilingStruct->classify->unsafeGetVariantPayload

        let noopOps = []
        let syncOps = []
        let asyncOps = []
        for idx in 0 to structs->Js.Array2.length - 1 {
          let innerStruct = structs->Js.Array2.unsafe_get(idx)
          switch innerStruct->getParseOperation {
          | NoOperation => noopOps->Js.Array2.push()->ignore
          | SyncOperation(fn) => syncOps->Js.Array2.push((idx, fn))->ignore
          | AsyncOperation(fn) => asyncOps->Js.Array2.push((idx, fn))->ignore
          }
        }
        let withAsyncOps = asyncOps->Js.Array2.length > 0

        if noopOps->Js.Array2.length === 0 {
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let idxRef = ref(0)
            let errorsRef = ref([])
            let maybeNewValueRef = ref(None)
            while (
              idxRef.contents < syncOps->Js.Array2.length && maybeNewValueRef.contents === None
            ) {
              let idx = idxRef.contents
              let (originalIdx, fn) = syncOps->Js.Array2.unsafe_get(idx)
              try {
                let newValue = fn(. input)
                maybeNewValueRef.contents = Some(newValue)
              } catch {
              | Error.Internal.Exception(internalError) => {
                  errorsRef.contents->Stdlib.Array.set(originalIdx, internalError)
                  idxRef.contents = idxRef.contents->Stdlib.Int.plus(1)
                }
              }
            }
            switch (maybeNewValueRef.contents, withAsyncOps) {
            | (Some(newValue), false) => newValue
            | (None, false) =>
              Error.Internal.raise(
                InvalidUnion(errorsRef.contents->Js.Array2.map(Error.Internal.toParseError)),
              )
            | (maybeSyncValue, true) =>
              {
                "maybeSyncValue": maybeSyncValue,
                "tempErrors": errorsRef.contents,
                "originalInput": input,
              }->castAnyToUnknown
            }
          })

          if withAsyncOps {
            ctx->TransformationFactory.Ctx.planAsyncTransformation(input => {
              switch input["maybeSyncValue"] {
              | Some(syncValue) => syncValue->Stdlib.Promise.resolve
              | None =>
                asyncOps
                ->Js.Array2.map(
                  ((originalIdx, fn)) => {
                    try {
                      fn(. input["originalInput"])(.)->Stdlib.Promise.thenResolveWithCatch(
                        value => raise(HackyValidValue(value)),
                        exn =>
                          switch exn {
                          | Error.Internal.Exception(internalError) =>
                            input["tempErrors"]->Stdlib.Array.set(originalIdx, internalError)
                          | _ => raise(exn)
                          },
                      )
                    } catch {
                    | Error.Internal.Exception(internalError) =>
                      input["tempErrors"]
                      ->Stdlib.Array.set(originalIdx, internalError)
                      ->Stdlib.Promise.resolve
                    }
                  },
                )
                ->Stdlib.Promise.all
                ->Stdlib.Promise.thenResolveWithCatch(
                  _ => {
                    Error.Internal.raise(
                      InvalidUnion(input["tempErrors"]->Js.Array2.map(Error.Internal.toParseError)),
                    )
                  },
                  exn => {
                    switch exn {
                    | HackyValidValue(value) => value
                    | _ => raise(exn)
                    }
                  },
                )
              }
            })
          }
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        let serializeOperations = []
        for idx in 0 to structs->Js.Array2.length - 1 {
          serializeOperations
          ->Js.Array2.push(structs->Js.Array2.unsafe_get(idx)->getSerializeOperation)
          ->ignore
        }

        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          let idxRef = ref(0)
          let errors = []
          let maybeNewValueRef = ref(None)
          while (
            idxRef.contents < serializeOperations->Js.Array2.length &&
              maybeNewValueRef.contents === None
          ) {
            let idx = idxRef.contents
            let serializeOperation = serializeOperations->Js.Array2.unsafe_get(idx)
            try {
              let newValue = switch serializeOperation {
              | None => input
              | Some(fn) => fn(. input)
              }
              maybeNewValueRef.contents = Some(newValue)
            } catch {
            | Error.Internal.Exception(internalError) => {
                errors->Js.Array2.push(internalError)->ignore
                idxRef.contents = idxRef.contents->Stdlib.Int.plus(1)
              }
            }
          }
          switch maybeNewValueRef.contents {
          | Some(ok) => ok
          | None =>
            Error.Internal.raise(
              InvalidUnion(errors->Js.Array2.map(Error.Internal.toSerializeError)),
            )
          }
        })
      }),
      (),
    )
  }
}

let descriptionMetadataId = Metadata.Id.make(~namespace="rescript-struct", ~name="description")

let describe = (struct, description) => {
  struct->Metadata.set(~id=descriptionMetadataId, ~metadata=description)
}

let description = struct => struct->Metadata.get(~id=descriptionMetadataId)

module Result = {
  let getExn = result => {
    switch result {
    | Ok(value) => value
    | Error(error) => Error.panic(error->Error.toString)
    }
  }

  let mapErrorToString = result => {
    result->Stdlib.Result.mapError(Error.toString)
  }
}

let rec inline = struct => {
  let inlinedStruct = switch struct->classify {
  | Literal(String(string)) => `S.literal(String(${string->Stdlib.Inlined.Value.fromString}))`
  | Literal(Int(int)) => `S.literal(Int(${int->Js.Int.toString}))`
  | Literal(Float(float)) => `S.literal(Float(${float->Js.Float.toString}.))`
  | Literal(Bool(bool)) => `S.literal(Bool(${bool->Stdlib.Bool.toString}))`
  | Literal(EmptyOption) => `S.literal(EmptyOption)`
  | Literal(EmptyNull) => `S.literal(EmptyNull)`
  | Literal(NaN) => `S.literal(NaN)`
  | Union(unionStructs) =>
    `S.union([${unionStructs
      ->Js.Array2.map(s => s->castUnknownStructToAnyStruct->inline)
      ->Js.Array2.joinWith(", ")}])`
  | Tuple([]) => `S.tuple0(.)`
  | Tuple(tupleStructs) =>
    `(S.Tuple.factory: (. ${tupleStructs
      ->Js.Array2.mapi((_, idx) => `S.t<'v${idx->Js.Int.toString}>`)
      ->Js.Array2.joinWith(", ")}) => S.t<(${tupleStructs
      ->Js.Array2.mapi((_, idx) => `'v${idx->Js.Int.toString}`)
      ->Js.Array2.joinWith(", ")})>)(. ${tupleStructs
      ->Js.Array2.map(s => s->castUnknownStructToAnyStruct->inline)
      ->Js.Array2.joinWith(", ")})`
  | Object({fieldNames, fields}) =>
    `S.object(o =>
  {
    ${fieldNames
      ->Js.Array2.map(fieldName => {
        `${fieldName->Stdlib.Inlined.Value.fromString}: o->S.field(${fieldName->Stdlib.Inlined.Value.fromString}, ${fields
          ->Js.Dict.unsafeGet(fieldName)
          ->castUnknownStructToAnyStruct
          ->inline})`
      })
      ->Js.Array2.joinWith(",\n    ")},
  }
)`
  | String => `S.string()`
  | Int => `S.int()`
  | Float => `S.float()`
  | Bool => `S.bool()`
  | Option(innerStruct) => `S.option(${innerStruct->castUnknownStructToAnyStruct->inline})`
  | Null(innerStruct) => `S.null(${innerStruct->castUnknownStructToAnyStruct->inline})`
  | Never => `S.never()`
  | Unknown => `S.unknown()`
  | Array(innerStruct) => `S.array(${innerStruct->castUnknownStructToAnyStruct->inline})`
  | Dict(innerStruct) => `S.dict(${innerStruct->castUnknownStructToAnyStruct->inline})`
  }

  // TODO: Add metadata support
  // TODO: Add literal variant support (NO, use polymorphic variants for unions)

  switch struct.maybeMetadataDict {
  | Some(metadataDict) =>
    `{
  let s = ${inlinedStruct}
  let _ = %raw(\`s.m = ${metadataDict
      ->Js.Json.stringifyAny
      ->{
        // FIXME: Make it more reliable
        Belt.Option.getUnsafe
      }}\`)
  s
}`
  | None => inlinedStruct
  }
}

let object = Object.factory
let field = Object.field
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
let defaulted = Defaulted.factory
let literal = Literal.factory
let literalVariant = Literal.Variant.factory
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
let json = Json.factory
