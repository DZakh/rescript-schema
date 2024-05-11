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

    @send
    external thenResolve: (t<'a>, 'a => 'b) => t<'b> = "then"

    @val @scope("Promise")
    external resolve: 'a => t<'a> = "resolve"
  }

  module Re = {
    @send
    external toString: Js.Re.t => string = "toString"
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

    @inline
    let has = (array, idx) => {
      array->Js.Array2.unsafe_get(idx)->(Obj.magic: 'a => bool)
    }

    let isArray = Js.Array2.isArray
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

    external unsafeToString: int => string = "%identity"
  }

  module Dict = {
    @val
    external copy: (@as(json`{}`) _, dict<'a>) => dict<'a> = "Object.assign"

    @inline
    let has = (dict, key) => {
      dict->Js.Dict.unsafeGet(key)->(Obj.magic: 'a => bool)
    }

    @inline
    let deleteInPlace = (dict, key) => {
      Js.Dict.unsafeDeleteKey(dict->(Obj.magic: dict<'a> => dict<string>), key)
    }

    let mapValues: (dict<'a>, 'a => 'b) => dict<'b> = %raw(`(dict, fn)=>{
      var key,newDict = {};
      for (key in dict) {
        newDict[key] = fn(dict[key])
      }
      return newDict
    }`)
  }

  module Float = {
    external unsafeToString: float => string = "%identity"
  }

  module BigInt = {
    @send external toString: bigint => string = "toString"
    @inline
    let toString = bigint => bigint->toString ++ "n"
  }

  module Function = {
    @variadic @new
    external _make: array<string> => 'function = "Function"

    @inline
    let make2 = (~ctxVarName1, ~ctxVarValue1, ~ctxVarName2, ~ctxVarValue2, ~inlinedFunction) => {
      _make([ctxVarName1, ctxVarName2, `return ${inlinedFunction}`])(ctxVarValue1, ctxVarValue2)
    }

    @send external toString: Js.Types.function_val => string = "toString"
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

module Path = {
  type t = string

  external toString: t => string = "%identity"

  @inline
  let empty = ""

  @inline
  let dynamic = "[]"

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

let symbol = Stdlib.Symbol.make("rescript-schema")

@unboxed
type isAsyncParse = | @as(0) Unknown | Value(bool)
type unknownKeys = Strip | Strict

@@warning("-37")
@tag("kind")
type rec literal =
  | String({value: string})
  | Number({value: float})
  | Boolean({value: bool})
  | BigInt({value: bigint})
  | Symbol({value: Js.Types.symbol})
  | Array({value: array<unknown>, items: array<literal>})
  | Dict({value: dict<unknown>, items: dict<literal>})
  | Function({value: Js.Types.function_val})
  | Object({value: Js.Types.obj_val})
  | Null({value: Js.Types.null_val})
  | Undefined({value: unit})
  | NaN({value: unknown})
@@warning("+37")

type rec t<'value> = {
  @as("t")
  tagged: tagged,
  @as("n")
  name: unit => string,
  @as("p")
  mutable parseOperationBuilder: builder,
  @as("s")
  mutable serializeOperationBuilder: builder,
  @as("f")
  maybeTypeFilter?: (~inputVar: string) => string,
  @as("j")
  maybeToJsonString?: string => string,
  @as("i")
  mutable isAsyncParse: isAsyncParse,
  @as("m")
  metadataMap: dict<unknown>,
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
  | Object({fields: dict<t<unknown>>, fieldNames: array<string>, unknownKeys: unknownKeys})
  | Tuple(array<t<unknown>>)
  | Union(array<t<unknown>>)
  | Dict(t<unknown>)
  | JSON({validated: bool})
and builder
and builderCtx = {
  @as("a")
  mutable isAsyncBranch: bool,
  @as("c")
  mutable code: string,
  @as("o")
  operation: operation,
  @as("v")
  mutable _varCounter: int,
  @as("s")
  mutable _vars: Stdlib.Set.t<string>,
  @as("l")
  mutable _varsAllocation: string,
  @as("i")
  mutable _input: string,
  @as("e")
  _embeded: array<unknown>,
}
and operation =
  | Parsing
  | Serializing
and schema<'a> = t<'a>
type rec error = private {operation: operation, code: errorCode, path: Path.t}
and errorCode =
  | OperationFailed(string)
  | InvalidOperation({description: string})
  | InvalidType({expected: schema<unknown>, received: unknown})
  | InvalidLiteral({expected: literal, received: unknown})
  | InvalidTupleSize({expected: int, received: int})
  | ExcessField(string)
  | InvalidUnion(array<error>)
  | UnexpectedAsync
  | InvalidJsonStruct(schema<unknown>)
type exn += private Raised(error)

external castUnknownSchemaToAnySchema: t<unknown> => t<'any> = "%identity"
external toUnknown: t<'any> => t<unknown> = "%identity"

let unsafeGetVariantPayload = variant => (variant->Obj.magic)["_0"]
let unsafeGetErrorPayload = variant => (variant->Obj.magic)["_1"]

module InternalError = {
  %%raw(`
    class RescriptSchemaError extends Error {
      constructor(code, operation, path) {
        super();
        this.operation = operation;
        this.code = code;
        this.path = path;
        this.s = symbol;
        this.RE_EXN_ID = Raised;
        this._1 = this;
        this.Error = this;
        this.name = "RescriptSchemaError";
      }
      get message() {
        return message(this);
      }
      get reason() {
        return reason(this);
      }
    }
  `)

  @new
  external make: (~code: errorCode, ~operation: operation, ~path: Path.t) => error =
    "RescriptSchemaError"

  let getOrRethrow = (exn: exn) => {
    if %raw("exn&&exn.s===symbol") {
      exn->(Obj.magic: exn => error)
    } else {
      raise(%raw("exn&&exn.RE_EXN_ID==='JsError'") ? exn->unsafeGetErrorPayload : exn)
    }
  }

  @inline
  let raise = (~code, ~operation, ~path) => {
    Stdlib.Exn.raiseAny(make(~code, ~operation, ~path))
  }

  let prependLocationOrRethrow = (exn, location) => {
    let error = exn->getOrRethrow
    raise(
      ~path=Path.concat(location->Path.fromLocation, error.path),
      ~code=error.code,
      ~operation=error.operation,
    )
  }

  @inline
  let panic = message => Stdlib.Exn.raiseError(Stdlib.Exn.makeError(`[rescript-schema] ${message}`))
}

type s<'value> = {
  schema: t<'value>,
  fail: 'a. (string, ~path: Path.t=?) => 'a,
}

module EffectCtx = {
  let make = (~selfSchema, ~path, ~operation) => {
    schema: selfSchema->castUnknownSchemaToAnySchema,
    fail: (message, ~path as customPath=Path.empty) => {
      InternalError.raise(
        ~path=path->Path.concat(customPath),
        ~code=OperationFailed(message),
        ~operation,
      )
    },
  }
}

@inline
let classify = schema => schema.tagged

module Builder = {
  type t = builder
  type ctx = builderCtx
  type implementation = (ctx, ~selfSchema: schema<unknown>, ~path: Path.t) => string

  let make = (Obj.magic: implementation => t)

  module Ctx = {
    type t = ctx

    @inline
    let embed = (b: t, value) => {
      `e[${(b._embeded->Js.Array2.push(value->castAnyToUnknown)->(Obj.magic: int => float) -. 1.)
          ->(Obj.magic: float => string)}]`
    }

    let scope = (b: t, fn) => {
      let prevVarsAllocation = b._varsAllocation
      let prevCode = b.code
      b._varsAllocation = ""
      b.code = ""
      let resultCode = fn(b)
      let varsAllocation = b._varsAllocation
      let code = varsAllocation === "" ? b.code : `let ${varsAllocation};${b.code}`
      b._varsAllocation = prevVarsAllocation
      b.code = prevCode
      code ++ resultCode
    }

    let varWithoutAllocation = (b: t) => {
      let newCounter = b._varCounter->Stdlib.Int.plus(1)
      b._varCounter = newCounter
      let v = `v${newCounter->Stdlib.Int.unsafeToString}`
      b._vars->Stdlib.Set.add(v)->ignore
      v
    }

    let var = (b: t) => {
      let v = b->varWithoutAllocation
      b._varsAllocation = b._varsAllocation === "" ? v : b._varsAllocation ++ "," ++ v
      v
    }

    @inline
    let useInput = b => {
      b._input
    }

    let toVar = (b, val) =>
      if b._vars->Stdlib.Set.has(val) {
        val
      } else {
        let var = b->var
        b.code = b.code ++ `${var}=${val};`
        var
      }

    @inline
    let useInputVar = b => {
      b->toVar(b->useInput)
    }

    @inline
    let isInternalError = (_b: t, var) => {
      `${var}&&${var}.s===s`
    }

    let transform = (b: t, ~input, ~isAsync, operation) => {
      if b.isAsyncBranch === true {
        let prevCode = b.code
        b.code = ""
        let inputVar = b->varWithoutAllocation
        let operationOutputVar = operation(b, ~input=inputVar)
        let outputVar = b->var
        b.code =
          prevCode ++
          `${outputVar}=()=>${input}().then(${inputVar}=>{${b.code}return ${operationOutputVar}${isAsync
              ? "()"
              : ""}});`
        outputVar
      } else if isAsync {
        b.isAsyncBranch = true
        // TODO: Would be nice to remove. Needed to enforce that async ops are always vars
        let outputVar = b->var
        b.code = b.code ++ `${outputVar}=${operation(b, ~input)};`
        outputVar
      } else {
        operation(b, ~input)
      }
    }

    let embedSyncOperation = (b: t, ~input, ~fn: 'input => 'output) => {
      b->transform(~input, ~isAsync=false, (b, ~input) => {
        `${b->embed(fn)}(${input})`
      })
    }

    let embedAsyncOperation = (b: t, ~input, ~fn: 'input => unit => promise<'output>) => {
      b->transform(~input, ~isAsync=true, (b, ~input) => {
        `${b->embed(fn)}(${input})`
      })
    }

    let raiseWithArg = (b: t, ~path, fn: 'arg => errorCode, arg) => {
      `${b->embed(arg => {
          InternalError.raise(~path, ~code=fn(arg), ~operation=b.operation)
        })}(${arg})`
    }

    let fail = (b: t, ~message, ~path) => {
      `${b->embed(() => {
          InternalError.raise(~path, ~code=OperationFailed(message), ~operation=b.operation)
        })}()`
    }

    let invalidOperation = (b: t, ~path, ~description) => {
      InternalError.raise(
        ~path,
        ~code=InvalidOperation({description: description}),
        ~operation=b.operation,
      )
    }

    let withCatch = (b: t, ~catch, fn) => {
      let prevCode = b.code

      b.code = ""
      let errorVar = b->varWithoutAllocation
      let maybeResolveVar = catch(b, ~errorVar)
      let catchCode = `if(${b->isInternalError(errorVar)}){${b.code}`

      b.code = ""
      let fnOutput = fn(b)
      let isAsync = b.isAsyncBranch
      let isInlined = !(b._vars->Stdlib.Set.has(fnOutput))

      let outputVar = isAsync || isInlined ? b->var : fnOutput

      let catchCode = switch maybeResolveVar {
      | None => _ => `${catchCode}}throw ${errorVar}`
      | Some(resolveVar) =>
        catchLocation =>
          catchCode ++
          switch catchLocation {
          | #0 if isAsync => `${outputVar}=()=>Promise.resolve(${resolveVar})`
          | #0 => `${outputVar}=${resolveVar}`
          | #1 => `return Promise.resolve(${resolveVar})`
          | #2 => `return ${resolveVar}`
          } ++
          `}else{throw ${errorVar}}`
      }

      b.code =
        prevCode ++
        `try{${b.code}${{
            switch (isAsync, isInlined) {
            | (true, _) =>
              `${outputVar}=()=>{try{return ${fnOutput}().catch(${errorVar}=>{${catchCode(
                  #2,
                )}})}catch(${errorVar}){${catchCode(#1)}}};`
            | (_, true) => `${outputVar}=${fnOutput}`
            | _ => ""
            }
          }}}catch(${errorVar}){${catchCode(#0)}}`

      outputVar
    }

    let withPathPrepend = (b: t, ~path, ~dynamicLocationVar as maybeDynamicLocationVar=?, fn) => {
      if path === Path.empty && maybeDynamicLocationVar === None {
        fn(b, ~path)
      } else {
        try b->withCatch(
          ~catch=(b, ~errorVar) => {
            b.code = `${errorVar}.path=${path->Stdlib.Inlined.Value.fromString}+${switch maybeDynamicLocationVar {
              | Some(var) => `'["'+${var}+'"]'+`
              | _ => ""
              }}${errorVar}.path`
            None
          },
          b => fn(b, ~path=Path.empty),
        ) catch {
        | Raised(error) =>
          InternalError.raise(
            ~path=path->Path.concat(Path.dynamic)->Path.concat(error.path),
            ~code=error.code,
            ~operation=error.operation,
          )
        }
      }
    }

    let typeFilterCode = (b: t, ~typeFilter, ~schema, ~inputVar, ~path) => {
      `if(${typeFilter(~inputVar)}){${b->raiseWithArg(
          ~path,
          input => InvalidType({
            expected: schema,
            received: input,
          }),
          inputVar,
        )}}`
    }

    let use = (b: t, ~schema, ~input, ~path) => {
      let isParentAsync = b.isAsyncBranch
      let isParsing = b.operation === Parsing
      b._input = input
      b.isAsyncBranch = false
      let output = (
        (isParsing ? schema.parseOperationBuilder : schema.serializeOperationBuilder)->(
          Obj.magic: builder => implementation
        )
      )(b, ~selfSchema=schema, ~path)
      if isParsing {
        schema.isAsyncParse = Value(b.isAsyncBranch)
        b.isAsyncBranch = isParentAsync || b.isAsyncBranch
      }
      output
    }

    let useWithTypeFilter = (b: t, ~schema, ~input, ~path) => {
      let input = switch schema.maybeTypeFilter {
      | Some(typeFilter) => {
          let inputVar = b->toVar(input)
          b.code = b.code ++ b->typeFilterCode(~schema, ~typeFilter, ~inputVar, ~path)
          inputVar
        }
      | None => input
      }
      b->use(~schema, ~input, ~path)
    }

    let withBuildErrorInline = (b: t, fn) => {
      try {
        fn()
      } catch {
      | exn => {
          let error = exn->InternalError.getOrRethrow
          b.code = `throw ${b->embed(error)};`
          b._input
        }
      }
    }
  }

  let noop = make((b, ~selfSchema as _, ~path as _) => {
    b->Ctx.useInput
  })

  let noopOperation = i => i->Obj.magic

  @inline
  let intitialInputVar = "i"

  let build = (builder, ~schema, ~operation) => {
    let b = {
      _embeded: [],
      _varCounter: -1,
      _varsAllocation: "",
      _vars: Stdlib.Set.fromArray([intitialInputVar]),
      _input: intitialInputVar,
      code: "",
      isAsyncBranch: false,
      operation,
    }

    let output = (builder->(Obj.magic: builder => implementation))(
      b,
      ~selfSchema=schema,
      ~path=Path.empty,
    )

    if operation === Parsing {
      switch schema.maybeTypeFilter {
      | Some(typeFilter) =>
        b.code =
          b->Ctx.typeFilterCode(
            ~schema,
            ~typeFilter,
            ~inputVar=intitialInputVar,
            ~path=Path.empty,
          ) ++ b.code
      | None => ()
      }
      schema.isAsyncParse = Value(b.isAsyncBranch)
    }

    if b.code === "" && output === intitialInputVar {
      noopOperation
    } else {
      let inlinedFunction = `${intitialInputVar}=>{${b._varsAllocation === ""
          ? ""
          : `let ${b._varsAllocation};`}${b.code}return ${output}}`

      // Js.log(inlinedFunction)

      Stdlib.Function.make2(
        ~ctxVarName1="e",
        ~ctxVarValue1=b._embeded,
        ~ctxVarName2="s",
        ~ctxVarValue2=symbol,
        ~inlinedFunction,
      )
    }
  }
}
// TODO: Split validation code and transformation code
module B = Builder.Ctx

module Literal = {
  open Stdlib

  type rec internal = {
    kind: kind,
    value: unknown,
    @as("s")
    string: string,
    @as("b")
    checkBuilder: (B.t, ~inputVar: string, ~literal: literal) => string,
    @as("j")
    isJsonable: bool,
    @as("i")
    items?: unknown,
  }
  and kind =
    | String
    | Number
    | Boolean
    | BigInt
    | Symbol
    | Array
    | Dict
    | Function
    | Object
    | Null
    | Undefined
    | NaN

  external toInternal: literal => internal = "%identity"
  external toPublic: internal => literal = "%identity"

  @inline
  let value = literal => (literal->toInternal).value

  @inline
  let isJsonable = literal => (literal->toInternal).isJsonable

  @inline
  let toString = literal => (literal->toInternal).string

  let arrayCheckBuilder = (b, ~inputVar, ~literal) => {
    let items = (literal->toInternal).items->(Obj.magic: option<unknown> => array<internal>)

    `(${inputVar}===${b->B.embed(
        literal->value,
      )}||Array.isArray(${inputVar})&&${inputVar}.length===${items
      ->Js.Array2.length
      ->Stdlib.Int.unsafeToString}` ++
    (items->Js.Array2.length > 0
      ? "&&" ++
        items
        ->Js.Array2.mapi((literal, idx) =>
          b->literal.checkBuilder(
            ~inputVar=`${inputVar}[${idx->Stdlib.Int.unsafeToString}]`,
            ~literal=literal->toPublic,
          )
        )
        ->Js.Array2.joinWith("&&")
      : "") ++ ")"
  }

  let dictCheckBuilder = (b, ~inputVar, ~literal) => {
    let items = (literal->toInternal).items->(Obj.magic: option<unknown> => dict<internal>)
    let fields = items->Js.Dict.keys
    let numberOfFields = fields->Js.Array2.length

    `(${inputVar}===${b->B.embed(
        value,
      )}||${inputVar}&&${inputVar}.constructor===Object&&Object.keys(${inputVar}).length===${numberOfFields->Stdlib.Int.unsafeToString}` ++
    (numberOfFields > 0
      ? "&&" ++
        fields
        ->Js.Array2.map(field => {
          let literal = items->Js.Dict.unsafeGet(field)
          b->literal.checkBuilder(
            ~inputVar=`${inputVar}[${field->Stdlib.Inlined.Value.fromString}]`,
            ~literal=literal->toPublic,
          )
        })
        ->Js.Array2.joinWith("&&")
      : "") ++ ")"
  }

  let inlinedStrictEqualCheckBuilder = (_, ~inputVar, ~literal) =>
    `${inputVar}===${literal->toString}`

  let strictEqualCheckBuilder = (b, ~inputVar, ~literal) =>
    `${inputVar}===${b->B.embed(literal->value)}`

  let undefined = {
    kind: Undefined,
    value: %raw(`undefined`),
    string: "undefined",
    isJsonable: false,
    checkBuilder: (_, ~inputVar, ~literal as _) => `${inputVar}===void 0`,
  }

  let null = {
    kind: Null,
    value: %raw(`null`),
    string: "null",
    isJsonable: true,
    checkBuilder: inlinedStrictEqualCheckBuilder,
  }

  let nan = {
    kind: NaN,
    value: %raw(`NaN`),
    string: "NaN",
    isJsonable: false,
    checkBuilder: (_, ~inputVar, ~literal as _) => `Number.isNaN(${inputVar})`,
  }

  let string = value => {
    {
      kind: String,
      value: value->castAnyToUnknown,
      string: Stdlib.Inlined.Value.fromString(value),
      isJsonable: true,
      checkBuilder: inlinedStrictEqualCheckBuilder,
    }
  }

  let boolean = value => {
    {
      kind: Boolean,
      value: value->castAnyToUnknown,
      string: value ? "true" : "false",
      isJsonable: true,
      checkBuilder: inlinedStrictEqualCheckBuilder,
    }
  }

  let number = value => {
    {
      kind: Number,
      value: value->castAnyToUnknown,
      string: value->Js.Float.toString,
      isJsonable: true,
      checkBuilder: inlinedStrictEqualCheckBuilder,
    }
  }

  let symbol = value => {
    {
      kind: Symbol,
      value: value->castAnyToUnknown,
      string: value->Symbol.toString,
      isJsonable: false,
      checkBuilder: strictEqualCheckBuilder,
    }
  }

  let bigint = value => {
    {
      kind: BigInt,
      value: value->castAnyToUnknown,
      string: value->BigInt.toString,
      isJsonable: false,
      checkBuilder: inlinedStrictEqualCheckBuilder,
    }
  }

  let function = value => {
    {
      kind: Function,
      value: value->castAnyToUnknown,
      string: value->Stdlib.Function.toString,
      isJsonable: false,
      checkBuilder: strictEqualCheckBuilder,
    }
  }

  let object = value => {
    {
      kind: Object,
      value: value->castAnyToUnknown,
      string: value->Object.internalClass,
      isJsonable: false,
      checkBuilder: strictEqualCheckBuilder,
    }
  }

  let rec parseInternal = (value): internal => {
    let value = value->castAnyToUnknown
    let typeOfValue = value->Type.typeof
    switch typeOfValue {
    | #undefined => undefined
    | #object if value === %raw(`null`) => null
    | #object if value->Stdlib.Array.isArray => array(value->(Obj.magic: unknown => array<unknown>))
    | #object
      if (value->(Obj.magic: 'a => {"constructor": unknown}))["constructor"] === %raw("Object") =>
      dict(value->(Obj.magic: unknown => Js.Dict.t<unknown>))
    | #object => object(value->(Obj.magic: unknown => Js.Types.obj_val))
    | #function => function(value->(Obj.magic: unknown => Js.Types.function_val))
    | #string => string(value->(Obj.magic: unknown => string))
    | #number if value->(Obj.magic: unknown => float)->Js.Float.isNaN => nan
    | #number => number(value->(Obj.magic: unknown => float))
    | #boolean => boolean(value->(Obj.magic: unknown => bool))
    | #symbol => symbol(value->(Obj.magic: unknown => Js.Types.symbol))
    | #bigint => bigint(value->(Obj.magic: unknown => bigint))
    }
  }
  and dict = value => {
    let items = Js.Dict.empty()
    let string = ref("{")
    let isJsonable = ref(true)
    let fields = value->Js.Dict.keys
    let numberOfFields = fields->Js.Array2.length
    for idx in 0 to numberOfFields - 1 {
      let field = fields->Js.Array2.unsafe_get(idx)
      let itemValue = value->Js.Dict.unsafeGet(field)
      let itemLiteral = itemValue->castUnknownToAny->parseInternal
      if isJsonable.contents && !itemLiteral.isJsonable {
        isJsonable.contents = false
      }
      if idx !== 0 {
        string.contents = string.contents ++ ","
      }
      string.contents =
        string.contents ++ `${field->Inlined.Value.fromString}:${itemLiteral.string}`
      items->Js.Dict.set(field, itemLiteral)
    }

    {
      kind: Dict,
      value: value->castAnyToUnknown,
      items: items->castAnyToUnknown,
      string: string.contents ++ "}",
      isJsonable: isJsonable.contents,
      checkBuilder: dictCheckBuilder,
    }
  }
  and array = value => {
    let items = []
    let isJsonable = ref(true)
    let string = ref("[")
    for idx in 0 to value->Js.Array2.length - 1 {
      let itemValue = value->Js.Array2.unsafe_get(idx)
      let itemLiteral = itemValue->castUnknownToAny->parseInternal
      if isJsonable.contents && !itemLiteral.isJsonable {
        isJsonable.contents = false
      }
      if idx !== 0 {
        string.contents = string.contents ++ ","
      }
      string.contents = string.contents ++ itemLiteral.string
      items->Js.Array2.push(itemLiteral)->ignore
    }

    {
      kind: Array,
      value: value->castAnyToUnknown,
      items: items->castAnyToUnknown,
      isJsonable: isJsonable.contents,
      string: string.contents ++ "]",
      checkBuilder: arrayCheckBuilder,
    }
  }

  @inline
  let parse = any => any->parseInternal->toPublic
}

let toInternalLiteral = {
  let rec loop = schema => {
    switch schema->classify {
    | Literal(literal) => literal->Literal.toInternal
    | Union(unionSchemas) => unionSchemas->Js.Array2.unsafe_get(0)->loop
    | Tuple(tupleSchemas) =>
      tupleSchemas
      ->Js.Array2.map(itemSchema => (itemSchema->loop).value)
      ->Literal.parseInternal
    | Object({fields}) =>
      fields
      ->Stdlib.Dict.mapValues(itemSchema => (itemSchema->loop).value)
      ->Literal.parseInternal
    | String
    | Int
    | Float
    | Bool
    | Option(_)
    | Null(_)
    | Never
    | Unknown
    | JSON(_)
    | Array(_)
    | Dict(_) =>
      Stdlib.Exn.raiseAny(symbol)
    }
  }
  schema => {
    try {
      Some(loop(schema))
    } catch {
    | Js.Exn.Error(jsExn) =>
      jsExn->(Obj.magic: Js.Exn.t => Stdlib.Symbol.t) === symbol ? None : Stdlib.Exn.raiseAny(jsExn)
    }
  }
}

let isAsyncParse = schema => {
  let schema = schema->toUnknown
  switch schema.isAsyncParse {
  | Unknown =>
    try {
      let _ = schema.parseOperationBuilder->Builder.build(~schema, ~operation=Parsing)
      schema.isAsyncParse->(Obj.magic: isAsyncParse => bool)
    } catch {
    | exn => {
        let _ = exn->InternalError.getOrRethrow
        false
      }
    }
  | Value(v) => v
  }
}

let rec validateJsonableSchema = (schema, ~rootSchema, ~isRoot=false) => {
  if isRoot || rootSchema !== schema {
    switch schema->classify {
    | String
    | Int
    | Float
    | Bool
    | Never
    | JSON(_) => ()
    | Dict(schema)
    | Null(schema)
    | Array(schema) =>
      schema->validateJsonableSchema(~rootSchema)
    | Object({fieldNames, fields}) =>
      for idx in 0 to fieldNames->Js.Array2.length - 1 {
        let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
        let fieldSchema = fields->Js.Dict.unsafeGet(fieldName)
        try {
          switch fieldSchema->classify {
          // Allow optional fields
          | Option(s) => s
          | _ => fieldSchema
          }->validateJsonableSchema(~rootSchema)
        } catch {
        | exn => exn->InternalError.prependLocationOrRethrow(fieldName)
        }
      }

    | Tuple(childrenSchemas) =>
      childrenSchemas->Js.Array2.forEachi((schema, i) => {
        try {
          schema->validateJsonableSchema(~rootSchema)
        } catch {
        // TODO: Should throw with the nested schema instead of prepending path?
        | exn => exn->InternalError.prependLocationOrRethrow(i->Js.Int.toString)
        }
      })
    | Union(childrenSchemas) =>
      childrenSchemas->Js.Array2.forEach(schema => schema->validateJsonableSchema(~rootSchema))
    | Literal(l) if l->Literal.isJsonable => ()
    | Option(_)
    | Unknown
    | Literal(_) =>
      InternalError.raise(~path=Path.empty, ~code=InvalidJsonStruct(schema), ~operation=Serializing)
    }
  }
}

@inline
let make = (
  ~name,
  ~tagged,
  ~metadataMap,
  ~parseOperationBuilder,
  ~serializeOperationBuilder,
  ~maybeTypeFilter,
  ~toJsonString=?,
) => {
  tagged,
  parseOperationBuilder,
  serializeOperationBuilder,
  isAsyncParse: Unknown,
  ?maybeTypeFilter,
  maybeToJsonString: ?toJsonString,
  name,
  metadataMap,
}

@inline
let makeWithNoopSerializer = (
  ~name,
  ~tagged,
  ~metadataMap,
  ~parseOperationBuilder,
  ~maybeTypeFilter,
  ~toJsonString=?,
) => {
  name,
  tagged,
  parseOperationBuilder,
  serializeOperationBuilder: Builder.noop,
  isAsyncParse: Unknown,
  ?maybeTypeFilter,
  maybeToJsonString: ?toJsonString,
  metadataMap,
}

let defaultToJsonString = input => `JSON.stringify(${input})`

module Operation = {
  let unexpectedAsync = _ =>
    InternalError.raise(~path=Path.empty, ~code=UnexpectedAsync, ~operation=Parsing)

  type label =
    | @as("op") Parser | @as("opa") ParserAsync | @as("os") Serializer | @as("osj") SerializerToJson

  @inline
  let make = (~label: label, ~init: t<unknown> => 'input => 'output) => {
    (
      (i, s) => {
        try {
          (s->Obj.magic->Js.Dict.unsafeGet((label :> string)))(i)
        } catch {
        | _ =>
          if s->Obj.magic->Js.Dict.unsafeGet((label :> string))->Obj.magic {
            %raw(`exn`)->Stdlib.Exn.raiseAny
          } else {
            let o = init(s->Obj.magic)
            s->Obj.magic->Js.Dict.set((label :> string), o)
            o(i)
          }
        }
      }
    )->Obj.magic
  }
}

let parseAnyOrRaiseWith = Operation.make(~label=Parser, ~init=schema => {
  let operation = schema.parseOperationBuilder->Builder.build(~schema, ~operation=Parsing)
  let isAsync = schema.isAsyncParse->(Obj.magic: isAsyncParse => bool)
  isAsync ? Operation.unexpectedAsync : operation
})

let parseAnyWith = (any, schema) => {
  try {
    parseAnyOrRaiseWith(any->castAnyToUnknown, schema)->castUnknownToAny->Ok
  } catch {
  | exn => exn->InternalError.getOrRethrow->Error
  }
}

let parseWith: (Js.Json.t, t<'value>) => result<'value, error> = parseAnyWith

let parseOrRaiseWith: (Js.Json.t, t<'value>) => 'value = parseAnyOrRaiseWith

let asyncPrepareOk = value => Ok(value->castUnknownToAny)

let asyncPrepareError = jsExn => {
  jsExn->(Obj.magic: Js.Exn.t => exn)->InternalError.getOrRethrow->Error
}

let internalParseAsyncWith = Operation.make(~label=ParserAsync, ~init=schema => {
  let operation = schema.parseOperationBuilder->Builder.build(~schema, ~operation=Parsing)
  let isAsync = schema.isAsyncParse->(Obj.magic: isAsyncParse => bool)
  isAsync
    ? operation->(Obj.magic: (unknown => unknown) => unknown => unit => promise<unknown>)
    : input => {
        let syncValue = operation(input)
        () => syncValue->Stdlib.Promise.resolve
      }
})

let parseAnyAsyncWith = (any, schema) => {
  try {
    internalParseAsyncWith(any->castAnyToUnknown, schema)()->Stdlib.Promise.thenResolveWithCatch(
      asyncPrepareOk,
      asyncPrepareError,
    )
  } catch {
  | exn => exn->InternalError.getOrRethrow->Error->Stdlib.Promise.resolve
  }
}

let parseAsyncWith = parseAnyAsyncWith

let parseAnyAsyncInStepsWith = (any, schema) => {
  try {
    let asyncFn = internalParseAsyncWith(any->castAnyToUnknown, schema)
    (() => asyncFn()->Stdlib.Promise.thenResolveWithCatch(asyncPrepareOk, asyncPrepareError))->Ok
  } catch {
  | exn => exn->InternalError.getOrRethrow->Error
  }
}

let parseAsyncInStepsWith = parseAnyAsyncInStepsWith

let serializeOrRaiseWith = Operation.make(~label=SerializerToJson, ~init=schema => {
  schema->validateJsonableSchema(~rootSchema=schema, ~isRoot=true)
  schema.serializeOperationBuilder->Builder.build(~schema, ~operation=Serializing)
})

let serializeWith = (value, schema) => {
  try {
    serializeOrRaiseWith(value, schema)->Ok
  } catch {
  | exn => exn->InternalError.getOrRethrow->Error
  }
}

let serializeToUnknownOrRaiseWith = Operation.make(~label=Serializer, ~init=schema => {
  schema.serializeOperationBuilder->Builder.build(~schema, ~operation=Serializing)
})

let serializeToUnknownWith = (value, schema) => {
  try {
    serializeToUnknownOrRaiseWith(value, schema)->Ok
  } catch {
  | exn => exn->InternalError.getOrRethrow->Error
  }
}

let serializeToJsonStringWith = (value: 'value, schema: t<'value>, ~space=0): result<
  string,
  error,
> => {
  switch value->serializeWith(schema) {
  | Ok(json) => Ok(json->Js.Json.stringifyWithSpace(space))
  | Error(_) as e => e
  }
}

let serializeToJsonStringOrRaiseWith = (value: 'value, schema: t<'value>, ~space=0): string => {
  value->serializeOrRaiseWith(schema)->Js.Json.stringifyWithSpace(space)
}

let parseJsonStringWith = (json: string, schema: t<'value>): result<'value, error> => {
  switch try {
    json->Js.Json.parseExn->Ok
  } catch {
  | Js.Exn.Error(error) =>
    Error(
      InternalError.make(
        ~code=OperationFailed(error->Js.Exn.message->(Obj.magic: option<string> => string)),
        ~operation=Parsing,
        ~path=Path.empty,
      ),
    )
  } {
  | Ok(json) => json->parseWith(schema)
  | Error(_) as e => e
  }
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

  module Map = {
    let empty = Js.Dict.empty()

    let set = (map, ~id: Id.t<'metadata>, metadata: 'metadata) => {
      map === empty
        ? %raw(`{[id]:metadata}`)
        : {
            let copy = map->Stdlib.Dict.copy
            copy->Js.Dict.set(id->Id.toKey, metadata->castAnyToUnknown)
            copy
          }
    }
  }

  let get = (schema, ~id: Id.t<'metadata>) => {
    schema.metadataMap->Js.Dict.unsafeGet(id->Id.toKey)->(Obj.magic: unknown => option<'metadata>)
  }

  let set = (schema, ~id: Id.t<'metadata>, metadata: 'metadata) => {
    let metadataMap = schema.metadataMap->Map.set(~id, metadata)
    make(
      ~name=schema.name,
      ~parseOperationBuilder=schema.parseOperationBuilder,
      ~serializeOperationBuilder=schema.serializeOperationBuilder,
      ~tagged=schema.tagged,
      ~maybeTypeFilter=schema.maybeTypeFilter,
      ~toJsonString=?schema.maybeToJsonString,
      ~metadataMap,
    )
  }
}

let recursive = fn => {
  let placeholder: t<'value> = {"m": Metadata.Map.empty}->Obj.magic
  let schema = fn(placeholder)
  placeholder->Stdlib.Object.overrideWith(schema)

  {
    let builder = placeholder.parseOperationBuilder
    placeholder.parseOperationBuilder = Builder.make((b, ~selfSchema, ~path) => {
      let input = b->B.useInput
      let isAsync = {
        selfSchema.parseOperationBuilder = Builder.noop
        let ctx = {
          _embeded: [],
          _varsAllocation: "",
          code: "",
          _input: Builder.intitialInputVar,
          _varCounter: -1,
          _vars: Stdlib.Set.fromArray([Builder.intitialInputVar]),
          isAsyncBranch: false,
          operation: Parsing,
        }
        let _ = (builder->(Obj.magic: builder => Builder.implementation))(ctx, ~selfSchema, ~path)
        ctx.isAsyncBranch
      }

      selfSchema.parseOperationBuilder = Builder.make((b, ~selfSchema, ~path as _) => {
        let input = b->B.useInput
        if isAsync {
          b->B.embedAsyncOperation(~input, ~fn=input => input->internalParseAsyncWith(selfSchema))
        } else {
          b->B.embedSyncOperation(~input, ~fn=input => input->parseAnyOrRaiseWith(selfSchema))
        }
      })

      let operation = builder->Builder.build(~schema=selfSchema, ~operation=Parsing)
      if isAsync {
        selfSchema->Obj.magic->Js.Dict.set((Operation.ParserAsync :> string), operation)
      } else {
        // TODO: Use init function
        selfSchema->Obj.magic->Js.Dict.set((Operation.Parser :> string), operation)
      }

      selfSchema.parseOperationBuilder = builder
      b->B.withPathPrepend(~path, (b, ~path as _) =>
        if isAsync {
          b->B.embedAsyncOperation(~input, ~fn=operation)
        } else {
          b->B.embedSyncOperation(~input, ~fn=operation)
        }
      )
    })
  }

  {
    let builder = placeholder.serializeOperationBuilder
    placeholder.serializeOperationBuilder = Builder.make((b, ~selfSchema, ~path) => {
      let input = b->B.useInput
      selfSchema.serializeOperationBuilder = Builder.make((b, ~selfSchema, ~path as _) => {
        let input = b->B.useInput
        b->B.embedSyncOperation(
          ~input,
          ~fn=input => input->serializeToUnknownOrRaiseWith(selfSchema),
        )
      })

      let operation = builder->Builder.build(~schema=selfSchema, ~operation=Serializing)

      // TODO: Use init function
      // TODO: What about json validation ?? Check whether it works correctly
      selfSchema->Obj.magic->Js.Dict.set((Operation.Serializer :> string), operation)

      selfSchema.serializeOperationBuilder = builder
      b->B.withPathPrepend(~path, (b, ~path as _) => b->B.embedSyncOperation(~input, ~fn=operation))
    })
  }

  placeholder
}

let setName = (schema, name) => {
  make(
    ~name=() => name,
    ~parseOperationBuilder=schema.parseOperationBuilder,
    ~serializeOperationBuilder=schema.serializeOperationBuilder,
    ~tagged=schema.tagged,
    ~maybeTypeFilter=schema.maybeTypeFilter,
    ~toJsonString=?schema.maybeToJsonString,
    ~metadataMap=schema.metadataMap,
  )
}

let primitiveName = () => {
  (%raw(`this`): t<'a>).tagged->(Obj.magic: tagged => string)
}

let containerName = () => {
  let tagged = (%raw(`this`): t<'a>).tagged->Obj.magic
  `${tagged["TAG"]}(${(tagged->unsafeGetVariantPayload).name()})`
}

let internalRefine = (schema, refiner) => {
  let schema = schema->toUnknown
  make(
    ~name=schema.name,
    ~tagged=schema.tagged,
    ~parseOperationBuilder=Builder.make((b, ~selfSchema, ~path) => {
      let input = b->B.useInput
      b->B.transform(~input=b->B.use(~schema, ~input, ~path), ~isAsync=false, (b, ~input) => {
        let inputVar = b->B.toVar(input)
        b.code = b.code ++ refiner(b, ~inputVar, ~selfSchema, ~path)
        inputVar
      })
    }),
    ~serializeOperationBuilder=Builder.make((b, ~selfSchema, ~path) => {
      let input = b->B.useInput
      b->B.use(
        ~schema,
        ~input=b->B.transform(~input, ~isAsync=false, (b, ~input) => {
          let inputVar = b->B.toVar(input)
          b.code = b.code ++ refiner(b, ~inputVar, ~selfSchema, ~path)
          inputVar
        }),
        ~path,
      )
    }),
    ~maybeTypeFilter=schema.maybeTypeFilter,
    ~toJsonString=?schema.maybeToJsonString,
    ~metadataMap=schema.metadataMap,
  )
}

let refine: (t<'value>, s<'value> => 'value => unit) => t<'value> = (schema, refiner) => {
  schema->internalRefine((b, ~inputVar, ~selfSchema, ~path) => {
    `${b->B.embed(
        refiner(EffectCtx.make(~selfSchema, ~path, ~operation=b.operation)),
      )}(${inputVar});`
  })
}

let addRefinement = (schema, ~metadataId, ~refinement, ~refiner) => {
  schema
  ->Metadata.set(
    ~id=metadataId,
    switch schema->Metadata.get(~id=metadataId) {
    | Some(refinements) => refinements->Stdlib.Array.append(refinement)
    | None => [refinement]
    },
  )
  ->internalRefine(refiner)
}

type transformDefinition<'input, 'output> = {
  @as("p")
  parser?: 'input => 'output,
  @as("a")
  asyncParser?: 'input => unit => promise<'output>,
  @as("s")
  serializer?: 'output => 'input,
}
let transform: (t<'input>, s<'output> => transformDefinition<'input, 'output>) => t<'output> = (
  schema,
  transformer,
) => {
  let schema = schema->toUnknown
  make(
    ~name=schema.name,
    ~tagged=schema.tagged,
    ~parseOperationBuilder=Builder.make((b, ~selfSchema, ~path) => {
      let input = b->B.useInput
      let input = b->B.use(~schema, ~input, ~path)
      switch transformer(EffectCtx.make(~selfSchema, ~path, ~operation=b.operation)) {
      | {parser, asyncParser: ?None} => b->B.embedSyncOperation(~input, ~fn=parser)
      | {parser: ?None, asyncParser} => b->B.embedAsyncOperation(~input, ~fn=asyncParser)
      | {parser: ?None, asyncParser: ?None, serializer: ?None} => input
      | {parser: ?None, asyncParser: ?None, serializer: _} =>
        b->B.invalidOperation(~path, ~description=`The S.transform parser is missing`)
      | {parser: _, asyncParser: _} =>
        b->B.invalidOperation(
          ~path,
          ~description=`The S.transform doesn't allow parser and asyncParser at the same time. Remove parser in favor of asyncParser.`,
        )
      }
    }),
    ~serializeOperationBuilder=Builder.make((b, ~selfSchema, ~path) => {
      let input = b->B.useInput
      switch transformer(EffectCtx.make(~selfSchema, ~path, ~operation=b.operation)) {
      | {serializer} =>
        b->B.use(~schema, ~input=b->B.embedSyncOperation(~input, ~fn=serializer), ~path)
      | {parser: ?None, asyncParser: ?None, serializer: ?None} => b->B.use(~schema, ~input, ~path)
      | {serializer: ?None, asyncParser: ?Some(_)}
      | {serializer: ?None, parser: ?Some(_)} =>
        b->B.invalidOperation(~path, ~description=`The S.transform serializer is missing`)
      }
    }),
    ~maybeTypeFilter=schema.maybeTypeFilter,
    ~toJsonString=?schema.maybeToJsonString,
    ~metadataMap=schema.metadataMap,
  )
}

type preprocessDefinition<'input, 'output> = {
  @as("p")
  parser?: unknown => 'output,
  @as("a")
  asyncParser?: unknown => unit => promise<'output>,
  @as("s")
  serializer?: unknown => 'input,
}
let rec preprocess = (schema, transformer) => {
  let schema = schema->toUnknown
  switch schema->classify {
  | Union(unionSchemas) =>
    make(
      ~name=schema.name,
      ~tagged=Union(
        unionSchemas->Js.Array2.map(unionSchema =>
          unionSchema->castUnknownSchemaToAnySchema->preprocess(transformer)->toUnknown
        ),
      ),
      ~parseOperationBuilder=schema.parseOperationBuilder,
      ~serializeOperationBuilder=schema.serializeOperationBuilder,
      ~maybeTypeFilter=schema.maybeTypeFilter,
      ~metadataMap=schema.metadataMap,
    )
  | _ =>
    make(
      ~name=schema.name,
      ~tagged=schema.tagged,
      ~parseOperationBuilder=Builder.make((b, ~selfSchema, ~path) => {
        let input = b->B.useInput
        switch transformer(EffectCtx.make(~selfSchema, ~path, ~operation=b.operation)) {
        | {parser, asyncParser: ?None} =>
          let operationResultVar = b->B.var
          b.code = b.code ++ `${operationResultVar}=${b->B.embedSyncOperation(~input, ~fn=parser)};`
          b->B.useWithTypeFilter(~schema, ~input=operationResultVar, ~path)
        | {parser: ?None, asyncParser} => {
            let parseResultVar = b->B.embedAsyncOperation(~input, ~fn=asyncParser)
            let outputVar = b->B.var
            let asyncResultVar = b->B.varWithoutAllocation

            // TODO: Optimize async transformation to chain .then
            b.code =
              b.code ++
              `${outputVar}=()=>${parseResultVar}().then(${asyncResultVar}=>{${b->B.scope(b => {
                  let schemaOutputVar =
                    b->B.useWithTypeFilter(~schema, ~input=asyncResultVar, ~path)
                  let isAsync = schema.isAsyncParse->(Obj.magic: isAsyncParse => bool)
                  `return ${isAsync ? `${schemaOutputVar}()` : schemaOutputVar}`
                })}});`
            outputVar
          }
        | {parser: ?None, asyncParser: ?None} => b->B.useWithTypeFilter(~schema, ~input, ~path)
        | {parser: _, asyncParser: _} =>
          b->B.invalidOperation(
            ~path,
            ~description=`The S.preprocess doesn't allow parser and asyncParser at the same time. Remove parser in favor of asyncParser.`,
          )
        }
      }),
      ~serializeOperationBuilder=Builder.make((b, ~selfSchema, ~path) => {
        let input = b->B.useInput
        let input = b->B.use(~schema, ~input, ~path)
        switch transformer(EffectCtx.make(~selfSchema, ~path, ~operation=b.operation)) {
        | {serializer} => b->B.embedSyncOperation(~input, ~fn=serializer)
        // TODO: Test that it doesn't return InvalidOperation when parser is passed but not serializer
        | {serializer: ?None} => input
        }
      }),
      ~maybeTypeFilter=None,
      ~metadataMap=schema.metadataMap,
    )
  }
}

type customDefinition<'input, 'output> = {
  @as("p")
  parser?: unknown => 'output,
  @as("a")
  asyncParser?: unknown => unit => promise<'output>,
  @as("s")
  serializer?: 'output => 'input,
}
let custom = (name, definer) => {
  make(
    ~name=() => name,
    ~metadataMap=Metadata.Map.empty,
    ~tagged=Unknown,
    ~parseOperationBuilder=Builder.make((b, ~selfSchema, ~path) => {
      let input = b->B.useInput
      switch definer(EffectCtx.make(~selfSchema, ~path, ~operation=b.operation)) {
      | {parser, asyncParser: ?None} => b->B.embedSyncOperation(~input, ~fn=parser)
      | {parser: ?None, asyncParser} => b->B.embedAsyncOperation(~input, ~fn=asyncParser)
      | {parser: ?None, asyncParser: ?None, serializer: ?None} => input
      | {parser: ?None, asyncParser: ?None, serializer: _} =>
        b->B.invalidOperation(~path, ~description=`The S.custom parser is missing`)
      | {parser: _, asyncParser: _} =>
        b->B.invalidOperation(
          ~path,
          ~description=`The S.custom doesn't allow parser and asyncParser at the same time. Remove parser in favor of asyncParser.`,
        )
      }
    }),
    ~serializeOperationBuilder=Builder.make((b, ~selfSchema, ~path) => {
      let input = b->B.useInput
      switch definer(EffectCtx.make(~selfSchema, ~path, ~operation=b.operation)) {
      | {serializer} => b->B.embedSyncOperation(~input, ~fn=serializer)
      | {parser: ?None, asyncParser: ?None, serializer: ?None} => input
      | {serializer: ?None, asyncParser: ?Some(_)}
      | {serializer: ?None, parser: ?Some(_)} =>
        b->B.invalidOperation(~path, ~description=`The S.custom serializer is missing`)
      }
    }),
    ~maybeTypeFilter=None,
  )
}

let literal = value => {
  let value = value->castAnyToUnknown
  let literal = value->Literal.parse
  let internalLiteral = literal->Literal.toInternal
  let operationBuilder = Builder.make((b, ~selfSchema as _, ~path) => {
    let inputVar = b->B.useInputVar
    b.code =
      b.code ++
      `${b->internalLiteral.checkBuilder(~inputVar, ~literal)}||${b->B.raiseWithArg(
          ~path,
          input => InvalidLiteral({
            expected: literal,
            received: input,
          }),
          inputVar,
        )};`
    inputVar
  })
  make(
    ~name=() => `Literal(${literal->Literal.toString})`,
    ~metadataMap=Metadata.Map.empty,
    ~tagged=Literal(literal),
    ~parseOperationBuilder=operationBuilder,
    ~serializeOperationBuilder=operationBuilder,
    ~maybeTypeFilter=None,
    ~toJsonString=?switch literal->Literal.isJsonable {
    | true => {
        let string = literal->Literal.toString->Stdlib.Inlined.Value.fromString
        Some(_ => string)
      }
    | false => None
    },
  )
}
let unit = literal(%raw("void 0"))

module Definition = {
  type t<'embeded>
  type node<'embeded> = dict<t<'embeded>>
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
    (schema: t<'value>, definer: 'value => 'variant): t<'variant> => {
      let schema = schema->toUnknown
      make(
        ~name=schema.name,
        ~tagged=schema.tagged,
        ~parseOperationBuilder=Builder.make((b, ~selfSchema as _, ~path) => {
          let input = b->B.useInput
          b->B.embedSyncOperation(~input=b->B.use(~schema, ~input, ~path), ~fn=definer)
        }),
        ~serializeOperationBuilder=Builder.make((b, ~selfSchema, ~path) => {
          let inputVar = b->B.useInputVar

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
                        ~path=path->Path.concat(outputPath),
                        input => InvalidLiteral({
                          expected: constant->Literal.parse,
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
          | RegisteredMultipleTimes =>
            b->B.invalidOperation(
              ~path,
              ~description=`Can't create serializer. The S.variant's value is registered multiple times. Use S.transform instead`,
            )
          | Registered(var) => b->B.use(~schema, ~input=var, ~path)
          | Unregistered =>
            switch selfSchema->toInternalLiteral {
            | Some(literal) => b->B.use(~schema, ~input=b->B.embed(literal.value), ~path)
            | None =>
              b->B.invalidOperation(
                ~path,
                ~description=`Can't create serializer. The S.variant's value is not registered and not a literal. Use S.transform instead`,
              )
            }
          }
        }),
        ~maybeTypeFilter=schema.maybeTypeFilter,
        ~toJsonString=?schema.maybeToJsonString,
        ~metadataMap=schema.metadataMap,
      )
    }
  }
}

module Option = {
  type default = Value(unknown) | Callback(unit => unknown)

  let defaultMetadataId: Metadata.Id.t<default> = Metadata.Id.make(
    ~namespace="rescript-schema",
    ~name="Option.default",
  )

  let default = schema => schema->Metadata.get(~id=defaultMetadataId)

  let parseOperationBuilder = Builder.make((b, ~selfSchema, ~path) => {
    let inputVar = b->B.useInputVar
    let outputVar = b->B.var

    let isNull = %raw(`selfSchema.t.TAG === "Null"`)
    let childSchema = selfSchema.tagged->unsafeGetVariantPayload

    let ifCode = b->B.scope(b => {
      `${outputVar}=${b->B.use(~schema=childSchema, ~input=inputVar, ~path)}`
    })
    let isAsync = childSchema.isAsyncParse->(Obj.magic: isAsyncParse => bool)

    b.code =
      b.code ++
      `if(${inputVar}!==${isNull
          ? "null"
          : "void 0"}){${ifCode}}else{${outputVar}=${switch isAsync {
        | false => `void 0`
        | true => `()=>Promise.resolve(void 0)`
        }}}`

    outputVar
  })

  let serializeOperationBuilder = Builder.make((b, ~selfSchema, ~path) => {
    let inputVar = b->B.useInputVar
    let outputVar = b->B.var

    let isNull = %raw(`selfSchema.t.TAG === "Null"`)
    let childSchema = selfSchema.tagged->unsafeGetVariantPayload

    b.code =
      b.code ++
      `if(${inputVar}!==void 0){${b->B.scope(b => {
          `${outputVar}=${b->B.use(
              ~schema=childSchema,
              ~input=`${b->B.embed(%raw("Caml_option.valFromOption"))}(${inputVar})`,
              ~path,
            )}`
        })}}else{${outputVar}=${isNull ? `null` : `void 0`}}`
    outputVar
  })

  let maybeTypeFilter = (~schema, ~inlinedNoneValue) => {
    switch schema.maybeTypeFilter {
    | Some(typeFilter) =>
      Some(
        (~inputVar) => {
          `${inputVar}!==${inlinedNoneValue}&&(${typeFilter(~inputVar)})`
        },
      )
    | None => None
    }
  }

  let factory = schema => {
    let schema = schema->toUnknown
    make(
      ~name=containerName,
      ~metadataMap=Metadata.Map.empty,
      ~tagged=Option(schema),
      ~parseOperationBuilder,
      ~serializeOperationBuilder,
      ~maybeTypeFilter=maybeTypeFilter(~schema, ~inlinedNoneValue="void 0"),
    )
  }

  let getWithDefault = (schema, default) => {
    let schema = schema->(Obj.magic: t<option<'value>> => t<unknown>)
    make(
      ~name=schema.name,
      ~metadataMap=schema.metadataMap->Metadata.Map.set(~id=defaultMetadataId, default),
      ~tagged=schema.tagged,
      ~parseOperationBuilder=Builder.make((b, ~selfSchema as _, ~path) => {
        let input = b->B.useInput
        b->B.transform(~input=b->B.use(~schema, ~input, ~path), ~isAsync=false, (b, ~input) => {
          // TODO: Reassign input if it's not a var
          `${input}===void 0?${switch default {
            | Value(v) => b->B.embed(v)
            | Callback(cb) => `${b->B.embed(cb)}()`
            }}:${input}`
        })
      }),
      ~serializeOperationBuilder=schema.serializeOperationBuilder,
      ~maybeTypeFilter=schema.maybeTypeFilter,
    )
  }

  let getOr = (schema, defalutValue) =>
    schema->getWithDefault(Value(defalutValue->castAnyToUnknown))
  let getOrWith = (schema, defalutCb) =>
    schema->getWithDefault(Callback(defalutCb->(Obj.magic: (unit => 'a) => unit => unknown)))
}

module Null = {
  let factory = schema => {
    let schema = schema->toUnknown
    make(
      ~name=containerName,
      ~metadataMap=Metadata.Map.empty,
      ~tagged=Null(schema),
      ~parseOperationBuilder=Option.parseOperationBuilder,
      ~serializeOperationBuilder=Option.serializeOperationBuilder,
      ~maybeTypeFilter=Option.maybeTypeFilter(~schema, ~inlinedNoneValue="null"),
      ~toJsonString=defaultToJsonString, // FIXME:
    )
  }
}

let nullable = schema => {
  Option.factory(Null.factory(schema))
}

module Object = {
  type s = {
    @as("f") field: 'value. (string, t<'value>) => 'value,
    @as("o") fieldOr: 'value. (string, t<'value>, 'value) => 'value,
    @as("t") tag: 'value. (string, 'value) => unit,
  }
  type itemDefinition = {
    @as("s")
    schema: schema<unknown>,
    @as("l")
    inlinedInputLocation: string,
    @as("p")
    inputPath: Path.t,
  }

  let typeFilter = (~inputVar) => `!${inputVar}||${inputVar}.constructor!==Object`

  let noopRefinement = (_b, ~selfSchema as _, ~inputVar as _, ~path as _) => ()

  let makeParseOperationBuilder = (
    ~itemDefinitions,
    ~itemDefinitionsSet,
    ~definition,
    ~inputRefinement,
    ~unknownKeysRefinement,
  ) => {
    Builder.make((b, ~selfSchema, ~path) => {
      let inputVar = b->B.useInputVar

      let registeredDefinitions = Stdlib.Set.empty()
      let asyncOutputVars = []

      inputRefinement(b, ~selfSchema, ~inputVar, ~path)

      let prevCode = b.code
      b.code = ""
      unknownKeysRefinement(b, ~selfSchema, ~inputVar, ~path)
      let unknownKeysRefinementCode = b.code
      b.code = ""

      let syncOutput = {
        let rec definitionToOutput = (definition: Definition.t<itemDefinition>, ~outputPath) => {
          let kind = definition->Definition.toKindWithSet(~embededSet=itemDefinitionsSet)
          switch kind {
          | Embeded => {
              let itemDefinition = definition->Definition.toEmbeded
              registeredDefinitions->Stdlib.Set.add(itemDefinition)->ignore
              let {schema, inputPath} = itemDefinition
              let fieldOuputVar =
                b->B.useWithTypeFilter(
                  ~schema,
                  ~input=`${inputVar}${inputPath}`,
                  ~path=path->Path.concat(inputPath),
                )
              let isAsyncField = schema.isAsyncParse->(Obj.magic: isAsyncParse => bool)
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
      let registeredFieldsCode = b.code
      b.code = ""

      for idx in 0 to itemDefinitions->Js.Array2.length - 1 {
        let itemDefinition = itemDefinitions->Js.Array2.unsafe_get(idx)
        if registeredDefinitions->Stdlib.Set.has(itemDefinition)->not {
          let {schema, inputPath} = itemDefinition
          let fieldOuputVar =
            b->B.useWithTypeFilter(
              ~schema,
              ~input=`${inputVar}${inputPath}`,
              ~path=path->Path.concat(inputPath),
            )
          let isAsyncField = schema.isAsyncParse->(Obj.magic: isAsyncParse => bool)
          if isAsyncField {
            // TODO: Ensure that it's not a var, but inlined
            asyncOutputVars->Js.Array2.push(fieldOuputVar)->ignore
          }
        }
      }
      let unregisteredFieldsCode = b.code

      b.code =
        prevCode ++ unregisteredFieldsCode ++ registeredFieldsCode ++ unknownKeysRefinementCode

      if asyncOutputVars->Js.Array2.length === 0 {
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
    })
  }

  module Ctx = {
    type t = {
      @as("n")
      fieldNames: array<string>,
      @as("h")
      fields: dict<schema<unknown>>,
      @as("d")
      itemDefinitionsSet: Stdlib.Set.t<itemDefinition>,
      // Public API for JS/TS users.
      // It shouldn't be used from ReScript and
      // needed only because we use @as to reduce bundle-size
      // of ReScript compiled code
      @as("field") _jsField: 'value. (string, t<'value>) => 'value,
      @as("fieldOr") _jsFieldOr: 'value. (string, t<'value>, 'value) => 'value,
      @as("tag") _jsTag: 'value. (string, 'value) => unit,
      // Public API for ReScript users
      ...s,
    }

    @inline
    let make = () => {
      let fields = Js.Dict.empty()
      let fieldNames = []
      let itemDefinitionsSet = Stdlib.Set.empty()

      let field:
        type value. (string, schema<value>) => value =
        (fieldName, schema) => {
          let schema = schema->toUnknown
          let inlinedInputLocation = fieldName->Stdlib.Inlined.Value.fromString
          if fields->Stdlib.Dict.has(fieldName) {
            InternalError.panic(
              `The field ${inlinedInputLocation} is defined multiple times. If you want to duplicate the field, use S.transform instead.`,
            )
          } else {
            let itemDefinition: itemDefinition = {
              schema,
              inlinedInputLocation,
              inputPath: inlinedInputLocation->Path.fromInlinedLocation,
            }
            fields->Js.Dict.set(fieldName, schema)
            fieldNames->Js.Array2.push(fieldName)->ignore
            itemDefinitionsSet->Stdlib.Set.add(itemDefinition)->ignore
            itemDefinition->(Obj.magic: itemDefinition => value)
          }
        }

      let tag = (tag, asValue) => {
        let _ = field(tag, literal(asValue))
      }

      let fieldOr = (fieldName, schema, or) => {
        field(fieldName, Option.factory(schema)->Option.getOr(or))
      }

      {
        fieldNames,
        fields,
        itemDefinitionsSet,
        // js/ts methods
        _jsField: field,
        _jsFieldOr: fieldOr,
        _jsTag: tag,
        // methods
        field,
        fieldOr,
        tag,
      }
    }
  }

  let factory = definer => {
    let ctx = Ctx.make()
    let definition = definer((ctx :> s))->(Obj.magic: 'any => Definition.t<itemDefinition>)
    let {itemDefinitionsSet, fields, fieldNames} = ctx
    let itemDefinitions = itemDefinitionsSet->Stdlib.Set.toArray

    make(
      ~name=() =>
        `Object({${fieldNames
          ->Js.Array2.map(fieldName => {
            let fieldSchema = fields->Js.Dict.unsafeGet(fieldName)
            `${fieldName->Stdlib.Inlined.Value.fromString}: ${fieldSchema.name()}`
          })
          ->Js.Array2.joinWith(", ")}})`,
      ~metadataMap=Metadata.Map.empty,
      ~tagged=Object({
        fields,
        fieldNames,
        unknownKeys: Strip,
      }),
      ~parseOperationBuilder=makeParseOperationBuilder(
        ~itemDefinitions,
        ~itemDefinitionsSet,
        ~definition,
        ~inputRefinement=noopRefinement,
        ~unknownKeysRefinement=(b, ~selfSchema, ~inputVar, ~path) => {
          let withUnknownKeysRefinement =
            (selfSchema->classify->Obj.magic)["unknownKeys"] === Strict
          switch (withUnknownKeysRefinement, itemDefinitions) {
          | (true, []) => {
              let keyVar = b->B.var
              b.code =
                b.code ++
                `for(${keyVar} in ${inputVar}){${b->B.raiseWithArg(
                    ~path,
                    exccessFieldName => ExcessField(exccessFieldName),
                    keyVar,
                  )}}`
            }
          | (true, _) => {
              let keyVar = b->B.var
              b.code = b.code ++ `for(${keyVar} in ${inputVar}){if(`
              for idx in 0 to itemDefinitions->Js.Array2.length - 1 {
                let itemDefinition = itemDefinitions->Js.Array2.unsafe_get(idx)
                if idx !== 0 {
                  b.code = b.code ++ "&&"
                }
                b.code = b.code ++ `${keyVar}!==${itemDefinition.inlinedInputLocation}`
              }
              b.code =
                b.code ++
                `){${b->B.raiseWithArg(
                    ~path,
                    exccessFieldName => ExcessField(exccessFieldName),
                    keyVar,
                  )}}}`
            }
          | _ => ()
          }
        },
      ),
      ~serializeOperationBuilder=Builder.make((b, ~selfSchema as _, ~path) => {
        let inputVar = b->B.useInputVar
        let fieldsCodeRef = ref("")

        let registeredDefinitions = Stdlib.Set.empty()

        {
          let prevCode = b.code
          b.code = ""
          let rec definitionToOutput = (definition: Definition.t<itemDefinition>, ~outputPath) => {
            let kind = definition->Definition.toKindWithSet(~embededSet=itemDefinitionsSet)
            switch kind {
            | Embeded =>
              let itemDefinition = definition->Definition.toEmbeded
              if registeredDefinitions->Stdlib.Set.has(itemDefinition) {
                b->B.invalidOperation(
                  ~path,
                  ~description=`The field ${itemDefinition.inlinedInputLocation} is registered multiple times. If you want to duplicate the field, use S.transform instead`,
                )
              } else {
                registeredDefinitions->Stdlib.Set.add(itemDefinition)->ignore
                let {inlinedInputLocation, schema} = itemDefinition
                fieldsCodeRef.contents =
                  fieldsCodeRef.contents ++
                  `${inlinedInputLocation}:${b->B.use(
                      ~schema,
                      ~input=`${inputVar}${outputPath}`,
                      ~path=path->Path.concat(outputPath),
                    )},`
              }
            | Constant => {
                let value = definition->Definition.toConstant
                b.code =
                  `if(${inputVar}${outputPath}!==${b->B.embed(value)}){${b->B.raiseWithArg(
                      ~path=path->Path.concat(outputPath),
                      input => InvalidLiteral({
                        expected: value->Literal.parse,
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
          b.code = prevCode ++ b.code
        }

        for idx in 0 to itemDefinitions->Js.Array2.length - 1 {
          let itemDefinition = itemDefinitions->Js.Array2.unsafe_get(idx)
          if registeredDefinitions->Stdlib.Set.has(itemDefinition)->not {
            let {schema, inlinedInputLocation} = itemDefinition
            switch schema->toInternalLiteral {
            | Some(literal) =>
              fieldsCodeRef.contents =
                fieldsCodeRef.contents ++ `${inlinedInputLocation}:${b->B.embed(literal.value)},`
            | None =>
              b->B.invalidOperation(
                ~path,
                ~description=`Can't create serializer. The ${inlinedInputLocation} field is not registered and not a literal. Use S.transform instead`,
              )
            }
          }
        }

        `{${fieldsCodeRef.contents}}`
      }),
      ~maybeTypeFilter=Some(typeFilter),
      ~toJsonString=input => {
        let jsonStringRef = ref(`'{`)
        for idx in 0 to itemDefinitions->Js.Array2.length - 1 {
          let itemDefinition = itemDefinitions->Js.Array2.unsafe_get(idx)
          jsonStringRef.contents =
            jsonStringRef.contents ++
            (idx === 0 ? `` : `,`) ++
            itemDefinition.inlinedInputLocation ++
            `:` ++
            `'+` ++
            (itemDefinition.schema.maybeToJsonString->(Obj.magic: option<'a> => 'a))(
              `${input}[${itemDefinition.inlinedInputLocation}]`,
            ) ++ `+'`
        }
        jsonStringRef.contents ++ `}'`
      },
      // ~toJsonString=defaultToJsonString, // FIXME:
    )
  }

  let strip = schema => {
    switch schema->classify {
    | Object({unknownKeys: Strict, fieldNames, fields}) =>
      make(
        ~name=schema.name,
        ~tagged=Object({unknownKeys: Strip, fieldNames, fields}),
        ~parseOperationBuilder=schema.parseOperationBuilder,
        ~serializeOperationBuilder=schema.serializeOperationBuilder,
        ~maybeTypeFilter=schema.maybeTypeFilter,
        ~toJsonString=?schema.maybeToJsonString,
        ~metadataMap=schema.metadataMap,
      )
    | _ => schema
    }
  }

  let strict = schema => {
    switch schema->classify {
    | Object({unknownKeys: Strip, fieldNames, fields}) =>
      make(
        ~name=schema.name,
        ~tagged=Object({unknownKeys: Strict, fieldNames, fields}),
        ~parseOperationBuilder=schema.parseOperationBuilder,
        ~serializeOperationBuilder=schema.serializeOperationBuilder,
        ~maybeTypeFilter=schema.maybeTypeFilter,
        ~toJsonString=?schema.maybeToJsonString,
        ~metadataMap=schema.metadataMap,
      )
    // TODO: Should it throw for non Object schemas?
    | _ => schema
    }
  }
}

module Never = {
  let builder = Builder.make((b, ~selfSchema, ~path) => {
    let input = b->B.useInput
    b.code =
      b.code ++
      b->B.raiseWithArg(
        ~path,
        input => InvalidType({
          expected: selfSchema,
          received: input,
        }),
        input,
      ) ++ ";"
    input
  })

  let schema = make(
    ~name=primitiveName,
    ~metadataMap=Metadata.Map.empty,
    ~tagged=Never,
    ~parseOperationBuilder=builder,
    ~serializeOperationBuilder=builder,
    ~maybeTypeFilter=None,
    ~toJsonString=defaultToJsonString,
  )
}

module Unknown = {
  let schema = {
    name: primitiveName,
    tagged: Unknown,
    parseOperationBuilder: Builder.noop,
    serializeOperationBuilder: Builder.noop,
    isAsyncParse: Value(false),
    metadataMap: Metadata.Map.empty,
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
      | Datetime
    type t = {
      kind: kind,
      message: string,
    }

    let metadataId: Metadata.Id.t<array<t>> = Metadata.Id.make(
      ~namespace="rescript-schema",
      ~name="String.refinements",
    )
  }

  let refinements = schema => {
    switch schema->Metadata.get(~id=Refinement.metadataId) {
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

  let typeFilter = (~inputVar) => `typeof ${inputVar}!=="string"`

  let schema = makeWithNoopSerializer(
    ~name=primitiveName,
    ~metadataMap=Metadata.Map.empty,
    ~tagged=String,
    ~parseOperationBuilder=Builder.noop,
    ~maybeTypeFilter=Some(typeFilter),
    ~toJsonString=defaultToJsonString,
  )

  let min = (schema, length, ~message as maybeMessage=?) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `String must be ${length->Stdlib.Int.unsafeToString} or more characters long`
    }
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(${inputVar}.length<${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Min({length: length}),
        message,
      },
    )
  }

  let max = (schema, length, ~message as maybeMessage=?) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `String must be ${length->Stdlib.Int.unsafeToString} or fewer characters long`
    }
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(${inputVar}.length>${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Max({length: length}),
        message,
      },
    )
  }

  let length = (schema, length, ~message as maybeMessage=?) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `String must be exactly ${length->Stdlib.Int.unsafeToString} characters long`
    }
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(${inputVar}.length!==${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Length({length: length}),
        message,
      },
    )
  }

  let email = (schema, ~message=`Invalid email address`) => {
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(!${b->B.embed(emailRegex)}.test(${inputVar})){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Email,
        message,
      },
    )
  }

  let uuid = (schema, ~message=`Invalid UUID`) => {
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(!${b->B.embed(uuidRegex)}.test(${inputVar})){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Uuid,
        message,
      },
    )
  }

  let cuid = (schema, ~message=`Invalid CUID`) => {
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(!${b->B.embed(cuidRegex)}.test(${inputVar})){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Cuid,
        message,
      },
    )
  }

  let url = (schema, ~message=`Invalid url`) => {
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `try{new URL(${inputVar})}catch(_){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Url,
        message,
      },
    )
  }

  let pattern = (schema, re, ~message=`Invalid`) => {
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        let reVar = b->B.var
        `${reVar}=${b->B.embed(
            re,
          )};${reVar}.lastIndex=0;if(!${reVar}.test(${inputVar})){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Pattern({re: re}),
        message,
      },
    )
  }

  let datetime = (schema, ~message=`Invalid datetime string! Must be UTC`) => {
    let refinement = {
      Refinement.kind: Datetime,
      message,
    }
    schema
    ->Metadata.set(
      ~id=Refinement.metadataId,
      {
        switch schema->Metadata.get(~id=Refinement.metadataId) {
        | Some(refinements) => refinements->Stdlib.Array.append(refinement)
        | None => [refinement]
        }
      },
    )
    ->transform(s => {
      parser: string => {
        if datetimeRe->Js.Re.test_(string)->not {
          s.fail(message)
        }
        Js.Date.fromString(string)
      },
      serializer: date => date->Js.Date.toISOString,
    })
  }

  let trim = schema => {
    let transformer = string => string->Js.String2.trim
    schema->transform(_ => {parser: transformer, serializer: transformer})
  }
}

module JsonString = {
  let factory = (schema, ~space=0) => {
    let schema = schema->toUnknown
    let toJsonString = switch schema.maybeToJsonString {
    | Some(v) => v
    | None =>
      InternalError.panic(
        `The schema ${schema.name()} passed to S.jsonString is not compatible with JSON`,
      )
    }
    make(
      ~name=primitiveName,
      ~metadataMap=Metadata.Map.empty,
      ~tagged=String,
      ~parseOperationBuilder=Builder.make((b, ~selfSchema as _, ~path) => {
        let input = b->B.useInput
        let jsonVar = b->B.var
        b.code =
          b.code ++
          `try{${jsonVar}=JSON.parse(${input})}catch(t){${b->B.raiseWithArg(
              ~path,
              message => OperationFailed(message),
              "t.message",
            )}}`

        b->B.useWithTypeFilter(~schema, ~input=jsonVar, ~path)
      }),
      ~serializeOperationBuilder=Builder.make((b, ~selfSchema as _, ~path) => {
        let input = b->B.useInput
        switch space {
        | 0 => toJsonString(input)
        | _ =>
          `JSON.stringify(${b->B.use(
              ~schema,
              ~input,
              ~path,
            )},null,${space->Stdlib.Int.unsafeToString})`
        }
      }),
      ~maybeTypeFilter=Some(String.typeFilter),
      ~toJsonString=defaultToJsonString,
    )
  }
}

module Bool = {
  let typeFilter = (~inputVar) => `typeof ${inputVar}!=="boolean"`

  let schema = makeWithNoopSerializer(
    ~name=primitiveName,
    ~metadataMap=Metadata.Map.empty,
    ~tagged=Bool,
    ~parseOperationBuilder=Builder.noop,
    ~maybeTypeFilter=Some(typeFilter),
    ~toJsonString=input => `(${input}?"true":"false")`,
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
      ~namespace="rescript-schema",
      ~name="Int.refinements",
    )
  }

  let refinements = schema => {
    switch schema->Metadata.get(~id=Refinement.metadataId) {
    | Some(m) => m
    | None => []
    }
  }

  let typeFilter = (~inputVar) =>
    `typeof ${inputVar}!=="number"||${inputVar}>2147483647||${inputVar}<-2147483648||${inputVar}%1!==0`

  let toJsonString = input => `${input}.toString()`

  let schema = makeWithNoopSerializer(
    ~name=primitiveName,
    ~metadataMap=Metadata.Map.empty,
    ~tagged=Int,
    ~parseOperationBuilder=Builder.noop,
    ~maybeTypeFilter=Some(typeFilter),
    ~toJsonString,
  )

  let min = (schema, minValue, ~message as maybeMessage=?) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Number must be greater than or equal to ${minValue->Stdlib.Int.unsafeToString}`
    }
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(${inputVar}<${b->B.embed(minValue)}){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Min({value: minValue}),
        message,
      },
    )
  }

  let max = (schema, maxValue, ~message as maybeMessage=?) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Number must be lower than or equal to ${maxValue->Stdlib.Int.unsafeToString}`
    }
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(${inputVar}>${b->B.embed(maxValue)}){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Max({value: maxValue}),
        message,
      },
    )
  }

  let port = (schema, ~message="Invalid port") => {
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(${inputVar}<1||${inputVar}>65535){${b->B.fail(~message, ~path)}}`
      },
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
      ~namespace="rescript-schema",
      ~name="Float.refinements",
    )
  }

  let refinements = schema => {
    switch schema->Metadata.get(~id=Refinement.metadataId) {
    | Some(m) => m
    | None => []
    }
  }

  let typeFilter = (~inputVar) => `typeof ${inputVar}!=="number"||Number.isNaN(${inputVar})`

  let schema = makeWithNoopSerializer(
    ~name=primitiveName,
    ~metadataMap=Metadata.Map.empty,
    ~tagged=Float,
    ~parseOperationBuilder=Builder.noop,
    ~maybeTypeFilter=Some(typeFilter),
    ~toJsonString=Int.toJsonString,
  )

  let min = (schema, minValue, ~message as maybeMessage=?) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Number must be greater than or equal to ${minValue->Stdlib.Float.unsafeToString}`
    }
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(${inputVar}<${b->B.embed(minValue)}){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Min({value: minValue}),
        message,
      },
    )
  }

  let max = (schema, maxValue, ~message as maybeMessage=?) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Number must be lower than or equal to ${maxValue->Stdlib.Float.unsafeToString}`
    }
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(${inputVar}>${b->B.embed(maxValue)}){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Max({value: maxValue}),
        message,
      },
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
      ~namespace="rescript-schema",
      ~name="Array.refinements",
    )
  }

  let refinements = schema => {
    switch schema->Metadata.get(~id=Refinement.metadataId) {
    | Some(m) => m
    | None => []
    }
  }

  let typeFilter = (~inputVar) => `!Array.isArray(${inputVar})`

  let factory = schema => {
    let schema = schema->toUnknown
    make(
      ~name=containerName,
      ~metadataMap=Metadata.Map.empty,
      ~tagged=Array(schema),
      ~parseOperationBuilder=Builder.make((b, ~selfSchema as _, ~path) => {
        let inputVar = b->B.useInputVar
        let iteratorVar = b->B.varWithoutAllocation
        let outputVar = b->B.var

        b.code =
          b.code ++
          `${outputVar}=[];for(let ${iteratorVar}=0;${iteratorVar}<${inputVar}.length;++${iteratorVar}){${b->B.scope(
              b => {
                let itemOutputVar =
                  b->B.withPathPrepend(
                    ~path,
                    ~dynamicLocationVar=iteratorVar,
                    (b, ~path) =>
                      b->B.useWithTypeFilter(~schema, ~input=`${inputVar}[${iteratorVar}]`, ~path),
                  )
                `${outputVar}.push(${itemOutputVar})`
              },
            )}}`

        let isAsync = schema.isAsyncParse->(Obj.magic: isAsyncParse => bool)
        if isAsync {
          let asyncOutputVar = b->B.var
          b.code = b.code ++ `${asyncOutputVar}=()=>Promise.all(${outputVar}.map(t=>t()));`
          asyncOutputVar
        } else {
          outputVar
        }
      }),
      ~serializeOperationBuilder=Builder.make((b, ~selfSchema as _, ~path) => {
        if schema.serializeOperationBuilder === Builder.noop {
          b->B.useInput
        } else {
          let inputVar = b->B.useInputVar
          let iteratorVar = b->B.varWithoutAllocation
          let outputVar = b->B.var

          b.code =
            b.code ++
            `${outputVar}=[];for(let ${iteratorVar}=0;${iteratorVar}<${inputVar}.length;++${iteratorVar}){${b->B.scope(
                b => {
                  let itemOutputVar =
                    b->B.withPathPrepend(
                      ~path,
                      ~dynamicLocationVar=iteratorVar,
                      (b, ~path) => b->B.use(~schema, ~input=`${inputVar}[${iteratorVar}]`, ~path),
                    )
                  `${outputVar}.push(${itemOutputVar})`
                },
              )}}`

          outputVar
        }
      }),
      ~maybeTypeFilter=Some(typeFilter),
      ~toJsonString=defaultToJsonString, // FIXME:
    )
  }

  let min = (schema, length, ~message as maybeMessage=?) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Array must be ${length->Stdlib.Int.unsafeToString} or more items long`
    }
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(${inputVar}.length<${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Min({length: length}),
        message,
      },
    )
  }

  let max = (schema, length, ~message as maybeMessage=?) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Array must be ${length->Stdlib.Int.unsafeToString} or fewer items long`
    }
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(${inputVar}.length>${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Max({length: length}),
        message,
      },
    )
  }

  let length = (schema, length, ~message as maybeMessage=?) => {
    let message = switch maybeMessage {
    | Some(m) => m
    | None => `Array must be exactly ${length->Stdlib.Int.unsafeToString} items long`
    }
    schema->addRefinement(
      ~metadataId=Refinement.metadataId,
      ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
        `if(${inputVar}.length!==${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
      },
      ~refinement={
        kind: Length({length: length}),
        message,
      },
    )
  }
}

module Dict = {
  let factory = schema => {
    let schema = schema->toUnknown
    make(
      ~name=containerName,
      ~metadataMap=Metadata.Map.empty,
      ~tagged=Dict(schema),
      ~parseOperationBuilder=Builder.make((b, ~selfSchema as _, ~path) => {
        let inputVar = b->B.useInputVar
        let keyVar = b->B.varWithoutAllocation
        let outputVar = b->B.var

        b.code =
          b.code ++
          `${outputVar}={};for(let ${keyVar} in ${inputVar}){${b->B.scope(b => {
              let itemOutputVar =
                b->B.withPathPrepend(
                  ~path,
                  ~dynamicLocationVar=keyVar,
                  (b, ~path) =>
                    b->B.useWithTypeFilter(~schema, ~input=`${inputVar}[${keyVar}]`, ~path),
                )
              `${outputVar}[${keyVar}]=${itemOutputVar}`
            })}}`

        let isAsync = schema.isAsyncParse->(Obj.magic: isAsyncParse => bool)
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
      ~serializeOperationBuilder=Builder.make((b, ~selfSchema as _, ~path) => {
        if schema.serializeOperationBuilder === Builder.noop {
          b->B.useInput
        } else {
          let inputVar = b->B.useInputVar
          let keyVar = b->B.varWithoutAllocation
          let outputVar = b->B.var

          b.code =
            b.code ++
            `${outputVar}={};for(let ${keyVar} in ${inputVar}){${b->B.scope(b => {
                let itemOutputVar =
                  b->B.withPathPrepend(
                    ~path,
                    ~dynamicLocationVar=keyVar,
                    (b, ~path) => b->B.use(~schema, ~input=`${inputVar}[${keyVar}]`, ~path),
                  )

                `${outputVar}[${keyVar}]=${itemOutputVar}`
              })}}`

          outputVar
        }
      }),
      ~maybeTypeFilter=Some(Object.typeFilter),
      ~toJsonString=defaultToJsonString, // FIXME:
    )
  }
}

module Tuple = {
  type s = {
    @as("i") item: 'value. (int, t<'value>) => 'value,
    @as("t") tag: 'value. (int, 'value) => unit,
  }

  module Ctx = {
    type t = {
      @as("s")
      schemas: array<schema<unknown>>,
      @as("d")
      itemDefinitionsSet: Stdlib.Set.t<Object.itemDefinition>,
      @as("item") _jsItem: 'value. (int, t<'value>) => 'value,
      @as("tag") _jsTag: 'value. (int, 'value) => unit,
      ...s,
    }

    @inline
    let make = () => {
      let schemas = []
      let itemDefinitionsSet = Stdlib.Set.empty()

      let item:
        type value. (int, schema<value>) => value =
        (idx, schema) => {
          let schema = schema->toUnknown
          let inlinedInputLocation = `"${idx->Stdlib.Int.unsafeToString}"`
          if schemas->Stdlib.Array.has(idx) {
            InternalError.panic(
              `The item ${inlinedInputLocation} is defined multiple times. If you want to duplicate the item, use S.transform instead.`,
            )
          } else {
            let itemDefinition: Object.itemDefinition = {
              schema,
              inlinedInputLocation,
              inputPath: inlinedInputLocation->Path.fromInlinedLocation,
            }
            schemas->Js.Array2.unsafe_set(idx, schema)
            itemDefinitionsSet->Stdlib.Set.add(itemDefinition)->ignore
            itemDefinition->(Obj.magic: Object.itemDefinition => value)
          }
        }

      let tag = (idx, asValue) => {
        let _ = item(idx, literal(asValue))
      }

      {
        schemas,
        itemDefinitionsSet,
        // js/ts methods
        _jsItem: item,
        _jsTag: tag,
        // methods
        item,
        tag,
      }
    }
  }

  let factory = definer => {
    let ctx = Ctx.make()
    let definition = definer((ctx :> s))->(Obj.magic: 'any => Definition.t<Object.itemDefinition>)
    let {itemDefinitionsSet, schemas} = ctx
    let length = schemas->Js.Array2.length
    for idx in 0 to length - 1 {
      if schemas->Js.Array2.unsafe_get(idx)->Obj.magic->not {
        let schema = unit->toUnknown
        let inlinedInputLocation = `"${idx->Stdlib.Int.unsafeToString}"`
        let itemDefinition: Object.itemDefinition = {
          schema,
          inlinedInputLocation,
          inputPath: inlinedInputLocation->Path.fromInlinedLocation,
        }
        schemas->Js.Array2.unsafe_set(idx, schema)
        itemDefinitionsSet->Stdlib.Set.add(itemDefinition)->ignore
      }
    }
    let itemDefinitions = itemDefinitionsSet->Stdlib.Set.toArray

    make(
      ~name=() => `Tuple(${schemas->Js.Array2.map(s => s.name())->Js.Array2.joinWith(", ")})`,
      ~tagged=Tuple(schemas),
      ~parseOperationBuilder=Object.makeParseOperationBuilder(
        ~itemDefinitions,
        ~itemDefinitionsSet,
        ~definition,
        ~inputRefinement=(b, ~selfSchema as _, ~inputVar, ~path) => {
          b.code =
            b.code ++
            `if(${inputVar}.length!==${length->Stdlib.Int.unsafeToString}){${b->B.raiseWithArg(
                ~path,
                numberOfInputItems => InvalidTupleSize({
                  expected: length,
                  received: numberOfInputItems,
                }),
                `${inputVar}.length`,
              )}}`
        },
        ~unknownKeysRefinement=Object.noopRefinement,
      ),
      ~serializeOperationBuilder=Builder.make((b, ~selfSchema as _, ~path) => {
        let inputVar = b->B.useInputVar
        let outputVar = b->B.var
        let registeredDefinitions = Stdlib.Set.empty()
        b.code = b.code ++ `${outputVar}=[];`

        {
          let prevCode = b.code
          b.code = ""
          let rec definitionToOutput = (
            definition: Definition.t<Object.itemDefinition>,
            ~outputPath,
          ) => {
            let kind = definition->Definition.toKindWithSet(~embededSet=itemDefinitionsSet)
            switch kind {
            | Embeded =>
              let itemDefinition = definition->Definition.toEmbeded
              if registeredDefinitions->Stdlib.Set.has(itemDefinition) {
                b->B.invalidOperation(
                  ~path,
                  ~description=`The item ${itemDefinition.inlinedInputLocation} is registered multiple times. If you want to duplicate the item, use S.transform instead`,
                )
              } else {
                registeredDefinitions->Stdlib.Set.add(itemDefinition)->ignore
                let {schema, inputPath} = itemDefinition
                let fieldOuputVar =
                  b->B.use(
                    ~schema,
                    ~input=`${inputVar}${outputPath}`,
                    ~path=path->Path.concat(outputPath),
                  )
                b.code = b.code ++ `${outputVar}${inputPath}=${fieldOuputVar};`
              }
            | Constant => {
                let value = definition->Definition.toConstant
                b.code =
                  `if(${inputVar}${outputPath}!==${b->B.embed(value)}){${b->B.raiseWithArg(
                      ~path=path->Path.concat(outputPath),
                      input => InvalidLiteral({
                        expected: value->Literal.parse,
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
          b.code = prevCode ++ b.code
        }

        for idx in 0 to itemDefinitions->Js.Array2.length - 1 {
          let itemDefinition = itemDefinitions->Js.Array2.unsafe_get(idx)
          if registeredDefinitions->Stdlib.Set.has(itemDefinition)->not {
            let {schema, inlinedInputLocation, inputPath} = itemDefinition
            switch schema->toInternalLiteral {
            | Some(literal) =>
              b.code = b.code ++ `${outputVar}${inputPath}=${b->B.embed(literal.value)};`
            | None =>
              b->B.invalidOperation(
                ~path,
                ~description=`Can't create serializer. The ${inlinedInputLocation} item is not registered and not a literal. Use S.transform instead`,
              )
            }
          }
        }

        outputVar
      }),
      ~maybeTypeFilter=Some(Array.typeFilter),
      ~metadataMap=Metadata.Map.empty,
      ~toJsonString=defaultToJsonString, // FIXME:
    )
  }
}

module Union = {
  let factory = schemas => {
    let schemas: array<t<unknown>> = schemas->Obj.magic

    switch schemas {
    | [] => InternalError.panic("S.union requires at least one item.")
    | [schema] => schema->castUnknownSchemaToAnySchema
    | _ =>
      make(
        ~name=() => `Union(${schemas->Js.Array2.map(s => s.name())->Js.Array2.joinWith(", ")})`,
        ~metadataMap=Metadata.Map.empty,
        ~tagged=Union(schemas),
        ~parseOperationBuilder=Builder.make((b, ~selfSchema, ~path) => {
          let inputVar = b->B.useInputVar
          let schemas = selfSchema->classify->unsafeGetVariantPayload

          let isAsyncRef = ref(false)
          let itemsCode = []
          let itemsOutputVar = []

          let prevCode = b.code
          for idx in 0 to schemas->Js.Array2.length - 1 {
            let schema = schemas->Js.Array2.unsafe_get(idx)
            b.code = ""
            let itemOutputVar = b->B.withBuildErrorInline(
              () => {
                b->B.useWithTypeFilter(
                  // A hack to bypass an additional function wrapping for var context optimisation
                  ~schema=%raw(`schema`),
                  ~input=inputVar,
                  ~path=Path.empty,
                )
              },
            )
            let isAsyncItem = schema.isAsyncParse->(Obj.magic: isAsyncParse => bool)
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

          // TODO: Use B.withCatch ???
          for idx in 0 to schemas->Js.Array2.length - 1 {
            let schema = schemas->Js.Array2.unsafe_get(idx)
            let code = itemsCode->Js.Array2.unsafe_get(idx)
            let itemOutputVar = itemsOutputVar->Js.Array2.unsafe_get(idx)
            let isAsyncItem = schema.isAsyncParse->(Obj.magic: isAsyncParse => bool)

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
                  ~path,
                  internalErrors => {
                    InvalidUnion(internalErrors)
                  },
                  `t.errors`,
                )}})` ++
              codeEndRef.contents
            outputVar
          } else {
            b.code =
              b.code ++
              b->B.raiseWithArg(
                ~path,
                internalErrors => InvalidUnion(internalErrors),
                `[${errorCodeRef.contents}]`,
              ) ++
              codeEndRef.contents
            outputVar
          }
        }),
        ~serializeOperationBuilder=Builder.make((b, ~selfSchema, ~path) => {
          let inputVar = b->B.useInputVar
          let schemas = selfSchema->classify->unsafeGetVariantPayload

          let outputVar = b->B.var

          let codeEndRef = ref("")
          let errorVarsRef = ref("")

          for idx in 0 to schemas->Js.Array2.length - 1 {
            let itemSchema = schemas->Js.Array2.unsafe_get(idx)
            let errorVar = b->B.varWithoutAllocation
            errorVarsRef.contents = errorVarsRef.contents ++ errorVar ++ `,`

            b.code =
              b.code ++
              `try{${b->B.scope(
                  b => {
                    let itemOutput =
                      b->B.withBuildErrorInline(
                        () => b->B.use(~schema=itemSchema, ~input=inputVar, ~path=Path.empty),
                      )
                    let itemOutput = switch itemSchema.maybeTypeFilter {
                    | Some(typeFilter) =>
                      let itemOutputVar = b->B.toVar(itemOutput)
                      b.code =
                        b.code ++
                        b->B.typeFilterCode(
                          ~schema=itemSchema,
                          ~typeFilter,
                          ~inputVar=itemOutputVar,
                          ~path=Path.empty,
                        )
                      itemOutputVar
                    | None => itemOutput
                    }
                    `${outputVar}=${itemOutput}`
                  },
                )}}catch(${errorVar}){if(${b->B.isInternalError(errorVar)}){`

            codeEndRef.contents = `}else{throw ${errorVar}}}` ++ codeEndRef.contents
          }

          b.code =
            b.code ++
            b->B.raiseWithArg(
              ~path,
              internalErrors => InvalidUnion(internalErrors),
              `[${errorVarsRef.contents}]`,
            ) ++
            codeEndRef.contents

          outputVar
        }),
        ~maybeTypeFilter=None,
        ~toJsonString=defaultToJsonString, // FIXME:
      )
    }
  }
}

let list = schema => {
  schema
  ->Array.factory
  ->transform(_ => {
    parser: array => array->Belt.List.fromArray,
    serializer: list => list->Belt.List.toArray,
  })
}

let json = (~validate) =>
  makeWithNoopSerializer(
    ~name=primitiveName,
    ~tagged=JSON({validated: validate}),
    ~metadataMap=Metadata.Map.empty,
    ~maybeTypeFilter=None,
    ~toJsonString=defaultToJsonString,
    ~parseOperationBuilder=validate
      ? Builder.make((b, ~selfSchema, ~path) => {
          let rec parse = (input, ~path=path) => {
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
                    inputItem->parse(
                      ~path=path->Path.concat(Path.fromLocation(idx->Js.Int.toString)),
                    ),
                  )
                  ->ignore
                }
                output->Js.Json.array
              } else {
                let input = input->(Obj.magic: unknown => dict<unknown>)
                let keys = input->Js.Dict.keys
                let output = Js.Dict.empty()
                for idx in 0 to keys->Js.Array2.length - 1 {
                  let key = keys->Js.Array2.unsafe_get(idx)
                  let field = input->Js.Dict.unsafeGet(key)
                  output->Js.Dict.set(
                    key,
                    field->parse(~path=path->Path.concat(Path.fromLocation(key))),
                  )
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
                  expected: selfSchema,
                  received: input,
                }),
                ~operation=Parsing,
              )
            }
          }
          let input = b->B.useInput

          `${b->B.embed(parse)}(${input})`
        })
      : Builder.noop,
  )

module Catch = {
  type s<'value> = {
    @as("e") error: error,
    @as("i") input: unknown,
    @as("s") schema: t<'value>,
    @as("f") fail: 'a. (string, ~path: Path.t=?) => 'a,
  }
}
let catch = (schema, getFallbackValue) => {
  let schema = schema->toUnknown
  make(
    ~name=schema.name,
    ~parseOperationBuilder=Builder.make((b, ~selfSchema, ~path) => {
      let inputVar = b->B.useInputVar
      b->B.withCatch(
        ~catch=(b, ~errorVar) => Some(
          `${b->B.embed((input, internalError) =>
              getFallbackValue({
                Catch.input,
                error: internalError,
                schema: selfSchema->castUnknownSchemaToAnySchema,
                fail: (message, ~path as customPath=Path.empty) => {
                  InternalError.raise(
                    ~path=path->Path.concat(customPath),
                    ~code=OperationFailed(message),
                    ~operation=b.operation,
                  )
                },
              })
            )}(${inputVar},${errorVar})`,
        ),
        b => {
          b->B.useWithTypeFilter(~schema, ~input=inputVar, ~path)
        },
      )
    }),
    ~serializeOperationBuilder=schema.serializeOperationBuilder,
    ~tagged=schema.tagged,
    ~maybeTypeFilter=None,
    ~toJsonString=?schema.maybeToJsonString,
    ~metadataMap=schema.metadataMap,
  )
}

let deprecationMetadataId: Metadata.Id.t<string> = Metadata.Id.make(
  ~namespace="rescript-schema",
  ~name="deprecation",
)

let deprecate = (schema, message) => {
  schema->Metadata.set(~id=deprecationMetadataId, message)
}

let deprecation = schema => schema->Metadata.get(~id=deprecationMetadataId)

let descriptionMetadataId: Metadata.Id.t<string> = Metadata.Id.make(
  ~namespace="rescript-schema",
  ~name="description",
)

let describe = (schema, description) => {
  schema->Metadata.set(~id=descriptionMetadataId, description)
}

let description = schema => schema->Metadata.get(~id=descriptionMetadataId)

module Schema = {
  type s = {matches: 'value. t<'value> => 'value}

  let rec definitionToSchema = (definition: Definition.t<schema<unknown>>, ~embededSet) => {
    let kind = definition->Definition.toKindWithSet(~embededSet)
    switch kind {
    | Embeded => definition->Definition.toEmbeded
    | Constant => {
        let constant = definition->Definition.toConstant
        literal(constant)
      }
    | Node => {
        let node = definition->Definition.toNode
        if node->Stdlib.Array.isArray {
          let node =
            node->(
              Obj.magic: Definition.node<schema<unknown>> => array<Definition.t<schema<unknown>>>
            )
          Tuple.factory(s => {
            for idx in 0 to node->Js.Array2.length - 1 {
              let definition = node->Js.Array2.unsafe_get(idx)
              node->Js.Array2.unsafe_set(
                idx,
                s.item(idx, definition->definitionToSchema(~embededSet))->(
                  Obj.magic: unknown => Definition.t<schema<unknown>>
                ),
              )
            }
            node
          })
        } else {
          Object.factory(s => {
            let keys = node->Js.Dict.keys
            for idx in 0 to keys->Js.Array2.length - 1 {
              let key = keys->Js.Array2.unsafe_get(idx)
              let definition = node->Js.Dict.unsafeGet(key)
              node->Js.Dict.set(
                key,
                s.field(key, definition->definitionToSchema(~embededSet))->(
                  Obj.magic: unknown => Definition.t<schema<unknown>>
                ),
              )
            }
            node
          })
        }
      }
    }
  }

  let factory = definer => {
    let embededSet = Stdlib.Set.empty()
    let matches:
      type value. schema<value> => value =
      schema => {
        let schema = schema->toUnknown
        embededSet->Stdlib.Set.add(schema)->ignore
        schema->(Obj.magic: t<unknown> => value)
      }
    let ctx = {
      matches: matches,
    }
    let definition =
      definer(ctx->(Obj.magic: s => 'value))->(Obj.magic: 'definition => Definition.t<t<unknown>>)
    definition->definitionToSchema(~embededSet)->castUnknownSchemaToAnySchema
  }
}

let schema = Schema.factory

module Error = {
  type class
  let class: class = %raw("RescriptSchemaError")

  let make = InternalError.make

  let raise = (error: error) => error->Stdlib.Exn.raiseAny

  let rec reason = (error, ~nestedLevel=0) => {
    switch error.code {
    | OperationFailed(reason) => reason
    | InvalidOperation({description}) => description
    | UnexpectedAsync => "Encountered unexpected asynchronous transform or refine. Use S.parseAsyncWith instead of S.parseWith"
    | ExcessField(fieldName) =>
      `Encountered disallowed excess key ${fieldName->Stdlib.Inlined.Value.fromString} on an object. Use Deprecated to ignore a specific field, or S.Object.strip to ignore excess keys completely`
    | InvalidType({expected, received}) =>
      `Expected ${expected.name()}, received ${received->Literal.parse->Literal.toString}`
    | InvalidLiteral({expected, received}) =>
      `Expected ${expected->Literal.toString}, received ${received
        ->Literal.parse
        ->Literal.toString}`
    | InvalidJsonStruct(schema) => `The schema ${schema.name()} is not compatible with JSON`
    | InvalidTupleSize({expected, received}) =>
      `Expected Tuple with ${expected->Stdlib.Int.unsafeToString} items, received ${received->Stdlib.Int.unsafeToString}`
    | InvalidUnion(errors) => {
        let lineBreak = `\n${" "->Js.String2.repeat(nestedLevel * 2)}`
        let reasons =
          errors
          ->Js.Array2.map(error => {
            let reason = error->reason(~nestedLevel=nestedLevel->Stdlib.Int.plus(1))
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

  let reason = reason->(Obj.magic: ((error, ~nestedLevel: int=?) => string) => error => string)

  let message = error => {
    let operation = switch error.operation {
    | Serializing => "serializing"
    | Parsing => "parsing"
    }
    let pathText = switch error.path {
    | "" => "root"
    | nonEmptyPath => nonEmptyPath
    }
    `Failed ${operation} at ${pathText}. Reason: ${error->reason}`
  }
}

let inline = {
  let rec internalInline = (schema, ~variant as maybeVariant=?, ()) => {
    let metadataMap = schema.metadataMap->Stdlib.Dict.copy

    let inlinedSchema = switch schema->classify {
    | Literal(literal) => `S.literal(%raw(\`${literal->Literal.toString}\`))`
    | Union(unionSchemas) => {
        let variantNamesCounter = Js.Dict.empty()
        `S.union([${unionSchemas
          ->Js.Array2.map(s => {
            let variantName = s.name()
            let numberOfVariantNames = switch variantNamesCounter->Js.Dict.get(variantName) {
            | Some(n) => n
            | None => 0
            }
            variantNamesCounter->Js.Dict.set(variantName, numberOfVariantNames->Stdlib.Int.plus(1))
            let variantName = switch numberOfVariantNames {
            | 0 => variantName
            | _ =>
              variantName ++ numberOfVariantNames->Stdlib.Int.plus(1)->Stdlib.Int.unsafeToString
            }
            let inlinedVariant = `#${variantName->Stdlib.Inlined.Value.fromString}`
            s->internalInline(~variant=inlinedVariant, ())
          })
          ->Js.Array2.joinWith(", ")}])`
      }
    | JSON({validated}) => `S.json(~validate=${validated->(Obj.magic: bool => string)})`
    | Tuple([s1]) => `S.tuple1(${s1->internalInline()})`
    | Tuple([s1, s2]) => `S.tuple2(${s1->internalInline()}, ${s2->internalInline()})`
    | Tuple([s1, s2, s3]) =>
      `S.tuple3(${s1->internalInline()}, ${s2->internalInline()}, ${s3->internalInline()})`
    | Tuple(tupleSchemas) =>
      `S.tuple(s => (${tupleSchemas
        ->Js.Array2.mapi((s, idx) =>
          `s.item(${idx->Stdlib.Int.unsafeToString}, ${s->internalInline()})`
        )
        ->Js.Array2.joinWith(", ")}))`
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
    | Option(schema) => `S.option(${schema->internalInline()})`
    | Null(schema) => `S.null(${schema->internalInline()})`
    | Never => `S.never`
    | Unknown => `S.unknown`
    | Array(schema) => `S.array(${schema->internalInline()})`
    | Dict(schema) => `S.dict(${schema->internalInline()})`
    }

    let inlinedSchema = switch schema->Option.default {
    | Some(default) => {
        metadataMap->Stdlib.Dict.deleteInPlace(Option.defaultMetadataId->Metadata.Id.toKey)
        switch default {
        | Value(defaultValue) =>
          inlinedSchema ++
          `->S.Option.getOr(%raw(\`${defaultValue->Stdlib.Inlined.Value.stringify}\`))`
        | Callback(defaultCb) =>
          inlinedSchema ++
          `->S.Option.getOrWith(() => %raw(\`${defaultCb()->Stdlib.Inlined.Value.stringify}\`))`
        }
      }

    | None => inlinedSchema
    }

    let inlinedSchema = switch schema->deprecation {
    | Some(message) => {
        metadataMap->Stdlib.Dict.deleteInPlace(deprecationMetadataId->Metadata.Id.toKey)
        inlinedSchema ++ `->S.deprecate(${message->Stdlib.Inlined.Value.fromString})`
      }

    | None => inlinedSchema
    }

    let inlinedSchema = switch schema->description {
    | Some(message) => {
        metadataMap->Stdlib.Dict.deleteInPlace(descriptionMetadataId->Metadata.Id.toKey)
        inlinedSchema ++ `->S.describe(${message->Stdlib.Inlined.Value.stringify})`
      }

    | None => inlinedSchema
    }

    let inlinedSchema = switch schema->classify {
    | Object({unknownKeys: Strict}) => inlinedSchema ++ `->S.Object.strict`
    | _ => inlinedSchema
    }

    let inlinedSchema = switch schema->classify {
    | String
    | Literal(String(_)) =>
      switch schema->String.refinements {
      | [] => inlinedSchema
      | refinements =>
        metadataMap->Stdlib.Dict.deleteInPlace(String.Refinement.metadataId->Metadata.Id.toKey)
        inlinedSchema ++
        refinements
        ->Js.Array2.map(refinement => {
          switch refinement {
          | {kind: Email, message} =>
            `->S.String.email(~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Url, message} =>
            `->S.String.url(~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Uuid, message} =>
            `->S.String.uuid(~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Cuid, message} =>
            `->S.String.cuid(~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Min({length}), message} =>
            `->S.String.min(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Max({length}), message} =>
            `->S.String.max(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Length({length}), message} =>
            `->S.String.length(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Pattern({re}), message} =>
            `->S.String.pattern(%re(${re
              ->Stdlib.Re.toString
              ->Stdlib.Inlined.Value.fromString}), ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Datetime, message} =>
            `->S.String.datetime(~message=${message->Stdlib.Inlined.Value.fromString})`
          }
        })
        ->Js.Array2.joinWith("")
      }
    | Int =>
      // | Literal(Int(_)) ???
      switch schema->Int.refinements {
      | [] => inlinedSchema
      | refinements =>
        metadataMap->Stdlib.Dict.deleteInPlace(Int.Refinement.metadataId->Metadata.Id.toKey)
        inlinedSchema ++
        refinements
        ->Js.Array2.map(refinement => {
          switch refinement {
          | {kind: Max({value}), message} =>
            `->S.Int.max(${value->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Min({value}), message} =>
            `->S.Int.min(${value->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Port, message} =>
            `->S.Int.port(~message=${message->Stdlib.Inlined.Value.fromString})`
          }
        })
        ->Js.Array2.joinWith("")
      }
    | Float =>
      // | Literal(Float(_)) ???
      switch schema->Float.refinements {
      | [] => inlinedSchema
      | refinements =>
        metadataMap->Stdlib.Dict.deleteInPlace(Float.Refinement.metadataId->Metadata.Id.toKey)
        inlinedSchema ++
        refinements
        ->Js.Array2.map(refinement => {
          switch refinement {
          | {kind: Max({value}), message} =>
            `->S.Float.max(${value->Stdlib.Inlined.Float.toRescript}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Min({value}), message} =>
            `->S.Float.min(${value->Stdlib.Inlined.Float.toRescript}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          }
        })
        ->Js.Array2.joinWith("")
      }

    | Array(_) =>
      switch schema->Array.refinements {
      | [] => inlinedSchema
      | refinements =>
        metadataMap->Stdlib.Dict.deleteInPlace(Array.Refinement.metadataId->Metadata.Id.toKey)
        inlinedSchema ++
        refinements
        ->Js.Array2.map(refinement => {
          switch refinement {
          | {kind: Max({length}), message} =>
            `->S.Array.max(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Min({length}), message} =>
            `->S.Array.min(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Length({length}), message} =>
            `->S.Array.length(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          }
        })
        ->Js.Array2.joinWith("")
      }

    | _ => inlinedSchema
    }

    let inlinedSchema = if metadataMap->Js.Dict.keys->Js.Array2.length !== 0 {
      `{
  let s = ${inlinedSchema}
  let _ = %raw(\`s.m = ${metadataMap->Js.Json.stringifyAny->Belt.Option.getUnsafe}\`)
  s
}`
    } else {
      inlinedSchema
    }

    let inlinedSchema = switch maybeVariant {
    | Some(variant) => inlinedSchema ++ `->S.variant(v => ${variant}(v))`
    | None => inlinedSchema
    }

    inlinedSchema
  }

  schema => {
    // Have it only for the sake of importing Caml_option in a less painfull way
    // Not related to the function at all
    if %raw(`false`) {
      switch %raw(`void 0`) {
      | Some(v) => v
      | None => ()
      }
    }

    schema->toUnknown->internalInline()
  }
}

let object = Object.factory
let never = Never.schema
let unknown = Unknown.schema
let string = String.schema
let bool = Bool.schema
let int = Int.schema
let float = Float.schema
let null = Null.factory
let option = Option.factory
let array = Array.factory
let dict = Dict.factory
let variant = Variant.factory
let tuple = Tuple.factory
let tuple1 = v0 => tuple(s => s.item(0, v0))
let tuple2 = (v0, v1) => tuple(s => (s.item(0, v0), s.item(1, v1)))
let tuple3 = (v0, v1, v2) => tuple(s => (s.item(0, v0), s.item(1, v1), s.item(2, v2)))
let union = Union.factory
let jsonString = JsonString.factory

@send
external name: t<'a> => string = "n"

// =============
// JS/TS API
// =============

@tag("success")
type jsResult<'value> = | @as(true) Success({value: 'value}) | @as(false) Failure({error: error})

let toJsResult = (result: result<'value, error>): jsResult<'value> => {
  switch result {
  | Ok(value) => Success({value: value})
  | Error(error) => Failure({error: error})
  }
}

let js_parse = (schema, data) => {
  try {
    Success({
      value: parseAnyOrRaiseWith(data, schema),
    })
  } catch {
  | exn => Failure({error: exn->InternalError.getOrRethrow})
  }
}

let js_parseOrThrow = (schema, data) => {
  data->parseAnyOrRaiseWith(schema)
}

let js_parseAsync = (schema, data) => {
  data->parseAnyAsyncWith(schema)->Stdlib.Promise.thenResolve(toJsResult)
}

let js_serialize = (schema, value) => {
  try {
    Success({
      value: serializeToUnknownOrRaiseWith(value, schema),
    })
  } catch {
  | exn => Failure({error: exn->InternalError.getOrRethrow})
  }
}

let js_serializeOrThrow = (schema, value) => {
  value->serializeToUnknownOrRaiseWith(schema)
}

let js_transform = (schema, ~parser as maybeParser=?, ~serializer as maybeSerializer=?) => {
  schema->transform(s => {
    {
      parser: ?switch maybeParser {
      | Some(parser) => Some(v => parser(v, s))
      | None => None
      },
      serializer: ?switch maybeSerializer {
      | Some(serializer) => Some(v => serializer(v, s))
      | None => None
      },
    }
  })
}

let js_refine = (schema, refiner) => {
  schema->refine(s => {
    v => refiner(v, s)
  })
}

let noop = a => a
let js_asyncParserRefine = (schema, refine) => {
  schema->transform(s => {
    {
      asyncParser: v => () => refine(v, s)->Stdlib.Promise.thenResolve(() => v),
      serializer: noop,
    }
  })
}

let js_optional = (schema, maybeOr) => {
  let schema = option(schema)
  switch maybeOr {
  | Some(or) if Js.typeof(or) === "function" => schema->Option.getOrWith(or->Obj.magic)->Obj.magic
  | Some(or) => schema->Option.getOr(or->Obj.magic)->Obj.magic
  | None => schema
  }
}

let js_tuple = definer => {
  if Js.typeof(definer) === "function" {
    let definer = definer->(Obj.magic: unknown => Tuple.s => 'a)
    tuple(definer)
  } else {
    let schemas = definer->(Obj.magic: unknown => array<t<unknown>>)
    tuple(s => {
      schemas->Js.Array2.mapi((schema, idx) => {
        s.item(idx, schema)
      })
    })
  }
}

let js_custom = (~name, ~parser as maybeParser=?, ~serializer as maybeSerializer=?, ()) => {
  custom(name, s => {
    {
      parser: ?switch maybeParser {
      | Some(parser) => Some(v => parser(v, s))
      | None => None
      },
      serializer: ?switch maybeSerializer {
      | Some(serializer) => Some(v => serializer(v, s))
      | None => None
      },
    }
  })
}

let js_object = definer => {
  if Js.typeof(definer) === "function" {
    let definer = definer->(Obj.magic: unknown => Object.s => 'a)
    object(definer)
  } else {
    let definer = definer->(Obj.magic: unknown => dict<t<unknown>>)
    object(s => {
      let definition = Js.Dict.empty()
      let fieldNames = definer->Js.Dict.keys
      for idx in 0 to fieldNames->Js.Array2.length - 1 {
        let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
        let schema = definer->Js.Dict.unsafeGet(fieldName)
        definition->Js.Dict.set(fieldName, s.field(fieldName, schema))
      }
      definition
    })
  }
}

let js_merge = (s1, s2) => {
  switch (s1, s2) {
  | (
      {tagged: Object({fieldNames: s1FieldNames, fields: s1Fields})},
      {tagged: Object({unknownKeys, fieldNames: s2FieldNames, fields: s2Fields})},
    ) =>
    let fieldNames = []
    let fields = Js.Dict.empty()
    for idx in 0 to s1FieldNames->Js.Array2.length - 1 {
      let fieldName = s1FieldNames->Js.Array2.unsafe_get(idx)
      fieldNames->Js.Array2.push(fieldName)->ignore
      fields->Js.Dict.set(fieldName, s1Fields->Js.Dict.unsafeGet(fieldName))
    }
    for idx in 0 to s2FieldNames->Js.Array2.length - 1 {
      let fieldName = s2FieldNames->Js.Array2.unsafe_get(idx)
      if fields->Stdlib.Dict.has(fieldName) {
        InternalError.panic(
          `The field ${fieldName->Stdlib.Inlined.Value.fromString} is defined multiple times.`,
        )
      }
      fieldNames->Js.Array2.push(fieldName)->ignore
      fields->Js.Dict.set(fieldName, s2Fields->Js.Dict.unsafeGet(fieldName))
    }
    make(
      ~name=() => `${s1.name()} & ${s2.name()}`,
      ~tagged=Object({
        unknownKeys,
        fieldNames,
        fields,
      }),
      ~parseOperationBuilder=Builder.make((b, ~selfSchema as _, ~path) => {
        let inputVar = b->B.useInputVar
        let s1Result = b->B.use(~schema=s1, ~input=inputVar, ~path)
        let s2Result = b->B.use(~schema=s2, ~input=inputVar, ~path)
        // TODO: Check that these are objects
        // TODO: Check that s1Result is not mutating input
        `Object.assign(${s1Result}, ${s2Result})`
      }),
      ~serializeOperationBuilder=Builder.make((b, ~selfSchema as _, ~path) => {
        b->B.invalidOperation(~path, ~description=`The S.merge serializing is not supported yet`)
      }),
      ~maybeTypeFilter=Some(Object.typeFilter),
      ~metadataMap=Metadata.Map.empty,
    )
  | _ => InternalError.panic("The merge supports only Object schemas.")
  }
}

let js_name = name
