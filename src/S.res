type never

type rec literal =
  | String(string)
  | Number(float)
  | Boolean(bool)
  | BigInt(Js.Types.bigint_val)
  | Symbol(Js.Types.symbol)
  | Array(array<literal>)
  | Dict(Js.Dict.t<literal>)
  | Function(Js.Types.function_val)
  | Object(Js.Types.obj_val)
  | Null
  | Undefined
  | NaN

module Obj = {
  external magic: 'a => 'b = "%identity"
}

module Stdlib = {
  module Type = {
    type t = [#undefined | #object | #boolean | #number | #bigint | #string | #symbol | #function]

    external typeof: 'a => t = "#typeof"
  }

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
    external thenResolveWithCatch: (
      t<'a>,
      @uncurry ('a => 'b),
      @uncurry (Js.Exn.t => 'b),
    ) => t<'b> = "then"

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

    @val external internalClass: Js.Types.obj_val => string = "Object.prototype.toString.call"
  }

  module Set = {
    type t<'value>

    @new
    external empty: unit => t<'value> = "Set"

    @send
    external has: (t<'value>, 'value) => bool = "has"

    @get external size: t<'value> => int = "size"

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

    let raiseAny = (any: 'any): 'a => any->Obj.magic->raise

    let raiseError: error => 'a = raiseAny
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

    let mapValues: (Js.Dict.t<'a>, (. 'a) => 'b) => Js.Dict.t<'b> = %raw(`(dict, fn)=>{
      var key,newDict = {};
      for (key in dict) {
        newDict[key] = fn(dict[key])
      }
      return newDict
    }`)
  }

  module Float = {
    // TODO: Use in more places
    external unsafeToString: float => string = "%identity"
  }

  module Bool = {
    @send external toString: bool => string = "toString"

    // TODO: Use in more places
    external unsafeToString: bool => string = "%identity"
  }

  module BigInt = {
    type t = Js.Types.bigint_val

    let unsafeToString = bigInt => {
      bigInt->(Obj.magic: t => string) ++ "n"
    }
  }

  module Function = {
    @variadic @new
    external _make: array<string> => 'function = "Function"

    @inline
    let make2 = (~ctxVarName1, ~ctxVarValue1, ~ctxVarName2, ~ctxVarValue2, ~inlinedFunction) => {
      _make([ctxVarName1, ctxVarName2, `return ${inlinedFunction}`])(. ctxVarValue1, ctxVarValue2)
    }
  }

  module Symbol = {
    type t = Js.Types.symbol

    @val external make: string => t = "Symbol"

    @send external toString: t => string = "toString"
  }

  module Inlined = {
    module Value = {
      @inline
      let stringify = any => {
        if any === %raw("void 0") {
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

  module Literal = {
    let rec classify = (. value): literal => {
      let typeOfValue = value->Type.typeof
      switch typeOfValue {
      | #undefined => Undefined
      | #object if value === %raw("null") => Null
      | #object if value->Js.Array2.isArray =>
        Array(value->(Obj.magic: 'a => array<'b>)->Js.Array2.map(i => i->classify))
      | #object
        if (value->(Obj.magic: 'a => {"constructor": unknown}))["constructor"] === %raw("Object") =>
        Dict(value->(Obj.magic: 'a => Js.Dict.t<'b>)->Dict.mapValues(classify))
      | #object => Object(value->(Obj.magic: 'a => Js.Types.obj_val))
      | #function => Function(value->(Obj.magic: 'a => Js.Types.function_val))
      | #string => String(value->(Obj.magic: 'a => string))
      | #number if value->(Obj.magic: 'a => float)->Js.Float.isNaN => NaN
      | #number => Number(value->(Obj.magic: 'a => float))
      | #boolean => Boolean(value->(Obj.magic: 'a => bool))
      | #symbol => Symbol(value->(Obj.magic: 'a => Js.Types.symbol))
      | #bigint => BigInt(value->(Obj.magic: 'a => Js.Types.bigint_val))
      }
    }

    let rec toText = literal => {
      switch literal {
      | NaN => `NaN`
      | Undefined => `undefined`
      | Null => `null`
      | Number(v) => v->Float.unsafeToString
      | Boolean(v) => v->Bool.unsafeToString
      | BigInt(v) => v->BigInt.unsafeToString
      | String(v) => v->Inlined.Value.fromString
      | Object(v) => v->Object.internalClass
      | Function(_) => "function"
      | Symbol(v) => v->Symbol.toString
      | Array(v) => `[${v->Js.Array2.map(toText)->Js.Array2.joinWith(",")}]`
      | Dict(v) =>
        `{${v
          ->Js.Dict.keys
          ->Js.Array2.map(key =>
            `${key->Inlined.Value.fromString}:${toText(v->Js.Dict.unsafeGet(key))}`
          )
          ->Js.Array2.joinWith(",")}}`
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

let symbol = Stdlib.Symbol.make("rescript-struct")

@unboxed
type isAsyncParse = | @as(0) Unknown | Value(bool)

type rec t<'value> = {
  @as("n")
  name: string,
  @as("t")
  tagged: tagged,
  @as("pb")
  mutable parseOperationBuilder: builder,
  @as("sb")
  mutable serializeOperationBuilder: builder,
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
  | Literal(literal)
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
and builder
and struct<'a> = t<'a>

module Error = {
  @inline
  let panic = message => Stdlib.Exn.raiseError(Stdlib.Exn.makeError(`[rescript-struct] ${message}`))

  type rec t = {operation: operation, code: code, path: Path.t}
  and code =
    | OperationFailed(string)
    // TODO: MissingTransformation/MissingOperation
    | MissingParser
    | MissingSerializer
    | InvalidType({expected: string, received: string})
    | InvalidLiteral({expected: literal, received: unknown})
    | InvalidTupleSize({expected: int, received: int})
    | ExcessField(string)
    | InvalidUnion(array<t>)
    | UnexpectedAsync
    | InvalidJsonStruct(struct<unknown>)
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
      @as("s")
      symbol: Stdlib.Symbol.t,
    }

    @inline
    let raise = (~path, ~code) => {
      Stdlib.Exn.raiseAny({code, path, symbol})
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

    let getOrRethrow = (jsExn: Js.Exn.t) => {
      if %raw("jsExn&&jsExn.s===symbol") {
        jsExn->(Obj.magic: Js.Exn.t => t)
      } else {
        Stdlib.Exn.raiseAny(jsExn)
      }
    }

    let prependLocationOrRethrow = (jsExn, location) => {
      let error = jsExn->getOrRethrow
      raise(~path=Path.concat(location->Path.fromLocation, error.path), ~code=error.code)
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
    | InvalidType({expected, received}) => `Expected ${expected}, received ${received}`
    | InvalidLiteral({expected, received}) =>
      `Expected ${expected->Stdlib.Literal.toText}, received ${received
        ->Stdlib.Literal.classify
        ->Stdlib.Literal.toText}`
    | InvalidJsonStruct(struct) => `The struct ${struct.name} is not compatible with JSON`
    | InvalidTupleSize({expected, received}) =>
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

let advancedFail = (error: Error.t) => {
  Error.Internal.raise(~path=error.path, ~code=error.code)
}

let fail = (~path=Path.empty, message) => {
  Error.Internal.raise(~path, ~code=OperationFailed(message))
}

exception Raised(Error.t)

type payloadedVariant<'payload> = {_0: 'payload}
let unsafeGetVariantPayload = variant => (variant->Obj.magic)._0

let emptyMetadataMap = Js.Dict.empty()

external castAnyToUnknown: 'any => unknown = "%identity"
external castUnknownToAny: unknown => 'any = "%identity"
external castUnknownStructToAnyStruct: t<unknown> => t<'any> = "%identity"
external toUnknown: t<'any> => t<unknown> = "%identity"

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
  type t = builder
  type ctx = {
    @as("c")
    mutable varCounter: int,
    @as("v")
    mutable varsAllocation: string,
    @as("a")
    asyncVars: Stdlib.Set.t<string>,
    @as("e")
    embeded: array<unknown>,
  }
  type implementation = (
    . ctx,
    ~selfStruct: struct<unknown>,
    ~inputVar: string,
    ~outputVar: string,
    ~pathVar: string,
  ) => string

  let make = (Obj.magic: implementation => t)

  // TODO: Noop checks stopped working
  let noop = make((. _b, ~selfStruct as _, ~inputVar, ~outputVar, ~pathVar as _) => {
    `${outputVar}=${inputVar};`
  })

  module Ctx = {
    type t = ctx

    @inline
    let embed = (b: t, value) => {
      `e[${(b.embeded->Js.Array2.push(value->castAnyToUnknown)->(Obj.magic: int => float) -. 1.)
          ->(Obj.magic: float => string)}]`
    }

    let varsScope = (b: t, fn) => {
      let prevVarsAllocation = b.varsAllocation
      b.varsAllocation = ""
      let code = fn(. b)
      let varsAllocation = b.varsAllocation
      let code = varsAllocation === "" ? code : `let ${varsAllocation};${code}`
      b.varsAllocation = prevVarsAllocation
      code
    }

    let var = (b: t) => {
      let newCounter = b.varCounter->Stdlib.Int.plus(1)
      b.varCounter = newCounter
      let v = `v${newCounter->Stdlib.Int.unsafeToString}`
      let varsAllocation = b.varsAllocation
      b.varsAllocation = varsAllocation === "" ? v : varsAllocation ++ "," ++ v
      v
    }

    let varWithoutAllocation = (b: t) => {
      let newCounter = b.varCounter->Stdlib.Int.plus(1)
      b.varCounter = newCounter
      `v${newCounter->Stdlib.Int.unsafeToString}`
    }

    let rec literal = (b: t, value: literal) => {
      switch value {
      | NaN => `NaN`
      | Undefined => `void 0`
      | Null => `null`
      | Number(v) => v->Stdlib.Float.unsafeToString
      | Boolean(v) => v->Stdlib.Bool.unsafeToString
      | BigInt(v) => v->Stdlib.BigInt.unsafeToString
      | String(v) => v->Stdlib.Inlined.Value.fromString
      | Object(v) => b->embed(v)
      | Function(v) => b->embed(v)
      | Symbol(v) => b->embed(v)
      | Array(v) => `[${v->Js.Array2.map(item => b->literal(item))->Js.Array2.joinWith(",")}]`
      | Dict(v) =>
        `{${v
          ->Js.Dict.keys
          ->Js.Array2.map(key =>
            `${key->Stdlib.Inlined.Value.fromString}:${b->literal(v->Js.Dict.unsafeGet(key))}`
          )
          ->Js.Array2.joinWith(",")}}`
      }
    }

    @inline
    let isInternalError = (_b: t, var) => {
      `${var}&&${var}.s===s`
    }

    // TODO: Figure out how to make it better
    let internalTransformRethrow = (b: t, ~pathVar) => {
      `if(${b->isInternalError("t")}){t.p=${pathVar}+t.p}throw t`
    }

    let embedSyncOperation = (
      b: t,
      ~inputVar,
      ~outputVar,
      ~pathVar,
      ~fn: 'input => 'output,
      ~isSafe=false,
      ~isRefine=false,
      (),
    ) => {
      switch b.asyncVars->Stdlib.Set.has(inputVar) {
      | false =>
        let code = isRefine
          ? `${b->embed(fn)}(${inputVar});${outputVar}=${inputVar};`
          : `${outputVar}=${b->embed(fn)}(${inputVar})`

        switch (isSafe, pathVar) {
        | (true, _)
        | (_, `""`) => code
        | _ => `try{${code}}catch(t){${b->internalTransformRethrow(~pathVar)}}`
        }

      | true =>
        b.asyncVars->Stdlib.Set.add(outputVar)->ignore
        let code = `${outputVar}=()=>${inputVar}().then(${isRefine
            ? `t=>{${b->embed(fn)}(t);return ${inputVar}}`
            : b->embed(fn)})`

        switch (isSafe, pathVar) {
        | (true, _)
        | (_, `""`) => code
        | _ => `${code}.catch(t=>{${b->internalTransformRethrow(~pathVar)}})`
        }
      } ++ ";"
    }

    let embedAsyncOperation = (
      b: t,
      ~inputVar,
      ~outputVar,
      ~pathVar,
      ~fn: (. 'input) => (. unit) => promise<'output>,
      ~isRefine=false,
      (),
    ) => {
      let {asyncVars} = b
      let isAsyncInput = asyncVars->Stdlib.Set.has(inputVar)
      asyncVars->Stdlib.Set.add(outputVar)->ignore
      switch isAsyncInput {
      | false =>
        switch pathVar {
        | `""` => {
            let code = `${b->embed(fn)}(${inputVar})`
            if isRefine {
              let syncResultVar = b->var
              `${syncResultVar}=${code};${outputVar}=()=>${syncResultVar}().then(_=>${inputVar});`
            } else {
              `${outputVar}=${code};`
            }
          }
        | _ => {
            let syncResultVar = b->var
            let code = `${syncResultVar}=${b->embed(fn)}(${inputVar});`
            `try{${code}${outputVar}=()=>{try{return ${syncResultVar}()${isRefine
                ? `.then(_=>${inputVar})`
                : ""}.catch(t=>{${b->internalTransformRethrow(
                ~pathVar,
              )}})}catch(t){${b->internalTransformRethrow(
                ~pathVar,
              )}}}}catch(t){${b->internalTransformRethrow(~pathVar)}};`
          }
        }

      | true => {
          let code = `${outputVar}=()=>${inputVar}().then(t=>${b->embed(fn)}(t)()${isRefine
              ? ".then(_=>t)"
              : ""})`
          switch pathVar {
          | `""` => code
          | _ => `${code}.catch(t=>{${b->internalTransformRethrow(~pathVar)}})`
          } ++ ";"
        }
      }
    }

    let raiseWithArg = (b: t, ~pathVar, fn: (. 'arg) => Error.code, arg) => {
      `${b->embed((path, arg) => {
          Error.Internal.raise(~path, ~code=fn(arg))
        })}(${pathVar},${arg})`
    }

    let raise = (b: t, ~pathVar, code) => {
      `${b->embed(path => {
          Error.Internal.raise(~path, ~code)
        })}(${pathVar})`
    }

    let run = (b: t, ~builder, ~struct, ~inputVar, ~outputVar, ~pathVar) => {
      let asyncVarsCountBefore = b.asyncVars->Stdlib.Set.size
      let code = (builder->(Obj.magic: builder => implementation))(.
        b,
        ~selfStruct=struct,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      )
      let isAsync = b.asyncVars->Stdlib.Set.size > asyncVarsCountBefore
      if isAsync {
        b.asyncVars->Stdlib.Set.add(outputVar)->ignore
      }
      if struct.parseOperationBuilder === builder {
        struct.isAsyncParse = Value(isAsync)
      }
      code
    }
  }

  let build = (builder, ~struct) => {
    let intitialInputVar = "i"
    let intitialOutputVar = "o"
    let b = {
      embeded: [],
      varCounter: -1,
      asyncVars: Stdlib.Set.empty(),
      varsAllocation: intitialOutputVar,
    }
    let code =
      b->Ctx.run(
        ~builder,
        ~struct,
        ~inputVar=intitialInputVar,
        ~outputVar=intitialOutputVar,
        ~pathVar=`""`,
      )
    // TODO: Optimize Builder.noop i=>{var _;return i}
    let inlinedFunction = `${intitialInputVar}=>{var ${b.varsAllocation};${code}return ${intitialOutputVar}}`
    Js.log(inlinedFunction)
    Stdlib.Function.make2(
      ~ctxVarName1="e",
      ~ctxVarValue1=b.embeded,
      ~ctxVarName2="s",
      ~ctxVarValue2=symbol,
      ~inlinedFunction,
    )
  }

  let compileParser = (struct, ~builder) => {
    let operation = builder->build(~struct)
    let isAsync = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
    struct.parse = isAsync
      ? (. _) => Error.Internal.raise(~path=Path.empty, ~code=UnexpectedAsync)
      : operation
    struct.parseAsync = isAsync
      ? operation
      : (. input) => {
          let syncValue = operation(. input)
          (. ()) => syncValue->Stdlib.Promise.resolve
        }
  }

  let compileSerializer = (struct, ~builder) => {
    let operation = builder->build(~struct)
    struct.serialize = operation
  }
}
module B = Builder.Ctx

let toLiteral = {
  let rec loop = (. struct) => {
    switch struct->classify {
    | Literal(literal) => literal
    | Union(unionStructs) => unionStructs->Js.Array2.unsafe_get(0)->loop
    | Tuple(tupleStructs) => Array(tupleStructs->Js.Array2.map(a => a->loop))
    | Object({fields}) => Dict(fields->Stdlib.Dict.mapValues(loop))
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
      Stdlib.Exn.raiseAny(symbol)
    }
  }
  struct => {
    try {
      Some(loop(struct))
    } catch {
    | Js.Exn.Error(jsExn) =>
      jsExn->(Obj.magic: Js.Exn.t => Stdlib.Symbol.t) === symbol ? None : Stdlib.Exn.raiseAny(jsExn)
    }
  }
}

let isAsyncParse = struct => {
  let struct = struct->toUnknown
  switch struct.isAsyncParse {
  | Unknown => {
      struct->Builder.compileParser(~builder=struct.parseOperationBuilder)
      struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
    }
  | Value(v) => v
  }
}

let initialSerialize = (. input) => {
  let struct = %raw("this")
  struct->Builder.compileSerializer(~builder=struct.serializeOperationBuilder)
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
    | Literal(Number(_))
    | Literal(Boolean(_))
    | // TODO: Support for Literal(Dict(_))
    // TODO: Support for Literal(Array(_))
    Literal(Null) => ()
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
        | Js.Exn.Error(jsExn) => jsExn->Error.Internal.prependLocationOrRethrow(fieldName)
        }
      }

    | Tuple(childrenStructs) =>
      childrenStructs->Js.Array2.forEachi((childStruct, i) => {
        try {
          childStruct->validateJsonableStruct(~rootStruct, ())
        } catch {
        | Js.Exn.Error(jsExn) => jsExn->Error.Internal.prependLocationOrRethrow(i->Js.Int.toString)
        }
      })
    | Union(childrenStructs) =>
      childrenStructs->Js.Array2.forEach(childStruct =>
        childStruct->validateJsonableStruct(~rootStruct, ())
      )
    | Option(_)
    | Unknown
    | Literal(_) =>
      Error.Internal.raise(~path=Path.empty, ~code=InvalidJsonStruct(struct))
    }
  }
}

let initialSerializeToJson = (. input) => {
  let struct = %raw("this")
  try {
    struct->validateJsonableStruct(~rootStruct=struct, ~isRoot=true, ())
    if struct.serialize === initialSerialize {
      struct->Builder.compileSerializer(~builder=struct.serializeOperationBuilder)
    }
    struct.serializeToJson =
      struct.serialize->(Obj.magic: ((. unknown) => unknown) => (. unknown) => Js.Json.t)
  } catch {
  | Js.Exn.Error(jsExn) => {
      let error = jsExn->Error.Internal.getOrRethrow
      struct.serializeToJson = (. _) => Stdlib.Exn.raiseAny(error)
    }
  }
  struct.serializeToJson(. input)
}

let intitialParse = (. input) => {
  let struct = %raw("this")
  struct->Builder.compileParser(~builder=struct.parseOperationBuilder)
  struct.parse(. input)
}

let intitialParseAsync = (. input) => {
  let struct = %raw("this")
  struct->Builder.compileParser(~builder=struct.parseOperationBuilder)
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
  | Js.Exn.Error(jsExn) => jsExn->Error.Internal.getOrRethrow->Error.Internal.toParseError->Error
  }
}

let parseWith: (Js.Json.t, t<'value>) => result<'value, Error.t> = parseAnyWith

let parseAnyOrRaiseWith = (any, struct) => {
  try {
    struct.parse(. any->castAnyToUnknown)->castUnknownToAny
  } catch {
  | Js.Exn.Error(jsExn) =>
    raise(Raised(jsExn->Error.Internal.getOrRethrow->Error.Internal.toParseError))
  }
}

let parseOrRaiseWith: (Js.Json.t, t<'value>) => 'value = parseAnyOrRaiseWith

let asyncPrepareOk = value => Ok(value->castUnknownToAny)

let asyncPrepareError = jsExn => {
  jsExn->Error.Internal.getOrRethrow->Error.Internal.toParseError->Error
}

let parseAnyAsyncWith = (any, struct) => {
  try {
    struct.parseAsync(. any->castAnyToUnknown)(.)->Stdlib.Promise.thenResolveWithCatch(
      asyncPrepareOk,
      asyncPrepareError,
    )
  } catch {
  | Js.Exn.Error(jsExn) =>
    jsExn->Error.Internal.getOrRethrow->Error.Internal.toParseError->Error->Stdlib.Promise.resolve
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
  | Js.Exn.Error(jsExn) => jsExn->Error.Internal.getOrRethrow->Error.Internal.toParseError->Error
  }
}

let parseAsyncInStepsWith = parseAnyAsyncInStepsWith

let serializeToUnknownWith = (value, struct) => {
  try {
    struct.serialize(. value->castAnyToUnknown)->Ok
  } catch {
  | Js.Exn.Error(jsExn) =>
    jsExn->Error.Internal.getOrRethrow->Error.Internal.toSerializeError->Error
  }
}

let serializeOrRaiseWith = (value, struct) => {
  try {
    struct.serializeToJson(. value->castAnyToUnknown)
  } catch {
  | Js.Exn.Error(jsExn) =>
    raise(Raised(jsExn->Error.Internal.getOrRethrow->Error.Internal.toSerializeError))
  }
}

let serializeToUnknownOrRaiseWith = (value, struct) => {
  try {
    struct.serialize(. value->castAnyToUnknown)
  } catch {
  | Js.Exn.Error(jsExn) =>
    raise(Raised(jsExn->Error.Internal.getOrRethrow->Error.Internal.toSerializeError))
  }
}

let serializeWith = (value, struct) => {
  try {
    struct.serializeToJson(. value->castAnyToUnknown)->Ok
  } catch {
  | Js.Exn.Error(jsExn) =>
    jsExn->Error.Internal.getOrRethrow->Error.Internal.toSerializeError->Error
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
    let builder = placeholder.parseOperationBuilder
    placeholder.parseOperationBuilder = Builder.make((.
      b,
      ~selfStruct,
      ~inputVar,
      ~outputVar,
      ~pathVar,
    ) => {
      let isAsync = {
        selfStruct.parseOperationBuilder = Builder.noop
        let asyncVars = Stdlib.Set.empty()
        let _ = (builder->(Obj.magic: builder => Builder.implementation))(.
          {
            Builder.embeded: [],
            varsAllocation: "",
            asyncVars,
            varCounter: -1,
          },
          ~selfStruct,
          ~inputVar,
          ~outputVar,
          ~pathVar,
        )
        asyncVars->Stdlib.Set.size > 0
      }

      selfStruct.parseOperationBuilder = Builder.make((.
        b,
        ~selfStruct,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        if isAsync {
          b->B.embedAsyncOperation(
            ~inputVar,
            ~outputVar,
            ~pathVar,
            ~fn=(. input) => selfStruct.parseAsync(input),
            (),
          )
        } else {
          b->B.embedSyncOperation(
            ~inputVar,
            ~outputVar,
            ~pathVar,
            ~fn=input => selfStruct.parse(input),
            (),
          )
        }
      })

      selfStruct->Builder.compileParser(~builder)
      selfStruct.parseOperationBuilder = builder
      if isAsync {
        b->B.embedAsyncOperation(~inputVar, ~outputVar, ~pathVar, ~fn=selfStruct.parseAsync, ())
      } else {
        b->B.embedSyncOperation(
          ~inputVar,
          ~outputVar,
          ~pathVar,
          ~fn=selfStruct.parse->(Obj.magic: ((. unknown) => unknown, unknown) => unknown),
          (),
        )
      }
    })
  }

  {
    let builder = placeholder.serializeOperationBuilder
    placeholder.serializeOperationBuilder = Builder.make((.
      b,
      ~selfStruct,
      ~inputVar,
      ~outputVar,
      ~pathVar,
    ) => {
      selfStruct.serializeOperationBuilder = Builder.make((.
        b,
        ~selfStruct,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        b->B.embedSyncOperation(
          ~inputVar,
          ~outputVar,
          ~pathVar,
          ~fn=input => selfStruct.serialize(input),
          (),
        )
      })
      selfStruct->Builder.compileSerializer(~builder)
      selfStruct.serializeOperationBuilder = builder
      b->B.embedSyncOperation(
        ~inputVar,
        ~outputVar,
        ~pathVar,
        ~fn=selfStruct.serialize->(Obj.magic: ((. unknown) => unknown, unknown) => unknown),
        (),
      )
    })
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
      Builder.make((. b, ~selfStruct as _, ~inputVar, ~outputVar, ~pathVar) => {
        let childOutputVar = b->B.var
        let code =
          b->B.run(
            ~builder=struct.parseOperationBuilder,
            ~struct,
            ~inputVar,
            ~outputVar=childOutputVar,
            ~pathVar,
          )

        `${code}${b->B.embedSyncOperation(
            ~inputVar=childOutputVar,
            ~outputVar,
            ~pathVar,
            ~fn=parser,
            ~isRefine=true,
            (),
          )}${b->B.embedAsyncOperation(
            ~inputVar=childOutputVar,
            ~outputVar,
            ~pathVar,
            ~fn=(. i) => (. ()) => asyncParser->Stdlib.Fn.call1(i),
            ~isRefine=true,
            (),
          )}`
      })
    | (Some(parser), None) =>
      Builder.make((. b, ~selfStruct as _, ~inputVar, ~outputVar, ~pathVar) => {
        let childOutputVar = b->B.var
        let code =
          b->B.run(
            ~builder=struct.parseOperationBuilder,
            ~struct,
            ~inputVar,
            ~outputVar=childOutputVar,
            ~pathVar,
          )

        `${code}${b->B.embedSyncOperation(
            ~inputVar=childOutputVar,
            ~outputVar,
            ~pathVar,
            ~fn=parser,
            ~isRefine=true,
            (),
          )}`
      })
    | (None, Some(asyncParser)) =>
      Builder.make((. b, ~selfStruct as _, ~inputVar, ~outputVar, ~pathVar) => {
        let childOutputVar = b->B.var
        let code =
          b->B.run(
            ~builder=struct.parseOperationBuilder,
            ~struct,
            ~inputVar,
            ~outputVar=childOutputVar,
            ~pathVar,
          )
        `${code}${b->B.embedAsyncOperation(
            ~inputVar=childOutputVar,
            ~outputVar,
            ~pathVar,
            ~fn=(. i) => (. ()) => asyncParser->Stdlib.Fn.call1(i),
            ~isRefine=true,
            (),
          )}`
      })
    | (None, None) => struct.parseOperationBuilder
    },
    ~serializeOperationBuilder=switch maybeSerializer {
    | Some(serializer) =>
      Builder.make((. b, ~selfStruct as _, ~inputVar, ~outputVar, ~pathVar) => {
        let transformResultVar = b->B.var
        let code =
          b->B.run(
            ~builder=struct.parseOperationBuilder,
            ~struct,
            ~inputVar=transformResultVar,
            ~outputVar,
            ~pathVar,
          )

        b->B.embedSyncOperation(
          ~inputVar,
          ~outputVar=transformResultVar,
          ~pathVar,
          ~fn=serializer,
          ~isRefine=true,
          (),
        ) ++ code
      })

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
    ~parseOperationBuilder=Builder.make((. b, ~selfStruct, ~inputVar, ~outputVar, ~pathVar) => {
      switch maybeParser {
      | Some(parser) =>
        switch parser->TransformationFactory.call(
          ~struct=selfStruct->castUnknownStructToAnyStruct,
        ) {
        | Noop =>
          b->B.run(~builder=struct.parseOperationBuilder, ~struct, ~inputVar, ~outputVar, ~pathVar)

        | Sync(syncTransformation) => {
            let childOutputVar = b->B.var
            let code =
              b->B.run(
                ~builder=struct.parseOperationBuilder,
                ~struct,
                ~inputVar,
                ~outputVar=childOutputVar,
                ~pathVar,
              )
            `${code}${b->B.embedSyncOperation(
                ~inputVar=childOutputVar,
                ~outputVar,
                ~pathVar,
                ~fn=syncTransformation,
                (),
              )}`
          }
        | Async(asyncParser) => {
            let childOutputVar = b->B.var
            let code =
              b->B.run(
                ~builder=struct.parseOperationBuilder,
                ~struct,
                ~inputVar,
                ~outputVar=childOutputVar,
                ~pathVar,
              )
            `${code}${b->B.embedAsyncOperation(
                ~inputVar=childOutputVar,
                ~outputVar,
                ~pathVar,
                ~fn=(. i) => (. ()) => asyncParser->Stdlib.Fn.call1(i),
                (),
              )}`
          }
        }
      | None => b->B.raise(~pathVar, MissingParser) ++ ";"
      }
    }),
    ~serializeOperationBuilder=Builder.make((. b, ~selfStruct, ~inputVar, ~outputVar, ~pathVar) => {
      switch maybeSerializer {
      | Some(serializer) =>
        switch serializer->TransformationFactory.call(
          ~struct=selfStruct->castUnknownStructToAnyStruct,
        ) {
        | Noop =>
          b->B.run(
            ~builder=struct.serializeOperationBuilder,
            ~struct,
            ~inputVar,
            ~outputVar,
            ~pathVar,
          )
        | Sync(fn) => {
            let transformOutputVar = b->B.var
            let code =
              b->B.run(
                ~builder=struct.serializeOperationBuilder,
                ~struct,
                ~inputVar=transformOutputVar,
                ~outputVar,
                ~pathVar,
              )
            `${b->B.embedSyncOperation(
                ~inputVar,
                ~outputVar=transformOutputVar,
                ~pathVar,
                ~fn,
                (),
              )}${code}`
          }
        | Async(_) => b->B.raise(~pathVar, MissingSerializer) ++ ";"
        }
      | None => b->B.raise(~pathVar, MissingSerializer) ++ ";"
      }
    }),
    ~metadataMap=struct.metadataMap,
    (),
  )
}

// TODO: Add internal transform so we can inline the built-in transforms (And use for S.transform/S.advancedTransform/S.refine/S.custom)
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
      Builder.make((. b, ~selfStruct as _, ~inputVar, ~outputVar, ~pathVar) => {
        let childOutputVar = b->B.var
        let code =
          b->B.run(
            ~builder=struct.parseOperationBuilder,
            ~struct,
            ~inputVar,
            ~outputVar=childOutputVar,
            ~pathVar,
          )
        `${code}${b->B.embedSyncOperation(
            ~inputVar=childOutputVar,
            ~outputVar,
            ~pathVar,
            ~fn=parser,
            (),
          )}`
      })
    | (None, Some(asyncParser)) =>
      Builder.make((. b, ~selfStruct as _, ~inputVar, ~outputVar, ~pathVar) => {
        let childOutputVar = b->B.var
        let code =
          b->B.run(
            ~builder=struct.parseOperationBuilder,
            ~struct,
            ~inputVar,
            ~outputVar=childOutputVar,
            ~pathVar,
          )
        `${code}${b->B.embedAsyncOperation(
            ~inputVar=childOutputVar,
            ~outputVar,
            ~pathVar,
            ~fn=(. i) => (. ()) => asyncParser->Stdlib.Fn.call1(i),
            (),
          )}`
      })
    | (None, None) =>
      Builder.make((. b, ~selfStruct as _, ~inputVar as _, ~outputVar as _, ~pathVar) => {
        b->B.raise(~pathVar, MissingParser) ++ ";"
      })
    },
    ~serializeOperationBuilder=switch maybeSerializer {
    | Some(serializer) =>
      Builder.make((. b, ~selfStruct as _, ~inputVar, ~outputVar, ~pathVar) => {
        let transformOutputVar = b->B.var
        let code =
          b->B.run(
            ~builder=struct.serializeOperationBuilder,
            ~struct,
            ~inputVar=transformOutputVar,
            ~outputVar,
            ~pathVar,
          )
        `${b->B.embedSyncOperation(
            ~inputVar,
            ~outputVar=transformOutputVar,
            ~pathVar,
            ~fn=serializer,
            (),
          )}${code}`
      })
    | None =>
      Builder.make((. b, ~selfStruct as _, ~inputVar as _, ~outputVar as _, ~pathVar) => {
        b->B.raise(~pathVar, MissingSerializer) ++ ";"
      })
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
      ~parseOperationBuilder=Builder.make((. b, ~selfStruct, ~inputVar, ~outputVar, ~pathVar) => {
        switch maybeParser {
        | Some(parser) =>
          switch parser->TransformationFactory.call(
            ~struct=selfStruct->castUnknownStructToAnyStruct,
          ) {
          | Noop =>
            b->B.run(
              ~builder=struct.parseOperationBuilder,
              ~struct,
              ~inputVar,
              ~outputVar,
              ~pathVar,
            )
          | Sync(syncTransformation) => {
              let parseResultVar = b->B.var
              let code =
                b->B.run(
                  ~builder=struct.parseOperationBuilder,
                  ~struct,
                  ~inputVar=parseResultVar,
                  ~outputVar,
                  ~pathVar,
                )
              `${b->B.embedSyncOperation(
                  ~inputVar,
                  ~outputVar=parseResultVar,
                  ~pathVar,
                  ~fn=syncTransformation,
                  (),
                )}${code}`
            }
          | Async(asyncParser) => {
              let parseResultVar = b->B.var
              let childOutputVar = b->B.var
              let code =
                b->B.run(
                  ~builder=struct.parseOperationBuilder,
                  ~struct,
                  ~inputVar="t",
                  ~outputVar=childOutputVar,
                  ~pathVar,
                )
              let isAsync = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)

              `${b->B.embedAsyncOperation(
                  ~inputVar,
                  ~outputVar=parseResultVar,
                  ~pathVar,
                  ~fn=(. i) => (. ()) => asyncParser->Stdlib.Fn.call1(i),
                  (),
                )}${outputVar}=()=>${parseResultVar}().then(t=>{${code}return ${isAsync
                  ? `${childOutputVar}()`
                  : childOutputVar}});`
            }
          }
        | None => b->B.raise(~pathVar, MissingParser) ++ ";"
        }
      }),
      ~serializeOperationBuilder=Builder.make((.
        b,
        ~selfStruct,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        switch maybeSerializer {
        | Some(serializer) =>
          switch serializer->TransformationFactory.call(
            ~struct=selfStruct->castUnknownStructToAnyStruct,
          ) {
          | Noop =>
            b->B.run(
              ~builder=struct.serializeOperationBuilder,
              ~struct,
              ~inputVar,
              ~outputVar,
              ~pathVar,
            )
          | Sync(fn) => {
              let structOuputVar = b->B.var
              let code =
                b->B.run(
                  ~builder=struct.serializeOperationBuilder,
                  ~struct,
                  ~inputVar,
                  ~outputVar=structOuputVar,
                  ~pathVar,
                )
              `${code}${b->B.embedSyncOperation(
                  ~inputVar=structOuputVar,
                  ~outputVar,
                  ~pathVar,
                  ~fn,
                  (),
                )}`
            }
          | Async(_) => b->B.raise(~pathVar, MissingSerializer) ++ ";"
          }
        | None => b->B.raise(~pathVar, MissingSerializer) ++ ";"
        }
      }),
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
      Builder.make((. b, ~selfStruct as _, ~inputVar, ~outputVar, ~pathVar) => {
        b->B.embedSyncOperation(~inputVar, ~outputVar, ~fn=parser, ~pathVar, ())
      })
    | (None, Some(asyncParser)) =>
      Builder.make((. b, ~selfStruct as _, ~inputVar, ~outputVar, ~pathVar) => {
        b->B.embedAsyncOperation(
          ~inputVar,
          ~outputVar,
          ~pathVar,
          ~fn=(. input) => (. ()) => asyncParser->Stdlib.Fn.call1(input),
          (),
        )
      })
    | (None, None) =>
      Builder.make((. b, ~selfStruct as _, ~inputVar as _, ~outputVar as _, ~pathVar) => {
        b->B.raise(~pathVar, MissingParser) ++ ";"
      })
    },
    ~serializeOperationBuilder=switch maybeSerializer {
    | Some(serializer) =>
      Builder.make((. b, ~selfStruct as _, ~inputVar, ~outputVar, ~pathVar) => {
        b->B.embedSyncOperation(~inputVar, ~outputVar, ~fn=serializer, ~pathVar, ())
      })
    | None =>
      Builder.make((. b, ~selfStruct as _, ~inputVar as _, ~outputVar as _, ~pathVar) => {
        b->B.raise(~pathVar, MissingSerializer) ++ ";"
      })
    },
    (),
  )
}

module Literal = {
  let rec literalCheckBuilder = (b, ~literal: literal, ~inputVar) => {
    // TODO: Test that all checks covered by tests
    switch literal {
    | NaN => `Number.isNaN(${inputVar})`
    | Array(v) =>
      `Array.isArray(${inputVar})&&${inputVar}.length===${v
        ->Js.Array2.length
        ->Stdlib.Int.unsafeToString}` ++ (
        v->Js.Array2.length > 0
          ? "&&" ++
            v
            ->Js.Array2.mapi((item, idx) =>
              b->literalCheckBuilder(
                ~literal=item,
                ~inputVar=`${inputVar}[${idx->Stdlib.Int.unsafeToString}]`,
              )
            )
            ->Js.Array2.joinWith("&&")
          : ""
      )

    | Dict(v) => {
        let keys = v->Js.Dict.keys
        let numberOfKeys = keys->Js.Array2.length
        // TODO: Check that it fails with null
        `${inputVar}.constructor===Object&&Object.keys(${inputVar}).length===${numberOfKeys->Stdlib.Int.unsafeToString}` ++ (
          numberOfKeys > 0
            ? "&&" ++
              keys
              ->Js.Array2.map(key => {
                let inputVar = b->B.var
                `(${inputVar}=${inputVar}[${key->Stdlib.Inlined.Value.fromString}],${b->literalCheckBuilder(
                    ~literal=v->Js.Dict.unsafeGet(key),
                    ~inputVar,
                  )})`
              })
              ->Js.Array2.joinWith("&&")
            : ""
        )
      }
    | _ => `${inputVar}===${b->B.literal(literal)}`
    }
  }

  let factory = value => {
    let literal = value->Stdlib.Literal.classify
    let operationBuilder = Builder.make((.
      b,
      ~selfStruct as _,
      ~inputVar,
      ~outputVar,
      ~pathVar,
    ) => {
      `${b->literalCheckBuilder(~literal, ~inputVar)}||${b->B.raiseWithArg(
          ~pathVar,
          (. input) => InvalidLiteral({
            expected: literal,
            received: input,
          }),
          inputVar,
        )};${outputVar}=${inputVar};`
    })
    make(
      // TODO: Get rid of names
      ~name="Literal",
      ~metadataMap=emptyMetadataMap,
      ~tagged=Literal(literal),
      ~parseOperationBuilder=operationBuilder,
      ~serializeOperationBuilder=operationBuilder,
      (),
    )
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
        ~parseOperationBuilder=Builder.make((.
          b,
          ~selfStruct as _,
          ~inputVar,
          ~outputVar,
          ~pathVar,
        ) => {
          let childOutputVar = b->B.var
          let code =
            b->B.run(
              ~builder=struct.parseOperationBuilder,
              ~struct,
              ~inputVar,
              ~outputVar=childOutputVar,
              ~pathVar,
            )
          code ++
          b->B.embedSyncOperation(
            ~inputVar=childOutputVar,
            ~outputVar,
            ~pathVar,
            ~fn=definer,
            ~isSafe=true,
            (),
          )
        }),
        ~serializeOperationBuilder=Builder.make((.
          b,
          ~selfStruct,
          ~inputVar,
          ~outputVar,
          ~pathVar,
        ) => {
          let {constantDefinitions, isValueRegistered, valuePath} = instructions
          let childInputVar = b->B.var
          let childCode =
            b->B.run(
              ~builder=struct.serializeOperationBuilder,
              ~struct,
              ~outputVar,
              ~inputVar=childInputVar,
              ~pathVar,
            )

          let codeRef = ref("")
          for idx in 0 to constantDefinitions->Js.Array2.length - 1 {
            let {path, value} = constantDefinitions->Js.Array2.unsafe_get(idx)
            codeRef.contents =
              codeRef.contents ++
              `if(${inputVar}${path}!==${b->B.embed(value)}){${b->B.raiseWithArg(
                  ~pathVar=`${pathVar}+${path->Stdlib.Inlined.Value.fromString}`,
                  (. input) => InvalidLiteral({
                    expected: value->Stdlib.Literal.classify,
                    received: input,
                  }),
                  `${inputVar}${path}`,
                )}}`
          }

          codeRef.contents ++
          switch isValueRegistered {
          | true => `${childInputVar}=${inputVar}${valuePath}`
          | false =>
            switch selfStruct->toLiteral {
            | Some(literal) => `${childInputVar}=${b->B.literal(literal)}`
            | None => b->B.raise(~pathVar, MissingSerializer)
            }
          } ++
          ";" ++
          childCode
        }),
        ~metadataMap=struct.metadataMap,
        (),
      )
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
      // TODO: Improve
      ~parseOperationBuilder=Builder.make((. b, ~selfStruct, ~inputVar, ~outputVar, ~pathVar) => {
        let {
          preparationPathes,
          inlinedPreparationValues,
          fieldDefinitions,
          constantDefinitions,
        } = instructions

        let asyncFieldVars = []

        let syncOutputVar = b->B.var
        let codeRef = ref(
          `if(!(typeof ${inputVar}==="object"&&${inputVar}!==null&&!Array.isArray(${inputVar}))){${b->B.raiseWithArg(
              ~pathVar,
              (. input) => InvalidType({
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
          let fieldInputVar = b->B.var
          let fieldOuputVar = b->B.var
          let fieldCode =
            b->B.run(
              ~builder=fieldStruct.parseOperationBuilder,
              ~struct=fieldStruct,
              ~inputVar=fieldInputVar,
              ~outputVar=fieldOuputVar,
              ~pathVar=`${pathVar}+'['+${inlinedFieldName->Stdlib.Inlined.Value.fromString}+']'`,
            )
          let isAsyncField = fieldStruct.isAsyncParse->(Obj.magic: isAsyncParse => bool)

          codeRef.contents =
            codeRef.contents ++
            `${fieldInputVar}=${inputVar}[${inlinedFieldName}];` ++
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
          `${codeRef.contents}${outputVar}=${syncOutputVar};`
        } else {
          let resolveVar = b->B.varWithoutAllocation
          let rejectVar = b->B.varWithoutAllocation
          let asyncParseResultVar = b->B.varWithoutAllocation
          let counterVar = b->B.varWithoutAllocation

          `${codeRef.contents}${outputVar}=()=>new Promise((${resolveVar},${rejectVar})=>{let ${counterVar}=${asyncFieldVars
            ->Js.Array2.length
            ->Js.Int.toString};${asyncFieldVars
            ->Js.Array2.map(asyncFieldVar => {
              `${asyncFieldVar}().then(${asyncParseResultVar}=>{${asyncFieldVar}=${asyncParseResultVar};if(${counterVar}--===1){${resolveVar}(${syncOutputVar})}},${rejectVar})`
            })
            ->Js.Array2.joinWith(";")}});`
        }
      }),
      ~serializeOperationBuilder=Builder.make((.
        b,
        ~selfStruct as _,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        let {fieldDefinitions, constantDefinitions} = instructions

        let codeRef = ref("")

        for idx in 0 to constantDefinitions->Js.Array2.length - 1 {
          let {path, value} = constantDefinitions->Js.Array2.unsafe_get(idx)
          codeRef.contents =
            codeRef.contents ++
            `if(${inputVar}${path}!==${b->B.embed(value)}){${b->B.raiseWithArg(
                ~pathVar=`${pathVar}+${path->Stdlib.Inlined.Value.fromString}`,
                (. input) => InvalidLiteral({
                  expected: value->Stdlib.Literal.classify,
                  received: input,
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
                let fieldOuputVar = b->B.var
                let fieldCode =
                  b->B.run(
                    ~builder=fieldStruct.serializeOperationBuilder,
                    ~struct=fieldStruct,
                    ~inputVar=destinationVar,
                    ~outputVar=fieldOuputVar,
                    ~pathVar=fieldPathVar,
                  )
                `${destinationVar}=${inputVar}${path};` ++
                fieldCode ++ (
                  destinationVar === fieldOuputVar ? "" : `${destinationVar}=${fieldOuputVar};`
                )
              }

            | false =>
              switch fieldStruct->toLiteral {
              | Some(literal) => `${destinationVar}=${b->B.literal(literal)}`
              | None => b->B.raise(~pathVar, MissingSerializer)
              } ++ ";"
            }
        }

        codeRef.contents
      }),
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
  let builder = Builder.make((. b, ~selfStruct as _, ~inputVar, ~outputVar as _, ~pathVar) => {
    b->B.raiseWithArg(
      ~pathVar,
      (. input) => InvalidType({
        expected: "Never",
        received: input->Stdlib.Unknown.toName,
      }),
      inputVar,
    ) ++ ";"
  })

  let struct = make(
    ~name=`Never`,
    ~metadataMap=emptyMetadataMap,
    ~tagged=Never,
    ~parseOperationBuilder=builder,
    ~serializeOperationBuilder=builder,
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

  let parseOperationBuilder = Builder.make((.
    b,
    ~selfStruct as _,
    ~inputVar,
    ~outputVar,
    ~pathVar,
  ) => {
    `if(typeof ${inputVar}!=="string"){${b->B.raiseWithArg(
        ~pathVar,
        (. input) => InvalidType({
          expected: "String",
          received: input->Stdlib.Unknown.toName,
        }),
        inputVar,
      )}}${outputVar}=${inputVar};`
  })

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
      ~parseOperationBuilder=Builder.make((. b, ~selfStruct, ~inputVar, ~outputVar, ~pathVar) => {
        let jsonStringVar = b->B.var
        let stringParserCode =
          b->B.run(
            ~builder=String.parseOperationBuilder,
            ~struct=selfStruct,
            ~inputVar,
            ~outputVar=jsonStringVar,
            ~pathVar,
          )
        let jsonVar = b->B.var
        let childCode =
          b->B.run(
            ~builder=childStruct.parseOperationBuilder,
            ~struct=childStruct,
            ~inputVar=jsonVar,
            ~outputVar,
            ~pathVar,
          )

        `${stringParserCode}try{${jsonVar}=JSON.parse(${jsonStringVar})}catch(t){${b->B.raiseWithArg(
            ~pathVar,
            (. message) => OperationFailed(message),
            "t.message",
          )}}${childCode}`
      }),
      ~serializeOperationBuilder=Builder.make((.
        b,
        ~selfStruct as _,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        let childOutputVar = b->B.var
        let childCode =
          b->B.run(
            ~builder=childStruct.parseOperationBuilder,
            ~struct=childStruct,
            ~inputVar,
            ~outputVar=childOutputVar,
            ~pathVar,
          )

        `${childCode}${outputVar}=JSON.stringify(${childOutputVar});`
      }),
      (),
    )
  }
}

module Bool = {
  let struct = make(
    ~name="Bool",
    ~metadataMap=emptyMetadataMap,
    ~tagged=Bool,
    ~parseOperationBuilder=Builder.make((.
      b,
      ~selfStruct as _,
      ~inputVar,
      ~outputVar,
      ~pathVar,
    ) => {
      `if(typeof ${inputVar}!=="boolean"){${b->B.raiseWithArg(
          ~pathVar,
          (. input) => InvalidType({
            expected: "Bool",
            received: input->Stdlib.Unknown.toName,
          }),
          inputVar,
        )}}${outputVar}=${inputVar};`
    }),
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
    ~parseOperationBuilder=Builder.make((.
      b,
      ~selfStruct as _,
      ~inputVar,
      ~outputVar,
      ~pathVar,
    ) => {
      `if(!(typeof ${inputVar}==="number"&&${inputVar}<2147483648&&${inputVar}>-2147483649&&${inputVar}%1===0)){${b->B.raiseWithArg(
          ~pathVar,
          (. input) => InvalidType({
            expected: "Int",
            received: input->Stdlib.Unknown.toName,
          }),
          inputVar,
        )}}${outputVar}=${inputVar};`
    }),
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
    ~parseOperationBuilder=Builder.make((.
      b,
      ~selfStruct as _,
      ~inputVar,
      ~outputVar,
      ~pathVar,
    ) => {
      `if(!(typeof ${inputVar}==="number"&&!Number.isNaN(${inputVar}))){${b->B.raiseWithArg(
          ~pathVar,
          (. input) => InvalidType({
            expected: "Float",
            received: input->Stdlib.Unknown.toName,
          }),
          inputVar,
        )}}${outputVar}=${inputVar};`
    }),
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
      ~parseOperationBuilder=Builder.make((.
        b,
        ~selfStruct as _,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        let childOutputVar = b->B.var
        let childCode =
          b->B.run(
            ~builder=childStruct.parseOperationBuilder,
            ~struct=childStruct,
            ~inputVar,
            ~outputVar=childOutputVar,
            ~pathVar,
          )
        let isAsyncChild = childStruct.isAsyncParse->(Obj.magic: isAsyncParse => bool)

        `if(${inputVar}!==null){${childCode}${b->B.embedSyncOperation(
            ~inputVar=childOutputVar,
            ~outputVar,
            ~pathVar,
            ~isSafe=true,
            ~fn=%raw("Caml_option.some"),
            (),
          )}}else{${outputVar}=${isAsyncChild ? `()=>Promise.resolve(void 0)` : `void 0`}}`
      }),
      ~serializeOperationBuilder=Builder.make((.
        b,
        ~selfStruct as _,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        let childOutputVar = b->B.var
        let childCode =
          b->B.run(
            ~builder=childStruct.serializeOperationBuilder,
            ~struct=childStruct,
            ~inputVar,
            ~outputVar=childOutputVar,
            ~pathVar,
          )

        `if(${inputVar}!==void 0){${inputVar}=${b->B.embed(
            %raw("Caml_option.valFromOption"),
          )}(${inputVar});${childCode}${outputVar}=${childOutputVar}}else{${outputVar}=null}`
      }),
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
      ~parseOperationBuilder=Builder.make((.
        b,
        ~selfStruct as _,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        let childOutputVar = b->B.var
        let childCode =
          b->B.run(
            ~builder=childStruct.parseOperationBuilder,
            ~struct=childStruct,
            ~inputVar,
            ~outputVar=childOutputVar,
            ~pathVar,
          )

        let isChildAsync = childStruct.isAsyncParse->(Obj.magic: isAsyncParse => bool)

        `if(${inputVar}!==void 0){${childCode}${b->B.embedSyncOperation(
            ~inputVar=childOutputVar,
            ~outputVar,
            ~pathVar,
            ~isSafe=true,
            ~fn=%raw("Caml_option.some"),
            (),
          )}}else{${outputVar}=${switch isChildAsync {
          | false => inputVar
          | true => `()=>Promise.resolve(${inputVar})`
          }}}`
      }),
      ~serializeOperationBuilder=Builder.make((.
        b,
        ~selfStruct as _,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        let childOutputVar = b->B.var
        let childCode =
          b->B.run(
            ~builder=childStruct.serializeOperationBuilder,
            ~struct=childStruct,
            ~inputVar,
            ~outputVar=childOutputVar,
            ~pathVar,
          )

        `if(${inputVar}!==void 0){${inputVar}=${b->B.embed(
            %raw("Caml_option.valFromOption"),
          )}(${inputVar});${childCode}${outputVar}=${childOutputVar}}else{${outputVar}=void 0}`
      }),
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
      ~parseOperationBuilder=Builder.make((.
        b,
        ~selfStruct as _,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        let iteratorVar = b->B.varWithoutAllocation

        let code = `if(!Array.isArray(${inputVar})){${b->B.raiseWithArg(
            ~pathVar,
            (. input) => InvalidType({
              expected: "Array",
              received: input->Stdlib.Unknown.toName,
            }),
            inputVar,
          )}}${outputVar}=[];for(let ${iteratorVar}=0;${iteratorVar}<${inputVar}.length;++${iteratorVar}){${b->B.varsScope(
            (. b) => {
              let itemVar = b->B.var
              let childOutputVar = b->B.var

              let childCode =
                b->B.run(
                  ~builder=childStruct.parseOperationBuilder,
                  ~struct=childStruct,
                  ~inputVar=itemVar,
                  ~outputVar=childOutputVar,
                  ~pathVar=`${pathVar}+'["'+${iteratorVar}+'"]'`,
                )
              `${itemVar}=${inputVar}[${iteratorVar}];${childCode}${outputVar}.push(${childOutputVar})`
            },
          )}}`

        let isAsync = childStruct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
        if isAsync {
          let syncOutputVar = b->B.var
          code ++
          `${syncOutputVar}=${outputVar};${outputVar}=()=>Promise.all(${syncOutputVar}.map(t=>t()));`
        } else {
          code
        }
      }),
      ~serializeOperationBuilder=Builder.make((.
        b,
        ~selfStruct as _,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        let iteratorVar = b->B.varWithoutAllocation

        // TODO: Optimize when childStruct.serializeOperationBuilder is noop
        `${outputVar}=[];for(let ${iteratorVar}=0;${iteratorVar}<${inputVar}.length;++${iteratorVar}){${b->B.varsScope(
            (. b) => {
              let itemVar = b->B.var
              let childOutputVar = b->B.var

              let code =
                b->B.run(
                  ~builder=childStruct.serializeOperationBuilder,
                  ~struct=childStruct,
                  ~inputVar=itemVar,
                  ~outputVar=childOutputVar,
                  ~pathVar=`${pathVar}+'["'+${iteratorVar}+'"]'`,
                )
              `${itemVar}=${inputVar}[${iteratorVar}];${code}${outputVar}.push(${childOutputVar})`
            },
          )}}`
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
      ~parseOperationBuilder=Builder.make((.
        b,
        ~selfStruct as _,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        let keyVar = b->B.varWithoutAllocation

        let code = `if(!(typeof ${inputVar}==="object"&&${inputVar}!==null&&!Array.isArray(${inputVar}))){${b->B.raiseWithArg(
            ~pathVar,
            (. input) => InvalidType({
              expected: "Dict",
              received: input->Stdlib.Unknown.toName,
            }),
            inputVar,
          )}}${outputVar}={};for(let ${keyVar} in ${inputVar}){${b->B.varsScope((. b) => {
            let itemVar = b->B.var
            let childOutputVar = b->B.var
            let childCode =
              b->B.run(
                ~builder=childStruct.parseOperationBuilder,
                ~struct=childStruct,
                ~inputVar=itemVar,
                ~outputVar=childOutputVar,
                ~pathVar=`${pathVar}+'["'+${keyVar}+'"]'`,
              )
            `${itemVar}=${inputVar}[${keyVar}];${childCode}${outputVar}[${keyVar}]=${childOutputVar}`
          })}}`

        let isAsync = childStruct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
        if isAsync {
          let resolveVar = b->B.varWithoutAllocation
          let rejectVar = b->B.varWithoutAllocation
          let asyncParseResultVar = b->B.varWithoutAllocation
          let counterVar = b->B.varWithoutAllocation
          let syncOutputVar = b->B.var
          `${code}${syncOutputVar}=${outputVar};${outputVar}=()=>new Promise((${resolveVar},${rejectVar})=>{let ${counterVar}=Object.keys(${syncOutputVar}).length;for(let ${keyVar} in ${syncOutputVar}){${syncOutputVar}[${keyVar}]().then(${asyncParseResultVar}=>{${syncOutputVar}[${keyVar}]=${asyncParseResultVar};if(${counterVar}--===1){${resolveVar}(${syncOutputVar})}},${rejectVar})}});`
        } else {
          code
        }
      }),
      ~serializeOperationBuilder=Builder.make((.
        b,
        ~selfStruct as _,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        let keyVar = b->B.varWithoutAllocation

        // TODO: Optimize when childStruct.serializeOperationBuilder is noop
        `${outputVar}={};for(let ${keyVar} in ${inputVar}){${b->B.varsScope((. b) => {
            let itemVar = b->B.var
            let childOutputVar = b->B.var
            let childCode =
              b->B.run(
                ~builder=childStruct.serializeOperationBuilder,
                ~struct=childStruct,
                ~inputVar=itemVar,
                ~outputVar=childOutputVar,
                ~pathVar=`${pathVar}+'["'+${keyVar}+'"]'`,
              )

            `${itemVar}=${inputVar}[${keyVar}];${childCode}${outputVar}[${keyVar}]=${childOutputVar}`
          })}}`
      }),
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
      ~parseOperationBuilder=Builder.make((.
        b,
        ~selfStruct as _,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        let childOutputVar = b->B.var
        let childCode =
          b->B.run(
            ~builder=childStruct.parseOperationBuilder,
            ~struct=childStruct,
            ~inputVar,
            ~outputVar=childOutputVar,
            ~pathVar,
          )
        let isChildAsync = childStruct.isAsyncParse->(Obj.magic: isAsyncParse => bool)

        let defaultValVar = `${b->B.embed(getDefaultValue)}()`

        `if(${inputVar}!==void 0){${childCode}${b->B.embedSyncOperation(
            ~inputVar=childOutputVar,
            ~outputVar,
            ~pathVar,
            ~isSafe=true,
            ~fn=%raw("Caml_option.some"),
            (),
          )}}else{${outputVar}=${switch isChildAsync {
          | false => defaultValVar
          | true => `()=>Promise.resolve(${defaultValVar})`
          }}}`
      }),
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
      ~parseOperationBuilder=Builder.make((.
        b,
        ~selfStruct as _,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        let codeRef = ref(
          `if(!Array.isArray(${inputVar})){${b->B.raiseWithArg(
              ~pathVar,
              (. input) => InvalidType({
                expected: "Tuple",
                received: input->Stdlib.Unknown.toName,
              }),
              inputVar,
            )}}if(${inputVar}.length!==${numberOfStructs->Stdlib.Int.unsafeToString}){${b->B.raiseWithArg(
              ~pathVar,
              (. numberOfInputItems) => InvalidTupleSize({
                expected: numberOfStructs,
                received: numberOfInputItems,
              }),
              `${inputVar}.length`,
            )}}`,
        )
        switch structs {
        | [] => codeRef.contents ++ `${outputVar}=void 0;`
        | [itemStruct] => {
            let childCode =
              b->B.run(
                ~builder=itemStruct.parseOperationBuilder,
                ~struct=itemStruct,
                ~inputVar=`${inputVar}[0]`,
                ~outputVar,
                ~pathVar=`${pathVar}+'["0"]'`,
              )
            codeRef.contents ++ childCode
          }
        | _ => {
            let asyncItemVars = []
            // TODO: Stop using syncOutputVar in favor on outputVar and move var reasignment to the async part
            let syncOutputVar = b->B.var
            codeRef.contents = codeRef.contents ++ `${syncOutputVar}=[];`
            for idx in 0 to structs->Js.Array2.length - 1 {
              let itemStruct = structs->Js.Array2.unsafe_get(idx)
              let childOutputVar = b->B.var
              let childCode =
                b->B.run(
                  ~builder=itemStruct.parseOperationBuilder,
                  ~struct=itemStruct,
                  ~inputVar=`${inputVar}[${idx->Stdlib.Int.unsafeToString}]`,
                  ~outputVar=childOutputVar,
                  ~pathVar=`${pathVar}+'["${idx->Stdlib.Int.unsafeToString}"]'`,
                )
              let isAsyncItem = itemStruct.isAsyncParse->(Obj.magic: isAsyncParse => bool)

              let destVar = `${syncOutputVar}[${idx->Stdlib.Int.unsafeToString}]`
              codeRef.contents = codeRef.contents ++ `${childCode}${destVar}=${childOutputVar};`
              if isAsyncItem {
                asyncItemVars->Js.Array2.push(destVar)->ignore
              }
            }

            if asyncItemVars->Js.Array2.length === 0 {
              codeRef.contents ++ `${outputVar}=${syncOutputVar};`
            } else {
              let resolveVar = b->B.varWithoutAllocation
              let rejectVar = b->B.varWithoutAllocation
              let asyncParseResultVar = b->B.varWithoutAllocation
              let counterVar = b->B.varWithoutAllocation

              `${codeRef.contents}${outputVar}=()=>new Promise((${resolveVar},${rejectVar})=>{let ${counterVar}=${asyncItemVars
                ->Js.Array2.length
                ->Js.Int.toString};${asyncItemVars
                ->Js.Array2.map(asyncItemVar => {
                  `${asyncItemVar}().then(${asyncParseResultVar}=>{${asyncItemVar}=${asyncParseResultVar};if(${counterVar}--===1){${resolveVar}(${syncOutputVar})}},${rejectVar})`
                })
                ->Js.Array2.joinWith(";")}});`
            }
          }
        }
      }),
      ~serializeOperationBuilder=switch structs {
      | [] =>
        Builder.make((. _b, ~selfStruct as _, ~inputVar as _, ~outputVar, ~pathVar as _) => {
          `${outputVar}=[];`
        })
      | [_] =>
        Builder.make((. _b, ~selfStruct as _, ~inputVar, ~outputVar, ~pathVar as _) => {
          `${outputVar}=[${inputVar}];`
        })
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
      ~parseOperationBuilder=Builder.make((. b, ~selfStruct, ~inputVar, ~outputVar, ~pathVar) => {
        let structs = selfStruct->classify->unsafeGetVariantPayload

        let errorVars = []
        let asyncItems = Js.Dict.empty()
        let withAsyncItemRef = ref(false)
        let syncOutputVar = b->B.var

        let codeRef = ref("")
        let codeEndRef = ref("")

        for idx in 0 to structs->Js.Array2.length - 1 {
          let itemStruct = structs->Js.Array2.unsafe_get(idx)
          let childOutputVar = b->B.var
          let childCode =
            b->B.run(
              ~builder=itemStruct.parseOperationBuilder,
              ~struct=itemStruct,
              ~inputVar,
              ~outputVar=childOutputVar,
              ~pathVar=`""`,
            )
          let isAsyncItem = itemStruct.isAsyncParse->(Obj.magic: isAsyncParse => bool)

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
                : `${syncOutputVar}=`}${childOutputVar}}catch(${errorVar}){if(${b->B.isInternalError(
                errorVar,
              )}${isAsyncItem ? `||${errorVar}===${childOutputVar}` : ""}){`
          codeEndRef.contents = `}else{throw ${errorVar}}}` ++ codeEndRef.contents
        }

        if withAsyncItemRef.contents {
          codeRef.contents = codeRef.contents ++ `${outputVar}=()=>Promise.any([`
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
            `]).catch(t=>{${b->B.raiseWithArg(
                ~pathVar,
                (. internalErrors) => {
                  InvalidUnion(internalErrors->Js.Array2.map(Error.Internal.toParseError))
                },
                `t.errors`,
              )}})`

          codeRef.contents ++
          codeEndRef.contents ++
          `if(!${outputVar}){${outputVar}=()=>Promise.resolve(${syncOutputVar})}`
        } else {
          codeRef.contents ++
          b->B.raiseWithArg(
            ~pathVar,
            (. internalErrors) => InvalidUnion(
              internalErrors->Js.Array2.map(Error.Internal.toParseError),
            ),
            `[${errorVars->Js.Array2.toString}]`,
          ) ++
          codeEndRef.contents ++
          `${outputVar}=${syncOutputVar};`
        }
      }),
      ~serializeOperationBuilder=Builder.make((.
        b,
        ~selfStruct,
        ~inputVar,
        ~outputVar,
        ~pathVar,
      ) => {
        let structs = selfStruct->classify->unsafeGetVariantPayload

        let errorVars = []

        let codeRef = ref("")
        let codeEndRef = ref("")

        for idx in 0 to structs->Js.Array2.length - 1 {
          let itemStruct = structs->Js.Array2.unsafe_get(idx)
          let childOutputVar = b->B.var
          let childCode =
            b->B.run(
              ~builder=itemStruct.serializeOperationBuilder,
              ~struct=itemStruct,
              ~inputVar,
              ~outputVar=childOutputVar,
              ~pathVar=`""`,
            )
          let errorVar = b->B.varWithoutAllocation
          errorVars->Js.Array2.push(errorVar)->ignore

          codeRef.contents =
            codeRef.contents ++
            `try{${childCode}${outputVar}=${childOutputVar}}catch(${errorVar}){if(${b->B.isInternalError(
                errorVar,
              )}){`
          codeEndRef.contents = `}else{throw ${errorVar}}}` ++ codeEndRef.contents
        }

        codeRef.contents ++
        b->B.raiseWithArg(
          ~pathVar,
          (. internalErrors) => InvalidUnion(
            internalErrors->Js.Array2.map(Error.Internal.toSerializeError),
          ),
          `[${errorVars->Js.Array2.toString}]`,
        ) ++
        codeEndRef.contents
      }),
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
      Error.Internal.raise(
        ~path,
        ~code=InvalidType({
          expected: "JSON",
          received: input->Stdlib.Unknown.toName,
        }),
      )
    }
  }

  make(
    ~name="JSON",
    ~tagged=JSON,
    ~metadataMap=emptyMetadataMap,
    ~parseOperationBuilder=Builder.make((.
      b,
      ~selfStruct as _,
      ~inputVar,
      ~outputVar,
      ~pathVar,
    ) => {
      `${outputVar}=${b->B.embed(parse)}(${inputVar},${pathVar});`
    }),
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
    ~parseOperationBuilder=Builder.make((.
      b,
      ~selfStruct as _,
      ~inputVar,
      ~outputVar,
      ~pathVar,
    ) => {
      let childOutputVar = b->B.var
      let childCode =
        b->B.run(
          ~builder=struct.parseOperationBuilder,
          ~struct,
          ~inputVar,
          ~outputVar=childOutputVar,
          ~pathVar,
        )
      let isAsync = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)

      let fallbackValVar = `${b->B.embed((input, internalError) =>
          getFallbackValue->Stdlib.Fn.call1({
            input,
            error: internalError->Error.Internal.toParseError,
          })
        )}(${inputVar},t)`

      // FIXME:
      if isAsync {
        `try{${childCode}${outputVar}=()=>{try{return ${childOutputVar}().catch(t=>{if(${b->B.isInternalError(
            "t",
          )}){return ${fallbackValVar}}else{throw t}})}catch(t){if(${b->B.isInternalError(
            "t",
          )}){return Promise.resolve(${fallbackValVar})}else{throw t}}}}catch(t){if(${b->B.isInternalError(
            "t",
          )}){${outputVar}=()=>Promise.resolve(${fallbackValVar})}else{throw t}}`
      } else {
        `try{${childCode}}catch(t){if(${b->B.isInternalError(
            "t",
          )}){${childOutputVar}=${fallbackValVar}}else{throw t}}${outputVar}=${childOutputVar};`
      }
    }),
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
  // TODO: Do it another way
  let rec toVariantName = struct => {
    switch struct->classify {
    | Literal(String(string)) => string
    | Literal(Number(float)) => float->Js.Float.toString
    | Literal(Boolean(true)) => `True`
    | Literal(Boolean(false)) => `False`
    | Literal(Undefined) => `Undefined`
    | Literal(Null) => `Null`
    | Literal(NaN) => `NaN`
    // TODO: Support recursive literal
    | Literal(_) => `Literal`
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
        | Number(float) => `Number(${float->Stdlib.Inlined.Float.toRescript})`
        | Boolean(bool) => `Bool(${bool->Stdlib.Bool.toString})`
        | Undefined => `Undefined`
        | Null => `EmptyNull`
        | NaN => `NaN`
        // TODO:
        | _ => `NaN`
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
    | Int =>
      // TODO:| Literal(Int(_))
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
    | Float =>
      // TODO: | Literal(Float(_))
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
let unit = Literal.factory(%raw("void 0"))
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
