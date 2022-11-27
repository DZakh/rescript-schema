type never
type unknown

module Stdlib = {
  module Promise = {
    type t<+'a> = Js.Promise.t<'a>

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
    let getWithDefault = (option, default) =>
      switch option {
      | Some(value) => value
      | None => default
      }

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

  @inline
  let empty = () => ""

  let fromLocation = Obj.magic

  @inline
  let toArray = (path: t) => {
    switch path {
    | "" => []
    | _ => path->Js.String2.split(",")
    }
  }

  @inline
  let fromArray = (array): t => {
    array->Js.Array2.toString
  }

  @inline
  let toText = path => {
    switch path {
    | [] => "root"
    | _ => path->Js.Array2.map(pathItem => `[${pathItem}]`)->Js.Array2.joinWith("")
    }
  }

  @inline
  let prependLocation = (path: t, location: string): t =>
    switch path {
    | "" => location
    | _ => `${location},${path}`
    }

  @inline
  let appendLocation = (path: t, location: string): t =>
    switch path {
    | "" => location
    | _ => `${path},${location}`
    }

  module Inlined = {
    type t = string

    @inline
    let empty = () => ""

    @inline
    let appendLocation = (inlinedPath: t, location: string): t =>
      `${inlinedPath}[${location->Stdlib.Inlined.Value.fromString}]`
  }
}

module Error = {
  @inline
  let panic = message => Stdlib.Exn.raiseError(Stdlib.Exn.makeError(`[rescript-struct] ${message}`))

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
    | UnexpectedAsync
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
      let raise = (~expected, ~received, ~initialPath=Path.empty(), ()) => {
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
      raise(Exception({code, path: Path.empty()}))
    }

    let toParseError = (internalError: t): public => {
      {
        operation: Parsing,
        code: internalError.code,
        path: internalError.path->Path.toArray,
      }
    }

    let toSerializeError = (internalError: t): public => {
      operation: Serializing,
      code: internalError.code,
      path: internalError.path->Path.toArray,
    }

    @inline
    let fromPublic = (publicError: public): t => {
      code: publicError.code,
      path: publicError.path->Path.fromArray,
    }

    let prependLocation = (error, location) => {
      {
        ...error,
        path: error.path->Path.prependLocation(location),
      }
    }
    let prependPath = prependLocation
  }

  module MissingParserAndSerializer = {
    let panic = location => panic(`For a ${location} either a parser, or a serializer is required`)
  }

  module Unreachable = {
    let panic = () => panic("Unreachable")
  }

  let prependLocation = (error, location) => {
    {
      ...error,
      path: [location]->Js.Array2.concat(error.path),
    }
  }

  let raiseCustom = error => {
    raise(Internal.Exception(error->Internal.fromPublic))
  }

  let raise = message => {
    raise(Internal.Exception({code: OperationFailed(message), path: Path.empty()}))
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
    | TupleSize({expected, received}) =>
      `Expected Tuple with ${expected->Js.Int.toString} items, received ${received->Js.Int.toString}`
    | InvalidUnion(errors) => {
        let lineBreak = `\n${" "->Js.String2.repeat(nestedLevel * 2)}`
        let reasons =
          errors
          ->Js.Array2.map(error => {
            let reason = error->toReason(~nestedLevel=nestedLevel->Stdlib.Int.plus(1))
            let location = switch error.path {
            | [] => ""
            | nonEmptyPath => `Failed at ${nonEmptyPath->Path.toText}. `
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
    let pathText = error.path->Path.toText
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
  | AsyncOperation((. unknown) => (. unit) => Js.Promise.t<unknown>)
type rec t<'value> = {
  @as("n")
  name: string,
  @as("t")
  tagged: tagged,
  @as("pf")
  parseTransformationFactory: internalTransformationFactory,
  @as("sf")
  serializeTransformationFactory: internalTransformationFactory,
  @as("p")
  mutable cachedParseOperation: operation,
  @as("s")
  mutable cachedSerializeOperation: option<(. unknown) => unknown>,
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
and field<'value> = (string, t<'value>)
and transformation<'input, 'output> =
  | Sync('input => 'output)
  | Async('input => Js.Promise.t<'output>)
and internalTransformationFactoryCtxPhase = NoTransformation | OnlySync | OnlyAsync | SyncAndAsync
and internalTransformationFactoryCtx = {
  @as("p")
  mutable phase: internalTransformationFactoryCtxPhase,
  @as("s")
  mutable syncTransformation: (. unknown) => unknown,
  @as("a")
  mutable asyncTransformation: (. unknown) => Js.Promise.t<unknown>,
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
    let makeAsyncTransformation = (fn: 'a => Js.Promise.t<'b>): (
      (. unknown) => Js.Promise.t<unknown>
    ) => fn->Obj.magic

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
  let cachedParseOperation = struct.cachedParseOperation
  if cachedParseOperation === %raw("undefined") {
    let compiledParseOperation =
      struct.parseTransformationFactory->TransformationFactory.compile(~struct)
    struct.cachedParseOperation = compiledParseOperation
    compiledParseOperation
  } else {
    cachedParseOperation
  }
}

let getSerializeOperation = struct => {
  let cachedSerializeOperation = struct.cachedSerializeOperation
  if cachedSerializeOperation === %raw("undefined") {
    let compiledSerializeOperation = switch struct.serializeTransformationFactory->TransformationFactory.compile(
      ~struct,
    ) {
    | NoOperation => None
    | SyncOperation(fn) => Some(fn)
    | AsyncOperation(_) => Error.Unreachable.panic()
    }
    struct.cachedSerializeOperation = compiledSerializeOperation
    compiledSerializeOperation
  } else {
    cachedSerializeOperation
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
  cachedParseOperation: %raw("undefined"),
  cachedSerializeOperation: %raw("undefined"),
  maybeInlinedRefinement,
  maybeMetadataDict,
}

let parseWith = (any, struct) => {
  let struct = struct->castAnyStructToUnknownStruct
  try {
    switch struct->getParseOperation {
    | NoOperation => any->Obj.magic->Ok
    | SyncOperation(fn) => fn(. any->Obj.magic)->Obj.magic->Ok
    | AsyncOperation(_) => Error.Internal.raise(UnexpectedAsync)
    }
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  }
}

let parseOrRaiseWith = (any, struct) => {
  let struct = struct->castAnyStructToUnknownStruct
  try {
    switch struct->getParseOperation {
    | NoOperation => any->Obj.magic
    | SyncOperation(fn) => fn(. any->Obj.magic)->Obj.magic
    | AsyncOperation(_) => Error.Internal.raise(UnexpectedAsync)
    }
  } catch {
  | Error.Internal.Exception(internalError) =>
    raise(Raised(internalError->Error.Internal.toParseError))
  }
}

let parseAsyncWith = (any, struct) => {
  let struct = struct->castAnyStructToUnknownStruct
  try {
    switch struct->getParseOperation {
    | NoOperation => any->Obj.magic->Ok->Stdlib.Promise.resolve
    | SyncOperation(fn) => fn(. any->Obj.magic)->Ok->Obj.magic->Stdlib.Promise.resolve
    | AsyncOperation(fn) =>
      fn(. any->Obj.magic)(.)
      ->Stdlib.Promise.thenResolve(value => Ok(value->Obj.magic))
      ->Stdlib.Promise.catch(exn => {
        switch exn {
        | Error.Internal.Exception(internalError) =>
          internalError->Error.Internal.toParseError->Error
        | _ => raise(exn)
        }
      })
    }
  } catch {
  | Error.Internal.Exception(internalError) =>
    internalError->Error.Internal.toParseError->Error->Stdlib.Promise.resolve
  }
}

let parseAsyncInStepsWith = (any, struct) => {
  let struct = struct->castAnyStructToUnknownStruct
  try {
    switch struct->getParseOperation {
    | NoOperation => () => any->Obj.magic->Ok->Stdlib.Promise.resolve
    | SyncOperation(fn) => {
        let syncValue = fn(. any->castAnyToUnknown)->castUnknownToAny
        () => syncValue->Ok->Stdlib.Promise.resolve
      }

    | AsyncOperation(fn) => {
        let asyncFn = fn(. any->castAnyToUnknown)
        () =>
          asyncFn(.)
          ->Stdlib.Promise.thenResolve(value => Ok(value->Obj.magic))
          ->Stdlib.Promise.catch(exn => {
            switch exn {
            | Error.Internal.Exception(internalError) =>
              internalError->Error.Internal.toParseError->Error
            | _ => raise(exn)
            }
          })
      }
    }->Ok
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  }
}

let serializeWith = (value, struct) => {
  let struct = struct->castAnyStructToUnknownStruct
  let value = value->castAnyToUnknown
  try {
    switch struct->getSerializeOperation {
    | None => value
    | Some(fn) => fn(. value)
    }->Ok
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toSerializeError->Error
  }
}

let serializeOrRaiseWith = (value, struct) => {
  let struct = struct->castAnyStructToUnknownStruct
  let value = value->castAnyToUnknown
  try {
    switch struct->getSerializeOperation {
    | None => value
    | Some(fn) => fn(. value)
    }
  } catch {
  | Error.Internal.Exception(internalError) =>
    raise(Raised(internalError->Error.Internal.toSerializeError))
  }
}

module Metadata = {
  external castDictOfAnyToUnknown: Js.Dict.t<'any> => Js.Dict.t<unknown> = "%identity"

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
      metadataChange->castDictOfAnyToUnknown
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
    ~serializeTransformationFactory=TransformationFactory.make((
      . ~ctx,
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
    ~serializeTransformationFactory=TransformationFactory.make((
      . ~ctx,
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
      ~parseTransformationFactory=TransformationFactory.make((
        . ~ctx,
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
      ~serializeTransformationFactory=TransformationFactory.make((
        . ~ctx,
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

    let classify = struct =>
      struct->Metadata.get(~id=metadataId)->Stdlib.Option.getWithDefault(Strip)
  }

  module FieldDefinition = {
    type t

    let value: t = %raw(`Symbol("rescript-struct:Object.FieldDefinition")`)

    let castToAny: t => 'a = Obj.magic
  }

  module DefinedFieldInstruction = {
    type struct = t<unknown>
    type t =
      | Discriminant({
          fieldStruct: struct,
          inlinedOriginalFieldName: string,
          originalFieldName: string,
        })
      | Registered({
          fieldStruct: struct,
          originalFieldName: string,
          inlinedOriginalFieldName: string,
          inlinedPath: Path.Inlined.t,
          path: Path.t,
        })

    @inline
    let getFieldStruct = (definedFieldInstruction: t) => {
      switch definedFieldInstruction {
      | Discriminant({fieldStruct}) => fieldStruct
      | Registered({fieldStruct}) => fieldStruct
      }
    }

    @inline
    let getOriginalFieldName = (definedFieldInstruction: t) => {
      switch definedFieldInstruction {
      | Discriminant({originalFieldName}) => originalFieldName
      | Registered({originalFieldName}) => originalFieldName
      }
    }

    @inline
    let getInlinedOriginalFieldName = (definedFieldInstruction: t) => {
      switch definedFieldInstruction {
      | Discriminant({inlinedOriginalFieldName}) => inlinedOriginalFieldName
      | Registered({inlinedOriginalFieldName}) => inlinedOriginalFieldName
      }
    }
  }

  module ConstantInstruction = {
    type t = {inlinedPath: string, @as("v") value: unknown, path: string}
  }

  module DefinerCtx = {
    type struct = t<unknown>
    type t = {
      mutable originalFieldNames: array<string>,
      originalFields: Js.Dict.t<struct>,
      mutable registeredFieldsCount: int,
      inlinedPreparationPathes: array<string>,
      inlinedPreparationValues: array<string>,
      definedFieldInstructions: array<DefinedFieldInstruction.t>,
      constantInstructions: array<ConstantInstruction.t>,
    }

    @inline
    let make = () => {
      originalFieldNames: %raw("undefined"),
      originalFields: Js.Dict.empty(),
      registeredFieldsCount: 0,
      inlinedPreparationPathes: [],
      inlinedPreparationValues: [],
      definedFieldInstructions: [],
      constantInstructions: [],
    }
  }

  let rec analyzeDefinition = (definition, ~definerCtx: DefinerCtx.t, ~path, ~inlinedPath) => {
    if definition->Obj.magic === FieldDefinition.value {
      let originalFieldName =
        definerCtx.originalFieldNames->Js.Array2.unsafe_get(definerCtx.registeredFieldsCount)
      definerCtx.registeredFieldsCount = Stdlib.Int.plus(definerCtx.registeredFieldsCount, 1)
      definerCtx.definedFieldInstructions
      ->Js.Array2.push(
        Registered({
          path,
          inlinedPath,
          fieldStruct: definerCtx.originalFields->Js.Dict.unsafeGet(originalFieldName),
          originalFieldName,
          inlinedOriginalFieldName: originalFieldName->Stdlib.Inlined.Value.fromString,
        }),
      )
      ->ignore
    } else if definition->Js.typeof === "object" && definition !== %raw(`null`) {
      let definition: Js.Dict.t<unknown> = definition->Obj.magic
      definerCtx.inlinedPreparationPathes->Js.Array2.push(inlinedPath)->ignore
      definerCtx.inlinedPreparationValues
      ->Js.Array2.push(Js.Array2.isArray(definition) ? "[]" : "{}")
      ->ignore
      let definitionFieldNames = definition->Js.Dict.keys
      for idx in 0 to definitionFieldNames->Js.Array2.length - 1 {
        let definitionFieldName = definitionFieldNames->Js.Array2.unsafe_get(idx)
        let fieldDefinition = definition->Js.Dict.unsafeGet(definitionFieldName)
        fieldDefinition->analyzeDefinition(
          ~definerCtx,
          ~path=path->Path.appendLocation(definitionFieldName),
          ~inlinedPath=inlinedPath->Path.Inlined.appendLocation(definitionFieldName),
        )
      }
    } else {
      definerCtx.constantInstructions
      ->Js.Array2.push({
        inlinedPath,
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
      let originalFields = "f"
      @inline
      let transformedObject = "t"
      @inline
      let asyncTransformedObject = "a"
      @inline
      let asyncFieldsCounter = "y"
      @inline
      let instructionIdx = "i"
      @inline
      let catchFieldError = "c"
      @inline
      let parseFnsByInstructionIdx = "p"
      @inline
      let constantInstructions = "d"
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
          originalFields,
          inlinedPreparationValues,
          inlinedPreparationPathes,
          definedFieldInstructions,
          constantInstructions,
        } = instructions

        let withUnknownKeysRefinement = struct->UnknownKeys.classify === UnknownKeys.Strict

        let definedAsyncFieldInstructions = []
        let parseFnsByInstructionIdx = Js.Dict.empty()

        let inlinedParseFunction = {
          let refinement = Stdlib.Inlined.If.make(
            ~condition=`typeof ${Var.originalObject}!=="object"||${Var.originalObject}===null||Array.isArray(${Var.originalObject})`,
            ~content=`${Var.raiseUnexpectedOriginalObjectTypeError}(${Var.originalObject})`,
          )

          let preparation = {
            let stringRef = ref(`var ${Var.transformedObject};`)
            for idx in 0 to inlinedPreparationPathes->Js.Array2.length - 1 {
              let preparationPath = inlinedPreparationPathes->Js.Array2.unsafe_get(idx)
              let preparationInlinedValue = inlinedPreparationValues->Js.Array2.unsafe_get(idx)
              stringRef.contents =
                stringRef.contents ++
                `${Var.transformedObject}${preparationPath}=${preparationInlinedValue};`
            }
            stringRef.contents
          }

          let transformedObjectConstruction =
            definedFieldInstructions->Js.Array2.length === 0
              ? ""
              : {
                  let tryContent = {
                    let stringRef = ref("")
                    for idx in 0 to definedFieldInstructions->Js.Array2.length - 1 {
                      let definedFieldInstruction =
                        definedFieldInstructions->Js.Array2.unsafe_get(idx)
                      let fieldStruct =
                        definedFieldInstruction->DefinedFieldInstruction.getFieldStruct
                      let inlinedOriginalFieldName =
                        definedFieldInstruction->DefinedFieldInstruction.getInlinedOriginalFieldName
                      let inlinedInstructionIdx = idx->Js.Int.toString
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

                      let inlinedInputData = `${Var.originalObject}[${inlinedOriginalFieldName}]`

                      let maybeInlinedDestination = if isAsync {
                        let inlinedDestination = `${Var.asyncTransformedObject}[${definedAsyncFieldInstructions
                          ->Js.Array2.length
                          ->Js.Int.toString}]`

                        if definedAsyncFieldInstructions->Js.Array2.length === 0 {
                          stringRef.contents =
                            stringRef.contents ++ `var ${Var.asyncTransformedObject}={};`
                        }

                        switch definedFieldInstruction {
                        | Registered({inlinedPath}) =>
                          stringRef.contents =
                            stringRef.contents ++
                            `${Var.transformedObject}${inlinedPath}=undefined;`
                        | _ => ()
                        }

                        definedAsyncFieldInstructions
                        ->Js.Array2.push(definedFieldInstruction)
                        ->ignore

                        Some(inlinedDestination)
                      } else {
                        switch definedFieldInstruction {
                        | Discriminant(_) => None
                        | Registered({inlinedPath}) =>
                          Some(`${Var.transformedObject}${inlinedPath}`)
                        }
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
                            }}}else{${Var.instructionIdx}=${inlinedInstructionIdx};${Var.raiseUnexpectedTypeError}(${Stdlib.Inlined.Constant.inputVar},${Var.originalFields}[${inlinedOriginalFieldName}])}`
                        | (Some(fn), None) => {
                            parseFnsByInstructionIdx->Js.Dict.set(inlinedInstructionIdx, fn)
                            `${Var.instructionIdx}=${inlinedInstructionIdx};${switch maybeInlinedDestination {
                              | Some(inlinedDestination) => `${inlinedDestination}=`
                              | None => ""
                              }}${Var.parseFnsByInstructionIdx}[${inlinedInstructionIdx}](${inlinedInputData});`
                          }
                        }
                    }
                    stringRef.contents
                  }

                  `var ${Var.instructionIdx};` ++
                  Stdlib.Inlined.TryCatch.make(
                    ~tryContent,
                    ~catchContent=`${Var.catchFieldError}(${Stdlib.Inlined.Constant.errorVar},${Var.instructionIdx})`,
                  )
                }

          let unknownKeysRefinement = withUnknownKeysRefinement
            ? {
                let stringRef = ref(`for(var k in ${Var.originalObject}){switch(k){`)
                for idx in 0 to definedFieldInstructions->Js.Array2.length - 1 {
                  let definedFieldInstruction = definedFieldInstructions->Js.Array2.unsafe_get(idx)
                  let inlinedOriginalFieldName =
                    definedFieldInstruction->DefinedFieldInstruction.getInlinedOriginalFieldName
                  stringRef.contents =
                    stringRef.contents ++ `case${inlinedOriginalFieldName}:continue;`
                }
                stringRef.contents ++ `default:${Var.raiseExcessFieldError}(k)}}`
              }
            : ""

          let constants = {
            let stringRef = ref("")
            for idx in 0 to constantInstructions->Js.Array2.length - 1 {
              let {inlinedPath} = constantInstructions->Js.Array2.unsafe_get(idx)
              stringRef.contents =
                stringRef.contents ++
                `${Var.transformedObject}${inlinedPath}=${Var.constantInstructions}[${idx->Js.Int.toString}].v;`
            }
            stringRef.contents
          }

          let returnValue =
            definedAsyncFieldInstructions->Js.Array2.length === 0
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
            ~ctxVarValue1=(~exn, ~instructionIdx) => {
              switch exn {
              | Error.Internal.Exception(internalError) =>
                Error.Internal.Exception(
                  internalError->Error.Internal.prependLocation(
                    definedFieldInstructions
                    ->Js.Array2.unsafe_get(instructionIdx)
                    ->DefinedFieldInstruction.getOriginalFieldName,
                  ),
                )

              | _ => exn
              }->raise
            },
            ~ctxVarName2=Var.parseFnsByInstructionIdx,
            ~ctxVarValue2=parseFnsByInstructionIdx,
            ~ctxVarName3=Var.originalFields,
            ~ctxVarValue3=originalFields,
            ~ctxVarName4=Var.constantInstructions,
            ~ctxVarValue4=constantInstructions,
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

        if definedAsyncFieldInstructions->Js.Array2.length > 0 {
          let inlinedAsyncParseFunction = {
            let resolveVar = "rs"
            let rejectVar = "rj"

            let content = {
              let contentRef = ref(
                `var ${Var.asyncFieldsCounter}=${definedAsyncFieldInstructions
                  ->Js.Array2.length
                  ->Js.Int.toString},${Var.transformedObject}=${Var.asyncTransformedObject}.${Var.transformedObject};`,
              )
              for idx in 0 to definedAsyncFieldInstructions->Js.Array2.length - 1 {
                let definedAsyncFieldInstruction =
                  definedAsyncFieldInstructions->Js.Array2.unsafe_get(idx)
                let inlinedIdx = idx->Js.Int.toString

                let onFieldSuccessInlinedFn = {
                  let fieldValueVar = "z"
                  let inlinedFieldValueAssignment = switch definedAsyncFieldInstruction {
                  | Discriminant(_) => ""
                  | Registered({inlinedPath}) =>
                    `${Var.transformedObject}${inlinedPath}=${fieldValueVar}`
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
              ~ctxVarValue1=(exn, asyncInstructionIdx) => {
                switch exn {
                | Error.Internal.Exception(internalError) =>
                  Error.Internal.Exception(
                    internalError->Error.Internal.prependLocation(
                      definedAsyncFieldInstructions
                      ->Js.Array2.unsafe_get(asyncInstructionIdx)
                      ->DefinedFieldInstruction.getOriginalFieldName,
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
      let serializeFnsByInstructionIdx = "s"
      @inline
      let constantInstructions = "d"
      @inline
      let raiseDiscriminantError = "r"
      @inline
      let transformedObject = "t"
      @inline
      let instructionIdx = "i"
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
        let inliningOriginalFieldNameRef = ref(%raw("undefined"))
        try {
          let {definedFieldInstructions, constantInstructions} = instructions

          let serializeFnsByInstructionIdx = Js.Dict.empty()

          let inlinedSerializeFunction = {
            let constants = {
              let stringRef = ref("")
              for idx in 0 to constantInstructions->Js.Array2.length - 1 {
                let {inlinedPath} = constantInstructions->Js.Array2.unsafe_get(idx)
                stringRef.contents =
                  stringRef.contents ++
                  Stdlib.Inlined.If.make(
                    ~condition=`${Var.transformedObject}${inlinedPath}!==${Var.constantInstructions}[${idx->Js.Int.toString}].v`,
                    ~content=`${Var.raiseDiscriminantError}(${idx->Js.Int.toString},${Var.transformedObject}${inlinedPath})`,
                  )
              }
              stringRef.contents
            }

            let originalObjectConstructionAndReturn = {
              let tryContent = {
                let contentRef = ref(`var ${Var.instructionIdx};return{`)
                for idx in 0 to definedFieldInstructions->Js.Array2.length - 1 {
                  let definedFieldInstruction = definedFieldInstructions->Js.Array2.unsafe_get(idx)
                  let fieldStruct = definedFieldInstruction->DefinedFieldInstruction.getFieldStruct
                  let inlinedOriginalFieldName =
                    definedFieldInstruction->DefinedFieldInstruction.getInlinedOriginalFieldName
                  let inlinedInstructionIdx = idx->Js.Int.toString
                  contentRef.contents =
                    contentRef.contents ++
                    switch definedFieldInstruction {
                    | Registered({inlinedPath}) =>
                      switch fieldStruct->getSerializeOperation {
                      | None =>
                        `${inlinedOriginalFieldName}:${Var.transformedObject}${inlinedPath},`
                      | Some(fn) => {
                          serializeFnsByInstructionIdx->Js.Dict.set(inlinedInstructionIdx, fn)

                          `${inlinedOriginalFieldName}:(${Var.instructionIdx}=${inlinedInstructionIdx},${Var.serializeFnsByInstructionIdx}[${inlinedInstructionIdx}](${Var.transformedObject}${inlinedPath})),`
                        }
                      }

                    | Discriminant(_) => {
                        inliningOriginalFieldNameRef.contents =
                          definedFieldInstruction->DefinedFieldInstruction.getOriginalFieldName
                        `${inlinedOriginalFieldName}:${fieldStruct->structToInlinedValue},`
                      }
                    }
                }
                contentRef.contents ++ "}"
              }

              Stdlib.Inlined.TryCatch.make(
                ~tryContent,
                ~catchContent=`${Var.catchFieldError}(${Stdlib.Inlined.Constant.errorVar},${Var.instructionIdx})`,
              )
            }

            Stdlib.Inlined.Fn.make(
              ~arguments=Var.transformedObject,
              ~content=`${constants}${originalObjectConstructionAndReturn}`,
            )
          }

          ctx->TransformationFactory.Ctx.planSyncTransformation(
            Stdlib.Function.make4(
              ~ctxVarName1=Var.serializeFnsByInstructionIdx,
              ~ctxVarValue1=serializeFnsByInstructionIdx,
              ~ctxVarName2=Var.constantInstructions,
              ~ctxVarValue2=constantInstructions,
              ~ctxVarName3=Var.raiseDiscriminantError,
              ~ctxVarValue3=(~instructionIdx, ~received) => {
                let {value, path} = constantInstructions->Js.Array2.unsafe_get(instructionIdx)
                Error.Internal.UnexpectedValue.raise(
                  ~expected=value,
                  ~received,
                  ~initialPath=path,
                  (),
                )
              },
              ~ctxVarName4=Var.catchFieldError,
              ~ctxVarValue4=(~exn, ~instructionIdx) => {
                switch exn {
                | Error.Internal.Exception(internalError) => {
                    let definedFieldInstruction =
                      definedFieldInstructions->Js.Array2.unsafe_get(instructionIdx)
                    switch definedFieldInstruction {
                    | Registered({path}) =>
                      Error.Internal.Exception(internalError->Error.Internal.prependPath(path))
                    | _ => Error.Unreachable.panic()
                    }
                  }

                | _ => exn
                }->raise
              },
              ~inlinedFunction=inlinedSerializeFunction,
            ),
          )
        } catch {
        | _ =>
          let inliningOriginalFieldName = inliningOriginalFieldNameRef.contents
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
      let originalFieldNames = definerCtx.originalFields->Js.Dict.keys
      definerCtx.originalFieldNames = originalFieldNames

      definition->analyzeDefinition(
        ~definerCtx,
        ~path=Path.empty(),
        ~inlinedPath=Path.Inlined.empty(),
      )

      {
        let originalFieldNamesCount = originalFieldNames->Js.Array2.length
        if definerCtx.registeredFieldsCount > originalFieldNamesCount {
          Error.panic("The object defention has more registered fields than expected.")
        }
        if definerCtx.registeredFieldsCount < originalFieldNamesCount {
          Error.panic("The object defention contains fields that weren't registered.")
        }
      }

      definerCtx
    }

    make(
      ~name="Object",
      ~tagged=Object({
        fields: instructions.originalFields,
        fieldNames: instructions.originalFieldNames,
      }),
      ~parseTransformationFactory=ParseTransformationFactory.make(~instructions),
      ~serializeTransformationFactory=SerializeTransformationFactory.make(~instructions),
      (),
    )
  }

  let field = (definerCtx: DefinerCtx.t, originalFieldName, struct) => {
    let struct = struct->castAnyStructToUnknownStruct
    definerCtx.originalFields->Js.Dict.set(originalFieldName, struct)
    FieldDefinition.value->FieldDefinition.castToAny
  }

  let discriminant = (definerCtx: DefinerCtx.t, originalFieldName, struct) => {
    let fieldStruct = struct->castAnyStructToUnknownStruct
    definerCtx.originalFields->Js.Dict.set(originalFieldName, fieldStruct)
    definerCtx.registeredFieldsCount = Stdlib.Int.plus(definerCtx.registeredFieldsCount, 1)
    definerCtx.definedFieldInstructions
    ->Js.Array2.unshift(
      Discriminant({
        fieldStruct,
        originalFieldName,
        inlinedOriginalFieldName: originalFieldName->Stdlib.Inlined.Value.fromString,
      }),
    )
    ->ignore
    ()
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
  let factory = () => {
    let transformationFactory = TransformationFactory.make((. ~ctx, ~struct) =>
      ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
        raiseUnexpectedTypeError(~input, ~struct)
      })
    )

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
  let cuidRegex = %re(`/^c[^\s-]{8,}$/i`)
  let uuidRegex = %re(`/^([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[a-f0-9]{4}-[a-f0-9]{12}|00000000-0000-0000-0000-000000000000)$/i`)
  let emailRegex = %re(`/^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i`)

  let factory = () => {
    make(
      ~name="String",
      ~tagged=String,
      ~inlinedRefinement=`typeof ${Stdlib.Inlined.Constant.inputVar}==="string"`,
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          if input->Js.typeof === "string" {
            input
          } else {
            raiseUnexpectedTypeError(~input, ~struct)
          }
        })
      ),
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      if value->Js.String2.length < length {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `String must be ${length->Js.Int.toString} or more characters long`,
          ),
        )
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let max = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      if value->Js.String2.length > length {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `String must be ${length->Js.Int.toString} or fewer characters long`,
          ),
        )
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let length = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      if value->Js.String2.length !== length {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `String must be exactly ${length->Js.Int.toString} characters long`,
          ),
        )
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let email = (struct, ~message=`Invalid email address`, ()) => {
    let refiner = value => {
      if !(emailRegex->Js.Re.test_(value)) {
        Error.raise(message)
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let uuid = (struct, ~message=`Invalid UUID`, ()) => {
    let refiner = value => {
      if !(uuidRegex->Js.Re.test_(value)) {
        Error.raise(message)
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let cuid = (struct, ~message=`Invalid CUID`, ()) => {
    let refiner = value => {
      if !(cuidRegex->Js.Re.test_(value)) {
        Error.raise(message)
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let url = (struct, ~message=`Invalid url`, ()) => {
    let refiner = value => {
      if !(value->Stdlib.Url.test) {
        Error.raise(message)
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let pattern = (struct, ~message=`Invalid`, re) => {
    let refiner = value => {
      re->Js.Re.setLastIndex(0)
      if !(re->Js.Re.test_(value)) {
        Error.raise(message)
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
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
              Error.raise(obj->Js.Exn.message->Stdlib.Option.getWithDefault("Failed to parse JSON"))
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
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          switch innerStruct->getSerializeOperation {
          | None => input
          | Some(fn) => fn(. input)
          }
          ->Obj.magic
          ->Js.Json.stringify
        })
      }),
      (),
    )
  }
}

module Bool = {
  let factory = () => {
    make(
      ~name="Bool",
      ~tagged=Bool,
      ~inlinedRefinement=`typeof ${Stdlib.Inlined.Constant.inputVar}==="boolean"`,
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          if input->Js.typeof === "boolean" {
            input
          } else {
            raiseUnexpectedTypeError(~input, ~struct)
          }
        })
      ),
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }
}

module Int = {
  let factory = () => {
    make(
      ~name="Int",
      ~tagged=Int,
      ~inlinedRefinement=`typeof ${Stdlib.Inlined.Constant.inputVar}==="number"&&${Stdlib.Inlined.Constant.inputVar}<2147483648&&${Stdlib.Inlined.Constant.inputVar}>-2147483649&&${Stdlib.Inlined.Constant.inputVar}%1===0`,
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          if Stdlib.Int.test(input) {
            input
          } else {
            raiseUnexpectedTypeError(~input, ~struct)
          }
        })
      ),
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, thanValue) => {
    let refiner = value => {
      if value < thanValue {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `Number must be greater than or equal to ${thanValue->Js.Int.toString}`,
          ),
        )
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let max = (struct, ~message as maybeMessage=?, thanValue) => {
    let refiner = value => {
      if value > thanValue {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `Number must be lower than or equal to ${thanValue->Js.Int.toString}`,
          ),
        )
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let port = (struct, ~message="Invalid port", ()) => {
    let refiner = value => {
      if value < 1 || value > 65535 {
        Error.raise(message)
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }
}

module Float = {
  let factory = () => {
    make(
      ~name="Float",
      ~tagged=Float,
      ~inlinedRefinement=`typeof ${Stdlib.Inlined.Constant.inputVar}==="number"&&!Number.isNaN(${Stdlib.Inlined.Constant.inputVar})`,
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
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
      ),
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }

  let min = Int.min->Obj.magic
  let max = Int.max->Obj.magic
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
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          switch input {
          | Some(value) =>
            switch innerStruct->getSerializeOperation {
            | None => value
            | Some(fn) => fn(. value)
            }
          | None => Js.Null.empty->castAnyToUnknown
          }
        })
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
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          switch input {
          | Some(value) =>
            switch innerStruct->getSerializeOperation {
            | None => value
            | Some(fn) => fn(. value)
            }
          | None => Js.Undefined.empty->castAnyToUnknown
          }
        })
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
    let refiner = value => {
      if value->Js.Array2.length < length {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `Array must be ${length->Js.Int.toString} or more items long`,
          ),
        )
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let max = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value => {
      if value->Js.Array2.length > length {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `Array must be ${length->Js.Int.toString} or fewer items long`,
          ),
        )
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let length = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value => {
      if value->Js.Array2.length !== length {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `Array must be exactly ${length->Js.Int.toString} items long`,
          ),
        )
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
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
            input->castUnknownToAny->Stdlib.Option.getWithDefault(defaultValue)
          })
        | SyncOperation(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            fn(. input)->castUnknownToAny->Stdlib.Option.getWithDefault(defaultValue)
          })
        | AsyncOperation(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(fn->Stdlib.Fn.castToCurried)
          ctx->TransformationFactory.Ctx.planAsyncTransformation(asyncFn => {
            asyncFn(.)->Stdlib.Promise.thenResolve(
              value => {
                value->castUnknownToAny->Stdlib.Option.getWithDefault(defaultValue)
              },
            )
          })
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          let value = Some(input)->castAnyToUnknown
          switch innerStruct->getSerializeOperation {
          | None => value
          | Some(fn) => fn(. value)
          }
        })
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
        ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let inputArray = numberOfStructs === 1 ? [input] : input->Obj.magic

            let newArray = []
            for idx in 0 to numberOfStructs - 1 {
              let innerData = inputArray->Js.Array2.unsafe_get(idx)
              let innerStruct = structs->Js.Array.unsafe_get(idx)
              switch innerStruct->getSerializeOperation {
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
        ),
        (),
      )
    }
  )->Obj.magic
}

module Union = {
  exception HackyValidValue(unknown)

  let factory = structs => {
    if structs->Js.Array2.length < 2 {
      Error.panic("A Union struct factory require at least two structs")
    }

    make(
      ~name=`Union`,
      ~tagged=Union(structs->Obj.magic),
      ~parseTransformationFactory=TransformationFactory.make((
        . ~ctx,
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
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          let idxRef = ref(0)
          let maybeLastErrorRef = ref(None)
          let maybeNewValueRef = ref(None)
          while idxRef.contents < structs->Js.Array2.length && maybeNewValueRef.contents === None {
            let idx = idxRef.contents
            let innerStruct = structs->Js.Array2.unsafe_get(idx)->Obj.magic
            try {
              let newValue = switch innerStruct->getSerializeOperation {
              | None => input
              | Some(fn) => fn(. input)
              }
              maybeNewValueRef.contents = Some(newValue)
            } catch {
            | Error.Internal.Exception(internalError) => {
                maybeLastErrorRef.contents = Some(internalError)
                idxRef.contents = idxRef.contents->Stdlib.Int.plus(1)
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
        })
      ),
      (),
    )
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
    result->Stdlib.Result.mapError(Error.toString)
  }
}

let object = Object.factory
let field = Object.field
let discriminant = Object.discriminant
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
