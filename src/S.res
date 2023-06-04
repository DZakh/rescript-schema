type never

module Obj = {
  external magic: 'a => 'b = "%identity"
}

module Stdlib = {
  module Unknown = {
    let toName = unknown =>
      switch unknown->Js.Types.classify {
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
      }
  }

  module Promise = {
    type t<+'a> = promise<'a>

    @send
    external thenResolveWithCatch: (t<'a>, @uncurry ('a => 'b), @uncurry (exn => 'b)) => t<'b> =
      "then"

    @val @scope("Promise")
    external resolve: 'a => t<'a> = "resolve"
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

  module Re = {
    @send
    external toString: Js.Re.t => string = "toString"
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
  }

  module Object = {
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
    let unique = array => array->Set.fromArray->Set.toArray

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
      (int1->Js.Int.toFloat +. int2->Js.Int.toFloat)->(Obj.magic: float => int)
    }

    // TODO: Use in more places
    external unsafeToString: int => string = "%identity"
  }

  module Dict = {
    @val
    external copy: (@as(json`{}`) _, Js.Dict.t<'a>) => Js.Dict.t<'a> = "Object.assign"

    @send
    external has: (Js.Dict.t<'a>, string) => bool = "hasOwnProperty"

    @inline
    let deleteInPlace = (dict, key) => {
      Js.Dict.unsafeDeleteKey(. dict->(Obj.magic: Js.Dict.t<'a> => Js.Dict.t<string>), key)
    }
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
  }

  module Inlined = {
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

    module Float = {
      @inline
      let toRescript = float => float->Js.Float.toString ++ (mod_float(float, 1.) === 0. ? "." : "")
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

  let rec toReason = (~nestedLevel=0, error) => {
    switch error.code {
    | OperationFailed(reason) => reason
    | MissingParser => "Struct parser is missing"
    | MissingSerializer => "Struct serializer is missing"
    | UnexpectedAsync => "Encountered unexpected asynchronous transform or refine. Use S.parseAsyncWith instead of S.parseWith"
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

let advancedFail = error => {
  raise(Error.Internal.Exception(error->Error.Internal.fromPublic))
}

let fail = (~path=Path.empty, message) => {
  raise(Error.Internal.Exception({code: OperationFailed(message), path}))
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

type operationBuilderResult = {
  code: string,
  outputVar: string,
  isAsync: bool,
}
@unboxed
type isAsyncParse = | @as(0) Unknown | Value(bool)

type rec t<'value> = {
  @as("n")
  name: string,
  @as("t")
  tagged: tagged,
  @as("pb")
  mutable parseOperationBuilder: (
    . builderCtx,
    ~selfStruct: t<unknown>,
    ~inputVar: string,
    ~pathVar: string,
  ) => operationBuilderResult,
  @as("sb")
  mutable serializeOperationBuilder: (
    . builderCtx,
    ~selfStruct: t<unknown>,
    ~inputVar: string,
    ~pathVar: string,
  ) => operationBuilderResult,
  @as("i")
  mutable isAsyncParse: isAsyncParse,
  @as("s")
  mutable serialize: (. unknown) => unknown,
  @as("j")
  mutable serializeToJson: (. unknown) => Js.Json.t,
  @as("p")
  mutable parse: (. unknown) => unknown,
  @as("a")
  mutable parseAsync: (. unknown) => (. unit) => promise<unknown>,
  @as("m")
  metadataMap: Js.Dict.t<unknown>,
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
  | JSON
and transformation<'input, 'output> =
  | Noop: transformation<'input, 'input>
  | Sync('input => 'output)
  | Async('input => promise<'output>)
and builderCtx = {
  mutable varCounter: int,
  mutable varsAllocation: string,
  embeded: array<unknown>,
}
and struct<'a> = t<'a>

type payloadedVariant<'payload> = {_0: 'payload}
let unsafeGetVariantPayload = variant => (variant->Obj.magic)._0

let emptyMetadataMap = Js.Dict.empty()

external castAnyToUnknown: 'any => unknown = "%identity"
external castUnknownToAny: unknown => 'any = "%identity"
external castUnknownStructToAnyStruct: t<unknown> => t<'any> = "%identity"
external toUnknown: t<'any> => t<unknown> = "%identity"
external castToTaggedLiteral: literal<'a> => taggedLiteral = "%identity"

module TransformationFactory = {
  type t<'value, 'input, 'output> = (~struct: struct<'value>) => transformation<'input, 'output>
  let call = (public, ~struct) =>
    (
      public->(
        Obj.magic: t<'value, 'input, 'output> => (
          . ~struct: struct<unknown>,
        ) => transformation<unknown, unknown>
      )
    )(. ~struct)
}

@inline
let classify = struct => struct.tagged

@inline
let name = struct => struct.name

module Builder = {
  module Ctx = {
    type t = builderCtx

    @inline
    let embed = (b: t, value) => {
      `e[${(b.embeded->Js.Array2.push(value->castAnyToUnknown)->(Obj.magic: int => float) -. 1.)
          ->(Obj.magic: float => string)}]`
    }

    let var = (b: t) => {
      b.varCounter = b.varCounter->Stdlib.Int.plus(1)
      let v = `v${b.varCounter->Stdlib.Int.unsafeToString}`
      b.varsAllocation = b.varsAllocation ++ "," ++ v
      v
    }

    let varWithoutAllocation = (b: t) => {
      b.varCounter = b.varCounter->Stdlib.Int.plus(1)
      `v${b.varCounter->Stdlib.Int.unsafeToString}`
    }

    let internalTransformRethrow = (~pathVar) => {
      `if(t&&t.RE_EXN_ID==="S-RescriptStruct.Error.Internal.Exception/1"){t._1.p=${pathVar}+t._1.p}throw t`
    }

    let syncOperation = (b: t, ~inputVar, ~fn: (. unknown) => unknown, ~prependPathVar) => {
      let outputVar = b->var
      let code = `${outputVar}=${b->embed(fn)}(${inputVar});`
      {
        isAsync: false,
        outputVar,
        code: switch prependPathVar {
        | `""` => code
        | pathVar => `try{${code}}catch(t){${internalTransformRethrow(~pathVar)}}`
        },
      }
    }

    let asyncOperation = (
      b: t,
      ~inputVar,
      ~fn: (. unknown) => (. unit) => promise<unknown>,
      ~prependPathVar,
    ) => {
      let outputVar = b->var
      switch prependPathVar {
      | `""` => {
          isAsync: true,
          outputVar,
          code: `${outputVar}=${b->embed(fn)}(${inputVar});`,
        }
      | pathVar =>
        let syncResultVar = b->varWithoutAllocation
        // TODO: Test more places that might break because of the var scope
        let code = `let ${syncResultVar}=${b->embed(fn)}(${inputVar});`
        {
          isAsync: true,
          outputVar,
          code: `try{${code}${outputVar}=()=>{try{return ${syncResultVar}().catch(t=>{${internalTransformRethrow(
              ~pathVar,
            )}})}catch(t){${internalTransformRethrow(
              ~pathVar,
            )}}}}catch(t){${internalTransformRethrow(~pathVar)}};`,
        }
      }
    }

    let syncTransform = (
      b: t,
      ~inputVar,
      ~outputVar,
      ~isAsyncInput,
      ~fn: 'input => 'output,
      ~isRefine=false,
      ~prependPathVar as maybePrependPathVar=?,
      (),
    ) => {
      switch isAsyncInput {
      | false =>
        let code = isRefine
          ? `${b->embed(fn)}(${inputVar});${outputVar}=${inputVar};`
          : `${outputVar}=${b->embed(fn)}(${inputVar})`
        switch maybePrependPathVar {
        | None
        | Some(`""`) => code
        | Some(pathVar) => `try{${code}}catch(t){${internalTransformRethrow(~pathVar)}}`
        }
      | true =>
        let code = `${outputVar}=()=>${inputVar}().then(${isRefine
            ? `t=>{${b->embed(fn)}(t);return ${inputVar}}`
            : b->embed(fn)})`
        switch maybePrependPathVar {
        | None
        | Some(`""`) => code
        | Some(pathVar) => `${code}.catch(t=>{${internalTransformRethrow(~pathVar)}})`
        }
      } ++ ";"
    }

    let asyncTransform = (
      b: t,
      ~inputVar,
      ~outputVar,
      ~isAsyncInput,
      ~fn: 'input => 'output,
      ~isRefine=false,
      ~prependPathVar as maybePrependPathVar=?,
      (),
    ) => {
      `${outputVar}=()=>` ++
      switch isAsyncInput {
      | false =>
        let code = `${b->embed(fn)}(${inputVar})` ++ (isRefine ? `.then(_=>${inputVar})` : "")
        switch maybePrependPathVar {
        | None
        | Some(`""`) => code
        | Some(pathVar) =>
          `{try{return ${code}.catch(t=>{${internalTransformRethrow(
              ~pathVar,
            )}})}catch(t){${internalTransformRethrow(~pathVar)}}}`
        }
      | true =>
        let code = `${inputVar}().then(${isRefine
            ? `t=>${b->embed(fn)}(t).then(_=>t)`
            : b->embed(fn)})`
        switch maybePrependPathVar {
        | None
        | Some(`""`) => code
        | Some(pathVar) => `${code}.catch(t=>{${internalTransformRethrow(~pathVar)}})`
        }
      } ++ ";"
    }

    let raiseWithArg = (b: t, ~pathVar, fn: (. 'arg) => Error.code, arg) => {
      `${b->embed((path, arg) => {
          raise(Error.Internal.Exception({code: fn(arg), path}))
        })}(${pathVar},${arg})`
    }

    let raise = (b: t, ~pathVar, code) => {
      `${b->embed(path => {
          raise(Error.Internal.Exception({code, path}))
        })}(${pathVar})`
    }

    let compileParser = (b: t, ~struct, ~inputVar, ~pathVar) => {
      struct.parseOperationBuilder(. b, ~selfStruct=struct, ~inputVar, ~pathVar)
    }
  }

  let noop = (. _b, ~selfStruct as _, ~inputVar, ~pathVar as _) => {
    {
      isAsync: false,
      outputVar: inputVar,
      code: "",
    }
  }

  let run = (operationBuilder, ~struct) => {
    let intitialInputVar = "i"
    let b = {
      embeded: [],
      varCounter: -1,
      varsAllocation: "_",
    }
    let {code, outputVar, isAsync} = operationBuilder(.
      b,
      ~selfStruct=struct,
      ~inputVar=intitialInputVar,
      ~pathVar=`""`,
    )
    struct.isAsyncParse = Value(isAsync)
    // TODO:Shouldn't run for serializers
    // TODO:Optimize Builder.noop i=>{var _;return i}
    let inlinedFunction = `${intitialInputVar}=>{var ${b.varsAllocation};${code}return ${outputVar}}`
    Js.log(inlinedFunction)
    Stdlib.Function.make1(~ctxVarName1="e", ~ctxVarValue1=b.embeded, ~inlinedFunction)
  }

  let compileParser = (struct, ~operationBuilder=struct.parseOperationBuilder, ()) => {
    let operation = operationBuilder->run(~struct)
    let isAsync = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
    struct.parse = isAsync ? (. _) => Error.Internal.raise(UnexpectedAsync) : operation
    struct.parseAsync = isAsync
      ? operation
      : (. input) => {
          let syncValue = operation(. input)
          (. ()) => syncValue->Stdlib.Promise.resolve
        }
  }

  let compileSerializer = (struct, ~operationBuilder=struct.serializeOperationBuilder, ()) => {
    let operation = operationBuilder->run(~struct)
    struct.serialize = operation
  }
}
module B = Builder.Ctx

let isAsyncParse = struct => {
  let struct = struct->toUnknown
  switch struct.isAsyncParse {
  | Unknown => {
      struct->Builder.compileParser()
      struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
    }
  | Value(v) => v
  }
}

let initialSerialize = (. input) => {
  let struct = %raw("this")
  struct->Builder.compileSerializer()
  struct.serialize(. input)
}

let rec validateJsonableStruct = (struct, ~rootStruct, ~isRoot=false, ()) => {
  if isRoot || rootStruct !== struct {
    switch struct->classify {
    | String
    | Int
    | Float
    | Bool
    | Never
    | JSON
    | Literal(String(_))
    | Literal(Int(_))
    | Literal(Float(_))
    | Literal(Bool(_))
    | Literal(EmptyNull) => ()
    | Dict(childStruct)
    | Null(childStruct)
    | Array(childStruct) =>
      childStruct->validateJsonableStruct(~rootStruct, ())
    | Object({fieldNames, fields}) =>
      for idx in 0 to fieldNames->Js.Array2.length - 1 {
        let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
        let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
        try {
          switch fieldStruct->classify {
          // Allow optional fields
          | Option(s) => s
          | _ => fieldStruct
          }->validateJsonableStruct(~rootStruct, ())
        } catch {
        | Error.Internal.Exception(e) =>
          raise(Error.Internal.Exception(e->Error.Internal.prependLocation(fieldName)))
        }
      }

    | Tuple(childrenStructs) =>
      childrenStructs->Js.Array2.forEachi((childStruct, i) => {
        try {
          childStruct->validateJsonableStruct(~rootStruct, ())
        } catch {
        | Error.Internal.Exception(e) =>
          raise(Error.Internal.Exception(e->Error.Internal.prependLocation(i->Js.Int.toString)))
        }
      })
    | Union(childrenStructs) =>
      childrenStructs->Js.Array2.forEach(childStruct =>
        childStruct->validateJsonableStruct(~rootStruct, ())
      )
    | Option(_)
    | Unknown
    | Literal(EmptyOption)
    | Literal(NaN) =>
      Error.Internal.raise(InvalidJsonStruct({received: struct->name}))
    }
  }
}

let initialSerializeToJson = (. input) => {
  let struct = %raw("this")
  try {
    struct->validateJsonableStruct(~rootStruct=struct, ~isRoot=true, ())
    if struct.serialize === initialSerialize {
      struct->Builder.compileSerializer()
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
  struct->Builder.compileParser()
  struct.parse(. input)
}

let intitialParseAsync = (. input) => {
  let struct = %raw("this")
  struct->Builder.compileParser()
  struct.parseAsync(. input)
}

@inline
let make = (
  ~name,
  ~tagged,
  ~metadataMap,
  ~parseOperationBuilder,
  ~serializeOperationBuilder,
  (),
) => {
  name,
  tagged,
  parseOperationBuilder,
  serializeOperationBuilder,
  isAsyncParse: Unknown,
  serialize: initialSerialize,
  serializeToJson: initialSerializeToJson,
  parse: intitialParse,
  parseAsync: intitialParseAsync,
  metadataMap,
}

let parseAnyWith = (any, struct) => {
  try {
    struct.parse(. any->castAnyToUnknown)->castUnknownToAny->Ok
  } catch {
  | Js.Exn.Error(jsError) => raise(jsError->(Obj.magic: Js.Exn.t => exn))
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  }
}

let parseWith: (Js.Json.t, t<'value>) => result<'value, Error.t> = parseAnyWith

let parseAnyOrRaiseWith = (any, struct) => {
  try {
    struct.parse(. any->castAnyToUnknown)->castUnknownToAny
  } catch {
  | Js.Exn.Error(jsError) => raise(jsError->(Obj.magic: Js.Exn.t => exn))
  | Error.Internal.Exception(internalError) =>
    raise(Raised(internalError->Error.Internal.toParseError))
  }
}

let parseOrRaiseWith: (Js.Json.t, t<'value>) => 'value = parseAnyOrRaiseWith

let asyncPrepareOk = value => Ok(value->castUnknownToAny)

let asyncPrepareError = exn => {
  switch exn {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  | _ => raise(exn)
  }
}

let parseAnyAsyncWith = (any, struct) => {
  try {
    struct.parseAsync(. any->castAnyToUnknown)(.)->Stdlib.Promise.thenResolveWithCatch(
      asyncPrepareOk,
      asyncPrepareError,
    )
  } catch {
  | Js.Exn.Error(jsError) => raise(jsError->(Obj.magic: Js.Exn.t => exn))
  | Error.Internal.Exception(internalError) =>
    internalError->Error.Internal.toParseError->Error->Stdlib.Promise.resolve
  }
}

let parseAsyncWith = parseAnyAsyncWith

let parseAnyAsyncInStepsWith = (any, struct) => {
  try {
    let asyncFn = struct.parseAsync(. any->castAnyToUnknown)

    (
      (. ()) => asyncFn(.)->Stdlib.Promise.thenResolveWithCatch(asyncPrepareOk, asyncPrepareError)
    )->Ok
  } catch {
  | Js.Exn.Error(jsError) => raise(jsError->(Obj.magic: Js.Exn.t => exn))
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  }
}

let parseAsyncInStepsWith = parseAnyAsyncInStepsWith

let serializeToUnknownWith = (value, struct) => {
  try {
    struct.serialize(. value->castAnyToUnknown)->Ok
  } catch {
  | Js.Exn.Error(jsError) => raise(jsError->(Obj.magic: Js.Exn.t => exn))
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toSerializeError->Error
  }
}

let serializeOrRaiseWith = (value, struct) => {
  try {
    struct.serializeToJson(. value->castAnyToUnknown)
  } catch {
  | Js.Exn.Error(jsError) => raise(jsError->(Obj.magic: Js.Exn.t => exn))
  | Error.Internal.Exception(internalError) =>
    raise(Raised(internalError->Error.Internal.toSerializeError))
  }
}

let serializeToUnknownOrRaiseWith = (value, struct) => {
  try {
    struct.serialize(. value->castAnyToUnknown)
  } catch {
  | Js.Exn.Error(jsError) => raise(jsError->(Obj.magic: Js.Exn.t => exn))
  | Error.Internal.Exception(internalError) =>
    raise(Raised(internalError->Error.Internal.toSerializeError))
  }
}

let serializeWith = (value, struct) => {
  try {
    struct.serializeToJson(. value->castAnyToUnknown)->Ok
  } catch {
  | Js.Exn.Error(jsError) => raise(jsError->(Obj.magic: Js.Exn.t => exn))
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toSerializeError->Error
  }
}

let serializeToJsonStringWith = (value: 'value, ~space=0, struct: t<'value>): result<
  string,
  Error.t,
> => {
  switch value->serializeWith(struct) {
  | Ok(json) => Ok(json->Js.Json.stringifyWithSpace(space))
  | Error(_) as e => e
  }
}

let parseJsonStringWith = (json: string, struct: t<'value>): result<'value, Error.t> => {
  switch try {
    json->Js.Json.parseExn->Ok
  } catch {
  | Js.Exn.Error(error) =>
    Error({
      Error.code: OperationFailed(error->Js.Exn.message->(Obj.magic: option<string> => string)),
      operation: Parsing,
      path: Path.empty,
    })
  } {
  | Ok(json) => json->parseWith(struct)
  | Error(_) as e => e
  }
}

let recursive = fn => {
  let placeholder: t<'value> = %raw(`{m:emptyMetadataMap}`)
  let struct = fn->Stdlib.Fn.call1(placeholder)
  placeholder->Stdlib.Object.overrideWith(struct)

  {
    let operationBuilder = placeholder.parseOperationBuilder
    placeholder.parseOperationBuilder = (. b, ~selfStruct, ~inputVar, ~pathVar) => {
      selfStruct.parseOperationBuilder = Builder.noop
      let {isAsync} = operationBuilder(. b, ~selfStruct, ~inputVar, ~pathVar)
      b.varCounter = -1
      b.varsAllocation = "_"
      selfStruct.parseOperationBuilder = (. b, ~selfStruct, ~inputVar, ~pathVar) => {
        if isAsync {
          b->B.asyncOperation(
            ~inputVar,
            ~fn=(. input) => selfStruct.parseAsync(input),
            ~prependPathVar=pathVar,
          )
        } else {
          b->B.syncOperation(
            ~inputVar,
            ~fn=(. input) => selfStruct.parse(input),
            ~prependPathVar=pathVar,
          )
        }
      }

      selfStruct->Builder.compileParser(~operationBuilder, ())
      selfStruct.parseOperationBuilder = operationBuilder
      if isAsync {
        b->B.asyncOperation(~inputVar, ~fn=selfStruct.parseAsync, ~prependPathVar=pathVar)
      } else {
        b->B.syncOperation(~inputVar, ~fn=selfStruct.parse, ~prependPathVar=pathVar)
      }
    }
  }

  {
    let operationBuilder = placeholder.serializeOperationBuilder
    placeholder.serializeOperationBuilder = (. b, ~selfStruct, ~inputVar, ~pathVar) => {
      selfStruct.serializeOperationBuilder = (. b, ~selfStruct, ~inputVar, ~pathVar) => {
        b->B.syncOperation(
          ~inputVar,
          ~fn=(. input) => selfStruct.serialize(input),
          ~prependPathVar=pathVar,
        )
      }
      selfStruct->Builder.compileSerializer(~operationBuilder, ())
      selfStruct.serializeOperationBuilder = operationBuilder
      b->B.syncOperation(~inputVar, ~fn=selfStruct.serialize, ~prependPathVar=pathVar)
    }
  }

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

  let get = (struct, ~id: Id.t<'metadata>): option<'metadata> => {
    struct.metadataMap->Js.Dict.get(id->Id.toKey)->Obj.magic
  }

  let set = (struct, ~id: Id.t<'metadata>, ~metadata: 'metadata) => {
    let metadataMap = struct.metadataMap->Stdlib.Dict.copy
    metadataMap->Js.Dict.set(id->Id.toKey, metadata->castAnyToUnknown)
    make(
      ~name=struct.name,
      ~parseOperationBuilder=struct.parseOperationBuilder,
      ~serializeOperationBuilder=struct.serializeOperationBuilder,
      ~tagged=struct.tagged,
      ~metadataMap,
      (),
    )
  }
}

let refine: (
  t<'value>,
  ~parser: 'value => unit=?,
  ~asyncParser: 'value => promise<unit>=?,
  ~serializer: 'value => unit=?,
  unit,
) => t<'value> = (
  struct,
  ~parser as maybeParser=?,
  ~asyncParser as maybeAsyncParser=?,
  ~serializer as maybeSerializer=?,
  (),
) => {
  let struct = struct->toUnknown

  if maybeParser === None && maybeAsyncParser === None && maybeSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Refine`)
  }

  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseOperationBuilder=switch (maybeParser, maybeAsyncParser) {
    | (Some(parser), Some(asyncParser)) =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let {code, outputVar: childOutputVar, isAsync} =
          b->B.compileParser(~struct, ~inputVar, ~pathVar)
        let outputVar = b->B.var
        {
          code: `${code}${b->B.syncTransform(
              ~inputVar=childOutputVar,
              ~outputVar,
              ~isAsyncInput=isAsync,
              ~fn=parser,
              ~prependPathVar=pathVar,
              ~isRefine=true,
              (),
            )}${b->B.asyncTransform(
              ~inputVar=childOutputVar,
              ~outputVar,
              ~isAsyncInput=isAsync,
              ~fn=asyncParser,
              ~prependPathVar=pathVar,
              ~isRefine=true,
              (),
            )}`,
          outputVar,
          isAsync: true,
        }
      }
    | (Some(parser), None) =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let {code, outputVar: childOutputVar, isAsync} =
          b->B.compileParser(~struct, ~inputVar, ~pathVar)
        let outputVar = b->B.var
        {
          code: `${code}${b->B.syncTransform(
              ~inputVar=childOutputVar,
              ~outputVar,
              ~isAsyncInput=isAsync,
              ~fn=parser,
              ~prependPathVar=pathVar,
              ~isRefine=true,
              (),
            )}`,
          outputVar,
          isAsync,
        }
      }
    | (None, Some(asyncParser)) =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let {code, outputVar: childOutputVar, isAsync} =
          b->B.compileParser(~struct, ~inputVar, ~pathVar)
        let outputVar = b->B.var
        {
          code: `${code}${b->B.asyncTransform(
              ~inputVar=childOutputVar,
              ~outputVar,
              ~isAsyncInput=isAsync,
              ~fn=asyncParser,
              ~prependPathVar=pathVar,
              ~isRefine=true,
              (),
            )}`,
          outputVar,
          isAsync: true,
        }
      }
    | (None, None) => struct.parseOperationBuilder
    },
    ~serializeOperationBuilder=switch maybeSerializer {
    | Some(serializer) =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let {code, outputVar} = b->B.compileParser(~struct, ~inputVar, ~pathVar)

        {
          code: b->B.syncTransform(
            ~inputVar,
            ~outputVar=inputVar,
            ~isAsyncInput=false,
            ~fn=serializer,
            ~prependPathVar=pathVar,
            ~isRefine=true,
            (),
          ) ++ code,
          outputVar,
          isAsync: false,
        }
      }

    | None => struct.serializeOperationBuilder
    },
    ~metadataMap=struct.metadataMap,
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

let advancedTransform: (
  t<'value>,
  ~parser: (~struct: t<'value>) => transformation<'value, 'transformed>=?,
  ~serializer: (~struct: t<'value>) => transformation<'transformed, 'value>=?,
  unit,
) => t<'transformed> = (struct, ~parser as maybeParser=?, ~serializer as maybeSerializer=?, ()) => {
  let struct = struct->toUnknown
  if maybeParser === None && maybeSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Transform`)
  }

  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseOperationBuilder=(. b, ~selfStruct, ~inputVar, ~pathVar) => {
      switch maybeParser {
      | Some(parser) =>
        switch parser->TransformationFactory.call(
          ~struct=selfStruct->castUnknownStructToAnyStruct,
        ) {
        | Noop => b->B.compileParser(~struct, ~inputVar, ~pathVar)
        | Sync(syncTransformation) => {
            let {code, outputVar: childOutputVar, isAsync} =
              b->B.compileParser(~struct, ~inputVar, ~pathVar)
            let outputVar = b->B.var
            {
              code: `${code}${b->B.syncTransform(
                  ~inputVar=childOutputVar,
                  ~outputVar,
                  ~isAsyncInput=isAsync,
                  ~fn=syncTransformation,
                  ~prependPathVar=pathVar,
                  (),
                )}`,
              outputVar,
              isAsync,
            }
          }
        | Async(asyncTransformation) => {
            let {code, outputVar: childOutputVar, isAsync} =
              b->B.compileParser(~struct, ~inputVar, ~pathVar)
            let outputVar = b->B.var
            {
              code: `${code}${b->B.asyncTransform(
                  ~inputVar=childOutputVar,
                  ~outputVar,
                  ~isAsyncInput=isAsync,
                  ~fn=asyncTransformation,
                  ~prependPathVar=pathVar,
                  (),
                )}`,
              outputVar,
              isAsync: true,
            }
          }
        }
      | None => {
          code: b->B.raise(~pathVar, MissingParser) ++ ";",
          outputVar: inputVar,
          isAsync: false,
        }
      }
    },
    ~serializeOperationBuilder=(. b, ~selfStruct, ~inputVar, ~pathVar) => {
      switch maybeSerializer {
      | Some(serializer) =>
        switch serializer->TransformationFactory.call(
          ~struct=selfStruct->castUnknownStructToAnyStruct,
        ) {
        | Noop => struct.serializeOperationBuilder(. b, ~selfStruct=struct, ~inputVar, ~pathVar)
        | Sync(fn) => {
            let transformOutputVar = b->B.var
            let {code, outputVar} = struct.serializeOperationBuilder(.
              b,
              ~selfStruct=struct,
              ~inputVar=transformOutputVar,
              ~pathVar,
            )
            {
              code: `${b->B.syncTransform(
                  ~inputVar,
                  ~outputVar=transformOutputVar,
                  ~isAsyncInput=false,
                  ~fn,
                  ~prependPathVar=pathVar,
                  (),
                )}${code}`,
              outputVar,
              isAsync: false,
            }
          }
        | Async(_) => {
            code: b->B.raise(~pathVar, MissingSerializer) ++ ";",
            outputVar: inputVar,
            isAsync: false,
          }
        }
      | None => {
          code: b->B.raise(~pathVar, MissingSerializer) ++ ";",
          outputVar: inputVar,
          isAsync: false,
        }
      }
    },
    ~metadataMap=struct.metadataMap,
    (),
  )
}

let transform: (
  t<'value>,
  ~parser: 'value => 'transformed=?,
  ~asyncParser: 'value => promise<'trnsformed>=?,
  ~serializer: 'transformed => 'value=?,
  unit,
) => t<'transformed> = (
  struct,
  ~parser as maybeParser=?,
  ~asyncParser as maybeAsyncParser=?,
  ~serializer as maybeSerializer=?,
  (),
) => {
  let struct = struct->toUnknown
  if maybeParser === None && maybeAsyncParser === None && maybeSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Transform`)
  }

  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseOperationBuilder=switch (maybeParser, maybeAsyncParser) {
    | (Some(_), Some(_)) =>
      Error.panic(
        "The S.transform doesn't support the `parser` and `asyncParser` arguments simultaneously. Move `asyncParser` to another S.transform.",
      )
    | (Some(parser), None) =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let {code, outputVar: childOutputVar, isAsync} =
          b->B.compileParser(~struct, ~inputVar, ~pathVar)
        let outputVar = b->B.var
        {
          code: `${code}${b->B.syncTransform(
              ~inputVar=childOutputVar,
              ~outputVar,
              ~isAsyncInput=isAsync,
              ~fn=parser,
              ~prependPathVar=pathVar,
              (),
            )}`,
          outputVar,
          isAsync,
        }
      }
    | (None, Some(asyncParser)) =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let {code, outputVar: childOutputVar, isAsync} =
          b->B.compileParser(~struct, ~inputVar, ~pathVar)
        let outputVar = b->B.var
        {
          code: `${code}${b->B.asyncTransform(
              ~inputVar=childOutputVar,
              ~outputVar,
              ~isAsyncInput=isAsync,
              ~fn=asyncParser,
              ~prependPathVar=pathVar,
              (),
            )}`,
          outputVar,
          isAsync: true,
        }
      }
    | (None, None) =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        code: b->B.raise(~pathVar, MissingParser) ++ ";",
        outputVar: inputVar,
        isAsync: false,
      }
    },
    ~serializeOperationBuilder=switch maybeSerializer {
    | Some(serializer) =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let transformOutputVar = b->B.var
        let {code, outputVar} = struct.serializeOperationBuilder(.
          b,
          ~selfStruct=struct,
          ~inputVar=transformOutputVar,
          ~pathVar,
        )
        {
          code: `${b->B.syncTransform(
              ~inputVar,
              ~outputVar=transformOutputVar,
              ~isAsyncInput=false,
              ~fn=serializer,
              ~prependPathVar=pathVar,
              (),
            )}${code}`,
          outputVar,
          isAsync: false,
        }
      }
    | None =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        code: b->B.raise(~pathVar, MissingSerializer) ++ ";",
        outputVar: inputVar,
        isAsync: false,
      }
    },
    ~metadataMap=struct.metadataMap,
    (),
  )
}

let rec advancedPreprocess = (
  struct,
  ~parser as maybeParser=?,
  ~serializer as maybeSerializer=?,
  (),
) => {
  let struct = struct->toUnknown

  if maybeParser === None && maybeSerializer === None {
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
          ->advancedPreprocess(~parser=?maybeParser, ~serializer=?maybeSerializer, ())
          ->toUnknown
        ),
      ),
      ~parseOperationBuilder=struct.parseOperationBuilder,
      ~serializeOperationBuilder=struct.serializeOperationBuilder,
      ~metadataMap=struct.metadataMap,
      (),
    )
  | _ =>
    make(
      ~name=struct.name,
      ~tagged=struct.tagged,
      ~parseOperationBuilder=(. b, ~selfStruct, ~inputVar, ~pathVar) => {
        switch maybeParser {
        | Some(parser) =>
          switch parser->TransformationFactory.call(
            ~struct=selfStruct->castUnknownStructToAnyStruct,
          ) {
          | Noop => b->B.compileParser(~struct, ~inputVar, ~pathVar)
          | Sync(syncTransformation) => {
              let parseResultVar = b->B.var
              let {code, outputVar, isAsync} =
                b->B.compileParser(~struct, ~inputVar=parseResultVar, ~pathVar)
              {
                code: `${b->B.syncTransform(
                    ~inputVar,
                    ~outputVar=parseResultVar,
                    ~isAsyncInput=false,
                    ~fn=syncTransformation,
                    ~prependPathVar=pathVar,
                    (),
                  )}${code}`,
                outputVar,
                isAsync,
              }
            }
          | Async(asyncTransformation) => {
              let parseResultVar = b->B.var
              let {code, outputVar: structOuputVar, isAsync: isAsyncStruct} =
                b->B.compileParser(~struct, ~inputVar="t", ~pathVar)
              let outputVar = b->B.var
              {
                code: `${b->B.asyncTransform(
                    ~inputVar,
                    ~outputVar=parseResultVar,
                    ~isAsyncInput=false,
                    ~fn=asyncTransformation,
                    ~prependPathVar=pathVar,
                    (),
                  )}${outputVar}=()=>${parseResultVar}().then(t=>{${code}return ${isAsyncStruct
                    ? `${structOuputVar}()`
                    : structOuputVar}});`,
                outputVar,
                isAsync: true,
              }
            }
          }
        | None => {
            code: b->B.raise(~pathVar, MissingParser) ++ ";",
            outputVar: inputVar,
            isAsync: false,
          }
        }
      },
      ~serializeOperationBuilder=(. b, ~selfStruct, ~inputVar, ~pathVar) => {
        switch maybeSerializer {
        | Some(serializer) =>
          switch serializer->TransformationFactory.call(
            ~struct=selfStruct->castUnknownStructToAnyStruct,
          ) {
          | Noop => struct.serializeOperationBuilder(. b, ~selfStruct=struct, ~inputVar, ~pathVar)
          | Sync(fn) => {
              let {code, outputVar: structOuputVar} = struct.serializeOperationBuilder(.
                b,
                ~selfStruct=struct,
                ~inputVar,
                ~pathVar,
              )
              let outputVar = b->B.var
              {
                code: `${code}${b->B.syncTransform(
                    ~inputVar=structOuputVar,
                    ~outputVar,
                    ~isAsyncInput=false,
                    ~fn,
                    ~prependPathVar=pathVar,
                    (),
                  )}`,
                outputVar,
                isAsync: false,
              }
            }
          | Async(_) => {
              code: b->B.raise(~pathVar, MissingSerializer) ++ ";",
              outputVar: inputVar,
              isAsync: false,
            }
          }
        | None => {
            code: b->B.raise(~pathVar, MissingSerializer) ++ ";",
            outputVar: inputVar,
            isAsync: false,
          }
        }
      },
      ~metadataMap=struct.metadataMap,
      (),
    )
  }
}

let custom = (
  ~name,
  ~parser as maybeParser=?,
  ~asyncParser as maybeAsyncParser=?,
  ~serializer as maybeSerializer=?,
  (),
) => {
  if maybeParser === None && maybeAsyncParser === None && maybeSerializer === None {
    Error.MissingParserAndSerializer.panic(`Custom struct factory`)
  }

  make(
    ~name,
    ~metadataMap=emptyMetadataMap,
    ~tagged=Unknown,
    ~parseOperationBuilder=switch (maybeParser, maybeAsyncParser) {
    | (Some(_), Some(_)) =>
      Error.panic(
        "The S.custom doesn't support the `parser` and `asyncParser` arguments simultaneously. Keep only `asyncParser`.",
      )
    | (Some(parser), None) =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        b->B.syncOperation(
          ~inputVar,
          ~fn=parser->(Obj.magic: (unknown => 'value) => (. unknown) => unknown),
          ~prependPathVar=pathVar,
        )
      }
    | (None, Some(asyncParser)) =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        b->B.asyncOperation(
          ~inputVar,
          ~fn=(. unknown) => (. ()) =>
            (
              asyncParser->(
                Obj.magic: (unknown => promise<'value>) => (. unknown) => promise<unknown>
              )
            )(. unknown),
          ~prependPathVar=pathVar,
        )
      }
    | (None, None) =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        code: b->B.raise(~pathVar, MissingParser) ++ ";",
        outputVar: inputVar,
        isAsync: false,
      }
    },
    ~serializeOperationBuilder=switch maybeSerializer {
    | Some(serializer) =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        b->B.syncOperation(
          ~inputVar,
          ~fn=serializer->(Obj.magic: ('value => 'any) => (. unknown) => unknown),
          ~prependPathVar=pathVar,
        )
      }
    | None =>
      (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        code: b->B.raise(~pathVar, MissingSerializer) ++ ";",
        outputVar: inputVar,
        isAsync: false,
      }
    },
    (),
  )
}

let rec internalToInlinedValue = struct => {
  switch struct->classify {
  | Literal(String(string)) => string->Stdlib.Inlined.Value.fromString
  | Literal(Int(int)) => int->Js.Int.toString
  | Literal(Float(float)) => float->Js.Float.toString
  | Literal(Bool(bool)) => bool->Stdlib.Bool.toString
  | Literal(EmptyOption) => "undefined"
  | Literal(EmptyNull) => "null"
  | Literal(NaN) => "NaN"
  | Union(unionStructs) => unionStructs->Js.Array2.unsafe_get(0)->internalToInlinedValue
  | Tuple(tupleStructs) =>
    `[${tupleStructs->Js.Array2.map(internalToInlinedValue)->Js.Array2.joinWith(",")}]`
  | Object({fieldNames, fields}) =>
    `{${fieldNames
      ->Js.Array2.map(fieldName => {
        `${fieldName->Stdlib.Inlined.Value.fromString}:${fields
          ->Js.Dict.unsafeGet(fieldName)
          ->internalToInlinedValue}`
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
  | JSON
  | Array(_)
  | Dict(_) =>
    Stdlib.Exn.raiseEmpty()
  }
}

module Variant = {
  module ConstantDefinition = {
    type t = {@as("v") value: unknown, @as("p") path: Path.t}
  }

  module DefinerCtx = {
    type t = {
      @as("a")
      mutable valuePath: Path.t,
      @as("r")
      mutable isValueRegistered: bool,
      @as("c")
      constantDefinitions: array<ConstantDefinition.t>,
    }

    @inline
    let make = () => {
      valuePath: Path.empty,
      isValueRegistered: false,
      constantDefinitions: [],
    }
  }

  let rec analyzeDefinition = (definition, ~definerCtx: DefinerCtx.t, ~path) => {
    if (
      // Use the definerCtx as a value placeholder
      definition->(Obj.magic: unknown => DefinerCtx.t) === definerCtx
    ) {
      if definerCtx.isValueRegistered {
        Error.panic(`The variant's value is registered multiple times. If you want to duplicate it, use S.transform instead.`)
      } else {
        definerCtx.valuePath = path
        definerCtx.isValueRegistered = true
      }
    } else if definition->Js.typeof === "object" && definition !== %raw(`null`) {
      let definition: Js.Dict.t<unknown> = definition->Obj.magic
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

  let factory = {
    (struct, definer) => {
      let struct = struct->toUnknown
      let instructions = {
        let definerCtx = DefinerCtx.make()
        let definition = definer->Stdlib.Fn.call1(definerCtx->Obj.magic)->castAnyToUnknown
        definition->analyzeDefinition(~definerCtx, ~path=Path.empty)
        definerCtx
      }

      make(
        ~name=struct.name,
        ~tagged=struct.tagged,
        ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
          let {isAsync, code, outputVar: structOutputVar} =
            b->B.compileParser(~struct, ~inputVar, ~pathVar)
          let outputVar = b->B.var
          {
            code: code ++
            b->B.syncTransform(
              ~inputVar=structOutputVar,
              ~outputVar,
              ~isAsyncInput=isAsync,
              ~fn=definer,
              (),
            ),
            outputVar,
            isAsync,
          }
        },
        ~serializeOperationBuilder=(. b, ~selfStruct, ~inputVar, ~pathVar) => {
          let {constantDefinitions, isValueRegistered, valuePath} = instructions
          let childStructInputVar = b->B.var
          let {code: childCode, outputVar} = struct.serializeOperationBuilder(.
            b,
            ~selfStruct=struct,
            ~inputVar=childStructInputVar,
            ~pathVar,
          )

          let codeRef = ref("")
          for idx in 0 to constantDefinitions->Js.Array2.length - 1 {
            let {path, value} = constantDefinitions->Js.Array2.unsafe_get(idx)
            codeRef.contents =
              codeRef.contents ++
              `if(${inputVar}${path}!==${b->B.embed(value)}){${b->B.raiseWithArg(
                  ~pathVar=`${pathVar}+${path->Stdlib.Inlined.Value.fromString}`,
                  (. input) => UnexpectedValue({
                    expected: value->Stdlib.Inlined.Value.stringify,
                    received: input->Stdlib.Inlined.Value.stringify,
                  }),
                  `${inputVar}${path}`,
                )}}`
          }

          {
            code: codeRef.contents ++
            switch isValueRegistered {
            | true => `${childStructInputVar}=${inputVar}${valuePath}`
            | false =>
              try {
                let inlinedValue = selfStruct->internalToInlinedValue
                `${childStructInputVar}=${inlinedValue}`
              } catch {
              | _ => b->B.raise(~pathVar, MissingSerializer)
              }
            } ++
            ";" ++
            childCode,
            outputVar,
            isAsync: false,
          }
        },
        ~metadataMap=struct.metadataMap,
        (),
      )
    }
  }
}

module Literal = {
  module Variant = {
    let factory:
      type literalValue variant. (literal<literalValue>, variant) => t<variant> =
      (innerLiteral, variant) => {
        let tagged = Literal(innerLiteral->castToTaggedLiteral)

        let makeSerializeOperationBuilder = output => (.
          b,
          ~selfStruct as _,
          ~inputVar,
          ~pathVar,
        ) => {
          let outputVar = b->B.var
          {
            code: `if(${inputVar}!==${b->B.embed(variant)}){${b->B.raiseWithArg(
                ~pathVar,
                (. input) => UnexpectedValue({
                  expected: variant->Stdlib.Inlined.Value.stringify,
                  received: input->Stdlib.Inlined.Value.stringify,
                }),
                inputVar,
              )}}${outputVar}=${b->B.embed(output)};`,
            isAsync: false,
            outputVar,
          }
        }

        switch innerLiteral {
        | EmptyNull =>
          make(
            ~name="EmptyNull Literal (null)",
            ~metadataMap=emptyMetadataMap,
            ~tagged,
            ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
              let outputVar = b->B.var
              {
                code: `if(${inputVar}!==null){${b->B.raiseWithArg(
                    ~pathVar,
                    (. input) => UnexpectedType({
                      expected: "EmptyNull Literal (null)",
                      received: input->Stdlib.Unknown.toName,
                    }),
                    inputVar,
                  )}}${outputVar}=${b->B.embed(variant)};`,
                isAsync: false,
                outputVar,
              }
            },
            ~serializeOperationBuilder=makeSerializeOperationBuilder(Js.Null.empty),
            (),
          )
        | EmptyOption =>
          make(
            ~name="EmptyOption Literal (undefined)",
            ~metadataMap=emptyMetadataMap,
            ~tagged,
            ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
              let outputVar = b->B.var
              {
                code: `if(${inputVar}!==undefined){${b->B.raiseWithArg(
                    ~pathVar,
                    (. input) => UnexpectedType({
                      expected: "EmptyOption Literal (undefined)",
                      received: input->Stdlib.Unknown.toName,
                    }),
                    inputVar,
                  )}}${outputVar}=${b->B.embed(variant)};`,
                isAsync: false,
                outputVar,
              }
            },
            ~serializeOperationBuilder=makeSerializeOperationBuilder(Js.Undefined.empty),
            (),
          )
        | NaN =>
          make(
            ~name="NaN Literal (NaN)",
            ~metadataMap=emptyMetadataMap,
            ~tagged,
            ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
              let outputVar = b->B.var
              {
                code: `if(!Number.isNaN(${inputVar})){${b->B.raiseWithArg(
                    ~pathVar,
                    (. input) => UnexpectedType({
                      expected: "NaN Literal (NaN)",
                      received: input->Stdlib.Unknown.toName,
                    }),
                    inputVar,
                  )}}${outputVar}=${b->B.embed(variant)};`,
                isAsync: false,
                outputVar,
              }
            },
            ~serializeOperationBuilder=makeSerializeOperationBuilder(Js.Float._NaN),
            (),
          )
        | Bool(bool) =>
          make(
            ~name=`Bool Literal (${bool->Stdlib.Bool.toString})`,
            ~metadataMap=emptyMetadataMap,
            ~tagged,
            ~parseOperationBuilder=(. b, ~selfStruct, ~inputVar, ~pathVar) => {
              let outputVar = b->B.var
              {
                code: `if(typeof ${inputVar}!=="boolean"){${b->B.raiseWithArg(
                    ~pathVar,
                    (. input) => UnexpectedType({
                      expected: selfStruct.name,
                      received: input->Stdlib.Unknown.toName,
                    }),
                    inputVar,
                  )}}if(${inputVar}!==${bool->Stdlib.Bool.toString}){${b->B.raiseWithArg(
                    ~pathVar,
                    (. input) => UnexpectedValue({
                      expected: bool->Stdlib.Bool.toString,
                      received: input->Stdlib.Inlined.Value.stringify,
                    }),
                    inputVar,
                  )}}${outputVar}=${b->B.embed(variant)};`,
                isAsync: false,
                outputVar,
              }
            },
            ~serializeOperationBuilder=makeSerializeOperationBuilder(bool),
            (),
          )
        | String(string) =>
          make(
            ~name=`String Literal ("${string}")`,
            ~metadataMap=emptyMetadataMap,
            ~tagged,
            ~parseOperationBuilder=(. b, ~selfStruct, ~inputVar, ~pathVar) => {
              let outputVar = b->B.var
              {
                code: `if(typeof ${inputVar}!=="string"){${b->B.raiseWithArg(
                    ~pathVar,
                    (. input) => UnexpectedType({
                      expected: selfStruct.name,
                      received: input->Stdlib.Unknown.toName,
                    }),
                    inputVar,
                  )}}if(${inputVar}!==${string->Stdlib.Inlined.Value.fromString}){${b->B.raiseWithArg(
                    ~pathVar,
                    (. input) => UnexpectedValue({
                      expected: string->Stdlib.Inlined.Value.fromString,
                      received: input->Stdlib.Inlined.Value.stringify,
                    }),
                    inputVar,
                  )}}${outputVar}=${b->B.embed(variant)};`,
                isAsync: false,
                outputVar,
              }
            },
            ~serializeOperationBuilder=makeSerializeOperationBuilder(string),
            (),
          )
        | Float(float) =>
          make(
            ~name=`Float Literal (${float->Js.Float.toString})`,
            ~metadataMap=emptyMetadataMap,
            ~tagged,
            ~parseOperationBuilder=(. b, ~selfStruct, ~inputVar, ~pathVar) => {
              let outputVar = b->B.var
              {
                code: `if(typeof ${inputVar}!=="number"){${b->B.raiseWithArg(
                    ~pathVar,
                    (. input) => UnexpectedType({
                      expected: selfStruct.name,
                      received: input->Stdlib.Unknown.toName,
                    }),
                    inputVar,
                  )}}if(${inputVar}!==${float->Js.Float.toString}){${b->B.raiseWithArg(
                    ~pathVar,
                    (. input) => UnexpectedValue({
                      expected: float->Js.Float.toString,
                      received: input->Stdlib.Inlined.Value.stringify,
                    }),
                    inputVar,
                  )}}${outputVar}=${b->B.embed(variant)};`,
                isAsync: false,
                outputVar,
              }
            },
            ~serializeOperationBuilder=makeSerializeOperationBuilder(float),
            (),
          )
        | Int(int) =>
          make(
            ~name=`Int Literal (${int->Stdlib.Int.unsafeToString})`,
            ~metadataMap=emptyMetadataMap,
            ~tagged,
            ~parseOperationBuilder=(. b, ~selfStruct, ~inputVar, ~pathVar) => {
              let outputVar = b->B.var
              {
                code: `if(!(typeof ${inputVar}==="number"&&${inputVar}<2147483648&&${inputVar}>-2147483649&&${inputVar}%1===0)){${b->B.raiseWithArg(
                    ~pathVar,
                    (. input) => UnexpectedType({
                      expected: selfStruct.name,
                      received: input->Stdlib.Unknown.toName,
                    }),
                    inputVar,
                  )}}if(${inputVar}!==${int->Stdlib.Int.unsafeToString}){${b->B.raiseWithArg(
                    ~pathVar,
                    (. input) => UnexpectedValue({
                      expected: int->Js.Int.toString,
                      received: input->Stdlib.Inlined.Value.stringify,
                    }),
                    inputVar,
                  )}}${outputVar}=${b->B.embed(variant)};`,
                isAsync: false,
                outputVar,
              }
            },
            ~serializeOperationBuilder=makeSerializeOperationBuilder(int),
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
  type ctx = {@as("f") field: 'value. (. string, t<'value>) => 'value}

  module UnknownKeys = {
    type tagged =
      | Strict
      | Strip

    let metadataId: Metadata.Id.t<tagged> = Metadata.Id.make(
      ~namespace="rescript-struct",
      ~name="Object.UnknownKeys",
    )

    let classify = struct => {
      switch struct->Metadata.get(~id=metadataId) {
      | Some(t) => t
      | None => Strip
      }
    }
  }

  module FieldDefinition = {
    type t = {
      @as("s")
      fieldStruct: struct<unknown>,
      @as("i")
      inlinedFieldName: string,
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
    type t = {
      @as("n")
      fieldNames: array<string>,
      @as("h")
      fields: Js.Dict.t<struct<unknown>>,
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
      @as("f")
      field: 'value. (. string, t<'value>) => 'value,
    }

    external toPublic: t => ctx = "%identity"

    @inline
    let make = () => {
      let fields = Js.Dict.empty()
      let fieldNames = []
      let fieldDefinitions = []
      let fieldDefinitionsSet = Stdlib.Set.empty()

      let field:
        type value. (. string, struct<value>) => value =
        (. fieldName, struct) => {
          let struct = struct->toUnknown
          switch fields->Stdlib.Dict.has(fieldName) {
          | true =>
            Error.panic(
              `The field "${fieldName}" is defined multiple times. If you want to duplicate a field, use S.transform instead.`,
            )
          | false => {
              let fieldDefinition: FieldDefinition.t = {
                fieldStruct: struct,
                inlinedFieldName: fieldName->Stdlib.Inlined.Value.fromString,
                path: Path.empty,
                isRegistered: false,
              }
              fields->Js.Dict.set(fieldName, struct)
              fieldNames->Js.Array2.push(fieldName)->ignore
              fieldDefinitions->Js.Array2.push(fieldDefinition)->ignore
              fieldDefinitionsSet->Stdlib.Set.add(fieldDefinition)->ignore
              fieldDefinition->(Obj.magic: FieldDefinition.t => value)
            }
          }
        }

      {
        fieldNames,
        fields,
        field,
        fieldDefinitions,
        preparationPathes: [],
        inlinedPreparationValues: [],
        constantDefinitions: [],
        fieldDefinitionsSet,
      }
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
          `The field ${fieldDefinition.inlinedFieldName} is registered multiple times. If you want to duplicate a field, use S.transform instead.`,
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

  let factory = definer => {
    let instructions = {
      let definerCtx = DefinerCtx.make()
      let definition = definer->Stdlib.Fn.call1(definerCtx->DefinerCtx.toPublic)->castAnyToUnknown
      definition->analyzeDefinition(~definerCtx, ~path=Path.empty)
      definerCtx
    }

    make(
      ~name="Object",
      ~metadataMap=emptyMetadataMap,
      ~tagged=Object({
        fields: instructions.fields,
        fieldNames: instructions.fieldNames,
      }),
      ~parseOperationBuilder=(. b, ~selfStruct, ~inputVar, ~pathVar) => {
        let {
          preparationPathes,
          inlinedPreparationValues,
          fieldDefinitions,
          constantDefinitions,
        } = instructions

        let asyncFieldVars = []

        // TODO: Test that it's fine with having it as a var instead of let
        let syncOutputVar = b->B.var
        let codeRef = ref(
          `if(!(typeof ${inputVar}==="object"&&${inputVar}!==null&&!Array.isArray(${inputVar}))){${b->B.raiseWithArg(
              ~pathVar,
              (. input) => UnexpectedType({
                expected: "Object",
                received: input->Stdlib.Unknown.toName,
              }),
              inputVar,
            )}}`,
        )

        for idx in 0 to preparationPathes->Js.Array2.length - 1 {
          let preparationPath = preparationPathes->Js.Array2.unsafe_get(idx)
          let preparationInlinedValue = inlinedPreparationValues->Js.Array2.unsafe_get(idx)
          codeRef.contents =
            codeRef.contents ++ `${syncOutputVar}${preparationPath}=${preparationInlinedValue};`
        }

        for idx in 0 to fieldDefinitions->Js.Array2.length - 1 {
          let fieldDefinition = fieldDefinitions->Js.Array2.unsafe_get(idx)
          let {fieldStruct, inlinedFieldName, isRegistered, path} = fieldDefinition

          let {code: fieldCode, outputVar: fieldOuputVar, isAsync: isAsyncField} =
            b->B.compileParser(
              ~struct=fieldStruct,
              ~inputVar=`${inputVar}[${inlinedFieldName}]`,
              ~pathVar=`${pathVar}+'['+${inlinedFieldName->Stdlib.Inlined.Value.fromString}+']'`,
            )

          codeRef.contents =
            codeRef.contents ++
            fieldCode ++ (isRegistered ? `${syncOutputVar}${path}=${fieldOuputVar};` : "")
          if isAsyncField {
            asyncFieldVars
            ->Js.Array2.push(isRegistered ? `${syncOutputVar}${path}` : fieldOuputVar)
            ->ignore
          }
        }

        let withUnknownKeysRefinement = selfStruct->UnknownKeys.classify === UnknownKeys.Strict
        switch (withUnknownKeysRefinement, fieldDefinitions) {
        | (true, []) => {
            let keyVar = b->B.var
            codeRef.contents =
              codeRef.contents ++
              `for(${keyVar} in ${inputVar}){${b->B.raiseWithArg(
                  ~pathVar,
                  (. exccessFieldName) => ExcessField(exccessFieldName),
                  keyVar,
                )}}`
          }
        | (true, _) => {
            let keyVar = b->B.var
            codeRef.contents = codeRef.contents ++ `for(${keyVar} in ${inputVar}){if(!(`
            for idx in 0 to fieldDefinitions->Js.Array2.length - 1 {
              let fieldDefinition = fieldDefinitions->Js.Array2.unsafe_get(idx)
              if idx !== 0 {
                codeRef.contents = codeRef.contents ++ "||"
              }
              codeRef.contents =
                codeRef.contents ++ `${keyVar}===${fieldDefinition.inlinedFieldName}`
            }
            codeRef.contents =
              codeRef.contents ++
              `)){${b->B.raiseWithArg(
                  ~pathVar,
                  (. exccessFieldName) => ExcessField(exccessFieldName),
                  keyVar,
                )}}}`
          }

        | _ => ()
        }

        for idx in 0 to constantDefinitions->Js.Array2.length - 1 {
          let {path, value} = constantDefinitions->Js.Array2.unsafe_get(idx)
          codeRef.contents = codeRef.contents ++ `${syncOutputVar}${path}=${b->B.embed(value)};`
        }

        if asyncFieldVars->Js.Array2.length === 0 {
          {
            code: codeRef.contents,
            outputVar: syncOutputVar,
            isAsync: false,
          }
        } else {
          let outputVar = b->B.var
          let resolveVar = b->B.varWithoutAllocation
          let rejectVar = b->B.varWithoutAllocation
          let asyncParseResultVar = b->B.varWithoutAllocation
          let counterVar = b->B.varWithoutAllocation

          {
            code: `${codeRef.contents}${outputVar}=()=>new Promise((${resolveVar},${rejectVar})=>{let ${counterVar}=${asyncFieldVars
              ->Js.Array2.length
              ->Js.Int.toString};${asyncFieldVars
              ->Js.Array2.map(asyncFieldVar => {
                `${asyncFieldVar}().then(${asyncParseResultVar}=>{${asyncFieldVar}=${asyncParseResultVar};if(${counterVar}--===1){${resolveVar}(${syncOutputVar})}},${rejectVar})`
              })
              ->Js.Array2.joinWith(";")}});`,
            outputVar,
            isAsync: true,
          }
        }
      },
      ~serializeOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let {fieldDefinitions, constantDefinitions} = instructions

        let outputVar = b->B.var
        let codeRef = ref("")

        for idx in 0 to constantDefinitions->Js.Array2.length - 1 {
          let {path, value} = constantDefinitions->Js.Array2.unsafe_get(idx)
          codeRef.contents =
            codeRef.contents ++
            `if(${inputVar}${path}!==${b->B.embed(value)}){${b->B.raiseWithArg(
                ~pathVar=`${pathVar}+${path->Stdlib.Inlined.Value.fromString}`,
                (. input) => UnexpectedValue({
                  expected: value->Stdlib.Inlined.Value.stringify,
                  received: input->Stdlib.Inlined.Value.stringify,
                }),
                `${inputVar}${path}`,
              )}}`
        }

        codeRef.contents = codeRef.contents ++ `${outputVar}={};`

        for idx in 0 to fieldDefinitions->Js.Array2.length - 1 {
          let fieldDefinition = fieldDefinitions->Js.Array2.unsafe_get(idx)
          let {fieldStruct, inlinedFieldName, isRegistered, path} = fieldDefinition
          let fieldPathVar = `${pathVar}+${path->Stdlib.Inlined.Value.fromString}`
          let destinationVar = `${outputVar}[${inlinedFieldName}]`

          codeRef.contents =
            codeRef.contents ++
            switch isRegistered {
            | true => {
                let {
                  outputVar: fieldOuputVar,
                  code: fieldCode,
                } = fieldStruct.serializeOperationBuilder(.
                  b,
                  ~selfStruct=fieldStruct,
                  ~inputVar=destinationVar,
                  ~pathVar=fieldPathVar,
                )
                `${destinationVar}=${inputVar}${path};` ++
                fieldCode ++ (
                  destinationVar === fieldOuputVar ? "" : `${destinationVar}=${fieldOuputVar};`
                )
              }

            | false =>
              try {
                let inlinedValue = fieldStruct->internalToInlinedValue
                `${destinationVar}=${inlinedValue};`
              } catch {
              | _ => b->B.raise(~pathVar=fieldPathVar, MissingSerializer) ++ ";"
              }
            }
        }

        {code: codeRef.contents, isAsync: false, outputVar}
      },
      (),
    )
  }

  let strip = struct => {
    struct->Metadata.set(~id=UnknownKeys.metadataId, ~metadata=UnknownKeys.Strip)
  }

  let strict = struct => {
    struct->Metadata.set(~id=UnknownKeys.metadataId, ~metadata=UnknownKeys.Strict)
  }
}

module Never = {
  let operationBuilder = (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
    {
      code: b->B.raiseWithArg(
        ~pathVar,
        (. input) => UnexpectedType({
          expected: "Never",
          received: input->Stdlib.Unknown.toName,
        }),
        inputVar,
      ) ++ ";",
      isAsync: false,
      outputVar: inputVar,
    }
  }

  let struct = make(
    ~name=`Never`,
    ~metadataMap=emptyMetadataMap,
    ~tagged=Never,
    ~parseOperationBuilder=operationBuilder,
    ~serializeOperationBuilder=operationBuilder,
    (),
  )
}

module Unknown = {
  let struct = make(
    ~name=`Unknown`,
    ~metadataMap=emptyMetadataMap,
    ~tagged=Unknown,
    ~parseOperationBuilder=Builder.noop,
    ~serializeOperationBuilder=Builder.noop,
    (),
  )
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
      | Datetime
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
  // Adapted from https://stackoverflow.com/a/46181/1550155
  let emailRegex = %re(`/^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[(((25[0-5])|(2[0-4][0-9])|(1[0-9]{2})|([0-9]{1,2}))\.){3}((25[0-5])|(2[0-4][0-9])|(1[0-9]{2})|([0-9]{1,2}))\])|(\[IPv6:(([a-f0-9]{1,4}:){7}|::([a-f0-9]{1,4}:){0,6}|([a-f0-9]{1,4}:){1}:([a-f0-9]{1,4}:){0,5}|([a-f0-9]{1,4}:){2}:([a-f0-9]{1,4}:){0,4}|([a-f0-9]{1,4}:){3}:([a-f0-9]{1,4}:){0,3}|([a-f0-9]{1,4}:){4}:([a-f0-9]{1,4}:){0,2}|([a-f0-9]{1,4}:){5}:([a-f0-9]{1,4}:){0,1})([a-f0-9]{1,4}|(((25[0-5])|(2[0-4][0-9])|(1[0-9]{2})|([0-9]{1,2}))\.){3}((25[0-5])|(2[0-4][0-9])|(1[0-9]{2})|([0-9]{1,2})))\])|([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])*(\.[A-Za-z]{2,})+))$/`)
  // Adapted from https://stackoverflow.com/a/3143231
  let datetimeRe = %re(`/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$/`)

  let parseOperationBuilder = (. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
    {
      code: `if(typeof ${inputVar}!=="string"){${b->B.raiseWithArg(
          ~pathVar,
          (. input) => UnexpectedType({
            expected: "String",
            received: input->Stdlib.Unknown.toName,
          }),
          inputVar,
        )}}`,
      isAsync: false,
      outputVar: inputVar,
    }
  }

  let struct = make(
    ~name="String",
    ~metadataMap=emptyMetadataMap,
    ~tagged=String,
    ~parseOperationBuilder,
    ~serializeOperationBuilder=Builder.noop,
    (),
  )

  let min = (struct, ~message as maybeMessage=?, length) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `String must be ${length->Js.Int.toString} or more characters long`
    }
    let refiner = value =>
      if value->Js.String2.length < length {
        fail(message)
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
        fail(message)
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
        fail(message)
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
        fail(message)
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
        fail(message)
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
        fail(message)
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
        fail(message)
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
        fail(message)
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

  let datetime = (struct, ~message=`Invalid datetime string! Must be UTC`, ()) => {
    let refinement = {
      Refinement.kind: Datetime,
      message,
    }
    struct
    ->Metadata.set(
      ~id=Refinement.metadataId,
      ~metadata={
        switch struct->Metadata.get(~id=Refinement.metadataId) {
        | Some(refinements) => refinements->Stdlib.Array.append(refinement)
        | None => [refinement]
        }
      },
    )
    ->transform(
      ~parser=string => {
        if datetimeRe->Js.Re.test_(string)->not {
          fail(message)
        }
        Js.Date.fromString(string)
      },
      ~serializer=date => date->Js.Date.toISOString,
      (),
    )
  }

  let trim = (struct, ()) => {
    let transformer = string => string->Js.String2.trim
    struct->transform(~parser=transformer, ~serializer=transformer, ())
  }
}

module JsonString = {
  let factory = childStruct => {
    let childStruct = childStruct->toUnknown
    make(
      ~name=`JsonString`,
      ~metadataMap=emptyMetadataMap,
      ~tagged=String,
      ~parseOperationBuilder=(. b, ~selfStruct, ~inputVar, ~pathVar) => {
        let {code: stringParserCode, outputVar: jsonStringVar} =
          b->String.parseOperationBuilder(~selfStruct, ~inputVar, ~pathVar)
        let jsonVar = b->B.var
        let {code: childCode, isAsync, outputVar} =
          b->B.compileParser(~struct=childStruct, ~inputVar=jsonVar, ~pathVar)

        {
          code: `${stringParserCode}try{${jsonVar}=JSON.parse(${jsonStringVar})}catch(t){${b->B.raiseWithArg(
              ~pathVar,
              (. message) => OperationFailed(message),
              "t.message",
            )}}${childCode}`,
          isAsync,
          outputVar,
        }
      },
      ~serializeOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let outputVar = b->B.var
        let {code: childCode, outputVar: childOutputVar} =
          b->B.compileParser(~struct=childStruct, ~inputVar, ~pathVar)

        {
          code: `${childCode}${outputVar}=JSON.stringify(${childOutputVar});`,
          isAsync: false,
          outputVar,
        }
      },
      (),
    )
  }
}

module Bool = {
  let struct = make(
    ~name="Bool",
    ~metadataMap=emptyMetadataMap,
    ~tagged=Bool,
    ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
      {
        code: `if(typeof ${inputVar}!=="boolean"){${b->B.raiseWithArg(
            ~pathVar,
            (. input) => UnexpectedType({
              expected: "Bool",
              received: input->Stdlib.Unknown.toName,
            }),
            inputVar,
          )}}`,
        isAsync: false,
        outputVar: inputVar,
      }
    },
    ~serializeOperationBuilder=Builder.noop,
    (),
  )
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

  let struct = make(
    ~name="Int",
    ~metadataMap=emptyMetadataMap,
    ~tagged=Int,
    ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
      {
        code: `if(!(typeof ${inputVar}==="number"&&${inputVar}<2147483648&&${inputVar}>-2147483649&&${inputVar}%1===0)){${b->B.raiseWithArg(
            ~pathVar,
            (. input) => UnexpectedType({
              expected: "Int",
              received: input->Stdlib.Unknown.toName,
            }),
            inputVar,
          )}}`,
        isAsync: false,
        outputVar: inputVar,
      }
    },
    ~serializeOperationBuilder=Builder.noop,
    (),
  )

  let min = (struct, ~message as maybeMessage=?, minValue) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Number must be greater than or equal to ${minValue->Js.Int.toString}`
    }
    let refiner = value => {
      if value < minValue {
        fail(message)
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
        fail(message)
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
        fail(message)
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

  let struct = make(
    ~name="Float",
    ~metadataMap=emptyMetadataMap,
    ~tagged=Float,
    ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
      {
        code: `if(!(typeof ${inputVar}==="number"&&!Number.isNaN(${inputVar}))){${b->B.raiseWithArg(
            ~pathVar,
            (. input) => UnexpectedType({
              expected: "Float",
              received: input->Stdlib.Unknown.toName,
            }),
            inputVar,
          )}}`,
        isAsync: false,
        outputVar: inputVar,
      }
    },
    ~serializeOperationBuilder=Builder.noop,
    (),
  )

  let min = (struct, ~message as maybeMessage=?, minValue) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Number must be greater than or equal to ${minValue->Js.Float.toString}`
    }
    let refiner = value => {
      if value < minValue {
        fail(message)
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
        fail(message)
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
  let factory = childStruct => {
    let childStruct = childStruct->toUnknown
    make(
      ~name=`Null`,
      ~metadataMap=emptyMetadataMap,
      ~tagged=Null(childStruct),
      ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let {code: childCode, isAsync: isChildAsync, outputVar: childOutputVar} =
          b->B.compileParser(~struct=childStruct, ~inputVar, ~pathVar)
        let outputVar = b->B.var

        {
          code: `if(${inputVar}!==null){${childCode}${b->B.syncTransform(
              ~inputVar=childOutputVar,
              ~outputVar,
              ~isAsyncInput=isChildAsync,
              ~fn=%raw("Caml_option.some"),
              (),
            )}}else{${outputVar}=${switch isChildAsync {
            | false => `undefined`
            | true => `()=>Promise.resolve(undefined)`
            }}}`,
          isAsync: isChildAsync,
          outputVar,
        }
      },
      ~serializeOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let {
          code: childCode,
          isAsync: isChildAsync,
          outputVar: childOutputVar,
        } = childStruct.serializeOperationBuilder(. b, ~selfStruct=childStruct, ~inputVar, ~pathVar)
        let outputVar = b->B.var

        {
          code: `if(${inputVar}!==undefined){${inputVar}=${b->B.embed(
              %raw("Caml_option.valFromOption"),
            )}(${inputVar});${childCode}${outputVar}=${childOutputVar}}else{${outputVar}=null}`,
          isAsync: isChildAsync,
          outputVar,
        }
      },
      (),
    )
  }
}

module Option = {
  let factory = childStruct => {
    let childStruct = childStruct->toUnknown
    make(
      ~name=`Option`,
      ~metadataMap=emptyMetadataMap,
      ~tagged=Option(childStruct),
      ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let {code: childCode, isAsync: isChildAsync, outputVar: childOutputVar} =
          b->B.compileParser(~struct=childStruct, ~inputVar, ~pathVar)
        let outputVar = b->B.var

        {
          code: `if(${inputVar}!==undefined){${childCode}${b->B.syncTransform(
              ~inputVar=childOutputVar,
              ~outputVar,
              ~isAsyncInput=isChildAsync,
              ~fn=%raw("Caml_option.some"),
              (),
            )}}else{${outputVar}=${switch isChildAsync {
            | false => inputVar
            | true => `()=>Promise.resolve(${inputVar})`
            }}}`,
          isAsync: isChildAsync,
          outputVar,
        }
      },
      ~serializeOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let {
          code: childCode,
          isAsync: isChildAsync,
          outputVar: childOutputVar,
        } = childStruct.serializeOperationBuilder(. b, ~selfStruct=childStruct, ~inputVar, ~pathVar)
        let outputVar = b->B.var

        {
          code: `if(${inputVar}!==undefined){${inputVar}=${b->B.embed(
              %raw("Caml_option.valFromOption"),
            )}(${inputVar});${childCode}${outputVar}=${childOutputVar}}else{${outputVar}=undefined}`,
          isAsync: isChildAsync,
          outputVar,
        }
      },
      (),
    )
  }
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

  let factory = childStruct => {
    let childStruct = childStruct->toUnknown
    make(
      ~name=`Array`,
      ~metadataMap=emptyMetadataMap,
      ~tagged=Array(childStruct),
      ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let itemVar = b->B.varWithoutAllocation
        let iteratorVar = b->B.varWithoutAllocation
        let {code: childCode, isAsync: isChildAsync, outputVar: childOutputVar} =
          b->B.compileParser(
            ~struct=childStruct,
            ~inputVar=itemVar,
            ~pathVar=`${pathVar}+'["'+${iteratorVar}+'"]'`,
          )
        let syncOutputVar = b->B.varWithoutAllocation
        let syncCode = `if(!Array.isArray(${inputVar})){${b->B.raiseWithArg(
            ~pathVar,
            (. input) => UnexpectedType({
              expected: "Array",
              received: input->Stdlib.Unknown.toName,
            }),
            inputVar,
          )}}let ${syncOutputVar}=[];for(let ${iteratorVar}=0;${iteratorVar}<${inputVar}.length;++${iteratorVar}){let ${itemVar}=${inputVar}[${iteratorVar}];${childCode}${syncOutputVar}.push(${childOutputVar})}`

        if isChildAsync {
          let outputVar = b->B.var
          {
            code: syncCode ++ `${outputVar}=()=>Promise.all(${syncOutputVar}.map(t=>t()));`,
            isAsync: true,
            outputVar,
          }
        } else {
          {code: syncCode, isAsync: false, outputVar: syncOutputVar}
        }
      },
      ~serializeOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let itemVar = b->B.varWithoutAllocation
        let iteratorVar = b->B.varWithoutAllocation
        let {code: childCode, outputVar: childOutputVar} = childStruct.serializeOperationBuilder(.
          b,
          ~selfStruct=childStruct,
          ~inputVar=itemVar,
          ~pathVar=`${pathVar}+'["'+${iteratorVar}+'"]'`,
        )
        if childCode === "" {
          {code: "", outputVar: inputVar, isAsync: false}
        } else {
          let outputVar = b->B.varWithoutAllocation
          {
            code: `let ${outputVar}=[];for(let ${iteratorVar}=0;${iteratorVar}<${inputVar}.length;++${iteratorVar}){let ${itemVar}=${inputVar}[${iteratorVar}];${childCode}${outputVar}.push(${childOutputVar})}`,
            outputVar,
            isAsync: false,
          }
        }
      },
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
        fail(message)
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
        fail(message)
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
        fail(message)
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
  let factory = childStruct => {
    let childStruct = childStruct->toUnknown
    make(
      ~name=`Dict`,
      ~metadataMap=emptyMetadataMap,
      ~tagged=Dict(childStruct),
      ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let itemVar = b->B.varWithoutAllocation
        let keyVar = b->B.varWithoutAllocation
        let {code: childCode, isAsync: isChildAsync, outputVar: childOutputVar} =
          b->B.compileParser(
            ~struct=childStruct,
            ~inputVar=itemVar,
            ~pathVar=`${pathVar}+'["'+${keyVar}+'"]'`,
          )
        let syncOutputVar = b->B.varWithoutAllocation
        let syncCode = `if(!(typeof ${inputVar}==="object"&&${inputVar}!==null&&!Array.isArray(${inputVar}))){${b->B.raiseWithArg(
            ~pathVar,
            (. input) => UnexpectedType({
              expected: "Dict",
              received: input->Stdlib.Unknown.toName,
            }),
            inputVar,
          )}}let ${syncOutputVar}={};for(let ${keyVar} in ${inputVar}){let ${itemVar}=${inputVar}[${keyVar}];${childCode}${syncOutputVar}[${keyVar}]=${childOutputVar}}`

        if isChildAsync {
          let outputVar = b->B.var
          let resolveVar = b->B.varWithoutAllocation
          let rejectVar = b->B.varWithoutAllocation
          let asyncParseResultVar = b->B.varWithoutAllocation
          let counterVar = b->B.varWithoutAllocation
          {
            code: `${syncCode}${outputVar}=()=>new Promise((${resolveVar},${rejectVar})=>{let ${counterVar}=Object.keys(${syncOutputVar}).length;for(let ${keyVar} in ${syncOutputVar}){${syncOutputVar}[${keyVar}]().then(${asyncParseResultVar}=>{${syncOutputVar}[${keyVar}]=${asyncParseResultVar};if(${counterVar}--===1){${resolveVar}(${syncOutputVar})}},${rejectVar})}});`,
            outputVar,
            isAsync: true,
          }
        } else {
          {code: syncCode, isAsync: false, outputVar: syncOutputVar}
        }
      },
      ~serializeOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let itemVar = b->B.varWithoutAllocation
        let keyVar = b->B.varWithoutAllocation
        let {code: childCode, outputVar: childOutputVar} = childStruct.serializeOperationBuilder(.
          b,
          ~selfStruct=childStruct,
          ~inputVar=itemVar,
          ~pathVar=`${pathVar}+'["'+${keyVar}+'"]'`,
        )
        if childCode === "" {
          {code: "", outputVar: inputVar, isAsync: false}
        } else {
          let outputVar = b->B.varWithoutAllocation
          {
            code: `let ${outputVar}={};for(let ${keyVar} in ${inputVar}){let ${itemVar}=${inputVar}[${keyVar}];${childCode}${outputVar}[${keyVar}]=${childOutputVar}}`,
            outputVar,
            isAsync: false,
          }
        }
      },
      (),
    )
  }
}

module Default = {
  let metadataId = Metadata.Id.make(~namespace="rescript-struct", ~name="Default")

  let factory = (childStruct, getDefaultValue) => {
    let childStruct = childStruct->Option.factory->(Obj.magic: t<'value> => t<unknown>)
    let getDefaultValue = getDefaultValue->(Obj.magic: (unit => 'value) => (. unit) => unknown)
    make(
      ~name=childStruct.name,
      ~metadataMap=emptyMetadataMap,
      ~tagged=childStruct.tagged,
      ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let {code: childCode, isAsync: isChildAsync, outputVar: childOutputVar} =
          b->B.compileParser(~struct=childStruct, ~inputVar, ~pathVar)
        let outputVar = b->B.var
        let defaultValVar = `${b->B.embed(getDefaultValue)}()`

        {
          code: `if(${inputVar}!==undefined){${childCode}${b->B.syncTransform(
              ~inputVar=childOutputVar,
              ~outputVar,
              ~isAsyncInput=isChildAsync,
              ~fn=%raw("Caml_option.some"),
              (),
            )}}else{${outputVar}=${switch isChildAsync {
            | false => defaultValVar
            | true => `()=>Promise.resolve(${defaultValVar})`
            }}}`,
          isAsync: isChildAsync,
          outputVar,
        }
      },
      ~serializeOperationBuilder=childStruct.serializeOperationBuilder,
      (),
    )->Metadata.set(~id=metadataId, ~metadata=getDefaultValue)
  }

  let classify = struct =>
    switch struct->Metadata.get(~id=metadataId) {
    | Some(getDefaultValue) => Some(getDefaultValue(.))
    | None => None
    }
}

module Tuple = {
  let factory = structs => {
    let numberOfStructs = structs->Js.Array2.length
    make(
      ~name="Tuple",
      ~metadataMap=emptyMetadataMap,
      ~tagged=Tuple(structs),
      ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let codeRef = ref(
          `if(!Array.isArray(${inputVar})){${b->B.raiseWithArg(
              ~pathVar,
              (. input) => UnexpectedType({
                expected: "Tuple",
                received: input->Stdlib.Unknown.toName,
              }),
              inputVar,
            )}}if(${inputVar}.length!==${numberOfStructs->Stdlib.Int.unsafeToString}){${b->B.raiseWithArg(
              ~pathVar,
              (. numberOfInputItems) => TupleSize({
                expected: numberOfStructs,
                received: numberOfInputItems,
              }),
              `${inputVar}.length`,
            )}}`,
        )
        switch structs {
        | [] => {
            code: codeRef.contents,
            outputVar: "void 0",
            isAsync: false,
          }
        | [itemStruct] => {
            let {code: childCode, isAsync: isAsyncItem, outputVar: childOutputVar} =
              b->B.compileParser(
                ~struct=itemStruct,
                ~inputVar=`${inputVar}[0]`,
                ~pathVar=`${pathVar}+'["0"]'`,
              )
            {
              code: codeRef.contents ++ childCode,
              outputVar: childOutputVar,
              isAsync: isAsyncItem,
            }
          }
        | _ => {
            let asyncItemVars = []
            let syncOutputVar = b->B.varWithoutAllocation
            codeRef.contents = codeRef.contents ++ `let ${syncOutputVar}=[];`
            for idx in 0 to structs->Js.Array2.length - 1 {
              let itemStruct = structs->Js.Array2.unsafe_get(idx)
              let {code: childCode, isAsync: isAsyncItem, outputVar: childOutputVar} =
                b->B.compileParser(
                  ~struct=itemStruct,
                  ~inputVar=`${inputVar}[${idx->Stdlib.Int.unsafeToString}]`,
                  ~pathVar=`${pathVar}+'["${idx->Stdlib.Int.unsafeToString}"]'`,
                )
              let destVar = `${syncOutputVar}[${idx->Stdlib.Int.unsafeToString}]`
              codeRef.contents = codeRef.contents ++ `${childCode}${destVar}=${childOutputVar};`
              if isAsyncItem {
                asyncItemVars->Js.Array2.push(destVar)->ignore
              }
            }

            if asyncItemVars->Js.Array2.length === 0 {
              {
                code: codeRef.contents,
                outputVar: syncOutputVar,
                isAsync: false,
              }
            } else {
              let outputVar = b->B.var
              let resolveVar = b->B.varWithoutAllocation
              let rejectVar = b->B.varWithoutAllocation
              let asyncParseResultVar = b->B.varWithoutAllocation
              let counterVar = b->B.varWithoutAllocation

              {
                code: `${codeRef.contents}${outputVar}=()=>new Promise((${resolveVar},${rejectVar})=>{let ${counterVar}=${asyncItemVars
                  ->Js.Array2.length
                  ->Js.Int.toString};${asyncItemVars
                  ->Js.Array2.map(asyncItemVar => {
                    `${asyncItemVar}().then(${asyncParseResultVar}=>{${asyncItemVar}=${asyncParseResultVar};if(${counterVar}--===1){${resolveVar}(${syncOutputVar})}},${rejectVar})`
                  })
                  ->Js.Array2.joinWith(";")}});`,
                outputVar,
                isAsync: true,
              }
            }
          }
        }
      },
      ~serializeOperationBuilder=switch structs {
      | [] =>
        (. b, ~selfStruct as _, ~inputVar as _, ~pathVar as _) => {
          let outputVar = b->B.var
          {
            code: `${outputVar}=[];`,
            isAsync: false,
            outputVar,
          }
        }
      | [_] =>
        (. b, ~selfStruct as _, ~inputVar, ~pathVar as _) => {
          let outputVar = b->B.var
          {
            code: `${outputVar}=[${inputVar}];`,
            isAsync: false,
            outputVar,
          }
        }
      | _ => Builder.noop
      },
      (),
    )
  }

  let factoryFromArgs = (
    () => {
      let structs = Stdlib.Fn.getArguments()
      factory(structs)
    }
  )->Obj.magic
}

module Union = {
  let factory = structs => {
    let structs: array<t<unknown>> = structs->Obj.magic

    if structs->Js.Array2.length < 2 {
      Error.panic("A Union struct factory require at least two structs.")
    }

    make(
      ~name=`Union`,
      ~metadataMap=emptyMetadataMap,
      ~tagged=Union(structs),
      ~parseOperationBuilder=(. b, ~selfStruct, ~inputVar, ~pathVar) => {
        let structs = selfStruct->classify->unsafeGetVariantPayload

        let errorVars = []
        let asyncItems = Js.Dict.empty()
        let withAsyncItemRef = ref(false)
        let outputVar = b->B.var
        let codeRef = ref("")
        let codeEndRef = ref("")

        for idx in 0 to structs->Js.Array2.length - 1 {
          let itemStruct = structs->Js.Array2.unsafe_get(idx)
          let {code: childCode, isAsync: isAsyncItem, outputVar: childOutputVar} =
            b->B.compileParser(~struct=itemStruct, ~inputVar, ~pathVar=`""`)

          let errorVar = b->B.varWithoutAllocation
          errorVars->Js.Array2.push(errorVar)->ignore

          if isAsyncItem {
            withAsyncItemRef := true
            asyncItems->Js.Dict.set(idx->Stdlib.Int.unsafeToString, childOutputVar)
          }

          codeRef.contents =
            codeRef.contents ++
            `try{${childCode}${isAsyncItem
                ? `throw `
                : `${outputVar}=`}${childOutputVar}}catch(${errorVar}){if(${errorVar}&&${errorVar}.RE_EXN_ID==="S-RescriptStruct.Error.Internal.Exception/1"${isAsyncItem
                ? `||${errorVar}===${childOutputVar}`
                : ""}){`
          codeEndRef.contents = `}else{throw ${errorVar}}}` ++ codeEndRef.contents
        }

        if withAsyncItemRef.contents {
          let asyncOutputVar = b->B.var
          codeRef.contents = codeRef.contents ++ `${asyncOutputVar}=()=>Promise.any([`
          for idx in 0 to errorVars->Js.Array2.length - 1 {
            let errorVar = errorVars->Js.Array2.unsafe_get(idx)
            let maybeAsyncVar = asyncItems->Js.Dict.get(idx->Stdlib.Int.unsafeToString)
            if idx !== 0 {
              codeRef.contents = codeRef.contents ++ ","
            }
            switch maybeAsyncVar {
            | Some(asyncVar) =>
              codeRef.contents = codeRef.contents ++ `${errorVar}===${asyncVar}?${errorVar}():`
            | None => ()
            }
            codeRef.contents = codeRef.contents ++ `Promise.reject(${errorVar})`
          }
          codeRef.contents =
            codeRef.contents ++
            `]).catch(t=>{t=t.errors;${b->B.raiseWithArg(
                ~pathVar,
                (. internalErrors) => {
                  InvalidUnion(internalErrors->Js.Array2.map(Error.Internal.toParseError))
                },
                `[${errorVars
                  ->Js.Array2.mapi((_, idx) => `t[${idx->Stdlib.Int.unsafeToString}]._1`)
                  ->Js.Array2.joinWith(",")}]`,
              )}})`
          {
            outputVar: asyncOutputVar,
            isAsync: true,
            code: codeRef.contents ++
            codeEndRef.contents ++
            `if(!${asyncOutputVar}){${asyncOutputVar}=()=>Promise.resolve(${outputVar})}`,
          }
        } else {
          {
            outputVar,
            isAsync: false,
            code: codeRef.contents ++
            b->B.raiseWithArg(
              ~pathVar,
              (. internalErrors) => InvalidUnion(
                internalErrors->Js.Array2.map(Error.Internal.toParseError),
              ),
              `[${errorVars->Js.Array2.map(v => `${v}._1`)->Js.Array2.joinWith(",")}]`,
            ) ++
            codeEndRef.contents,
          }
        }
      },
      ~serializeOperationBuilder=(. b, ~selfStruct, ~inputVar, ~pathVar) => {
        let structs = selfStruct->classify->unsafeGetVariantPayload

        let errorVars = []
        let outputVar = b->B.var
        let codeRef = ref("")
        let codeEndRef = ref("")

        for idx in 0 to structs->Js.Array2.length - 1 {
          let itemStruct = structs->Js.Array2.unsafe_get(idx)
          let {code: childCode, outputVar: childOutputVar} = itemStruct.serializeOperationBuilder(.
            b,
            ~selfStruct=itemStruct,
            ~inputVar,
            ~pathVar=`""`,
          )
          let errorVar = b->B.varWithoutAllocation
          errorVars->Js.Array2.push(errorVar)->ignore

          codeRef.contents =
            codeRef.contents ++
            `try{${childCode}${outputVar}=${childOutputVar}}catch(${errorVar}){if(${errorVar}&&${errorVar}.RE_EXN_ID==="S-RescriptStruct.Error.Internal.Exception/1"){`
          codeEndRef.contents = `}else{throw ${errorVar}}}` ++ codeEndRef.contents
        }

        {
          outputVar,
          isAsync: false,
          code: codeRef.contents ++
          b->B.raiseWithArg(
            ~pathVar,
            (. internalErrors) => InvalidUnion(
              internalErrors->Js.Array2.map(Error.Internal.toSerializeError),
            ),
            `[${errorVars->Js.Array2.map(v => `${v}._1`)->Js.Array2.joinWith(",")}]`,
          ) ++
          codeEndRef.contents,
        }
      },
      (),
    )
  }
}

let list = childStruct => {
  childStruct
  ->Array.factory
  ->transform(
    ~parser=array => array->Belt.List.fromArray,
    ~serializer=list => list->Belt.List.toArray,
    (),
  )
}

let json = {
  let rec parse = (input, ~path) => {
    switch input->Js.typeof {
    | "number" if Js.Float.isNaN(input->(Obj.magic: unknown => float))->not =>
      input->(Obj.magic: unknown => Js.Json.t)

    | "object" =>
      if input === %raw("null") {
        input->(Obj.magic: unknown => Js.Json.t)
      } else if input->Js.Array2.isArray {
        let input = input->(Obj.magic: unknown => array<unknown>)
        let output = []
        for idx in 0 to input->Js.Array2.length - 1 {
          let inputItem = input->Js.Array2.unsafe_get(idx)
          output
          ->Js.Array2.push(
            inputItem->parse(~path=path->Path.concat(Path.fromLocation(idx->Js.Int.toString))),
          )
          ->ignore
        }
        output->Js.Json.array
      } else {
        let input = input->(Obj.magic: unknown => Js.Dict.t<unknown>)
        let keys = input->Js.Dict.keys
        let output = Js.Dict.empty()
        for idx in 0 to keys->Js.Array2.length - 1 {
          let key = keys->Js.Array2.unsafe_get(idx)
          let field = input->Js.Dict.unsafeGet(key)
          output->Js.Dict.set(key, field->parse(~path=path->Path.concat(Path.fromLocation(key))))
        }
        output->Js.Json.object_
      }

    | "string"
    | "boolean" =>
      input->(Obj.magic: unknown => Js.Json.t)

    | _ =>
      raise(
        Error.Internal.Exception({
          code: UnexpectedType({
            expected: "JSON",
            received: input->Stdlib.Unknown.toName,
          }),
          path,
        }),
      )
    }
  }

  make(
    ~name="JSON",
    ~tagged=JSON,
    ~metadataMap=emptyMetadataMap,
    ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
      {
        code: `${b->B.embed(parse)}(${inputVar},${pathVar});`,
        isAsync: false,
        outputVar: inputVar,
      }
    },
    ~serializeOperationBuilder=Builder.noop,
    (),
  )
}

type catchCtx = {
  error: Error.t,
  input: unknown,
}
let catch = (struct, getFallbackValue) => {
  let struct = struct->toUnknown
  make(
    ~name=struct.name,
    ~parseOperationBuilder=(. b, ~selfStruct as _, ~inputVar, ~pathVar) => {
      let {code: structCode, isAsync, outputVar: structOutputVar} =
        b->B.compileParser(~struct, ~inputVar, ~pathVar)
      let fallbackValVar = `${b->B.embed((input, internalError) =>
          getFallbackValue->Stdlib.Fn.call1({
            input,
            error: internalError->Error.Internal.toParseError,
          })
        )}(${inputVar},t._1)`

      if isAsync {
        let outputVar = b->B.var
        {
          code: `try{${structCode}${outputVar}=()=>{try{return ${structOutputVar}().catch(t=>{if(t&&t.RE_EXN_ID==="S-RescriptStruct.Error.Internal.Exception/1"){return ${fallbackValVar}}else{throw t}})}catch(t){if(t&&t.RE_EXN_ID==="S-RescriptStruct.Error.Internal.Exception/1"){return Promise.resolve(${fallbackValVar})}else{throw t}}}}catch(t){if(t&&t.RE_EXN_ID==="S-RescriptStruct.Error.Internal.Exception/1"){${outputVar}=()=>Promise.resolve(${fallbackValVar})}else{throw t}}`,
          isAsync: true,
          outputVar,
        }
      } else {
        {
          code: `try{${structCode}}catch(t){if(t&&t.RE_EXN_ID==="S-RescriptStruct.Error.Internal.Exception/1"){${structOutputVar}=${fallbackValVar}}else{throw t}}`,
          isAsync: false,
          outputVar: structOutputVar,
        }
      }
    },
    ~serializeOperationBuilder=struct.serializeOperationBuilder,
    ~tagged=struct.tagged,
    ~metadataMap=struct.metadataMap,
    (),
  )
}

let deprecationMetadataId: Metadata.Id.t<string> = Metadata.Id.make(
  ~namespace="rescript-struct",
  ~name="deprecation",
)

let deprecate = (struct, message) => {
  struct->Metadata.set(~id=deprecationMetadataId, ~metadata=message)
}

let deprecation = struct => struct->Metadata.get(~id=deprecationMetadataId)

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

let inline = {
  let rec toVariantName = struct => {
    switch struct->classify {
    | Literal(String(string)) => string
    | Literal(Int(int)) => int->Js.Int.toString
    | Literal(Float(float)) => float->Js.Float.toString
    | Literal(Bool(true)) => `True`
    | Literal(Bool(false)) => `False`
    | Literal(EmptyOption) => `EmptyOption`
    | Literal(EmptyNull) => `EmptyNull`
    | Literal(NaN) => `NaN`
    | Union(_) => `Union`
    | Tuple([]) => `EmptyTuple`
    | Tuple(_) => `Tuple`
    | Object({fieldNames: []}) => `EmptyObject`
    | Object(_) => `Object`
    | String => `String`
    | Int => `Int`
    | Float => `Float`
    | Bool => `Bool`
    | Never => `Never`
    | Unknown => `Unknown`
    | Option(s) => `OptionOf${s->toVariantName}`
    | Null(s) => `NullOf${s->toVariantName}`
    | Array(s) => `ArrayOf${s->toVariantName}`
    | Dict(s) => `DictOf${s->toVariantName}`
    | JSON => `JSON`
    }
  }

  let rec internalInline = (struct, ~variant as maybeVariant=?, ()) => {
    let metadataMap = struct.metadataMap->Stdlib.Dict.copy

    let inlinedStruct = switch struct->classify {
    | Literal(taggedLiteral) => {
        let inlinedLiteral = switch taggedLiteral {
        | String(string) => `String(${string->Stdlib.Inlined.Value.fromString})`
        | Int(int) => `Int(${int->Js.Int.toString})`
        | Float(float) => `Float(${float->Stdlib.Inlined.Float.toRescript})`
        | Bool(bool) => `Bool(${bool->Stdlib.Bool.toString})`
        | EmptyOption => `EmptyOption`
        | EmptyNull => `EmptyNull`
        | NaN => `NaN`
        }
        switch maybeVariant {
        | Some(variant) => `S.literalVariant(${inlinedLiteral}, ${variant})`
        | None => `S.literal(${inlinedLiteral})`
        }
      }

    | Union(unionStructs) => {
        let variantNamesCounter = Js.Dict.empty()
        `S.union([${unionStructs
          ->Js.Array2.map(s => {
            let variantName = s->toVariantName
            let numberOfVariantNames = switch variantNamesCounter->Js.Dict.get(variantName) {
            | Some(n) => n
            | None => 0
            }
            variantNamesCounter->Js.Dict.set(variantName, numberOfVariantNames->Stdlib.Int.plus(1))
            let variantName = switch numberOfVariantNames {
            | 0 => variantName
            | _ => variantName ++ numberOfVariantNames->Stdlib.Int.plus(1)->Js.Int.toString
            }
            let inlinedVariant = `#${variantName->Stdlib.Inlined.Value.fromString}`
            s->internalInline(~variant=inlinedVariant, ())
          })
          ->Js.Array2.joinWith(", ")}])`
      }
    | JSON => `S.json`

    | Tuple([]) => `S.tuple0(.)`
    | Tuple(tupleStructs) => {
        let numberOfItems = tupleStructs->Js.Array2.length
        if numberOfItems > 10 {
          Error.panic("The S.inline doesn't support tuples with more than 10 items.")
        }
        `S.tuple${numberOfItems->Js.Int.toString}(. ${tupleStructs
          ->Js.Array2.map(s => s->internalInline())
          ->Js.Array2.joinWith(", ")})`
      }
    | Object({fieldNames: []}) => `S.object(_ => ())`
    | Object({fieldNames, fields}) =>
      `S.object(o =>
  {
    ${fieldNames
        ->Js.Array2.map(fieldName => {
          `${fieldName->Stdlib.Inlined.Value.fromString}: o.field(${fieldName->Stdlib.Inlined.Value.fromString}, ${fields
            ->Js.Dict.unsafeGet(fieldName)
            ->internalInline()})`
        })
        ->Js.Array2.joinWith(",\n    ")},
  }
)`
    | String => `S.string`
    | Int => `S.int`
    | Float => `S.float`
    | Bool => `S.bool`
    | Option(childStruct) => {
        let internalInlinedStruct = childStruct->internalInline()
        switch struct->Default.classify {
        | Some(defaultValue) => {
            metadataMap->Stdlib.Dict.deleteInPlace(Default.metadataId->Metadata.Id.toKey)
            internalInlinedStruct ++
            `->S.default(() => %raw(\`${defaultValue->Stdlib.Inlined.Value.stringify}\`))`
          }

        | None => `S.option(${internalInlinedStruct})`
        }
      }
    | Null(childStruct) => `S.null(${childStruct->internalInline()})`
    | Never => `S.never`
    | Unknown => `S.unknown`
    | Array(childStruct) => `S.array(${childStruct->internalInline()})`
    | Dict(childStruct) => `S.dict(${childStruct->internalInline()})`
    }

    let inlinedStruct = switch struct->deprecation {
    | Some(message) => {
        metadataMap->Stdlib.Dict.deleteInPlace(deprecationMetadataId->Metadata.Id.toKey)
        inlinedStruct ++ `->S.deprecate(${message->Stdlib.Inlined.Value.fromString})`
      }

    | None => inlinedStruct
    }

    let inlinedStruct = switch struct->description {
    | Some(message) => {
        metadataMap->Stdlib.Dict.deleteInPlace(descriptionMetadataId->Metadata.Id.toKey)
        inlinedStruct ++ `->S.describe(${message->Stdlib.Inlined.Value.stringify})`
      }

    | None => inlinedStruct
    }

    let inlinedStruct = switch struct->Object.UnknownKeys.classify {
    | Strict => inlinedStruct ++ `->S.Object.strict`

    | Strip => inlinedStruct
    }
    metadataMap->Stdlib.Dict.deleteInPlace(Object.UnknownKeys.metadataId->Metadata.Id.toKey)

    let inlinedStruct = switch struct->classify {
    | String
    | Literal(String(_)) =>
      switch struct->String.refinements {
      | [] => inlinedStruct
      | refinements =>
        metadataMap->Stdlib.Dict.deleteInPlace(String.Refinement.metadataId->Metadata.Id.toKey)
        inlinedStruct ++
        refinements
        ->Js.Array2.map(refinement => {
          switch refinement {
          | {kind: Email, message} =>
            `->S.String.email(~message=${message->Stdlib.Inlined.Value.fromString}, ())`
          | {kind: Url, message} =>
            `->S.String.url(~message=${message->Stdlib.Inlined.Value.fromString}, ())`
          | {kind: Uuid, message} =>
            `->S.String.uuid(~message=${message->Stdlib.Inlined.Value.fromString}, ())`
          | {kind: Cuid, message} =>
            `->S.String.cuid(~message=${message->Stdlib.Inlined.Value.fromString}, ())`
          | {kind: Min({length}), message} =>
            `->S.String.min(~message=${message->Stdlib.Inlined.Value.fromString}, ${length->Js.Int.toString})`
          | {kind: Max({length}), message} =>
            `->S.String.max(~message=${message->Stdlib.Inlined.Value.fromString}, ${length->Js.Int.toString})`
          | {kind: Length({length}), message} =>
            `->S.String.length(~message=${message->Stdlib.Inlined.Value.fromString}, ${length->Js.Int.toString})`
          | {kind: Pattern({re}), message} =>
            `->S.String.pattern(~message=${message->Stdlib.Inlined.Value.fromString}, %re(${re
              ->Stdlib.Re.toString
              ->Stdlib.Inlined.Value.fromString}))`
          | {kind: Datetime, message} =>
            `->S.String.datetime(~message=${message->Stdlib.Inlined.Value.fromString}, ())`
          }
        })
        ->Js.Array2.joinWith("")
      }
    | Int
    | Literal(Int(_)) =>
      switch struct->Int.refinements {
      | [] => inlinedStruct
      | refinements =>
        metadataMap->Stdlib.Dict.deleteInPlace(Int.Refinement.metadataId->Metadata.Id.toKey)
        inlinedStruct ++
        refinements
        ->Js.Array2.map(refinement => {
          switch refinement {
          | {kind: Max({value}), message} =>
            `->S.Int.max(~message=${message->Stdlib.Inlined.Value.fromString}, ${value->Js.Int.toString})`
          | {kind: Min({value}), message} =>
            `->S.Int.min(~message=${message->Stdlib.Inlined.Value.fromString}, ${value->Js.Int.toString})`
          | {kind: Port, message} =>
            `->S.Int.port(~message=${message->Stdlib.Inlined.Value.fromString}, ())`
          }
        })
        ->Js.Array2.joinWith("")
      }
    | Float
    | Literal(Float(_)) =>
      switch struct->Float.refinements {
      | [] => inlinedStruct
      | refinements =>
        metadataMap->Stdlib.Dict.deleteInPlace(Float.Refinement.metadataId->Metadata.Id.toKey)
        inlinedStruct ++
        refinements
        ->Js.Array2.map(refinement => {
          switch refinement {
          | {kind: Max({value}), message} =>
            `->S.Float.max(~message=${message->Stdlib.Inlined.Value.fromString}, ${value->Stdlib.Inlined.Float.toRescript})`
          | {kind: Min({value}), message} =>
            `->S.Float.min(~message=${message->Stdlib.Inlined.Value.fromString}, ${value->Stdlib.Inlined.Float.toRescript})`
          }
        })
        ->Js.Array2.joinWith("")
      }

    | Array(_) =>
      switch struct->Array.refinements {
      | [] => inlinedStruct
      | refinements =>
        metadataMap->Stdlib.Dict.deleteInPlace(Array.Refinement.metadataId->Metadata.Id.toKey)
        inlinedStruct ++
        refinements
        ->Js.Array2.map(refinement => {
          switch refinement {
          | {kind: Max({length}), message} =>
            `->S.Array.max(~message=${message->Stdlib.Inlined.Value.fromString}, ${length->Js.Int.toString})`
          | {kind: Min({length}), message} =>
            `->S.Array.min(~message=${message->Stdlib.Inlined.Value.fromString}, ${length->Js.Int.toString})`
          | {kind: Length({length}), message} =>
            `->S.Array.length(~message=${message->Stdlib.Inlined.Value.fromString}, ${length->Js.Int.toString})`
          }
        })
        ->Js.Array2.joinWith("")
      }

    | _ => inlinedStruct
    }

    let inlinedStruct = if metadataMap->Js.Dict.keys->Js.Array2.length !== 0 {
      `{
  let s = ${inlinedStruct}
  let _ = %raw(\`s.m = ${metadataMap->Js.Json.stringifyAny->Belt.Option.getUnsafe}\`)
  s
}`
    } else {
      inlinedStruct
    }

    let inlinedStruct = switch (struct->classify, maybeVariant) {
    | (Literal(_), _) => inlinedStruct
    | (_, Some(variant)) => inlinedStruct ++ `->S.variant(v => ${variant}(v))`
    | _ => inlinedStruct
    }

    inlinedStruct
  }

  struct => {
    struct->toUnknown->internalInline()
  }
}

let object = Object.factory
let never = Never.struct
let unknown = Unknown.struct
let unit = Literal.factory(EmptyOption)
let string = String.struct
let bool = Bool.struct
let int = Int.struct
let float = Float.struct
let null = Null.factory
let option = Option.factory
let array = Array.factory
let dict = Dict.factory
let default = Default.factory
let variant = Variant.factory
let literal = Literal.factory
let literalVariant = Literal.Variant.factory
let tuple0 = (. ()) => Tuple.factory([])
let tuple1 = (. v0) => Tuple.factory([v0->toUnknown])
let tuple2 = (. v0, v1) => Tuple.factory([v0->toUnknown, v1->toUnknown])
let tuple3 = (. v0, v1, v2) => Tuple.factory([v0->toUnknown, v1->toUnknown, v2->toUnknown])
let tuple4 = Tuple.factoryFromArgs
let tuple5 = Tuple.factoryFromArgs
let tuple6 = Tuple.factoryFromArgs
let tuple7 = Tuple.factoryFromArgs
let tuple8 = Tuple.factoryFromArgs
let tuple9 = Tuple.factoryFromArgs
let tuple10 = Tuple.factoryFromArgs
let union = Union.factory
let jsonString = JsonString.factory
