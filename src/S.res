// Enforce uncurried mode
// because the package will work incorrectly with Curry
@@uncurried

type never

external castAnyToUnknown: 'any => unknown = "%identity"
external castUnknownToAny: unknown => 'any = "%identity"

module Obj = {
  external magic: 'a => 'b = "%identity"
}

module Stdlib = {
  module Type = {
    type t = [#undefined | #object | #boolean | #number | #bigint | #string | #symbol | #function]

    external typeof: 'a => t = "#typeof"
  }

  module Promise = {
    type t<+'a> = promise<'a>

    @send
    external thenResolveWithCatch: (t<'a>, 'a => 'b, Js.Exn.t => 'b) => t<'b> = "then"

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

    let isArray = Js.Array2.isArray
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
      Js.Dict.unsafeDeleteKey(dict->(Obj.magic: Js.Dict.t<'a> => Js.Dict.t<string>), key)
    }

    let mapValues: (Js.Dict.t<'a>, 'a => 'b) => Js.Dict.t<'b> = %raw(`(dict, fn)=>{
      var key,newDict = {};
      for (key in dict) {
        newDict[key] = fn(dict[key])
      }
      return newDict
    }`)

    let every: (Js.Dict.t<'a>, 'a => bool) => bool = %raw(`(dict, fn)=>{
      for (var key in dict) {
        if (!fn(dict[key])) {
          return false
        }
      }
      return true
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
      _make([ctxVarName1, ctxVarName2, `return ${inlinedFunction}`])(ctxVarValue1, ctxVarValue2)
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
}

module Literal = {
  open Stdlib

  type rec t =
    | String(string)
    | Number(float)
    | Boolean(bool)
    | BigInt(Js.Types.bigint_val)
    | Symbol(Js.Types.symbol)
    | Array(array<t>)
    | Dict(Js.Dict.t<t>)
    | Function(Js.Types.function_val)
    | Object(Js.Types.obj_val)
    | Null
    | Undefined
    | NaN

  let rec classify = (value): t => {
    let typeOfValue = value->Type.typeof
    switch typeOfValue {
    | #undefined => Undefined
    | #object if value === %raw(`null`) => Null
    | #object if value->Stdlib.Array.isArray =>
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

  let rec value = literal => {
    switch literal {
    | NaN => %raw(`NaN`)
    | Undefined => %raw(`undefined`)
    | Null => %raw(`null`)
    | Number(v) => v->castAnyToUnknown
    | Boolean(v) => v->castAnyToUnknown
    | BigInt(v) => v->castAnyToUnknown
    | String(v) => v->castAnyToUnknown
    | Object(v) => v->castAnyToUnknown
    | Function(v) => v->castAnyToUnknown
    | Symbol(v) => v->castAnyToUnknown
    | Array(v) => v->Js.Array2.map(value)->castAnyToUnknown
    | Dict(v) => v->Dict.mapValues(value)->castAnyToUnknown
    }
  }

  let rec isJsonable = literal => {
    switch literal {
    | Null
    | Number(_)
    | Boolean(_)
    | String(_) => true
    | NaN
    | Undefined
    | BigInt(_)
    | Object(_)
    | Function(_)
    | Symbol(_) => false
    | Array(v) => v->Js.Array2.every(isJsonable)
    | Dict(v) => v->Dict.every(isJsonable)
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
    | Function(_) => "[object Function]"
    | Symbol(v) => v->Symbol.toString
    | Array(v) => `[${v->Js.Array2.map(toText)->Js.Array2.joinWith(", ")}]`
    | Dict(v) =>
      `{${v
        ->Js.Dict.keys
        ->Js.Array2.map(key =>
          `${key->Inlined.Value.fromString}: ${toText(v->Js.Dict.unsafeGet(key))}`
        )
        ->Js.Array2.joinWith(", ")}}`
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
  let fromInlinedLocation = inlinedLocation => `[${inlinedLocation}]`

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
  @as("t")
  tagged: tagged,
  @as("pb")
  mutable parseOperationBuilder: builder,
  @as("sb")
  mutable serializeOperationBuilder: builder,
  @as("i")
  mutable isAsyncParse: isAsyncParse,
  @as("s")
  mutable serialize: unknown => unknown,
  @as("j")
  mutable serializeToJson: unknown => Js.Json.t,
  @as("p")
  mutable parse: unknown => unknown,
  @as("a")
  mutable parseAsync: unknown => unit => promise<unknown>,
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
  | Literal(Literal.t)
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
type rec error = {operation: operation, code: errorCode, path: Path.t}
and errorCode =
  | OperationFailed(string)
  | MissingOperation({description: string})
  | InvalidType({expected: struct<unknown>, received: unknown})
  | InvalidLiteral({expected: Literal.t, received: unknown})
  | InvalidTupleSize({expected: int, received: int})
  | ExcessField(string)
  | InvalidUnion(array<error>)
  | UnexpectedAsync
  | InvalidJsonStruct(struct<unknown>)
and operation =
  | Serializing
  | Parsing

external castUnknownStructToAnyStruct: t<unknown> => t<'any> = "%identity"
external toUnknown: t<'any> => t<unknown> = "%identity"

module InternalError = {
  type t = {
    @as("c")
    code: errorCode,
    @as("p")
    path: Path.t,
    @as("s")
    symbol: Stdlib.Symbol.t,
  }

  @inline
  let raise = (~path, ~code) => {
    Stdlib.Exn.raiseAny({code, path, symbol})
  }

  let toParseError = (internalError: t) => {
    {
      operation: Parsing,
      code: internalError.code,
      path: internalError.path,
    }
  }

  let toSerializeError = (internalError: t) => {
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

  @inline
  let panic = message => Stdlib.Exn.raiseError(Stdlib.Exn.makeError(`[rescript-struct] ${message}`))

  module MissingParserAndSerializer = {
    let panic = location => panic(`For a ${location} either a parser, or a serializer is required`)
  }
}

@inline
let classify = struct => struct.tagged

type payloadedVariant<'payload> = {_0: 'payload}
let unsafeGetVariantPayload = variant => (variant->Obj.magic)._0

let emptyMetadataMap = Js.Dict.empty()

// TODO: Clean up
module TransformationFactory = {
  let call = (public, ~struct) =>
    (
      public->(
        Obj.magic: ((~struct: struct<'value>) => transformation<'input, 'output>) => (
          ~struct: struct<unknown>,
        ) => transformation<unknown, unknown>
      )
    )(~struct)
}

module Builder = {
  type t = builder
  type ctx = {
    @as("v")
    mutable varCounter: int,
    @as("l")
    mutable varsAllocation: string,
    @as("c")
    mutable code: string,
    @as("a")
    asyncVars: Stdlib.Set.t<string>,
    @as("e")
    embeded: array<unknown>,
  }
  type implementation = (
    ctx,
    ~selfStruct: struct<unknown>,
    ~inputVar: string,
    ~pathVar: string,
  ) => string

  let make = (Obj.magic: implementation => t)

  // TODO: Noop checks stopped working
  let noop = make((_b, ~selfStruct as _, ~inputVar, ~pathVar as _) => {
    inputVar
  })

  let noopOperation = a => a

  module Ctx = {
    type t = ctx

    @inline
    let embed = (b: t, value) => {
      `e[${(b.embeded->Js.Array2.push(value->castAnyToUnknown)->(Obj.magic: int => float) -. 1.)
          ->(Obj.magic: float => string)}]`
    }

    let scope = (b: t, fn) => {
      let prevVarsAllocation = b.varsAllocation
      let prevCode = b.code
      b.varsAllocation = ""
      b.code = ""
      let resultCode = fn(b)
      let varsAllocation = b.varsAllocation
      let code = varsAllocation === "" ? b.code : `let ${varsAllocation};${b.code}`
      b.varsAllocation = prevVarsAllocation
      b.code = prevCode
      code ++ resultCode
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

    @inline
    let isInternalError = (_b: t, var) => {
      `${var}&&${var}.s===s`
    }

    // TODO: Figure out how to make it better
    // Move S.fail to ctx and have path embeded from the begining
    let internalTransformRethrow = (b: t, ~pathVar) => {
      `if(${b->isInternalError("t")}){t.p=${pathVar}+t.p}throw t`
    }

    let embedSyncOperation = (
      b: t,
      ~inputVar,
      ~pathVar,
      ~fn: 'input => 'output,
      ~isSafe=false,
      ~isRefine=false,
      (),
    ) => {
      let outputVar = b->var
      b.code =
        b.code ++
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
      outputVar
    }

    let embedAsyncOperation = (
      b: t,
      ~inputVar,
      ~pathVar,
      ~fn: 'input => unit => promise<'output>,
      ~isRefine=false,
      (),
    ) => {
      let {asyncVars} = b
      let isAsyncInput = asyncVars->Stdlib.Set.has(inputVar)
      let outputVar = b->var
      asyncVars->Stdlib.Set.add(outputVar)->ignore
      b.code =
        b.code ++
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
      outputVar
    }

    let raiseWithArg = (b: t, ~pathVar, fn: 'arg => errorCode, arg) => {
      `${b->embed((path, arg) => {
          InternalError.raise(~path, ~code=fn(arg))
        })}(${pathVar},${arg})`
    }

    let missingOperation = (b: t, ~pathVar, ~description) => {
      `${b->embed(path => {
          InternalError.raise(~path, ~code=MissingOperation({description: description}))
        })}(${pathVar});`
    }

    let run = (b: t, ~builder, ~struct, ~inputVar, ~pathVar) => {
      let asyncVarsCountBefore = b.asyncVars->Stdlib.Set.size
      let outputVar = (builder->(Obj.magic: builder => implementation))(
        b,
        ~selfStruct=struct,
        ~inputVar,
        ~pathVar,
      )
      let isAsync = b.asyncVars->Stdlib.Set.size > asyncVarsCountBefore
      if isAsync {
        b.asyncVars->Stdlib.Set.add(outputVar)->ignore
      }
      if struct.parseOperationBuilder === builder {
        struct.isAsyncParse = Value(isAsync)
      }
      outputVar
    }
  }

  let build = (builder, ~struct) => {
    if builder === noop {
      if struct.parseOperationBuilder === builder {
        struct.isAsyncParse = Value(false)
      }
      noopOperation
    } else {
      let intitialInputVar = "i"

      let b = {
        embeded: [],
        varCounter: -1,
        asyncVars: Stdlib.Set.empty(),
        code: "",
        varsAllocation: "",
      }

      let inlinedFunction = `${intitialInputVar}=>{${b->Ctx.scope(b => {
          let outputVar = b->Ctx.run(~builder, ~struct, ~inputVar=intitialInputVar, ~pathVar=`""`)
          `return ${outputVar}`
        })}}`
      // Js.log(inlinedFunction)
      Stdlib.Function.make2(
        ~ctxVarName1="e",
        ~ctxVarValue1=b.embeded,
        ~ctxVarName2="s",
        ~ctxVarValue2=symbol,
        ~inlinedFunction,
      )
    }
  }

  let compileParser = (struct, ~builder) => {
    let operation = builder->build(~struct)
    let isAsync = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
    struct.parse = isAsync
      ? _ => InternalError.raise(~path=Path.empty, ~code=UnexpectedAsync)
      : operation
    struct.parseAsync = isAsync
      ? operation->(Obj.magic: (unknown => unknown) => unknown => unit => promise<unknown>)
      : input => {
          let syncValue = operation(input)
          () => syncValue->Stdlib.Promise.resolve
        }
  }

  let compileSerializer = (struct, ~builder) => {
    let operation = builder->build(~struct)
    struct.serialize = operation
  }
}
// TODO: Split validation code and transformation code
module B = Builder.Ctx

let toLiteral = {
  let rec loop = struct => {
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

let initialSerialize = input => {
  let struct = %raw("this")
  struct->Builder.compileSerializer(~builder=struct.serializeOperationBuilder)
  struct.serialize(input)
}

let rec validateJsonableStruct = (struct, ~rootStruct, ~isRoot=false, ()) => {
  if isRoot || rootStruct !== struct {
    switch struct->classify {
    | String
    | Int
    | Float
    | Bool
    | Never
    | JSON => ()
    | Dict(struct)
    | Null(struct)
    | Array(struct) =>
      struct->validateJsonableStruct(~rootStruct, ())
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
        | Js.Exn.Error(jsExn) => jsExn->InternalError.prependLocationOrRethrow(fieldName)
        }
      }

    | Tuple(childrenStructs) =>
      childrenStructs->Js.Array2.forEachi((struct, i) => {
        try {
          struct->validateJsonableStruct(~rootStruct, ())
        } catch {
        // TODO: Should throw with the nested struct instead of prepending path?
        | Js.Exn.Error(jsExn) => jsExn->InternalError.prependLocationOrRethrow(i->Js.Int.toString)
        }
      })
    | Union(childrenStructs) =>
      childrenStructs->Js.Array2.forEach(struct => struct->validateJsonableStruct(~rootStruct, ()))
    | Literal(l) if l->Literal.isJsonable => ()
    | Option(_)
    | Unknown
    | Literal(_) =>
      InternalError.raise(~path=Path.empty, ~code=InvalidJsonStruct(struct))
    }
  }
}

let initialSerializeToJson = input => {
  let struct = %raw("this")
  try {
    struct->validateJsonableStruct(~rootStruct=struct, ~isRoot=true, ())
    if struct.serialize === initialSerialize {
      struct->Builder.compileSerializer(~builder=struct.serializeOperationBuilder)
    }
    struct.serializeToJson =
      struct.serialize->(Obj.magic: (unknown => unknown) => unknown => Js.Json.t)
  } catch {
  | Js.Exn.Error(jsExn) => {
      let error = jsExn->InternalError.getOrRethrow
      struct.serializeToJson = _ => Stdlib.Exn.raiseAny(error)
    }
  }
  struct.serializeToJson(input)
}

let intitialParse = input => {
  let struct = %raw("this")
  struct->Builder.compileParser(~builder=struct.parseOperationBuilder)
  struct.parse(input)
}

let intitialParseAsync = input => {
  let struct = %raw("this")
  struct->Builder.compileParser(~builder=struct.parseOperationBuilder)
  struct.parseAsync(input)
}

@inline
let make = (~tagged, ~metadataMap, ~parseOperationBuilder, ~serializeOperationBuilder, ()) => {
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

let advancedFail = (error: error) => {
  InternalError.raise(~path=error.path, ~code=error.code)
}

let fail = (~path=Path.empty, message) => {
  InternalError.raise(~path, ~code=OperationFailed(message))
}

exception Raised(error)

let parseAnyWith = (any, struct) => {
  try {
    struct.parse(any->castAnyToUnknown)->castUnknownToAny->Ok
  } catch {
  | Js.Exn.Error(jsExn) => jsExn->InternalError.getOrRethrow->InternalError.toParseError->Error
  }
}

let parseWith: (Js.Json.t, t<'value>) => result<'value, error> = parseAnyWith

let parseAnyOrRaiseWith = (any, struct) => {
  try {
    struct.parse(any->castAnyToUnknown)->castUnknownToAny
  } catch {
  | Js.Exn.Error(jsExn) =>
    raise(Raised(jsExn->InternalError.getOrRethrow->InternalError.toParseError))
  }
}

let parseOrRaiseWith: (Js.Json.t, t<'value>) => 'value = parseAnyOrRaiseWith

let asyncPrepareOk = value => Ok(value->castUnknownToAny)

let asyncPrepareError = jsExn => {
  jsExn->InternalError.getOrRethrow->InternalError.toParseError->Error
}

let parseAnyAsyncWith = (any, struct) => {
  try {
    struct.parseAsync(any->castAnyToUnknown)()->Stdlib.Promise.thenResolveWithCatch(
      asyncPrepareOk,
      asyncPrepareError,
    )
  } catch {
  | Js.Exn.Error(jsExn) =>
    jsExn->InternalError.getOrRethrow->InternalError.toParseError->Error->Stdlib.Promise.resolve
  }
}

let parseAsyncWith = parseAnyAsyncWith

let parseAnyAsyncInStepsWith = (any, struct) => {
  try {
    let asyncFn = struct.parseAsync(any->castAnyToUnknown)

    (() => asyncFn()->Stdlib.Promise.thenResolveWithCatch(asyncPrepareOk, asyncPrepareError))->Ok
  } catch {
  | Js.Exn.Error(jsExn) => jsExn->InternalError.getOrRethrow->InternalError.toParseError->Error
  }
}

let parseAsyncInStepsWith = parseAnyAsyncInStepsWith

let serializeToUnknownWith = (value, struct) => {
  try {
    struct.serialize(value->castAnyToUnknown)->Ok
  } catch {
  | Js.Exn.Error(jsExn) => jsExn->InternalError.getOrRethrow->InternalError.toSerializeError->Error
  }
}

let serializeOrRaiseWith = (value, struct) => {
  try {
    struct.serializeToJson(value->castAnyToUnknown)
  } catch {
  | Js.Exn.Error(jsExn) =>
    raise(Raised(jsExn->InternalError.getOrRethrow->InternalError.toSerializeError))
  }
}

let serializeToUnknownOrRaiseWith = (value, struct) => {
  try {
    struct.serialize(value->castAnyToUnknown)
  } catch {
  | Js.Exn.Error(jsExn) =>
    raise(Raised(jsExn->InternalError.getOrRethrow->InternalError.toSerializeError))
  }
}

let serializeWith = (value, struct) => {
  try {
    struct.serializeToJson(value->castAnyToUnknown)->Ok
  } catch {
  | Js.Exn.Error(jsExn) => jsExn->InternalError.getOrRethrow->InternalError.toSerializeError->Error
  }
}

let serializeToJsonStringWith = (value: 'value, ~space=0, struct: t<'value>): result<
  string,
  error,
> => {
  switch value->serializeWith(struct) {
  | Ok(json) => Ok(json->Js.Json.stringifyWithSpace(space))
  | Error(_) as e => e
  }
}

let parseJsonStringWith = (json: string, struct: t<'value>): result<'value, error> => {
  switch try {
    json->Js.Json.parseExn->Ok
  } catch {
  | Js.Exn.Error(error) =>
    Error({
      code: OperationFailed(error->Js.Exn.message->(Obj.magic: option<string> => string)),
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
  let struct = fn(placeholder)
  placeholder->Stdlib.Object.overrideWith(struct)

  {
    let builder = placeholder.parseOperationBuilder
    placeholder.parseOperationBuilder = Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
      let isAsync = {
        selfStruct.parseOperationBuilder = Builder.noop
        let asyncVars = Stdlib.Set.empty()
        let _ = (builder->(Obj.magic: builder => Builder.implementation))(
          {
            Builder.embeded: [],
            varsAllocation: "",
            code: "",
            asyncVars,
            varCounter: -1,
          },
          ~selfStruct,
          ~inputVar,
          ~pathVar,
        )
        asyncVars->Stdlib.Set.size > 0
      }

      selfStruct.parseOperationBuilder = Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
        if isAsync {
          b->B.embedAsyncOperation(
            ~inputVar,
            ~pathVar,
            ~fn=input => selfStruct.parseAsync(input),
            (),
          )
        } else {
          b->B.embedSyncOperation(~inputVar, ~pathVar, ~fn=input => selfStruct.parse(input), ())
        }
      })

      selfStruct->Builder.compileParser(~builder)
      selfStruct.parseOperationBuilder = builder
      if isAsync {
        b->B.embedAsyncOperation(~inputVar, ~pathVar, ~fn=selfStruct.parseAsync, ())
      } else {
        b->B.embedSyncOperation(~inputVar, ~pathVar, ~fn=selfStruct.parse, ())
      }
    })
  }

  {
    let builder = placeholder.serializeOperationBuilder
    placeholder.serializeOperationBuilder = Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
      selfStruct.serializeOperationBuilder = Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
        b->B.embedSyncOperation(~inputVar, ~pathVar, ~fn=input => selfStruct.serialize(input), ())
      })
      selfStruct->Builder.compileSerializer(~builder)
      selfStruct.serializeOperationBuilder = builder
      b->B.embedSyncOperation(~inputVar, ~pathVar, ~fn=selfStruct.serialize, ())
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

  let make1: (
    Id.t<'metadata>,
    'metadata,
  ) => Js.Dict.t<unknown> = %raw(`(id,metadata)=>({[id]:metadata})`)

  let get = (struct, ~id: Id.t<'metadata>) => {
    struct.metadataMap->Js.Dict.unsafeGet(id->Id.toKey)->(Obj.magic: unknown => option<'metadata>)
  }

  let set = (struct, ~id: Id.t<'metadata>, metadata: 'metadata) => {
    let metadataMap =
      struct.metadataMap === emptyMetadataMap
        ? make1(id, metadata)
        : {
            let copy = struct.metadataMap->Stdlib.Dict.copy
            copy->Js.Dict.set(id->Id.toKey, metadata->castAnyToUnknown)
            copy
          }
    make(
      ~parseOperationBuilder=struct.parseOperationBuilder,
      ~serializeOperationBuilder=struct.serializeOperationBuilder,
      ~tagged=struct.tagged,
      ~metadataMap,
      (),
    )
  }
}

let nameMetadataId = Metadata.Id.make(~namespace="rescript-struct", ~name="name")

let rec name = struct => {
  switch struct->Metadata.get(~id=nameMetadataId) {
  | Some(n) => n
  | None => {
      let tagged = struct->classify
      switch tagged {
      | Literal(l) => `Literal(${l->Literal.toText})`
      | Union(structs) =>
        `Union(${structs
          ->Js.Array2.map(s => s->castUnknownStructToAnyStruct->name)
          ->Js.Array2.joinWith(", ")})`
      | Tuple(structs) =>
        `Tuple(${structs
          ->Js.Array2.map(s => s->castUnknownStructToAnyStruct->name)
          ->Js.Array2.joinWith(", ")})`
      | Object({fieldNames, fields}) =>
        `Object({${fieldNames
          ->Js.Array2.map(fieldName => {
            let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
            `${fieldName->Stdlib.Inlined.Value.fromString}: ${fieldStruct
              ->castUnknownStructToAnyStruct
              ->name}`
          })
          ->Js.Array2.joinWith(", ")}})`
      | Option(s) => `Option(${s->castUnknownStructToAnyStruct->name})`
      | Null(s) => `Null(${s->castUnknownStructToAnyStruct->name})`
      | Array(s) => `Array(${s->castUnknownStructToAnyStruct->name})`
      | Dict(s) => `Dict(${s->castUnknownStructToAnyStruct->name})`
      | String
      | Int
      | Float
      | Bool
      | Never
      | Unknown
      | JSON =>
        tagged->(Obj.magic: tagged => string)
      }
    }
  }
}

let setName = (struct, name) => {
  struct->Metadata.set(~id=nameMetadataId, name)
}

let asyncParserRefine = (struct, refiner) => {
  let struct = struct->toUnknown
  make(
    ~tagged=struct.tagged,
    ~parseOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
      b->B.embedAsyncOperation(
        ~inputVar=b->B.run(~builder=struct.parseOperationBuilder, ~struct, ~inputVar, ~pathVar),
        ~pathVar,
        ~fn=i => () => refiner(i),
        ~isRefine=true,
        (),
      )
    }),
    ~serializeOperationBuilder=struct.serializeOperationBuilder,
    ~metadataMap=struct.metadataMap,
    (),
  )
}

let refine: (t<'value>, 'value => unit) => t<'value> = (struct, refiner) => {
  let struct = struct->toUnknown
  make(
    ~tagged=struct.tagged,
    ~parseOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
      b->B.embedSyncOperation(
        ~inputVar=b->B.run(~builder=struct.parseOperationBuilder, ~struct, ~inputVar, ~pathVar),
        ~pathVar,
        ~fn=refiner,
        ~isRefine=true,
        (),
      )
    }),
    ~serializeOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
      b->B.run(
        ~builder=struct.parseOperationBuilder,
        ~struct,
        ~inputVar=b->B.embedSyncOperation(~inputVar, ~pathVar, ~fn=refiner, ~isRefine=true, ()),
        ~pathVar,
      )
    }),
    ~metadataMap=struct.metadataMap,
    (),
  )
}

let addRefinement = (struct, ~metadataId, ~refinement, ~refiner) => {
  struct
  ->Metadata.set(
    ~id=metadataId,
    switch struct->Metadata.get(~id=metadataId) {
    | Some(refinements) => refinements->Stdlib.Array.append(refinement)
    | None => [refinement]
    },
  )
  ->refine(refiner)
}

let advancedTransform: (
  t<'value>,
  ~parser: (~struct: t<'value>) => transformation<'value, 'transformed>=?,
  ~serializer: (~struct: t<'value>) => transformation<'transformed, 'value>=?,
  unit,
) => t<'transformed> = (struct, ~parser as maybeParser=?, ~serializer as maybeSerializer=?, ()) => {
  let struct = struct->toUnknown
  if maybeParser === None && maybeSerializer === None {
    InternalError.MissingParserAndSerializer.panic(`struct factory Transform`)
  }

  make(
    ~tagged=struct.tagged,
    ~parseOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
      switch maybeParser {
      | Some(parser) =>
        switch parser->TransformationFactory.call(
          ~struct=selfStruct->castUnknownStructToAnyStruct,
        ) {
        | Noop => b->B.run(~builder=struct.parseOperationBuilder, ~struct, ~inputVar, ~pathVar)
        | Sync(syncTransformation) =>
          b->B.embedSyncOperation(
            ~inputVar=b->B.run(~builder=struct.parseOperationBuilder, ~struct, ~inputVar, ~pathVar),
            ~pathVar,
            ~fn=syncTransformation,
            (),
          )
        | Async(asyncParser) =>
          b->B.embedAsyncOperation(
            ~inputVar=b->B.run(~builder=struct.parseOperationBuilder, ~struct, ~inputVar, ~pathVar),
            ~pathVar,
            ~fn=i => () => asyncParser(i),
            (),
          )
        }
      | None =>
        b->B.missingOperation(~pathVar, ~description=`The S.advancedTransform parser is missing`)
      }
    }),
    ~serializeOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
      switch maybeSerializer {
      | Some(serializer) =>
        switch serializer->TransformationFactory.call(
          ~struct=selfStruct->castUnknownStructToAnyStruct,
        ) {
        | Noop => b->B.run(~builder=struct.serializeOperationBuilder, ~struct, ~inputVar, ~pathVar)
        | Sync(fn) =>
          b->B.run(
            ~builder=struct.serializeOperationBuilder,
            ~struct,
            ~inputVar=b->B.embedSyncOperation(~inputVar, ~pathVar, ~fn, ()),
            ~pathVar,
          )
        | Async(_) =>
          b->B.missingOperation(
            ~pathVar,
            ~description=`The S.advancedTransform serializer doesn't support async`,
          )
        }
      | None =>
        b->B.missingOperation(
          ~pathVar,
          ~description=`The S.advancedTransform serializer is missing`,
        )
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
    InternalError.MissingParserAndSerializer.panic(`struct factory Transform`)
  }

  make(
    ~tagged=struct.tagged,
    ~parseOperationBuilder=switch (maybeParser, maybeAsyncParser) {
    | (Some(_), Some(_)) =>
      InternalError.panic(
        "The S.transform doesn't support the `parser` and `asyncParser` arguments simultaneously. Move `asyncParser` to another S.transform.",
      )
    | (Some(parser), None) =>
      Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        b->B.embedSyncOperation(
          ~inputVar=b->B.run(~builder=struct.parseOperationBuilder, ~struct, ~inputVar, ~pathVar),
          ~pathVar,
          ~fn=parser,
          (),
        )
      })
    | (None, Some(asyncParser)) =>
      Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        b->B.embedAsyncOperation(
          ~inputVar=b->B.run(~builder=struct.parseOperationBuilder, ~struct, ~inputVar, ~pathVar),
          ~pathVar,
          ~fn=i => () => asyncParser(i),
          (),
        )
      })
    | (None, None) =>
      Builder.make((b, ~selfStruct as _, ~inputVar as _, ~pathVar) => {
        b->B.missingOperation(~pathVar, ~description=`The S.transform parser is missing`)
      })
    },
    ~serializeOperationBuilder=switch maybeSerializer {
    | Some(serializer) =>
      Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        b->B.run(
          ~builder=struct.serializeOperationBuilder,
          ~struct,
          ~inputVar=b->B.embedSyncOperation(~inputVar, ~pathVar, ~fn=serializer, ()),
          ~pathVar,
        )
      })
    | None =>
      Builder.make((b, ~selfStruct as _, ~inputVar as _, ~pathVar) => {
        b->B.missingOperation(~pathVar, ~description=`The S.transform serializer is missing`)
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
    InternalError.MissingParserAndSerializer.panic(`struct factory Preprocess`)
  }

  switch struct->classify {
  | Union(unionStructs) =>
    make(
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
      ~tagged=struct.tagged,
      ~parseOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
        switch maybeParser {
        | Some(parser) =>
          switch parser->TransformationFactory.call(
            ~struct=selfStruct->castUnknownStructToAnyStruct,
          ) {
          | Noop => b->B.run(~builder=struct.parseOperationBuilder, ~struct, ~inputVar, ~pathVar)
          | Sync(syncTransformation) =>
            b->B.run(
              ~builder=struct.parseOperationBuilder,
              ~struct,
              ~inputVar=b->B.embedSyncOperation(~inputVar, ~pathVar, ~fn=syncTransformation, ()),
              ~pathVar,
            )
          | Async(asyncParser) => {
              let parseResultVar =
                b->B.embedAsyncOperation(~inputVar, ~pathVar, ~fn=i => () => asyncParser(i), ())
              let outputVar = b->B.var
              b.code =
                b.code ++
                `${outputVar}=()=>${parseResultVar}().then(t=>{${b->B.scope(b => {
                    let structOutputVar =
                      b->B.run(
                        ~builder=struct.parseOperationBuilder,
                        ~struct,
                        ~inputVar="t",
                        ~pathVar,
                      )
                    let isAsync = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
                    `return ${isAsync ? `${structOutputVar}()` : structOutputVar}`
                  })}});`
              outputVar
            }
          }
        | None =>
          b->B.missingOperation(~pathVar, ~description=`The S.advancedPreprocess parser is missing`)
        }
      }),
      ~serializeOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
        switch maybeSerializer {
        | Some(serializer) =>
          switch serializer->TransformationFactory.call(
            ~struct=selfStruct->castUnknownStructToAnyStruct,
          ) {
          | Noop =>
            b->B.run(~builder=struct.serializeOperationBuilder, ~struct, ~inputVar, ~pathVar)
          | Sync(fn) =>
            b->B.embedSyncOperation(
              ~inputVar=b->B.run(
                ~builder=struct.serializeOperationBuilder,
                ~struct,
                ~inputVar,
                ~pathVar,
              ),
              ~pathVar,
              ~fn,
              (),
            )
          | Async(_) =>
            b->B.missingOperation(
              ~pathVar,
              ~description=`The S.advancedPreprocess serializer doesn't support async`,
            )
          }
        | None =>
          b->B.missingOperation(
            ~pathVar,
            ~description=`The S.advancedPreprocess serializer is missing`,
          )
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
    InternalError.MissingParserAndSerializer.panic(`Custom struct factory`)
  }

  make(
    ~metadataMap=Metadata.make1(nameMetadataId, name),
    ~tagged=Unknown,
    ~parseOperationBuilder=switch (maybeParser, maybeAsyncParser) {
    | (Some(_), Some(_)) =>
      InternalError.panic(
        "The S.custom doesn't support the `parser` and `asyncParser` arguments simultaneously. Keep only `asyncParser`.",
      )
    | (Some(parser), None) =>
      Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        b->B.embedSyncOperation(~inputVar, ~fn=parser, ~pathVar, ())
      })
    | (None, Some(asyncParser)) =>
      Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        b->B.embedAsyncOperation(~inputVar, ~pathVar, ~fn=input => () => asyncParser(input), ())
      })
    | (None, None) =>
      Builder.make((b, ~selfStruct as _, ~inputVar as _, ~pathVar) => {
        b->B.missingOperation(~pathVar, ~description=`The S.custom parser is missing`)
      })
    },
    ~serializeOperationBuilder=switch maybeSerializer {
    | Some(serializer) =>
      Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        b->B.embedSyncOperation(~inputVar, ~fn=serializer, ~pathVar, ())
      })
    | None =>
      Builder.make((b, ~selfStruct as _, ~inputVar as _, ~pathVar) => {
        b->B.missingOperation(~pathVar, ~description=`The S.custom serializer is missing`)
      })
    },
    (),
  )
}

let rec literalCheckBuilder = (b, ~value, ~inputVar) => {
  if value->castUnknownToAny->Js.Float.isNaN {
    `Number.isNaN(${inputVar})`
  } else {
    let check = `${inputVar}===${b->B.embed(value)}`
    if value->Stdlib.Array.isArray {
      let value = value->(Obj.magic: unknown => array<unknown>)
      `(${check}||Array.isArray(${inputVar})&&${inputVar}.length===${value
        ->Js.Array2.length
        ->Stdlib.Int.unsafeToString}` ++
      (value->Js.Array2.length > 0
        ? "&&" ++
          value
          ->Js.Array2.mapi((item, idx) =>
            b->literalCheckBuilder(
              ~value=item,
              ~inputVar=`${inputVar}[${idx->Stdlib.Int.unsafeToString}]`,
            )
          )
          ->Js.Array2.joinWith("&&")
        : "") ++ ")"
    } else if (
      value !== %raw(`null`) &&
      value->Stdlib.Type.typeof === #object &&
      (value->(Obj.magic: 'a => {"constructor": unknown}))["constructor"] === %raw("Object")
    ) {
      let value = value->(Obj.magic: unknown => Js.Dict.t<unknown>)
      let keys = value->Js.Dict.keys
      let numberOfKeys = keys->Js.Array2.length
      `(${check}||${inputVar}!==null&&${inputVar}.constructor===Object&&Object.keys(${inputVar}).length===${numberOfKeys->Stdlib.Int.unsafeToString}` ++
      (numberOfKeys > 0
        ? "&&" ++
          keys
          ->Js.Array2.map(key => {
            b->literalCheckBuilder(
              ~value=value->Js.Dict.unsafeGet(key),
              ~inputVar=`${inputVar}[${key->Stdlib.Inlined.Value.fromString}]`,
            )
          })
          ->Js.Array2.joinWith("&&")
        : "") ++ ")"
    } else {
      check
    }
  }
}

let literal = value => {
  let value = value->castAnyToUnknown
  let literal = value->Literal.classify
  let operationBuilder = Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
    b.code =
      b.code ++
      `${b->literalCheckBuilder(~value, ~inputVar)}||${b->B.raiseWithArg(
          ~pathVar,
          input => InvalidLiteral({
            expected: literal,
            received: input,
          }),
          inputVar,
        )};`
    inputVar
  })
  make(
    ~metadataMap=emptyMetadataMap,
    ~tagged=Literal(literal),
    ~parseOperationBuilder=operationBuilder,
    ~serializeOperationBuilder=operationBuilder,
    (),
  )
}

module Definition = {
  type t<'embeded>
  type node<'embeded> = Js.Dict.t<t<'embeded>>
  type kind = | @as(0) Node | @as(1) Constant | @as(2) Embeded

  let toKindWithSet = (definition: t<'embeded>, ~embededSet: Stdlib.Set.t<'embeded>) => {
    if embededSet->Stdlib.Set.has(definition->(Obj.magic: t<'embeded> => 'embeded)) {
      Embeded
    } else if definition->Stdlib.Type.typeof === #object && definition !== %raw(`null`) {
      Node
    } else {
      Constant
    }
  }

  @inline
  let toKindWithValue = (definition: t<'embeded>, ~embeded: 'embeded) => {
    if embeded === definition->(Obj.magic: t<'embeded> => 'embeded) {
      Embeded
    } else if definition->Stdlib.Type.typeof === #object && definition !== %raw(`null`) {
      Node
    } else {
      Constant
    }
  }

  let toConstant = (Obj.magic: t<'embeded> => unknown)
  let toEmbeded = (Obj.magic: t<'embeded> => 'embeded)
  let toNode = (Obj.magic: t<'embeded> => node<'embeded>)
}

module Variant = {
  @unboxed
  type serializeOutput = Registered(string) | @as(0) Unregistered | @as(1) RegisteredMultipleTimes

  let factory = {
    (struct: t<'value>, definer: 'value => 'variant): t<'variant> => {
      let struct = struct->toUnknown
      make(
        ~tagged=struct.tagged,
        ~parseOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
          b->B.embedSyncOperation(
            ~inputVar=b->B.run(~builder=struct.parseOperationBuilder, ~struct, ~inputVar, ~pathVar),
            ~pathVar,
            ~fn=definer,
            ~isSafe=true,
            (),
          )
        }),
        ~serializeOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
          let definition =
            definer(symbol->(Obj.magic: Stdlib.Symbol.t => 'value))->(
              Obj.magic: 'variant => Definition.t<Stdlib.Symbol.t>
            )

          let output = {
            // TODO: Check that it might be not an object in union
            let rec definitionToOutput = (
              definition: Definition.t<Stdlib.Symbol.t>,
              ~outputPath,
            ) => {
              let kind = definition->Definition.toKindWithValue(~embeded=symbol)
              switch kind {
              | Embeded => Registered(`${inputVar}${outputPath}`)
              | Constant => {
                  let constant = definition->Definition.toConstant
                  let constantVar = b->B.var
                  b.code =
                    b.code ++
                    `${constantVar}=${inputVar}${outputPath};if(${constantVar}!==${b->B.embed(
                        constant,
                      )}){${b->B.raiseWithArg(
                        ~pathVar=`${pathVar}+${outputPath->Stdlib.Inlined.Value.fromString}`,
                        input => InvalidLiteral({
                          expected: constant->Literal.classify,
                          received: input,
                        }),
                        constantVar,
                      )}}`
                  Unregistered
                }
              | Node => {
                  let node = definition->Definition.toNode
                  let keys = node->Js.Dict.keys
                  let maybeOutputRef = ref(Unregistered)
                  for idx in 0 to keys->Js.Array2.length - 1 {
                    let key = keys->Js.Array2.unsafe_get(idx)
                    let definition = node->Js.Dict.unsafeGet(key)
                    let maybeOutput = definitionToOutput(
                      definition,
                      ~outputPath=Path.concat(outputPath, Path.fromLocation(key)),
                    )
                    switch (maybeOutputRef.contents, maybeOutput) {
                    | (Registered(_), Registered(_))
                    | (Registered(_), RegisteredMultipleTimes) =>
                      maybeOutputRef.contents = RegisteredMultipleTimes
                    | (RegisteredMultipleTimes, _)
                    | (Registered(_), Unregistered) => ()
                    | (Unregistered, _) => maybeOutputRef.contents = maybeOutput
                    }
                  }
                  maybeOutputRef.contents
                }
              }
            }
            definitionToOutput(definition, ~outputPath=Path.empty)
          }

          switch output {
          | RegisteredMultipleTimes => {
              b.code =
                b->B.missingOperation(
                  ~pathVar,
                  ~description=`Can't create serializer. The S.variant's value is registered multiple times. Use S.transform instead`,
                )
              inputVar
            }
          | Registered(var) =>
            b->B.run(~builder=struct.serializeOperationBuilder, ~struct, ~inputVar=var, ~pathVar)
          | Unregistered =>
            switch selfStruct->toLiteral {
            | Some(literal) =>
              b->B.run(
                ~builder=struct.serializeOperationBuilder,
                ~struct,
                ~inputVar=b->B.embed(literal->Literal.value),
                ~pathVar,
              )
            | None => {
                b.code =
                  b->B.missingOperation(
                    ~pathVar,
                    ~description=`Can't create serializer. The S.variant's value is not registered and not a literal. Use S.transform instead`,
                  )
                inputVar
              }
            }
          }
        }),
        ~metadataMap=struct.metadataMap,
        (),
      )
    }
  }
}

module Object = {
  type ctx = {
    @as("f") field: 'value. (string, t<'value>) => 'value,
    @as("t") tag: 'value. (string, 'value) => unit,
  }

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
      struct: struct<unknown>,
      @as("l")
      inlinedInputLocation: string,
      @as("p")
      inputPath: Path.t,
      @as("r")
      mutable isRegistered: bool,
    }
  }

  module Ctx = {
    type t = {
      @as("n")
      fieldNames: array<string>,
      @as("h")
      fields: Js.Dict.t<struct<unknown>>,
      @as("d")
      fieldDefinitionsSet: Stdlib.Set.t<FieldDefinition.t>,
      ...ctx,
    }

    @inline
    let make = () => {
      let fields = Js.Dict.empty()
      let fieldNames = []
      let fieldDefinitionsSet = Stdlib.Set.empty()

      let field:
        type value. (string, struct<value>) => value =
        (fieldName, struct) => {
          let struct = struct->toUnknown
          switch fields->Stdlib.Dict.has(fieldName) {
          | true =>
            InternalError.panic(
              `The field "${fieldName}" is defined multiple times. If you want to duplicate a field, use S.transform instead.`,
            )
          | false => {
              let inlinedInputLocation = fieldName->Stdlib.Inlined.Value.fromString
              let fieldDefinition: FieldDefinition.t = {
                struct,
                inlinedInputLocation,
                inputPath: inlinedInputLocation->Path.fromInlinedLocation,
                isRegistered: false,
              }
              fields->Js.Dict.set(fieldName, struct)
              fieldNames->Js.Array2.push(fieldName)->ignore
              fieldDefinitionsSet->Stdlib.Set.add(fieldDefinition)->ignore
              fieldDefinition->(Obj.magic: FieldDefinition.t => value)
            }
          }
        }

      let tag = (tag, asValue) => {
        let _ = field(tag, literal(asValue))
      }

      {
        fieldNames,
        fields,
        fieldDefinitionsSet,
        // methods
        field,
        tag,
      }
    }
  }

  // TODO: get rid of
  let rec validateDefinition = (
    definition: Definition.t<FieldDefinition.t>,
    ~ctx: Ctx.t,
    ~path,
  ) => {
    let kind = definition->Definition.toKindWithSet(~embededSet=ctx.fieldDefinitionsSet)
    switch kind {
    | Constant => ()
    | Embeded => {
        let fieldDefinition = definition->Definition.toEmbeded
        if fieldDefinition.isRegistered {
          InternalError.panic(
            `The field ${fieldDefinition.inlinedInputLocation} is registered multiple times. If you want to duplicate a field, use S.transform instead.`,
          )
        } else {
          fieldDefinition.isRegistered = true
        }
      }
    | Node => {
        let node = definition->Definition.toNode
        let keys = node->Js.Dict.keys
        for idx in 0 to keys->Js.Array2.length - 1 {
          let key = keys->Js.Array2.unsafe_get(idx)
          let definition = node->Js.Dict.unsafeGet(key)
          definition->validateDefinition(~ctx, ~path=path->Path.concat(key->Path.fromLocation))
        }
      }
    }
  }

  let factory = definer => {
    let ctx = Ctx.make()
    let definition = definer((ctx :> ctx))->(Obj.magic: 'any => Definition.t<FieldDefinition.t>)
    definition->validateDefinition(~ctx, ~path=Path.empty)
    let {fieldDefinitionsSet, fields, fieldNames} = ctx
    let fieldDefinitions = fieldDefinitionsSet->Stdlib.Set.toArray

    make(
      ~metadataMap=emptyMetadataMap,
      ~tagged=Object({
        fields,
        fieldNames,
      }),
      ~parseOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
        let asyncOutputVars = []

        b.code =
          b.code ++
          `if(!(typeof ${inputVar}==="object"&&${inputVar}!==null&&!Array.isArray(${inputVar}))){${b->B.raiseWithArg(
              ~pathVar,
              input => InvalidType({
                expected: selfStruct,
                received: input,
              }),
              inputVar,
            )}}`

        for idx in 0 to fieldDefinitions->Js.Array2.length - 1 {
          let {struct, inputPath, isRegistered} = fieldDefinitions->Js.Array2.unsafe_get(idx)
          if !isRegistered {
            let fieldInputVar = b->B.var
            b.code = b.code ++ `${fieldInputVar}=${inputVar}${inputPath};`
            let fieldOuputVar =
              b->B.run(
                ~builder=struct.parseOperationBuilder,
                ~struct,
                ~inputVar=fieldInputVar,
                ~pathVar=`${pathVar}+${inputPath->Stdlib.Inlined.Value.fromString}`,
              )
            let isAsyncField = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
            if isAsyncField {
              // TODO: Ensure that it's not a var, but inlined
              asyncOutputVars->Js.Array2.push(fieldOuputVar)->ignore
            }
          }
        }

        let withUnknownKeysRefinement = selfStruct->UnknownKeys.classify === UnknownKeys.Strict
        switch (withUnknownKeysRefinement, fieldDefinitions) {
        | (true, []) => {
            let keyVar = b->B.var
            b.code =
              b.code ++
              `for(${keyVar} in ${inputVar}){${b->B.raiseWithArg(
                  ~pathVar,
                  exccessFieldName => ExcessField(exccessFieldName),
                  keyVar,
                )}}`
          }
        | (true, _) => {
            let keyVar = b->B.var
            b.code = b.code ++ `for(${keyVar} in ${inputVar}){if(`
            for idx in 0 to fieldDefinitions->Js.Array2.length - 1 {
              let fieldDefinition = fieldDefinitions->Js.Array2.unsafe_get(idx)
              if idx !== 0 {
                b.code = b.code ++ "&&"
              }
              b.code = b.code ++ `${keyVar}!==${fieldDefinition.inlinedInputLocation}`
            }
            b.code =
              b.code ++
              `){${b->B.raiseWithArg(
                  ~pathVar,
                  exccessFieldName => ExcessField(exccessFieldName),
                  keyVar,
                )}}}`
          }

        | _ => ()
        }

        let syncOutput = {
          let rec definitionToOutput = (
            definition: Definition.t<FieldDefinition.t>,
            ~outputPath,
          ) => {
            let kind = definition->Definition.toKindWithSet(~embededSet=fieldDefinitionsSet)
            switch kind {
            | Embeded => {
                let {struct, inputPath} = definition->Definition.toEmbeded
                let fieldInputVar = b->B.var
                b.code = b.code ++ `${fieldInputVar}=${inputVar}${inputPath};`
                let fieldOuputVar =
                  b->B.run(
                    ~builder=struct.parseOperationBuilder,
                    ~struct,
                    ~inputVar=fieldInputVar,
                    ~pathVar=`${pathVar}+${inputPath->Stdlib.Inlined.Value.fromString}`,
                  )
                let isAsyncField = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
                if isAsyncField {
                  // TODO: Ensure that it's not a var, but inlined
                  asyncOutputVars->Js.Array2.push(fieldOuputVar)->ignore
                }

                fieldOuputVar
              }
            | Constant => {
                let constant = definition->Definition.toConstant
                b->B.embed(constant)
              }
            | Node => {
                let node = definition->Definition.toNode
                let isArray = Stdlib.Array.isArray(node)
                let keys = node->Js.Dict.keys
                let codeRef = ref(isArray ? "[" : "{")
                for idx in 0 to keys->Js.Array2.length - 1 {
                  let key = keys->Js.Array2.unsafe_get(idx)
                  let definition = node->Js.Dict.unsafeGet(key)
                  let output =
                    definition->definitionToOutput(
                      ~outputPath=Path.concat(outputPath, Path.fromLocation(key)),
                    )
                  codeRef.contents =
                    codeRef.contents ++
                    (isArray ? output : `${key->Stdlib.Inlined.Value.fromString}:${output}`) ++ ","
                }
                codeRef.contents ++ (isArray ? "]" : "}")
              }
            }
          }
          definition->definitionToOutput(~outputPath=Path.empty)
        }

        if asyncOutputVars->Js.Array2.length === 0 {
          // TODO: Solve S.refine (and other) allocating the object twice
          syncOutput
        } else {
          let outputVar = b->B.var
          b.code =
            b.code ++
            `${outputVar}=()=>Promise.all([${asyncOutputVars
              ->Js.Array2.map(asyncOutputVar => `${asyncOutputVar}()`)
              ->Js.Array2.joinWith(
                ",",
              )}]).then(([${asyncOutputVars->Js.Array2.toString}])=>(${syncOutput}));`
          outputVar
        }
      }),
      ~serializeOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let fieldsCodeRef = ref("")
        let prevCode = b.code
        b.code = ""

        {
          let rec definitionToOutput = (
            definition: Definition.t<FieldDefinition.t>,
            ~outputPath,
          ) => {
            let kind = definition->Definition.toKindWithSet(~embededSet=fieldDefinitionsSet)
            switch kind {
            | Embeded => {
                let {struct, inlinedInputLocation} = definition->Definition.toEmbeded
                if struct.serializeOperationBuilder === Builder.noop {
                  fieldsCodeRef.contents =
                    fieldsCodeRef.contents ++ `${inlinedInputLocation}:${inputVar}${outputPath},`
                } else {
                  let fieldInputVar = b->B.var
                  b.code = b.code ++ `${fieldInputVar}=${inputVar}${outputPath};`
                  let fieldOuputVar =
                    b->B.run(
                      ~builder=struct.serializeOperationBuilder,
                      ~struct,
                      ~inputVar=fieldInputVar,
                      ~pathVar=`${pathVar}+${outputPath->Stdlib.Inlined.Value.fromString}`,
                    )
                  fieldsCodeRef.contents =
                    fieldsCodeRef.contents ++ `${inlinedInputLocation}:${fieldOuputVar},`
                }
              }
            | Constant => {
                let value = definition->Definition.toConstant
                b.code =
                  `if(${inputVar}${outputPath}!==${b->B.embed(value)}){${b->B.raiseWithArg(
                      ~pathVar=`${pathVar}+${outputPath->Stdlib.Inlined.Value.fromString}`,
                      input => InvalidLiteral({
                        expected: value->Literal.classify,
                        received: input,
                      }),
                      `${inputVar}${outputPath}`,
                    )}}` ++
                  b.code
              }
            | Node => {
                let node = definition->Definition.toNode
                let keys = node->Js.Dict.keys
                for idx in 0 to keys->Js.Array2.length - 1 {
                  let key = keys->Js.Array2.unsafe_get(idx)
                  let definition = node->Js.Dict.unsafeGet(key)
                  definitionToOutput(
                    definition,
                    ~outputPath=Path.concat(outputPath, Path.fromLocation(key)),
                  )
                }
              }
            }
          }
          definitionToOutput(definition, ~outputPath=Path.empty)
        }

        b.code = prevCode ++ b.code

        // TODO: Should be before registered fields
        for idx in 0 to fieldDefinitions->Js.Array2.length - 1 {
          let {struct, inlinedInputLocation, isRegistered} =
            fieldDefinitions->Js.Array2.unsafe_get(idx)
          if !isRegistered {
            switch struct->toLiteral {
            | Some(literal) =>
              fieldsCodeRef.contents =
                fieldsCodeRef.contents ++
                `${inlinedInputLocation}:${b->B.embed(literal->Literal.value)},`
            | None =>
              b.code =
                b->B.missingOperation(
                  ~pathVar,
                  ~description=`Can't create serializer. The ${inlinedInputLocation} field is not registered and not a literal. Use S.transform instead`,
                )
            }
          }
        }

        `{${fieldsCodeRef.contents}}`
      }),
      (),
    )
  }

  let strip = struct => {
    struct->Metadata.set(~id=UnknownKeys.metadataId, UnknownKeys.Strip)
  }

  let strict = struct => {
    struct->Metadata.set(~id=UnknownKeys.metadataId, UnknownKeys.Strict)
  }
}

module Never = {
  let builder = Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
    b->B.raiseWithArg(
      ~pathVar,
      input => InvalidType({
        expected: selfStruct,
        received: input,
      }),
      inputVar,
    )
  })

  let struct = make(
    ~metadataMap=emptyMetadataMap,
    ~tagged=Never,
    ~parseOperationBuilder=builder,
    ~serializeOperationBuilder=builder,
    (),
  )
}

module Unknown = {
  let struct = make(
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

  let parseOperationBuilder = Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
    b.code =
      b.code ++
      `if(typeof ${inputVar}!=="string"){${b->B.raiseWithArg(
          ~pathVar,
          input => InvalidType({
            expected: selfStruct,
            received: input,
          }),
          inputVar,
        )}}`
    inputVar
  })

  let struct = make(
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
      {
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
  let factory = struct => {
    let struct = struct->toUnknown
    try {
      struct->validateJsonableStruct(~rootStruct=struct, ~isRoot=true, ())
    } catch {
    | Js.Exn.Error(jsExn) => {
        let _ = jsExn->InternalError.getOrRethrow
        InternalError.panic(
          `The struct ${struct->name} passed to S.jsonString is not compatible with JSON`,
        )
      }
    }
    make(
      ~metadataMap=emptyMetadataMap,
      ~tagged=String,
      ~parseOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
        let jsonStringVar =
          b->B.run(~builder=String.parseOperationBuilder, ~struct=selfStruct, ~inputVar, ~pathVar)
        let jsonVar = b->B.var
        b.code =
          b.code ++
          `try{${jsonVar}=JSON.parse(${jsonStringVar})}catch(t){${b->B.raiseWithArg(
              ~pathVar,
              message => OperationFailed(message),
              "t.message",
            )}}`

        b->B.run(~builder=struct.parseOperationBuilder, ~struct, ~inputVar=jsonVar, ~pathVar)
      }),
      ~serializeOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        `JSON.stringify(${b->B.run(
            ~builder=struct.parseOperationBuilder,
            ~struct,
            ~inputVar,
            ~pathVar,
          )})`
      }),
      (),
    )
  }
}

module Bool = {
  let struct = make(
    ~metadataMap=emptyMetadataMap,
    ~tagged=Bool,
    ~parseOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
      b.code =
        b.code ++
        `if(typeof ${inputVar}!=="boolean"){${b->B.raiseWithArg(
            ~pathVar,
            input => InvalidType({
              expected: selfStruct,
              received: input,
            }),
            inputVar,
          )}}`
      inputVar
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
    ~metadataMap=emptyMetadataMap,
    ~tagged=Int,
    ~parseOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
      b.code =
        b.code ++
        `if(!(typeof ${inputVar}==="number"&&${inputVar}<2147483648&&${inputVar}>-2147483649&&${inputVar}%1===0)){${b->B.raiseWithArg(
            ~pathVar,
            input => InvalidType({
              expected: selfStruct,
              received: input,
            }),
            inputVar,
          )}}`
      inputVar
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
    ~metadataMap=emptyMetadataMap,
    ~tagged=Float,
    ~parseOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
      b.code =
        b.code ++
        `if(!(typeof ${inputVar}==="number"&&!Number.isNaN(${inputVar}))){${b->B.raiseWithArg(
            ~pathVar,
            input => InvalidType({
              expected: selfStruct,
              received: input,
            }),
            inputVar,
          )}}`
      inputVar
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
  let factory = struct => {
    let struct = struct->toUnknown
    make(
      ~metadataMap=emptyMetadataMap,
      ~tagged=Null(struct),
      ~parseOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let outputVar = b->B.var

        let ifCode = b->B.scope(b => {
          let structOutputVar =
            b->B.run(~builder=struct.parseOperationBuilder, ~struct, ~inputVar, ~pathVar)

          `${outputVar}=${b->B.embedSyncOperation(
              ~inputVar=structOutputVar,
              ~pathVar,
              ~isSafe=true,
              ~fn=%raw("Caml_option.some"),
              (),
            )}`
        })
        let isAsync = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)

        b.code =
          b.code ++
          `if(${inputVar}!==null){${ifCode}}else{${outputVar}=${isAsync
              ? `()=>Promise.resolve(void 0)`
              : `void 0`}}`

        outputVar
      }),
      ~serializeOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let outputVar = b->B.var
        b.code =
          b.code ++
          `if(${inputVar}!==void 0){${b->B.scope(b => {
              `${outputVar}=${b->B.run(
                  ~builder=struct.serializeOperationBuilder,
                  ~struct,
                  ~inputVar=`${b->B.embed(%raw("Caml_option.valFromOption"))}(${inputVar})`,
                  ~pathVar,
                )}`
            })}}else{${outputVar}=null}`
        outputVar
      }),
      (),
    )
  }
}

module Option = {
  let factory = struct => {
    let struct = struct->toUnknown
    make(
      ~metadataMap=emptyMetadataMap,
      ~tagged=Option(struct),
      ~parseOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let outputVar = b->B.var

        let ifCode = b->B.scope(b => {
          `${outputVar}=${b->B.embedSyncOperation(
              ~inputVar=b->B.run(
                ~builder=struct.parseOperationBuilder,
                ~struct,
                ~inputVar,
                ~pathVar,
              ),
              ~pathVar,
              ~isSafe=true,
              ~fn=%raw("Caml_option.some"),
              (),
            )}`
        })

        let isAsync = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)

        b.code =
          b.code ++
          `if(${inputVar}!==void 0){${ifCode}}else{${outputVar}=${switch isAsync {
            | false => inputVar
            | true => `()=>Promise.resolve(${inputVar})`
            }}}`
        outputVar
      }),
      ~serializeOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let outputVar = b->B.var
        b.code =
          b.code ++
          `if(${inputVar}!==void 0){${b->B.scope(b => {
              `${outputVar}=${b->B.run(
                  ~builder=struct.serializeOperationBuilder,
                  ~struct,
                  ~inputVar=`${b->B.embed(%raw("Caml_option.valFromOption"))}(${inputVar})`,
                  ~pathVar,
                )}`
            })}}else{${outputVar}=void 0}`
        outputVar
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

  let factory = struct => {
    let struct = struct->toUnknown
    make(
      ~metadataMap=emptyMetadataMap,
      ~tagged=Array(struct),
      ~parseOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
        let iteratorVar = b->B.varWithoutAllocation
        let outputVar = b->B.var

        b.code =
          b.code ++
          `if(!Array.isArray(${inputVar})){${b->B.raiseWithArg(
              ~pathVar,
              input => InvalidType({
                expected: selfStruct,
                received: input,
              }),
              inputVar,
            )}}${outputVar}=[];for(let ${iteratorVar}=0;${iteratorVar}<${inputVar}.length;++${iteratorVar}){${b->B.scope(
              b => {
                let itemVar = b->B.var
                b.code = b.code ++ `${itemVar}=${inputVar}[${iteratorVar}];`
                let itemOutputVar =
                  b->B.run(
                    ~builder=struct.parseOperationBuilder,
                    ~struct,
                    ~inputVar=itemVar,
                    ~pathVar=`${pathVar}+'["'+${iteratorVar}+'"]'`,
                  )
                `${outputVar}.push(${itemOutputVar})`
              },
            )}}`

        let isAsync = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
        if isAsync {
          let asyncOutputVar = b->B.var
          b.code = b.code ++ `${asyncOutputVar}=()=>Promise.all(${outputVar}.map(t=>t()));`
          asyncOutputVar
        } else {
          outputVar
        }
      }),
      ~serializeOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let iteratorVar = b->B.varWithoutAllocation
        let outputVar = b->B.var

        // TODO: Optimize when struct.serializeOperationBuilder is noop
        b.code =
          b.code ++
          `${outputVar}=[];for(let ${iteratorVar}=0;${iteratorVar}<${inputVar}.length;++${iteratorVar}){${b->B.scope(
              b => {
                let itemVar = b->B.var
                b.code = b.code ++ `${itemVar}=${inputVar}[${iteratorVar}];`
                let itemOutputVar =
                  b->B.run(
                    ~builder=struct.serializeOperationBuilder,
                    ~struct,
                    ~inputVar=itemVar,
                    ~pathVar=`${pathVar}+'["'+${iteratorVar}+'"]'`,
                  )
                `${outputVar}.push(${itemOutputVar})`
              },
            )}}`

        outputVar
      }),
      (),
    )
  }

  // TODO: inline built-in refinements
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
  let factory = struct => {
    let struct = struct->toUnknown
    make(
      ~metadataMap=emptyMetadataMap,
      ~tagged=Dict(struct),
      ~parseOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
        let keyVar = b->B.varWithoutAllocation
        let outputVar = b->B.var

        b.code =
          b.code ++
          `if(!(typeof ${inputVar}==="object"&&${inputVar}!==null&&!Array.isArray(${inputVar}))){${b->B.raiseWithArg(
              ~pathVar,
              input => InvalidType({
                expected: selfStruct,
                received: input,
              }),
              inputVar,
            )}}${outputVar}={};for(let ${keyVar} in ${inputVar}){${b->B.scope(b => {
              let itemVar = b->B.var
              b.code = b.code ++ `${itemVar}=${inputVar}[${keyVar}];`
              let itemOutputVar =
                b->B.run(
                  ~builder=struct.parseOperationBuilder,
                  ~struct,
                  ~inputVar=itemVar,
                  ~pathVar=`${pathVar}+'["'+${keyVar}+'"]'`,
                )
              `${outputVar}[${keyVar}]=${itemOutputVar}`
            })}}`

        let isAsync = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
        if isAsync {
          let resolveVar = b->B.varWithoutAllocation
          let rejectVar = b->B.varWithoutAllocation
          let asyncParseResultVar = b->B.varWithoutAllocation
          let counterVar = b->B.varWithoutAllocation
          let asyncOutputVar = b->B.var
          b.code =
            b.code ++
            `${asyncOutputVar}=()=>new Promise((${resolveVar},${rejectVar})=>{let ${counterVar}=Object.keys(${outputVar}).length;for(let ${keyVar} in ${outputVar}){${outputVar}[${keyVar}]().then(${asyncParseResultVar}=>{${outputVar}[${keyVar}]=${asyncParseResultVar};if(${counterVar}--===1){${resolveVar}(${outputVar})}},${rejectVar})}});`
          asyncOutputVar
        } else {
          outputVar
        }
      }),
      ~serializeOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let keyVar = b->B.varWithoutAllocation
        let outputVar = b->B.var

        // TODO: Optimize when struct.serializeOperationBuilder is noop
        b.code =
          b.code ++
          `${outputVar}={};for(let ${keyVar} in ${inputVar}){${b->B.scope(b => {
              let itemVar = b->B.var
              b.code = b.code ++ `${itemVar}=${inputVar}[${keyVar}];`
              let itemOutputVar =
                b->B.run(
                  ~builder=struct.serializeOperationBuilder,
                  ~struct,
                  ~inputVar=itemVar,
                  ~pathVar=`${pathVar}+'["'+${keyVar}+'"]'`,
                )
              `${outputVar}[${keyVar}]=${itemOutputVar}`
            })}}`

        outputVar
      }),
      (),
    )
  }
}

module Default = {
  let metadataId = Metadata.Id.make(~namespace="rescript-struct", ~name="Default")

  let factory = (struct, getDefaultValue) => {
    let struct = struct->Option.factory->(Obj.magic: t<'value> => t<unknown>)
    let getDefaultValue = getDefaultValue->(Obj.magic: (unit => 'value) => unit => unknown)
    make(
      ~metadataMap=emptyMetadataMap,
      ~tagged=struct.tagged,
      ~parseOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
        let outputVar = b->B.var

        let ifCode = b->B.scope(b => {
          `${outputVar}=${b->B.embedSyncOperation(
              ~inputVar=b->B.run(
                ~builder=struct.parseOperationBuilder,
                ~struct,
                ~inputVar,
                ~pathVar,
              ),
              ~pathVar,
              ~isSafe=true,
              ~fn=%raw("Caml_option.some"),
              (),
            )}`
        })
        let defaultValVar = `${b->B.embed(getDefaultValue)}()`

        let isAsync = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)

        b.code =
          b.code ++
          `if(${inputVar}!==void 0){${ifCode}}else{${outputVar}=${switch isAsync {
            | false => defaultValVar
            | true => `()=>Promise.resolve(${defaultValVar})`
            }}}`

        outputVar
      }),
      ~serializeOperationBuilder=struct.serializeOperationBuilder,
      (),
    )->Metadata.set(~id=metadataId, getDefaultValue)
  }

  let classify = struct =>
    switch struct->Metadata.get(~id=metadataId) {
    // TODO: Test with getDefaultValue returning None
    | Some(getDefaultValue) => Some(getDefaultValue())
    | None => None
    }
}

module Tuple = {
  let factory = structs => {
    let numberOfStructs = structs->Js.Array2.length
    make(
      ~metadataMap=emptyMetadataMap,
      ~tagged=Tuple(structs),
      ~parseOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
        b.code =
          b.code ++
          `if(!Array.isArray(${inputVar})){${b->B.raiseWithArg(
              ~pathVar,
              input => InvalidType({
                expected: selfStruct,
                received: input,
              }),
              inputVar,
            )}}if(${inputVar}.length!==${numberOfStructs->Stdlib.Int.unsafeToString}){${b->B.raiseWithArg(
              ~pathVar,
              numberOfInputItems => InvalidTupleSize({
                expected: numberOfStructs,
                received: numberOfInputItems,
              }),
              `${inputVar}.length`,
            )}}`

        switch structs {
        | [] => `void 0`
        | [itemStruct] =>
          b->B.run(
            ~builder=itemStruct.parseOperationBuilder,
            ~struct=itemStruct,
            ~inputVar=`${inputVar}[0]`,
            ~pathVar=`${pathVar}+'["0"]'`,
          )
        | _ => {
            let outputVar = b->B.var
            b.code = b.code ++ `${outputVar}=[];`
            let asyncItemVars = []
            for idx in 0 to structs->Js.Array2.length - 1 {
              let itemStruct = structs->Js.Array2.unsafe_get(idx)

              let itemVar = b->B.var
              b.code = b.code ++ `${itemVar}=${inputVar}[${idx->Stdlib.Int.unsafeToString}];`
              let itemOutputVar =
                b->B.run(
                  ~builder=itemStruct.parseOperationBuilder,
                  ~struct=itemStruct,
                  ~inputVar=itemVar,
                  ~pathVar=`${pathVar}+'["${idx->Stdlib.Int.unsafeToString}"]'`,
                )
              let isAsyncItem = itemStruct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
              let destVar = `${outputVar}[${idx->Stdlib.Int.unsafeToString}]`

              if isAsyncItem {
                // TODO: use strings and generate async code in a single place
                asyncItemVars->Js.Array2.push(destVar)->ignore
              }

              // TODO: Create array without assigning
              b.code = b.code ++ `${destVar}=${itemOutputVar};`
            }

            if asyncItemVars->Js.Array2.length === 0 {
              outputVar
            } else {
              let resolveVar = b->B.varWithoutAllocation
              let rejectVar = b->B.varWithoutAllocation
              let asyncParseResultVar = b->B.varWithoutAllocation
              let counterVar = b->B.varWithoutAllocation
              let asyncOutputVar = b->B.var

              b.code =
                b.code ++
                `${asyncOutputVar}=()=>new Promise((${resolveVar},${rejectVar})=>{let ${counterVar}=${asyncItemVars
                  ->Js.Array2.length
                  ->Js.Int.toString};${asyncItemVars
                  ->Js.Array2.map(asyncItemVar => {
                    `${asyncItemVar}().then(${asyncParseResultVar}=>{${asyncItemVar}=${asyncParseResultVar};if(${counterVar}--===1){${resolveVar}(${outputVar})}},${rejectVar})`
                  })
                  ->Js.Array2.joinWith(";")}});`

              asyncOutputVar
            }
          }
        }
      }),
      ~serializeOperationBuilder=switch structs {
      | [] =>
        Builder.make((_b, ~selfStruct as _, ~inputVar as _, ~pathVar as _) => {
          `[]`
        })
      | [_] =>
        Builder.make((_b, ~selfStruct as _, ~inputVar, ~pathVar as _) => {
          `[${inputVar}]`
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
      InternalError.panic("A Union struct factory require at least two structs.")
    }

    make(
      ~metadataMap=emptyMetadataMap,
      ~tagged=Union(structs),
      ~parseOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
        let structs = selfStruct->classify->unsafeGetVariantPayload

        let isAsyncRef = ref(false)
        let itemsCode = []
        let itemsOutputVar = []

        let prevCode = b.code
        for idx in 0 to structs->Js.Array2.length - 1 {
          let struct = structs->Js.Array2.unsafe_get(idx)
          b.code = ""
          let itemOutputVar =
            b->B.run(~builder=struct.parseOperationBuilder, ~struct, ~inputVar, ~pathVar=`""`)
          let isAsyncItem = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)
          if isAsyncItem {
            isAsyncRef.contents = true
          }
          itemsOutputVar->Js.Array2.push(itemOutputVar)->ignore
          itemsCode->Js.Array2.push(b.code)->ignore
        }
        b.code = prevCode
        let isAsync = isAsyncRef.contents

        let outputVar = b->B.var

        let codeEndRef = ref("")
        let errorCodeRef = ref("")

        for idx in 0 to structs->Js.Array2.length - 1 {
          let struct = structs->Js.Array2.unsafe_get(idx)
          let code = itemsCode->Js.Array2.unsafe_get(idx)
          let itemOutputVar = itemsOutputVar->Js.Array2.unsafe_get(idx)
          let isAsyncItem = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)

          let errorVar = b->B.varWithoutAllocation

          let errorCode = if isAsync {
            (isAsyncItem ? `${errorVar}===${itemOutputVar}?${errorVar}():` : "") ++
            `Promise.reject(${errorVar})`
          } else {
            errorVar
          }
          if idx === 0 {
            errorCodeRef.contents = errorCode
          } else {
            errorCodeRef.contents = errorCodeRef.contents ++ "," ++ errorCode
          }

          b.code =
            b.code ++
            `try{${code}${switch (isAsyncItem, isAsync) {
              | (true, _) => `throw ${itemOutputVar}`
              | (false, false) => `${outputVar}=${itemOutputVar}`
              | (false, true) => `${outputVar}=()=>Promise.resolve(${itemOutputVar})`
              }}}catch(${errorVar}){if(${b->B.isInternalError(errorVar)}${isAsyncItem
                ? `||${errorVar}===${itemOutputVar}`
                : ""}){`
          codeEndRef.contents = `}else{throw ${errorVar}}}` ++ codeEndRef.contents
        }

        if isAsync {
          b.code =
            b.code ++
            `${outputVar}=()=>Promise.any([${errorCodeRef.contents}]).catch(t=>{${b->B.raiseWithArg(
                ~pathVar,
                internalErrors => {
                  InvalidUnion(internalErrors->Js.Array2.map(InternalError.toParseError))
                },
                `t.errors`,
              )}})` ++
            codeEndRef.contents
          outputVar
        } else {
          b.code =
            b.code ++
            b->B.raiseWithArg(
              ~pathVar,
              internalErrors => InvalidUnion(
                internalErrors->Js.Array2.map(InternalError.toParseError),
              ),
              `[${errorCodeRef.contents}]`,
            ) ++
            codeEndRef.contents
          outputVar
        }
      }),
      ~serializeOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
        let structs = selfStruct->classify->unsafeGetVariantPayload

        let outputVar = b->B.var

        let codeEndRef = ref("")
        let errorVarsRef = ref("")

        for idx in 0 to structs->Js.Array2.length - 1 {
          let itemStruct = structs->Js.Array2.unsafe_get(idx)
          let errorVar = b->B.varWithoutAllocation
          errorVarsRef.contents = errorVarsRef.contents ++ errorVar ++ `,`

          b.code =
            b.code ++
            `try{${b->B.scope(b => {
                `${outputVar}=${b->B.run(
                    ~builder=itemStruct.serializeOperationBuilder,
                    ~struct=itemStruct,
                    ~inputVar,
                    ~pathVar=`""`,
                  )}`
              })}}catch(${errorVar}){if(${b->B.isInternalError(errorVar)}){`

          codeEndRef.contents = `}else{throw ${errorVar}}}` ++ codeEndRef.contents
        }

        b.code =
          b.code ++
          b->B.raiseWithArg(
            ~pathVar,
            internalErrors => InvalidUnion(
              internalErrors->Js.Array2.map(InternalError.toSerializeError),
            ),
            `[${errorVarsRef.contents}]`,
          ) ++
          codeEndRef.contents

        outputVar
      }),
      (),
    )
  }
}

let list = struct => {
  struct
  ->Array.factory
  ->transform(
    ~parser=array => array->Belt.List.fromArray,
    ~serializer=list => list->Belt.List.toArray,
    (),
  )
}

let json = make(
  ~tagged=JSON,
  ~metadataMap=emptyMetadataMap,
  ~parseOperationBuilder=Builder.make((b, ~selfStruct, ~inputVar, ~pathVar) => {
    let rec parse = (input, ~path) => {
      switch input->Stdlib.Type.typeof {
      | #number if Js.Float.isNaN(input->(Obj.magic: unknown => float))->not =>
        input->(Obj.magic: unknown => Js.Json.t)

      | #object =>
        if input === %raw(`null`) {
          input->(Obj.magic: unknown => Js.Json.t)
        } else if input->Stdlib.Array.isArray {
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

      | #string
      | #boolean =>
        input->(Obj.magic: unknown => Js.Json.t)

      | _ =>
        InternalError.raise(
          ~path,
          ~code=InvalidType({
            expected: selfStruct,
            received: input,
          }),
        )
      }
    }

    `${b->B.embed(parse)}(${inputVar},${pathVar})`
  }),
  ~serializeOperationBuilder=Builder.noop,
  (),
)

type catchCtx = {
  error: error,
  input: unknown,
}
let catch = (struct, getFallbackValue) => {
  let struct = struct->toUnknown
  make(
    ~parseOperationBuilder=Builder.make((b, ~selfStruct as _, ~inputVar, ~pathVar) => {
      let outputVar = b->B.var
      let syncTryCode = b->B.scope(b => {
        `${outputVar}=${b->B.run(
            ~builder=struct.parseOperationBuilder,
            ~struct,
            ~inputVar,
            ~pathVar,
          )}`
      })
      let isAsync = struct.isAsyncParse->(Obj.magic: isAsyncParse => bool)

      let fallbackValVar = `${b->B.embed((input, internalError) =>
          getFallbackValue({
            input,
            error: internalError->InternalError.toParseError,
          })
        )}(${inputVar},t)`

      // TODO: Improve (?)
      if isAsync {
        let asyncOutputVar = b->B.var
        b.code =
          b.code ++
          `try{${syncTryCode};${asyncOutputVar}=()=>{try{return ${outputVar}().catch(t=>{if(${b->B.isInternalError(
              "t",
            )}){return ${fallbackValVar}}else{throw t}})}catch(t){if(${b->B.isInternalError(
              "t",
            )}){return Promise.resolve(${fallbackValVar})}else{throw t}}}}catch(t){if(${b->B.isInternalError(
              "t",
            )}){${asyncOutputVar}=()=>Promise.resolve(${fallbackValVar})}else{throw t}}`
        asyncOutputVar
      } else {
        b.code =
          b.code ++
          `try{${syncTryCode}}catch(t){if(${b->B.isInternalError(
              "t",
            )}){${outputVar}=${fallbackValVar}}else{throw t}}`
        outputVar
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
  struct->Metadata.set(~id=deprecationMetadataId, message)
}

let deprecation = struct => struct->Metadata.get(~id=deprecationMetadataId)

let descriptionMetadataId = Metadata.Id.make(~namespace="rescript-struct", ~name="description")

let describe = (struct, description) => {
  struct->Metadata.set(~id=descriptionMetadataId, description)
}

let description = struct => struct->Metadata.get(~id=descriptionMetadataId)

module Error = {
  let rec toReason = (~nestedLevel=0, error) => {
    switch error.code {
    | OperationFailed(reason) => reason
    | MissingOperation({description}) => description
    | UnexpectedAsync => "Encountered unexpected asynchronous transform or refine. Use S.parseAsyncWith instead of S.parseWith"
    | ExcessField(fieldName) =>
      `Encountered disallowed excess key ${fieldName->Stdlib.Inlined.Value.fromString} on an object. Use Deprecated to ignore a specific field, or S.Object.strip to ignore excess keys completely`
    | InvalidType({expected, received}) =>
      `Expected ${expected->name}, received ${received->Literal.classify->Literal.toText}`
    | InvalidLiteral({expected, received}) =>
      `Expected ${expected->Literal.toText}, received ${received->Literal.classify->Literal.toText}`
    | InvalidJsonStruct(struct) => `The struct ${struct->name} is not compatible with JSON`
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

module Result = {
  let getExn = result => {
    switch result {
    | Ok(value) => value
    | Error(error) => InternalError.panic(error->Error.toString)
    }
  }

  let mapErrorToString = result => {
    result->Stdlib.Result.mapError(Error.toString)
  }
}

let inline = {
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
            let variantName = s->name
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
          InternalError.panic("The S.inline doesn't support tuples with more than 10 items.")
        }
        `S.tuple${numberOfItems->Js.Int.toString}(. ${tupleStructs
          ->Js.Array2.map(s => s->internalInline())
          ->Js.Array2.joinWith(", ")})`
      }
    | Object({fieldNames: []}) => `S.object(_ => ())`
    | Object({fieldNames, fields}) =>
      `S.object(s =>
  {
    ${fieldNames
        ->Js.Array2.map(fieldName => {
          `${fieldName->Stdlib.Inlined.Value.fromString}: s.field(${fieldName->Stdlib.Inlined.Value.fromString}, ${fields
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
    | Option(struct) => {
        let internalInlinedStruct = struct->internalInline()
        switch struct->Default.classify {
        | Some(defaultValue) => {
            metadataMap->Stdlib.Dict.deleteInPlace(Default.metadataId->Metadata.Id.toKey)
            internalInlinedStruct ++
            `->S.default(() => %raw(\`${defaultValue->Stdlib.Inlined.Value.stringify}\`))`
          }

        | None => `S.option(${internalInlinedStruct})`
        }
      }
    | Null(struct) => `S.null(${struct->internalInline()})`
    | Never => `S.never`
    | Unknown => `S.unknown`
    | Array(struct) => `S.array(${struct->internalInline()})`
    | Dict(struct) => `S.dict(${struct->internalInline()})`
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
let unit = literal(%raw("void 0"))
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
let tuple0 = () => Tuple.factory([])
let tuple1 = v0 => Tuple.factory([v0->toUnknown])
let tuple2 = (v0, v1) => Tuple.factory([v0->toUnknown, v1->toUnknown])
let tuple3 = (v0, v1, v2) => Tuple.factory([v0->toUnknown, v1->toUnknown, v2->toUnknown])
let tuple4 = Tuple.factoryFromArgs
let tuple5 = Tuple.factoryFromArgs
let tuple6 = Tuple.factoryFromArgs
let tuple7 = Tuple.factoryFromArgs
let tuple8 = Tuple.factoryFromArgs
let tuple9 = Tuple.factoryFromArgs
let tuple10 = Tuple.factoryFromArgs
let union = Union.factory
let jsonString = JsonString.factory
