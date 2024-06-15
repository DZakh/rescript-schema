@@uncurried
@@warning("-30")

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

  module WeakMap = {
    type t<'k, 'v> = Js.WeakMap.t<'k, 'v>

    @new external make: unit => t<'k, 'v> = "WeakMap"

    @send external get: (t<'k, 'v>, 'k) => option<'v> = "get"
    @send external has: (t<'k, 'v>, 'k) => bool = "has"
    @send external set: (t<'k, 'v>, 'k, 'v) => t<'k, 'v> = "set"
  }

  module WeakSet = {
    type t<'v> = Js.WeakSet.t<'v>

    @new external make: unit => t<'v> = "WeakSet"

    @send external add: (t<'v>, 'v) => t<'v> = "add"
    @send external has: (t<'v>, 'v) => bool = "has"
  }

  module Array = {
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
let itemSymbol = Stdlib.Symbol.make("item")

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
  @as("r")
  rawTagged: tagged,
  @as("n")
  name: unit => string,
  @as("p")
  mutable parseOperationBuilder: builder,
  @as("s")
  mutable serializeOperationBuilder: builder,
  @as("f")
  maybeTypeFilter: option<(~inputVar: string) => string>,
  @as("i")
  mutable isAsyncParse: isAsyncParse,
  @as("d")
  mutable // Use char to unsafely prevent Caml_option applications
  definer?: char,
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
  | Object({items: array<item>, fields: dict<item>, unknownKeys: unknownKeys, definition: unknown})
  | Tuple({items: array<item>, definition: unknown})
  | Union(array<t<unknown>>)
  | Dict(t<unknown>)
  | JSON({validated: bool})
and item = {
  @as("t")
  schema: schema<unknown>,
  @as("p")
  path: Path.t,
  @as("l")
  location: string,
  @as("i")
  inlinedLocation: string,
  @as("s")
  symbol: Js.Types.symbol,
}
and builder = (b, ~input: val, ~selfSchema: schema<unknown>, ~path: Path.t) => val
and val = {
  @as("v")
  mutable _var?: string,
  @as("i")
  _initial?: string,
  @as("s")
  _scope: b,
  @as("a")
  mutable isAsync: bool,
}
and bGlobal = {
  @as("v")
  mutable varCounter: int,
  @as("o")
  operation: operation,
  @as("e")
  embeded: array<unknown>,
}
and b = {
  @as("c")
  mutable code: string,
  @as("l")
  mutable varsAllocation: string,
  @as("a")
  mutable isAllocated: bool,
  @as("g")
  global: bGlobal,
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
let classifyRaw = schema => schema.rawTagged

module Builder = {
  type t = builder
  let make = (
    Obj.magic: ((b, ~input: val, ~selfSchema: schema<unknown>, ~path: Path.t) => val) => t
  )

  module B = {
    @inline
    let embed = (b: b, value) => {
      `e[${(b.global.embeded
        ->Js.Array2.push(value->castAnyToUnknown)
        ->(Obj.magic: int => float) -. 1.)->(Obj.magic: float => string)}]`
    }

    let scope = (b: b): b => {
      {
        global: b.global,
        code: "",
        varsAllocation: "",
        isAllocated: false,
      }
    }

    let allocateScope = (b: b): string => {
      let varsAllocation = b.varsAllocation
      b.isAllocated = true
      varsAllocation === "" ? b.code : `let ${varsAllocation};${b.code}`
    }

    let varWithoutAllocation = (b: b) => {
      let newCounter = b.global.varCounter->Stdlib.Int.plus(1)
      b.global.varCounter = newCounter
      `v${newCounter->Stdlib.Int.unsafeToString}`
    }

    let allocateVal = (b: b): val => {
      {_scope: b, isAsync: false}
    }

    let val = (b: b, initial: string): val => {
      {_initial: initial, _scope: b, isAsync: false}
    }

    let asyncVal = (b: b, initial: string): val => {
      {_initial: initial, _scope: b, isAsync: true}
    }

    module Val = {
      let inline = (_b: b, val: val) => {
        switch val {
        | {_var: var} => var
        | _ => val._initial->(Obj.magic: option<string> => string) // There should never be the case when we inline not allocated val
        }
      }

      let var = (b: b, val: val) => {
        switch val {
        | {_var} => _var
        | _ => {
            let var = b->varWithoutAllocation
            let isValScopeActive = !val._scope.isAllocated
            let activeScope = isValScopeActive ? val._scope : b
            let allocation = switch val._initial {
            | Some(i) if isValScopeActive => `${var}=${i}`
            | _ => var
            }
            let varsAllocation = activeScope.varsAllocation
            activeScope.varsAllocation = varsAllocation === ""
              ? allocation
              : varsAllocation ++ "," ++ allocation
            switch val._initial {
            | Some(i) if !isValScopeActive => b.code = b.code ++ `${var}=${i};`
            | _ => ()
            }
            val._var = Some(var)
            var
          }
        }
      }

      let push = (b: b, input: val, val: val) => {
        `${b->var(input)}.push(${b->inline(val)})`
      }

      let addKey = (b: b, input: val, key, val: val) => {
        `${b->var(input)}[${key}]=${b->inline(val)}`
      }

      let set = (b: b, input: val, val) => {
        if input === val {
          ""
        } else {
          switch (input, val) {
          | ({isAsync: false}, {isAsync: true}) => {
              input.isAsync = true
              `${b->var(input)}=${b->inline(val)}`
            }
          | ({isAsync: false}, {isAsync: false})
          | ({isAsync: true}, {isAsync: true}) =>
            `${b->var(input)}=${b->inline(val)}`
          | ({isAsync: true}, {isAsync: false}) =>
            `${b->var(input)}=()=>Promise.resolve(${b->inline(val)})`
          }
        }
      }

      let setInlined = (b: b, input: val, inlined) => {
        `${b->var(input)}=${inlined}`
      }

      let map = (b: b, inlinedFn, input: val) => {
        b->val(`${inlinedFn}(${b->inline(input)})`)
      }
    }

    @inline
    let isInternalError = (_b: b, var) => {
      `${var}&&${var}.s===s`
    }

    let transform = (b: b, ~input, operation) => {
      if input.isAsync {
        let bb = b->scope
        let operationInput: val = {
          _var: bb->varWithoutAllocation,
          _scope: bb,
          isAsync: false,
        }
        let operationOutputVal = operation(bb, ~input=operationInput)
        let operationCode = bb->allocateScope

        b->asyncVal(
          // TODO: Use Val.inline
          `()=>${b->Val.var(input)}().then(${b->Val.var(
              operationInput,
            )}=>{${operationCode}return ${operationOutputVal.isAsync
              ? "(" ++ b->Val.inline(operationOutputVal) ++ ")()"
              : b->Val.inline(operationOutputVal)}})`,
        )
      } else {
        operation(b, ~input)
      }
    }

    let embedSyncOperation = (b: b, ~input, ~fn: 'input => 'output) => {
      b->transform(~input, (b, ~input) => {
        b->Val.map(b->embed(fn), input)
      })
    }

    let embedAsyncOperation = (b: b, ~input, ~fn: 'input => unit => promise<'output>) => {
      b->transform(~input, (b, ~input) => {
        let val = b->Val.map(b->embed(fn), input)
        val.isAsync = true
        val
      })
    }

    let raiseWithArg = (b: b, ~path, fn: 'arg => errorCode, arg) => {
      `${b->embed(arg => {
          InternalError.raise(~path, ~code=fn(arg), ~operation=b.global.operation)
        })}(${arg})`
    }

    let fail = (b: b, ~message, ~path) => {
      `${b->embed(() => {
          InternalError.raise(~path, ~code=OperationFailed(message), ~operation=b.global.operation)
        })}()`
    }

    let invalidOperation = (b: b, ~path, ~description) => {
      InternalError.raise(
        ~path,
        ~code=InvalidOperation({description: description}),
        ~operation=b.global.operation,
      )
    }

    // TODO: Refactor
    let withCatch = (b: b, ~input, ~catch, fn) => {
      let prevCode = b.code

      b.code = ""
      let errorVar = b->varWithoutAllocation
      let maybeResolveVal = catch(b, ~errorVar)
      let catchCode = `if(${b->isInternalError(errorVar)}){${b.code}`
      b.code = ""

      let bb = b->scope
      let fnOutput = fn(bb)
      b.code = b.code ++ bb->allocateScope

      let isAsync = fnOutput.isAsync
      let output = input === fnOutput ? input : {_scope: b, isAsync}

      let catchCode = switch maybeResolveVal {
      | None => _ => `${catchCode}}throw ${errorVar}`
      | Some(resolveVal) =>
        catchLocation =>
          catchCode ++
          switch catchLocation {
          | #0 => b->Val.set(output, resolveVal)
          | #1 => `return Promise.resolve(${b->Val.inline(resolveVal)})`
          | #2 => `return ${b->Val.inline(resolveVal)}`
          } ++
          `}else{throw ${errorVar}}`
      }

      let fnOutputVar = b->Val.var(fnOutput)

      b.code =
        prevCode ++
        `try{${b.code}${{
            switch isAsync {
            | true =>
              b->Val.setInlined(
                output,
                `()=>{try{return ${fnOutputVar}().catch(${errorVar}=>{${catchCode(
                    #2,
                  )}})}catch(${errorVar}){${catchCode(#1)}}}`,
              )
            | false => b->Val.set(output, fnOutput)
            }
          }}}catch(${errorVar}){${catchCode(#0)}}`

      output
    }

    let withPathPrepend = (
      b: b,
      ~input,
      ~path,
      ~dynamicLocationVar as maybeDynamicLocationVar=?,
      fn,
    ) => {
      if path === Path.empty && maybeDynamicLocationVar === None {
        fn(b, ~input, ~path)
      } else {
        try b->withCatch(
          ~input,
          ~catch=(b, ~errorVar) => {
            b.code = `${errorVar}.path=${path->Stdlib.Inlined.Value.fromString}+${switch maybeDynamicLocationVar {
              | Some(var) => `'["'+${var}+'"]'+`
              | _ => ""
              }}${errorVar}.path`
            None
          },
          b => fn(b, ~input, ~path=Path.empty),
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

    let typeFilterCode = (b: b, ~typeFilter, ~schema, ~input, ~path) => {
      let inputVar = b->Val.var(input)
      `if(${typeFilter(~inputVar)}){${b->raiseWithArg(
          ~path,
          input => InvalidType({
            expected: schema,
            received: input,
          }),
          inputVar,
        )}}`
    }

    @inline
    let serialize = (b: b, ~schema, ~input, ~path) => {
      schema.serializeOperationBuilder(b, ~input, ~selfSchema=schema, ~path)
    }

    @inline
    let parse = (b: b, ~schema, ~input, ~path) => {
      schema.parseOperationBuilder(b, ~input, ~selfSchema=schema, ~path)
    }

    let parseWithTypeCheck = (b: b, ~schema, ~input, ~path) => {
      switch schema.maybeTypeFilter {
      | Some(typeFilter) =>
        b.code = b.code ++ b->typeFilterCode(~schema, ~typeFilter, ~input, ~path)
        let bb = b->scope
        let val = bb->parse(~schema, ~input, ~path)
        b.code = b.code ++ bb->allocateScope
        val
      | None => b->parse(~schema, ~input, ~path)
      }
    }
  }

  let noop = make((_b, ~input, ~selfSchema as _, ~path as _) => input)

  let noopOperation = i => i->Obj.magic

  @inline
  let intitialInputVar = "i"

  let build = (builder, ~schema, ~operation) => {
    let b = {
      code: "",
      varsAllocation: "",
      isAllocated: false,
      global: {
        varCounter: -1,
        embeded: [],
        operation,
      },
    }
    let input = {_var: intitialInputVar, _scope: b, isAsync: false}

    let output = builder(b, ~input, ~selfSchema=schema, ~path=Path.empty)

    if b.varsAllocation !== "" {
      b.code = `let ${b.varsAllocation};${b.code}`
    }

    if operation === Parsing {
      switch schema.maybeTypeFilter {
      | Some(typeFilter) =>
        b.code = b->B.typeFilterCode(~schema, ~typeFilter, ~input, ~path=Path.empty) ++ b.code
      | None => ()
      }
      schema.isAsyncParse = Value(output.isAsync)
    }

    if b.code === "" && output === input {
      noopOperation
    } else {
      let inlinedFunction = `${intitialInputVar}=>{${b.code}return ${b->B.Val.inline(output)}}`

      // Js.log(inlinedFunction)

      Stdlib.Function.make2(
        ~ctxVarName1="e",
        ~ctxVarValue1=b.global.embeded,
        ~ctxVarName2="s",
        ~ctxVarValue2=symbol,
        ~inlinedFunction,
      )
    }
  }
}
// TODO: Split validation code and transformation code
module B = Builder.B

module Literal = {
  open Stdlib

  type rec internal = {
    kind: kind,
    value: unknown,
    @as("s")
    string: string,
    @as("b")
    checkBuilder: (b, ~inputVar: string, ~literal: literal) => string,
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
    checkBuilder: inlinedStrictEqualCheckBuilder,
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
        isJsonable := false
      }
      if idx !== 0 {
        string := string.contents ++ ","
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
        isJsonable := false
      }
      if idx !== 0 {
        string := string.contents ++ ","
      }
      string := string.contents ++ itemLiteral.string
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

  @inline
  let isLiteralSchema = schema => (schema->classifyRaw->Obj.magic)["TAG"] === "Literal"

  @inline
  let unsafeFromSchema = (schema): literal => {
    schema->classifyRaw->unsafeGetVariantPayload
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
    switch schema->classifyRaw {
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
    | Object({items}) =>
      for idx in 0 to items->Js.Array2.length - 1 {
        let item = items->Js.Array2.unsafe_get(idx)
        try {
          switch item.schema->classifyRaw {
          // Allow optional fields
          | Option(s) => s
          | _ => item.schema
          }->validateJsonableSchema(~rootSchema)
        } catch {
        | exn => exn->InternalError.prependLocationOrRethrow(item.location)
        }
      }

    | Tuple({items}) =>
      items->Js.Array2.forEachi((item, idx) => {
        try {
          item.schema->validateJsonableSchema(~rootSchema)
        } catch {
        // TODO: Should throw with the nested schema instead of prepending path?
        | exn => exn->InternalError.prependLocationOrRethrow(idx->Js.Int.toString)
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
  ~rawTagged,
  ~metadataMap,
  ~parseOperationBuilder,
  ~serializeOperationBuilder,
  ~maybeTypeFilter,
) => {
  rawTagged,
  parseOperationBuilder,
  serializeOperationBuilder,
  isAsyncParse: Unknown,
  maybeTypeFilter,
  name,
  metadataMap,
}

@inline
let makeWithNoopSerializer = (
  ~name,
  ~rawTagged,
  ~metadataMap,
  ~parseOperationBuilder,
  ~maybeTypeFilter,
) => {
  name,
  rawTagged,
  parseOperationBuilder,
  serializeOperationBuilder: Builder.noop,
  isAsyncParse: Unknown,
  maybeTypeFilter,
  metadataMap,
}

module Operation = {
  let unexpectedAsync = () =>
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
      ~rawTagged=schema.rawTagged,
      ~maybeTypeFilter=schema.maybeTypeFilter,
      ~metadataMap,
    )
  }
}

let recursive = fn => {
  let placeholder: t<'value> = {"m": Metadata.Map.empty}->Obj.magic
  let schema = fn(placeholder)
  placeholder->Stdlib.Object.overrideWith(schema)
  placeholder.definer = None

  {
    let builder = placeholder.parseOperationBuilder
    placeholder.parseOperationBuilder = Builder.make((b, ~input, ~selfSchema, ~path) => {
      let isAsync = {
        selfSchema.parseOperationBuilder = Builder.noop
        let b = {
          global: {
            ...b.global,
            varCounter: -1,
            embeded: [],
          },
          code: "",
          varsAllocation: "",
          isAllocated: false,
        }
        let input = {_var: Builder.intitialInputVar, _scope: b, isAsync: false}
        let output = builder(b, ~input, ~selfSchema, ~path)
        output.isAsync
      }

      selfSchema.parseOperationBuilder = Builder.make((b, ~input, ~selfSchema, ~path as _) => {
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

      b->B.withPathPrepend(~input, ~path, (b, ~input, ~path as _) =>
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
    placeholder.serializeOperationBuilder = Builder.make((b, ~input, ~selfSchema, ~path) => {
      selfSchema.serializeOperationBuilder = Builder.make((b, ~input, ~selfSchema, ~path as _) => {
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
      b->B.withPathPrepend(~input, ~path, (b, ~input, ~path as _) =>
        b->B.embedSyncOperation(~input, ~fn=operation)
      )
    })
  }

  placeholder
}

let setName = (schema, name) => {
  make(
    ~name=() => name,
    ~parseOperationBuilder=schema.parseOperationBuilder,
    ~serializeOperationBuilder=schema.serializeOperationBuilder,
    ~rawTagged=schema.rawTagged,
    ~maybeTypeFilter=schema.maybeTypeFilter,
    ~metadataMap=schema.metadataMap,
  )
}

let primitiveName = () => {
  (%raw(`this`): t<'a>).rawTagged->(Obj.magic: tagged => string)
}

let containerName = () => {
  let tagged = (%raw(`this`): t<'a>).rawTagged->Obj.magic
  `${tagged["TAG"]}(${(tagged->unsafeGetVariantPayload).name()})`
}

let internalRefine = (schema, refiner) => {
  let schema = schema->toUnknown
  make(
    ~name=schema.name,
    ~rawTagged=schema.rawTagged,
    ~parseOperationBuilder=Builder.make((b, ~input, ~selfSchema, ~path) => {
      b->B.transform(~input=b->B.parse(~schema, ~input, ~path), (b, ~input) => {
        let rCode = refiner(b, ~input, ~selfSchema, ~path)
        b.code = b.code ++ rCode
        input
      })
    }),
    ~serializeOperationBuilder=Builder.make((b, ~input, ~selfSchema, ~path) => {
      b->B.serialize(
        ~schema,
        ~input=b->B.transform(~input, (b, ~input) => {
          b.code = b.code ++ refiner(b, ~input, ~selfSchema, ~path)
          input
        }),
        ~path,
      )
    }),
    ~maybeTypeFilter=schema.maybeTypeFilter,
    ~metadataMap=schema.metadataMap,
  )
}

let refine: (t<'value>, s<'value> => 'value => unit) => t<'value> = (schema, refiner) => {
  schema->internalRefine((b, ~input, ~selfSchema, ~path) => {
    `${b->B.embed(
        refiner(EffectCtx.make(~selfSchema, ~path, ~operation=b.global.operation)),
      )}(${b->B.Val.var(input)});`
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
    ~rawTagged=schema.rawTagged,
    ~parseOperationBuilder=Builder.make((b, ~input, ~selfSchema, ~path) => {
      let input = b->B.parse(~schema, ~input, ~path)

      switch transformer(EffectCtx.make(~selfSchema, ~path, ~operation=b.global.operation)) {
      | {parser, asyncParser: ?None} => b->B.embedSyncOperation(~input, ~fn=parser)
      | {parser: ?None, asyncParser} => b->B.embedAsyncOperation(~input, ~fn=asyncParser)
      | {parser: ?None, asyncParser: ?None, serializer: ?None} => input
      | {parser: ?None, asyncParser: ?None, serializer: _} =>
        b->B.invalidOperation(~path, ~description=`The S.transform parser is missing`)
      | {parser: _, asyncParser: _} =>
        b->B.invalidOperation(
          ~path,
          ~description=`The S.transform doesn't allow parser and asyncParser at the same time. Remove parser in favor of asyncParser`,
        )
      }
    }),
    ~serializeOperationBuilder=Builder.make((b, ~input, ~selfSchema, ~path) => {
      switch transformer(EffectCtx.make(~selfSchema, ~path, ~operation=b.global.operation)) {
      | {serializer} =>
        b->B.serialize(~schema, ~input=b->B.embedSyncOperation(~input, ~fn=serializer), ~path)
      | {parser: ?None, asyncParser: ?None, serializer: ?None} =>
        b->B.serialize(~schema, ~input, ~path)
      | {serializer: ?None, asyncParser: ?Some(_)}
      | {serializer: ?None, parser: ?Some(_)} =>
        b->B.invalidOperation(~path, ~description=`The S.transform serializer is missing`)
      }
    }),
    ~maybeTypeFilter=schema.maybeTypeFilter,
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
  switch schema->classifyRaw {
  | Union(unionSchemas) =>
    make(
      ~name=schema.name,
      ~rawTagged=Union(
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
      ~rawTagged=schema.rawTagged,
      ~parseOperationBuilder=Builder.make((b, ~input, ~selfSchema, ~path) => {
        switch transformer(EffectCtx.make(~selfSchema, ~path, ~operation=b.global.operation)) {
        | {parser, asyncParser: ?None} =>
          b->B.parseWithTypeCheck(
            ~schema,
            ~input=b->B.embedSyncOperation(~input, ~fn=parser),
            ~path,
          )
        | {parser: ?None, asyncParser} =>
          b->B.transform(~input=b->B.embedAsyncOperation(~input, ~fn=asyncParser), (b, ~input) => {
            b->B.parseWithTypeCheck(~schema, ~input, ~path)
          })
        | {parser: ?None, asyncParser: ?None} => b->B.parseWithTypeCheck(~schema, ~input, ~path)
        | {parser: _, asyncParser: _} =>
          b->B.invalidOperation(
            ~path,
            ~description=`The S.preprocess doesn't allow parser and asyncParser at the same time. Remove parser in favor of asyncParser`,
          )
        }
      }),
      ~serializeOperationBuilder=Builder.make((b, ~input, ~selfSchema, ~path) => {
        let input = b->B.serialize(~schema, ~input, ~path)

        switch transformer(EffectCtx.make(~selfSchema, ~path, ~operation=b.global.operation)) {
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
    ~rawTagged=Unknown,
    ~parseOperationBuilder=Builder.make((b, ~input, ~selfSchema, ~path) => {
      switch definer(EffectCtx.make(~selfSchema, ~path, ~operation=b.global.operation)) {
      | {parser, asyncParser: ?None} => b->B.embedSyncOperation(~input, ~fn=parser)
      | {parser: ?None, asyncParser} => b->B.embedAsyncOperation(~input, ~fn=asyncParser)
      | {parser: ?None, asyncParser: ?None, serializer: ?None} => input
      | {parser: ?None, asyncParser: ?None, serializer: _} =>
        b->B.invalidOperation(~path, ~description=`The S.custom parser is missing`)
      | {parser: _, asyncParser: _} =>
        b->B.invalidOperation(
          ~path,
          ~description=`The S.custom doesn't allow parser and asyncParser at the same time. Remove parser in favor of asyncParser`,
        )
      }
    }),
    ~serializeOperationBuilder=Builder.make((b, ~input, ~selfSchema, ~path) => {
      switch definer(EffectCtx.make(~selfSchema, ~path, ~operation=b.global.operation)) {
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
  let operationBuilder = Builder.make((b, ~input, ~selfSchema as _, ~path) => {
    let inputVar = b->B.Val.var(input)
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
    input
  })
  make(
    ~name=() => `Literal(${literal->Literal.toString})`,
    ~metadataMap=Metadata.Map.empty,
    ~rawTagged=Literal(literal),
    ~parseOperationBuilder=operationBuilder,
    ~serializeOperationBuilder=operationBuilder,
    ~maybeTypeFilter=None,
  )
}
let unit = literal(%raw("void 0"))

module Definition = {
  type t<'embeded>
  type node<'embeded> = dict<t<'embeded>>

  @inline
  let isEmbeded = (definition: t<'embeded>, ~embeded) =>
    embeded === definition->(Obj.magic: t<'embeded> => 'embeded)

  @inline
  let isEmbededBySet = (definition: t<'embeded>, ~embededSet) =>
    embededSet->Stdlib.WeakSet.has(definition->(Obj.magic: t<'embeded> => 'embeded))

  @inline
  let isNode = (definition: t<'embeded>) =>
    definition->Stdlib.Type.typeof === #object && definition !== %raw(`null`)

  let toConstant = (Obj.magic: t<'embeded> => unknown)
  let toEmbeded = (Obj.magic: t<'embeded> => 'embeded)
  let toNode = (Obj.magic: t<'embeded> => node<'embeded>)

  @inline
  let isEmbededItem = definition => (definition->toEmbeded).symbol === itemSymbol
}

module Variant = {
  @unboxed
  type serializeOutput = Registered(val) | @as(0) Unregistered | @as(1) RegisteredMultipleTimes

  let factory = {
    (schema: t<'value>, definer: 'value => 'variant): t<'variant> => {
      let schema = schema->toUnknown
      make(
        ~name=schema.name,
        ~rawTagged=schema.rawTagged,
        ~parseOperationBuilder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
          b->B.embedSyncOperation(~input=b->B.parse(~schema, ~input, ~path), ~fn=definer)
        }),
        ~serializeOperationBuilder=Builder.make((b, ~input, ~selfSchema, ~path) => {
          let inputVar = b->B.Val.var(input)

          let definition =
            definer(symbol->(Obj.magic: Stdlib.Symbol.t => 'value))->(
              Obj.magic: 'variant => Definition.t<Stdlib.Symbol.t>
            )

          let output = {
            // TODO: Check that it might be not an object in union
            let rec definitionToValue = (definition: Definition.t<Stdlib.Symbol.t>, ~valuePath) => {
              if definition->Definition.isEmbeded(~embeded=symbol) {
                Registered(valuePath === "" ? input : b->B.val(`${inputVar}${valuePath}`))
              } else if definition->Definition.isNode {
                let node = definition->Definition.toNode
                let keys = node->Js.Dict.keys
                let maybeOutputRef = ref(Unregistered)
                for idx in 0 to keys->Js.Array2.length - 1 {
                  let key = keys->Js.Array2.unsafe_get(idx)
                  let definition = node->Js.Dict.unsafeGet(key)
                  let maybeOutput = definitionToValue(
                    definition,
                    ~valuePath=Path.concat(valuePath, Path.fromLocation(key)),
                  )
                  switch (maybeOutputRef.contents, maybeOutput) {
                  | (Registered(_), Registered(_))
                  | (Registered(_), RegisteredMultipleTimes) =>
                    maybeOutputRef := RegisteredMultipleTimes
                  | (RegisteredMultipleTimes, _)
                  | (Registered(_), Unregistered) => ()
                  | (Unregistered, _) => maybeOutputRef := maybeOutput
                  }
                }
                maybeOutputRef.contents
              } else {
                let constant = definition->Definition.toConstant
                let constantVal = valuePath === "" ? input : b->B.val(`${inputVar}${valuePath}`)
                let constantVar = b->B.Val.var(constantVal)
                b.code =
                  b.code ++
                  `if(${constantVar}!==${b->B.embed(constant)}){${b->B.raiseWithArg(
                      ~path=path->Path.concat(valuePath),
                      input => InvalidLiteral({
                        expected: constant->Literal.parse,
                        received: input,
                      }),
                      constantVar,
                    )}}`
                Unregistered
              }
            }
            definitionToValue(definition, ~valuePath=Path.empty)
          }

          switch output {
          | RegisteredMultipleTimes =>
            b->B.invalidOperation(
              ~path,
              ~description=`The S.variant's value is registered multiple times`,
            )
          | Registered(var) => b->B.serialize(~schema, ~input=var, ~path)
          | Unregistered =>
            if selfSchema->Literal.isLiteralSchema {
              b->B.serialize(
                ~schema,
                ~input=b->B.val(b->B.embed(selfSchema->Literal.unsafeFromSchema->Literal.value)),
                ~path,
              )
            } else {
              b->B.invalidOperation(~path, ~description=`The S.variant's value is not registered`)
            }
          }
        }),
        ~maybeTypeFilter=schema.maybeTypeFilter,
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

  let parseOperationBuilder = Builder.make((b, ~input, ~selfSchema, ~path) => {
    let isNull = %raw(`selfSchema.r.TAG === "Null"`)
    let childSchema = selfSchema->classifyRaw->unsafeGetVariantPayload

    let bb = b->B.scope
    let itemOutput = bb->B.parse(~schema=childSchema, ~input, ~path)
    let itemCode = bb->B.allocateScope

    let isTransformed = isNull || itemOutput !== input

    let output = isTransformed ? {_scope: b, isAsync: itemOutput.isAsync} : input

    if itemCode !== "" || isTransformed {
      b.code =
        b.code ++
        `if(${b->B.Val.var(input)}!==${isNull ? "null" : "void 0"}){${itemCode}${b->B.Val.set(
            output,
            itemOutput,
          )}}${isNull || output.isAsync ? `else{${b->B.Val.set(output, b->B.val(`void 0`))}}` : ""}`
    }

    output
  })

  let serializeOperationBuilder = Builder.make((b, ~input, ~selfSchema, ~path) => {
    let output = b->B.allocateVal
    let inputVar = b->B.Val.var(input)

    let isNull = %raw(`selfSchema.r.TAG === "Null"`)
    let childSchema = selfSchema->classifyRaw->unsafeGetVariantPayload

    let bb = b->B.scope
    let itemOutput =
      bb->B.serialize(
        ~schema=childSchema,
        ~input=bb->B.Val.map(bb->B.embed(%raw("Caml_option.valFromOption")), input),
        ~path,
      )
    let itemCode = bb->B.allocateScope

    b.code =
      b.code ++
      `if(${inputVar}!==void 0){${itemCode}${b->B.Val.set(output, itemOutput)}}${isNull
          ? `else{${b->B.Val.setInlined(output, `null`)}}`
          : ""}`

    output
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
      ~rawTagged=Option(schema),
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
      ~rawTagged=schema.rawTagged,
      ~parseOperationBuilder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
        b->B.transform(~input=b->B.parse(~schema, ~input, ~path), (b, ~input) => {
          let inputVar = b->B.Val.var(input)
          b->B.val(
            `${inputVar}===void 0?${switch default {
              | Value(v) => b->B.embed(v)
              | Callback(cb) => `${b->B.embed(cb)}()`
              }}:${inputVar}`,
          )
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
      ~rawTagged=Null(schema),
      ~parseOperationBuilder=Option.parseOperationBuilder,
      ~serializeOperationBuilder=Option.serializeOperationBuilder,
      ~maybeTypeFilter=Option.maybeTypeFilter(~schema, ~inlinedNoneValue="null"),
    )
  }
}

let nullable = schema => {
  Option.factory(Null.factory(schema))
}

module Never = {
  let builder = Builder.make((b, ~input, ~selfSchema, ~path) => {
    b.code =
      b.code ++
      b->B.raiseWithArg(
        ~path,
        input => InvalidType({
          expected: selfSchema,
          received: input,
        }),
        b->B.Val.inline(input),
      ) ++ ";"
    input
  })

  let schema = make(
    ~name=primitiveName,
    ~metadataMap=Metadata.Map.empty,
    ~rawTagged=Never,
    ~parseOperationBuilder=builder,
    ~serializeOperationBuilder=builder,
    ~maybeTypeFilter=None,
  )
}

module Object = {
  type rec s = {
    @as("f") field: 'value. (string, t<'value>) => 'value,
    fieldOr: 'value. (string, t<'value>, 'value) => 'value,
    tag: 'value. (string, 'value) => unit,
    nested: 'value. (string, s => 'value) => 'value,
    flatten: 'value. t<'value> => 'value,
  }

  type ctx = {
    // Public API for JS/TS users.
    // It shouldn't be used from ReScript and
    // needed only because we use @as for field to reduce bundle-size
    // of ReScript compiled code
    @as("field") _jsField: 'value. (string, schema<'value>) => 'value,
    // Public API for ReScript users
    ...s,
  }

  let typeFilter = (~inputVar) => `!${inputVar}||${inputVar}.constructor!==Object`

  let getItems = (schema): array<item> => (schema->classifyRaw->Obj.magic)["items"]
  let getDefinition = schema => (schema->classifyRaw->Obj.magic)["definition"]

  let parseOperationBuilder = (b, ~input, ~selfSchema, ~path) => {
    let asyncOutputVars = []

    let outputs = Stdlib.WeakMap.make()

    let rec parseItems = (b: b, ~input, ~schema, ~path) => {
      let inputVar = b->B.Val.var(input)

      let items = schema->getItems
      let isObject = (schema->classifyRaw->Obj.magic)["TAG"] === "Object"

      for idx in 0 to items->Js.Array2.length - 1 {
        let prevCode = b.code
        b.code = ""

        let item = items->Js.Array2.unsafe_get(idx)
        let {schema, path: itemPath} = item
        let itemInput = b->B.val(`${inputVar}${itemPath}`)
        let path = path->Path.concat(itemPath)

        switch schema.maybeTypeFilter {
        | Some(typeFilter) =>
          b.code = b.code ++ b->B.typeFilterCode(~schema, ~typeFilter, ~input=itemInput, ~path)
        | None => ()
        }

        if isObject && schema.definer->Obj.magic {
          let bb = b->B.scope
          bb->parseItems(~input=itemInput, ~schema, ~path)
          b.code = prevCode ++ b.code ++ bb->B.allocateScope
        } else {
          let itemOutput = b->B.parse(~schema, ~input=itemInput, ~path)

          let _ = outputs->Stdlib.WeakMap.set(item, itemOutput)

          if itemOutput.isAsync {
            asyncOutputVars->Js.Array2.push(b->B.Val.var(itemOutput))->ignore
          }

          // Parse literal fields first, because they are most often used as discriminants
          if schema->Literal.isLiteralSchema {
            b.code = b.code ++ prevCode
          } else {
            b.code = prevCode ++ b.code
          }
        }
      }

      if isObject && (selfSchema->classifyRaw->Obj.magic)["unknownKeys"] === Strict {
        let key = b->B.allocateVal
        let keyVar = b->B.Val.var(key)
        b.code = b.code ++ `for(${keyVar} in ${inputVar}){if(`
        switch items {
        | [] => b.code = b.code ++ "true"
        | _ =>
          for idx in 0 to items->Js.Array2.length - 1 {
            let item = items->Js.Array2.unsafe_get(idx)
            if idx !== 0 {
              b.code = b.code ++ "&&"
            }
            b.code = b.code ++ `${keyVar}!==${item.inlinedLocation}`
          }
        }
        b.code =
          b.code ++
          `){${b->B.raiseWithArg(
              ~path,
              exccessFieldName => ExcessField(exccessFieldName),
              keyVar,
            )}}}`
      }
    }
    b->parseItems(~input, ~schema=selfSchema, ~path)

    let syncOutput = {
      let rec definitionToValue = (definition: Definition.t<item>, ~outputPath) => {
        switch outputs->Stdlib.WeakMap.get(definition->Definition.toEmbeded) {
        | Some(val) => b->B.Val.inline(val)
        | None =>
          if definition->Definition.isNode {
            let node = definition->Definition.toNode
            let isArray = Stdlib.Array.isArray(node)
            let keys = node->Js.Dict.keys

            let codeRef = ref(isArray ? "[" : "{")
            for idx in 0 to keys->Js.Array2.length - 1 {
              let key = keys->Js.Array2.unsafe_get(idx)
              let definition = node->Js.Dict.unsafeGet(key)
              let output =
                definition->definitionToValue(
                  ~outputPath=Path.concat(outputPath, Path.fromLocation(key)),
                )
              codeRef.contents =
                codeRef.contents ++
                (isArray ? output : `${key->Stdlib.Inlined.Value.fromString}:${output}`) ++ ","
            }
            codeRef.contents ++ (isArray ? "]" : "}")
          } else {
            let constant = definition->Definition.toConstant
            b->B.embed(constant)
          }
        }
      }
      selfSchema->getDefinition->definitionToValue(~outputPath=Path.empty)
    }

    if asyncOutputVars->Js.Array2.length === 0 {
      b->B.val(syncOutput)
    } else {
      b->B.asyncVal(
        `()=>Promise.all([${asyncOutputVars
          ->Js.Array2.map(asyncOutputVar => `${asyncOutputVar}()`)
          ->Js.Array2.joinWith(
            ",",
          )}]).then(([${asyncOutputVars->Js.Array2.toString}])=>(${syncOutput}))`,
      )
    }
  }

  type serializeCtx = {@as("d") mutable discriminantCode: string}

  let serializeOperationBuilder = Builder.make((b, ~input, ~selfSchema, ~path) => {
    let inputVar = b->B.Val.var(input)

    let ctx: serializeCtx = {discriminantCode: ""}
    let embededOutputs = Stdlib.WeakMap.make()

    let rec definitionToOutput = (definition: Definition.t<item>, ~outputPath) => {
      if definition->Definition.isNode {
        if definition->Definition.isEmbededItem {
          let item = definition->Definition.toEmbeded
          if embededOutputs->Stdlib.WeakMap.has(item) {
            b->B.invalidOperation(
              ~path,
              ~description=`The item ${item.inlinedLocation} is registered multiple times`,
            )
          } else {
            let {schema} = item
            let itemInput = b->B.val(`${inputVar}${outputPath}`)
            let itemOutput =
              b->B.serialize(~schema, ~input=itemInput, ~path=path->Path.concat(outputPath))

            embededOutputs->Stdlib.WeakMap.set(item, itemOutput)->ignore
          }
        } else {
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
      } else {
        let value = definition->Definition.toConstant
        let itemInputVar = `${inputVar}${outputPath}`
        ctx.discriminantCode =
          ctx.discriminantCode ++
          `if(${itemInputVar}!==${b->B.embed(value)}){${b->B.raiseWithArg(
              ~path=path->Path.concat(outputPath),
              input => InvalidLiteral({
                expected: value->Literal.parse,
                received: input,
              }),
              itemInputVar,
            )}}`
      }
    }
    selfSchema->getDefinition->definitionToOutput(~outputPath=Path.empty)
    b.code = ctx.discriminantCode ++ b.code

    let rec toRaw = (~schema, ~path) => {
      let items = schema->getItems
      let isObject = (schema->classifyRaw->Obj.magic)["TAG"] === "Object"

      let output = ref("")
      for idx in 0 to items->Js.Array2.length - 1 {
        let item = items->Js.Array2.unsafe_get(idx)

        let itemOutput = switch embededOutputs->Stdlib.WeakMap.get(item) {
        | Some(o) => b->B.Val.inline(o)
        | None =>
          let itemSchema = item.schema
          if itemSchema->Literal.isLiteralSchema {
            b->B.embed(itemSchema->Literal.unsafeFromSchema->Literal.value)
          } else if isObject && itemSchema.definer->Obj.magic {
            toRaw(~schema=itemSchema, ~path=path->Path.concat(item.path))
          } else {
            b->B.invalidOperation(
              ~path,
              ~description=`The ${item.inlinedLocation} item is not registered or not a literal`,
            )
          }
        }
        if isObject {
          output := output.contents ++ `${item.inlinedLocation}:${itemOutput},`
        } else {
          output := output.contents ++ `${itemOutput},`
        }
      }

      isObject ? "{" ++ output.contents ++ "}" : "[" ++ output.contents ++ "]"
    }

    b->B.val(toRaw(~schema=selfSchema, ~path))
  })

  let rec factory:
    type value. (s => value) => schema<value> =
    definer => {
      let fields = Js.Dict.empty()
      let items = []
      let embededDefinitions = Stdlib.WeakSet.make()

      let ctx = {
        let flatten = schema => {
          if schema.definer->Obj.magic {
            (schema.definer->Obj.magic)(%raw(`this`))
          } else {
            InternalError.panic(`The schema ${schema.name()} can't be flattened`)
          }
        }

        let field:
          type value. (string, schema<value>) => value =
          (fieldName, schema) => {
            let schema = schema->toUnknown
            let inlinedLocation = fieldName->Stdlib.Inlined.Value.fromString
            if fields->Stdlib.Dict.has(fieldName) {
              InternalError.panic(`The field ${inlinedLocation} is defined multiple times`)
            } else {
              let schema = if schema.definer->Obj.magic {
                if embededDefinitions->Stdlib.WeakSet.has(schema) {
                  factory(schema.definer->Obj.magic)
                } else {
                  let _ = embededDefinitions->Stdlib.WeakSet.add(schema)
                  schema
                }
              } else {
                schema
              }
              let item: item = {
                schema,
                location: fieldName,
                inlinedLocation,
                path: inlinedLocation->Path.fromInlinedLocation,
                symbol: itemSymbol,
              }
              fields->Js.Dict.set(fieldName, item)
              items->Js.Array2.push(item)->ignore
              if schema.definer->Obj.magic {
                schema->getDefinition->(Obj.magic: unknown => value)
              } else {
                item->(Obj.magic: item => value)
              }
            }
          }

        let tag = (tag, asValue) => {
          let _ = field(tag, literal(asValue))
        }

        let fieldOr = (fieldName, schema, or) => {
          field(fieldName, Option.factory(schema)->Option.getOr(or))
        }

        let nested:
          type value. (string, s => value) => value =
          (_fieldName, _definer) => {
            InternalError.panic(`Nested fields are not supported`)
            // switch fields->Js.Dict.unsafeGet(fieldName)->(Obj.magic: item => option<item>) {
            // | Some({schema, inlinedLocation}) =>
            //   switch schema->classifyRaw {
            //   | Object(_) => definer(schema->classifyRaw->(Obj.magic: tagged => s))
            //   | _ =>
            //     InternalError.panic(
            //       `Failed to define nested ${inlinedLocation} field since it's already defined as non-object`,
            //     )
            //   }
            // | None =>
            //   let nestedCtx = {
            //     taggedKey: "Object",
            //     unknownKeys: Strip,
            //     fields: Js.Dict.empty(),
            //     fieldNames: [],
            //     items: [],
            //     isNested: true,
            //     // js/ts methods
            //     _jsField: field,
            //     _jsFieldOr: fieldOr,
            //     _jsTag: tag,
            //     // methods
            //     field,
            //     fieldOr,
            //     tag,
            //     nested,
            //   }
            //   let nestedSchema = make(
            //     ~name,
            //     ~metadataMap=Metadata.Map.empty,
            //     ~rawTagged=nestedCtx->ctxToTagged,
            //     ~parseOperationBuilder=Builder.noop,
            //     ~serializeOperationBuilder=Builder.noop,
            //     ~maybeTypeFilter=Some(typeFilter),
            //   )
            //   let _ = ctx.field(fieldName, nestedSchema)
            //   definer((nestedCtx :> s))
            // }
          }

        {
          // js/ts methods
          _jsField: field,
          // methods
          field,
          fieldOr,
          tag,
          nested,
          flatten,
        }
      }

      let definition = definer((ctx :> s))->(Obj.magic: value => unknown)

      {
        rawTagged: Object({
          items,
          fields,
          unknownKeys: Strip,
          definition,
        }),
        parseOperationBuilder,
        serializeOperationBuilder,
        isAsyncParse: Unknown,
        maybeTypeFilter: Some(typeFilter),
        name: () => {
          `Object({${items
            ->Js.Array2.map(item => {
              `${item.inlinedLocation}: ${item.schema.name()}`
            })
            ->Js.Array2.joinWith(", ")}})`
        },
        metadataMap: Metadata.Map.empty,
        definer: definer->Obj.magic,
      }
    }

  let setUnknownKeys = (schema, unknownKeys) => {
    switch schema->classifyRaw {
    | Object({unknownKeys: schemaUnknownKeys, items, fields, definition})
      if schemaUnknownKeys !== unknownKeys => {
        name: schema.name,
        rawTagged: Object({
          unknownKeys,
          items,
          fields,
          definition,
        }),
        parseOperationBuilder: schema.parseOperationBuilder,
        serializeOperationBuilder: schema.serializeOperationBuilder,
        maybeTypeFilter: schema.maybeTypeFilter,
        isAsyncParse: schema.isAsyncParse,
        metadataMap: schema.metadataMap,
        definer: ?schema.definer,
      }
    // TODO: Should it throw for non Object schemas?
    | _ => schema
    }
  }

  let strip = schema => {
    schema->setUnknownKeys(Strip)
  }

  let strict = schema => {
    schema->setUnknownKeys(Strict)
  }
}

module Unknown = {
  let schema = {
    name: primitiveName,
    rawTagged: Unknown,
    parseOperationBuilder: Builder.noop,
    serializeOperationBuilder: Builder.noop,
    isAsyncParse: Value(false),
    metadataMap: Metadata.Map.empty,
    maybeTypeFilter: None,
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
    ~rawTagged=String,
    ~parseOperationBuilder=Builder.noop,
    ~maybeTypeFilter=Some(typeFilter),
  )
}

module JsonString = {
  let factory = (schema, ~space=0) => {
    let schema = schema->toUnknown
    try {
      schema->validateJsonableSchema(~rootSchema=schema, ~isRoot=true)
    } catch {
    | exn => {
        let _ = exn->InternalError.getOrRethrow
        InternalError.panic(
          `The schema ${schema.name()} passed to S.jsonString is not compatible with JSON`,
        )
      }
    }
    make(
      ~name=primitiveName,
      ~metadataMap=Metadata.Map.empty,
      ~rawTagged=String,
      ~parseOperationBuilder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
        let jsonVal = b->B.allocateVal

        b.code =
          b.code ++
          `try{${b->B.Val.set(
              jsonVal,
              b->B.Val.map("JSON.parse", input),
            )}}catch(t){${b->B.raiseWithArg(
              ~path,
              message => OperationFailed(message),
              "t.message",
            )}}`

        let bb = b->B.scope
        let val = bb->B.parseWithTypeCheck(~schema, ~input=jsonVal, ~path)
        b.code = b.code ++ bb->B.allocateScope
        val
      }),
      ~serializeOperationBuilder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
        b->B.val(
          `JSON.stringify(${b->B.Val.inline(b->B.serialize(~schema, ~input, ~path))}${space > 0
              ? `,null,${space->Stdlib.Int.unsafeToString}`
              : ""})`,
        )
      }),
      ~maybeTypeFilter=Some(String.typeFilter),
    )
  }
}

module Bool = {
  let typeFilter = (~inputVar) => `typeof ${inputVar}!=="boolean"`

  let schema = makeWithNoopSerializer(
    ~name=primitiveName,
    ~metadataMap=Metadata.Map.empty,
    ~rawTagged=Bool,
    ~parseOperationBuilder=Builder.noop,
    ~maybeTypeFilter=Some(typeFilter),
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

  let schema = makeWithNoopSerializer(
    ~name=primitiveName,
    ~metadataMap=Metadata.Map.empty,
    ~rawTagged=Int,
    ~parseOperationBuilder=Builder.noop,
    ~maybeTypeFilter=Some(typeFilter),
  )
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
    ~rawTagged=Float,
    ~parseOperationBuilder=Builder.noop,
    ~maybeTypeFilter=Some(typeFilter),
  )
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
      ~rawTagged=Array(schema),
      ~parseOperationBuilder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
        let inputVar = b->B.Val.var(input)
        let iteratorVar = b->B.varWithoutAllocation

        let bb = b->B.scope
        let itemInput = bb->B.val(`${inputVar}[${iteratorVar}]`)
        let itemOutput =
          bb->B.withPathPrepend(~input=itemInput, ~path, ~dynamicLocationVar=iteratorVar, (
            b,
            ~input,
            ~path,
          ) => b->B.parseWithTypeCheck(~schema, ~input, ~path))
        let itemCode = bb->B.allocateScope
        let isTransformed = itemInput !== itemOutput
        let output = isTransformed ? b->B.val("[]") : input

        b.code =
          b.code ++
          `for(let ${iteratorVar}=0;${iteratorVar}<${inputVar}.length;++${iteratorVar}){${itemCode}${isTransformed
              ? b->B.Val.push(output, itemOutput)
              : ""}}`

        if itemOutput.isAsync {
          b->B.asyncVal(`()=>Promise.all(${b->B.Val.var(output)}.map(t=>t()))`)
        } else {
          output
        }
      }),
      ~serializeOperationBuilder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
        if schema.serializeOperationBuilder === Builder.noop {
          input
        } else {
          let inputVar = b->B.Val.var(input)
          let iteratorVar = b->B.varWithoutAllocation
          let output = b->B.val("[]")

          let bb = b->B.scope
          let itemOutput =
            bb->B.withPathPrepend(
              ~input=bb->B.val(`${inputVar}[${iteratorVar}]`),
              ~path,
              ~dynamicLocationVar=iteratorVar,
              (b, ~input, ~path) => b->B.serialize(~schema, ~input, ~path),
            )
          let itemCode = bb->B.allocateScope

          b.code =
            b.code ++
            `for(let ${iteratorVar}=0;${iteratorVar}<${inputVar}.length;++${iteratorVar}){${itemCode}${b->B.Val.push(
                output,
                itemOutput,
              )}}`

          output
        }
      }),
      ~maybeTypeFilter=Some(typeFilter),
    )
  }
}

module Dict = {
  let factory = schema => {
    let schema = schema->toUnknown
    make(
      ~name=containerName,
      ~metadataMap=Metadata.Map.empty,
      ~rawTagged=Dict(schema),
      ~parseOperationBuilder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
        let inputVar = b->B.Val.var(input)
        let keyVar = b->B.varWithoutAllocation

        let bb = b->B.scope
        let itemInput = bb->B.val(`${inputVar}[${keyVar}]`)
        let itemOutput =
          bb->B.withPathPrepend(~path, ~input=itemInput, ~dynamicLocationVar=keyVar, (
            b,
            ~input,
            ~path,
          ) => b->B.parseWithTypeCheck(~schema, ~input, ~path))
        let itemCode = bb->B.allocateScope
        let isTransformed = itemInput !== itemOutput
        let output = isTransformed ? b->B.val("{}") : input

        b.code =
          b.code ++
          `for(let ${keyVar} in ${inputVar}){${itemCode}${isTransformed
              ? b->B.Val.addKey(output, keyVar, itemOutput)
              : ""}}`

        if itemOutput.isAsync {
          let resolveVar = b->B.varWithoutAllocation
          let rejectVar = b->B.varWithoutAllocation
          let asyncParseResultVar = b->B.varWithoutAllocation
          let counterVar = b->B.varWithoutAllocation
          let outputVar = b->B.Val.var(output)
          b->B.asyncVal(
            `()=>new Promise((${resolveVar},${rejectVar})=>{let ${counterVar}=Object.keys(${outputVar}).length;for(let ${keyVar} in ${outputVar}){${outputVar}[${keyVar}]().then(${asyncParseResultVar}=>{${outputVar}[${keyVar}]=${asyncParseResultVar};if(${counterVar}--===1){${resolveVar}(${outputVar})}},${rejectVar})}})`,
          )
        } else {
          output
        }
      }),
      ~serializeOperationBuilder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
        if schema.serializeOperationBuilder === Builder.noop {
          input
        } else {
          let inputVar = b->B.Val.var(input)
          let output = b->B.val("{}")
          let keyVar = b->B.varWithoutAllocation

          let bb = b->B.scope
          let itemOutput =
            bb->B.withPathPrepend(
              ~input=bb->B.val(`${inputVar}[${keyVar}]`),
              ~path,
              ~dynamicLocationVar=keyVar,
              (b, ~input, ~path) => b->B.serialize(~schema, ~input, ~path),
            )
          let itemCode = bb->B.allocateScope

          b.code =
            b.code ++
            `for(let ${keyVar} in ${inputVar}){${itemCode}${b->B.Val.addKey(
                output,
                keyVar,
                itemOutput,
              )}}`

          output
        }
      }),
      ~maybeTypeFilter=Some(Object.typeFilter),
    )
  }
}

module Tuple = {
  type s = {
    item: 'value. (int, t<'value>) => 'value,
    tag: 'value. (int, 'value) => unit,
  }

  let factory = definer => {
    let items = []
    let ctx = {
      let item:
        type value. (int, schema<value>) => value =
        (idx, schema) => {
          let schema = schema->toUnknown
          let location = idx->Js.Int.toString
          let inlinedLocation = `"${location}"`
          if items->Stdlib.Array.has(idx) {
            InternalError.panic(`The item ${inlinedLocation} is defined multiple times`)
          } else {
            let item: item = {
              schema,
              location,
              inlinedLocation,
              path: inlinedLocation->Path.fromInlinedLocation,
              symbol: itemSymbol,
            }
            items->Js.Array2.unsafe_set(idx, item)
            item->(Obj.magic: item => value)
          }
        }

      let tag = (idx, asValue) => {
        let _ = item(idx, literal(asValue))
      }

      {
        item,
        tag,
      }
    }
    let definition = definer((ctx :> s))->(Obj.magic: 'any => unknown)

    let length = items->Js.Array2.length
    for idx in 0 to length - 1 {
      if items->Js.Array2.unsafe_get(idx)->Obj.magic->not {
        let schema = unit->toUnknown
        let location = idx->Js.Int.toString
        let inlinedLocation = `"${location}"`
        let item: item = {
          schema,
          location,
          inlinedLocation,
          path: inlinedLocation->Path.fromInlinedLocation,
          symbol: itemSymbol,
        }
        items->Js.Array2.unsafe_set(idx, item)
      }
    }

    make(
      ~name=() => `Tuple(${items->Js.Array2.map(i => i.schema.name())->Js.Array2.joinWith(", ")})`,
      ~rawTagged=Tuple({
        items,
        definition,
      }),
      ~parseOperationBuilder=Object.parseOperationBuilder,
      ~serializeOperationBuilder=Object.serializeOperationBuilder,
      ~maybeTypeFilter=Some(
        (~inputVar) =>
          Array.typeFilter(~inputVar) ++
          `||${inputVar}.length!==${length->Stdlib.Int.unsafeToString}`,
      ),
      ~metadataMap=Metadata.Map.empty,
    )
  }
}

module Union = {
  let factory = schemas => {
    let schemas: array<t<unknown>> = schemas->Obj.magic

    switch schemas {
    | [] => InternalError.panic("S.union requires at least one item")
    | [schema] => schema->castUnknownSchemaToAnySchema
    | _ =>
      make(
        ~name=() => `Union(${schemas->Js.Array2.map(s => s.name())->Js.Array2.joinWith(", ")})`,
        ~metadataMap=Metadata.Map.empty,
        ~rawTagged=Union(schemas),
        ~parseOperationBuilder=Builder.make((b, ~input, ~selfSchema, ~path) => {
          let schemas = selfSchema->classifyRaw->unsafeGetVariantPayload

          let output = b->B.allocateVal
          let codeEndRef = ref("")
          let errorCodeRef = ref("")
          let isAsync = ref(false)

          // TODO: Add support for async
          for idx in 0 to schemas->Js.Array2.length - 1 {
            let prevCode = b.code
            try {
              let schema = schemas->Js.Array2.unsafe_get(idx)
              let errorVar = `e` ++ idx->Stdlib.Int.unsafeToString
              b.code = b.code ++ `try{`
              let itemOutput = b->B.parseWithTypeCheck(~schema, ~input, ~path=Path.empty)
              if itemOutput.isAsync {
                isAsync := true
              }

              b.code = b.code ++ `${b->B.Val.set(output, itemOutput)}}catch(${errorVar}){`
              codeEndRef := codeEndRef.contents ++ "}"

              errorCodeRef := errorCodeRef.contents ++ errorVar ++ ","
            } catch {
            | exn =>
              errorCodeRef :=
                errorCodeRef.contents ++ b->B.embed(exn->InternalError.getOrRethrow) ++ ","
              b.code = prevCode
            }
          }

          if isAsync.contents {
            b->B.invalidOperation(
              ~path,
              ~description="S.union doesn't support async items. Please create an issue to rescript-schema if you nead the feature",
            )
          }

          b.code =
            b.code ++
            b->B.raiseWithArg(
              ~path,
              internalErrors => {
                InvalidUnion(internalErrors)
              },
              `[${errorCodeRef.contents}]`,
            ) ++
            codeEndRef.contents

          let isAllSchemasBuilderFailed = codeEndRef.contents === ""
          if isAllSchemasBuilderFailed {
            b.code = b.code ++ ";"
            input
          } else {
            output
          }
        }),
        ~serializeOperationBuilder=Builder.make((b, ~input, ~selfSchema, ~path) => {
          let schemas = selfSchema->classifyRaw->unsafeGetVariantPayload

          let output = b->B.allocateVal
          let codeEndRef = ref("")
          let errorCodeRef = ref("")

          for idx in 0 to schemas->Js.Array2.length - 1 {
            let prevCode = b.code
            try {
              let schema = schemas->Js.Array2.unsafe_get(idx)
              let errorVar = `e` ++ idx->Stdlib.Int.unsafeToString

              let bb = b->B.scope
              let itemOutput = bb->B.serialize(~schema, ~input, ~path=Path.empty)
              switch schema.maybeTypeFilter {
              | Some(typeFilter) =>
                bb.code =
                  bb.code ++
                  bb->B.typeFilterCode(~schema, ~typeFilter, ~input=itemOutput, ~path=Path.empty)
              | None => ()
              }

              b.code =
                b.code ++
                `try{${bb->B.allocateScope}${b->B.Val.set(output, itemOutput)}}catch(${errorVar}){`
              codeEndRef := codeEndRef.contents ++ "}"
              errorCodeRef := errorCodeRef.contents ++ errorVar ++ ","
            } catch {
            | exn => {
                errorCodeRef :=
                  errorCodeRef.contents ++ b->B.embed(exn->InternalError.getOrRethrow) ++ ","
                b.code = prevCode
              }
            }
          }

          b.code =
            b.code ++
            b->B.raiseWithArg(
              ~path,
              internalErrors => {
                InvalidUnion(internalErrors)
              },
              `[${errorCodeRef.contents}]`,
            ) ++
            codeEndRef.contents

          let isAllSchemasBuilderFailed = codeEndRef.contents === ""
          if isAllSchemasBuilderFailed {
            b.code = b.code ++ ";"
            input
          } else {
            output
          }
        }),
        ~maybeTypeFilter=None,
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
    ~rawTagged=JSON({validated: validate}),
    ~metadataMap=Metadata.Map.empty,
    ~maybeTypeFilter=None,
    ~parseOperationBuilder=validate
      ? Builder.make((b, ~input, ~selfSchema, ~path) => {
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

          b->B.Val.map(b->B.embed(parse), input)
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
    ~parseOperationBuilder=Builder.make((b, ~input, ~selfSchema, ~path) => {
      let inputVar = b->B.Val.var(input)

      b->B.withCatch(
        ~input,
        ~catch=(b, ~errorVar) => Some(
          b->B.val(
            `${b->B.embed((input, internalError) =>
                getFallbackValue({
                  Catch.input,
                  error: internalError,
                  schema: selfSchema->castUnknownSchemaToAnySchema,
                  fail: (message, ~path as customPath=Path.empty) => {
                    InternalError.raise(
                      ~path=path->Path.concat(customPath),
                      ~code=OperationFailed(message),
                      ~operation=b.global.operation,
                    )
                  },
                })
              )}(${inputVar},${errorVar})`,
          ),
        ),
        b => {
          b->B.parseWithTypeCheck(~schema, ~input, ~path)
        },
      )
    }),
    ~serializeOperationBuilder=schema.serializeOperationBuilder,
    ~rawTagged=schema.rawTagged,
    ~maybeTypeFilter=None,
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
    if definition->Definition.isEmbededBySet(~embededSet) {
      definition->Definition.toEmbeded
    } else if definition->Definition.isNode {
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
        })->toUnknown
      }
    } else {
      let constant = definition->Definition.toConstant
      literal(constant)
    }
  }

  let factory = definer => {
    let embededSet = Stdlib.WeakSet.make()
    let matches:
      type value. schema<value> => value =
      schema => {
        let schema = schema->toUnknown
        embededSet->Stdlib.WeakSet.add(schema)->ignore
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
    | InvalidUnion(errors) => {
        let lineBreak = `\n${" "->Js.String2.repeat(nestedLevel * 2)}`
        let reasonsDict = Js.Dict.empty()

        errors->Js.Array2.forEach(error => {
          let reason = error->reason(~nestedLevel=nestedLevel->Stdlib.Int.plus(1))
          let location = switch error.path {
          | "" => ""
          | nonEmptyPath => `Failed at ${nonEmptyPath}. `
          }
          reasonsDict->Js.Dict.set(`- ${location}${reason}`, ())
        })
        let uniqueReasons = reasonsDict->Js.Dict.keys

        `Invalid union with following errors${lineBreak}${uniqueReasons->Js.Array2.joinWith(
            lineBreak,
          )}`
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

    let inlinedSchema = switch schema->classifyRaw {
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
    | Tuple({items: [i1]}) => `S.tuple1(${i1.schema->internalInline()})`
    | Tuple({items: [i1, i2]}) =>
      `S.tuple2(${i1.schema->internalInline()}, ${i2.schema->internalInline()})`
    | Tuple({items: [i1, i2, i3]}) =>
      `S.tuple3(${i1.schema->internalInline()}, ${i2.schema->internalInline()}, ${i3.schema->internalInline()})`
    | Tuple({items: tupleSchemas}) =>
      `S.tuple(s => (${tupleSchemas
        ->Js.Array2.mapi((item, idx) =>
          `s.item(${idx->Stdlib.Int.unsafeToString}, ${item.schema->internalInline()})`
        )
        ->Js.Array2.joinWith(", ")}))`
    | Object({items: []}) => `S.object(_ => ())`
    | Object({items}) =>
      `S.object(s =>
  {
    ${items
        ->Js.Array2.map(item => {
          `${item.inlinedLocation}: s.field(${item.inlinedLocation}, ${item.schema->internalInline()})`
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

    let inlinedSchema = switch schema->classifyRaw {
    | Object({unknownKeys: Strict}) => inlinedSchema ++ `->S.Object.strict`
    | _ => inlinedSchema
    }

    let inlinedSchema = switch schema->classifyRaw {
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
            `->S.email(~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Url, message} => `->S.url(~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Uuid, message} =>
            `->S.uuid(~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Cuid, message} =>
            `->S.cuid(~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Min({length}), message} =>
            `->S.stringMin(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Max({length}), message} =>
            `->S.stringMax(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Length({length}), message} =>
            `->S.stringLength(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Pattern({re}), message} =>
            `->S.pattern(%re(${re
              ->Stdlib.Re.toString
              ->Stdlib.Inlined.Value.fromString}), ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Datetime, message} =>
            `->S.datetime(~message=${message->Stdlib.Inlined.Value.fromString})`
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
            `->S.intMax(${value->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Min({value}), message} =>
            `->S.intMin(${value->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Port, message} =>
            `->S.port(~message=${message->Stdlib.Inlined.Value.fromString})`
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
            `->S.floatMax(${value->Stdlib.Inlined.Float.toRescript}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Min({value}), message} =>
            `->S.floatMin(${value->Stdlib.Inlined.Float.toRescript}, ~message=${message->Stdlib.Inlined.Value.fromString})`
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
            `->S.arrayMax(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Min({length}), message} =>
            `->S.arrayMin(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Length({length}), message} =>
            `->S.arrayLength(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
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
// Built-in refinements
// =============

let intMin = (schema, minValue, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `Number must be greater than or equal to ${minValue->Stdlib.Int.unsafeToString}`
  }
  schema->addRefinement(
    ~metadataId=Int.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(${b->B.Val.var(input)}<${b->B.embed(minValue)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Min({value: minValue}),
      message,
    },
  )
}

let intMax = (schema, maxValue, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `Number must be lower than or equal to ${maxValue->Stdlib.Int.unsafeToString}`
  }
  schema->addRefinement(
    ~metadataId=Int.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(${b->B.Val.var(input)}>${b->B.embed(maxValue)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Max({value: maxValue}),
      message,
    },
  )
}

let port = (schema, ~message="Invalid port") => {
  schema->addRefinement(
    ~metadataId=Int.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(${b->B.Val.var(input)}<1||${b->B.Val.var(input)}>65535){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Port,
      message,
    },
  )
}

let floatMin = (schema, minValue, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `Number must be greater than or equal to ${minValue->Stdlib.Float.unsafeToString}`
  }
  schema->addRefinement(
    ~metadataId=Float.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(${b->B.Val.var(input)}<${b->B.embed(minValue)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Min({value: minValue}),
      message,
    },
  )
}

let floatMax = (schema, maxValue, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `Number must be lower than or equal to ${maxValue->Stdlib.Float.unsafeToString}`
  }
  schema->addRefinement(
    ~metadataId=Float.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(${b->B.Val.var(input)}>${b->B.embed(maxValue)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Max({value: maxValue}),
      message,
    },
  )
}

let arrayMin = (schema, length, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `Array must be ${length->Stdlib.Int.unsafeToString} or more items long`
  }
  schema->addRefinement(
    ~metadataId=Array.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(${b->B.Val.var(input)}.length<${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Min({length: length}),
      message,
    },
  )
}

let arrayMax = (schema, length, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `Array must be ${length->Stdlib.Int.unsafeToString} or fewer items long`
  }
  schema->addRefinement(
    ~metadataId=Array.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(${b->B.Val.var(input)}.length>${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Max({length: length}),
      message,
    },
  )
}

let arrayLength = (schema, length, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `Array must be exactly ${length->Stdlib.Int.unsafeToString} items long`
  }
  schema->addRefinement(
    ~metadataId=Array.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(${b->B.Val.var(input)}.length!==${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Length({length: length}),
      message,
    },
  )
}

let stringMin = (schema, length, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `String must be ${length->Stdlib.Int.unsafeToString} or more characters long`
  }
  schema->addRefinement(
    ~metadataId=String.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(${b->B.Val.var(input)}.length<${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Min({length: length}),
      message,
    },
  )
}

let stringMax = (schema, length, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `String must be ${length->Stdlib.Int.unsafeToString} or fewer characters long`
  }
  schema->addRefinement(
    ~metadataId=String.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(${b->B.Val.var(input)}.length>${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Max({length: length}),
      message,
    },
  )
}

let stringLength = (schema, length, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `String must be exactly ${length->Stdlib.Int.unsafeToString} characters long`
  }
  schema->addRefinement(
    ~metadataId=String.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(${b->B.Val.var(input)}.length!==${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Length({length: length}),
      message,
    },
  )
}

let email = (schema, ~message=`Invalid email address`) => {
  schema->addRefinement(
    ~metadataId=String.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(!${b->B.embed(String.emailRegex)}.test(${b->B.Val.var(input)})){${b->B.fail(
          ~message,
          ~path,
        )}}`
    },
    ~refinement={
      kind: Email,
      message,
    },
  )
}

let uuid = (schema, ~message=`Invalid UUID`) => {
  schema->addRefinement(
    ~metadataId=String.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(!${b->B.embed(String.uuidRegex)}.test(${b->B.Val.var(input)})){${b->B.fail(
          ~message,
          ~path,
        )}}`
    },
    ~refinement={
      kind: Uuid,
      message,
    },
  )
}

let cuid = (schema, ~message=`Invalid CUID`) => {
  schema->addRefinement(
    ~metadataId=String.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `if(!${b->B.embed(String.cuidRegex)}.test(${b->B.Val.var(input)})){${b->B.fail(
          ~message,
          ~path,
        )}}`
    },
    ~refinement={
      kind: Cuid,
      message,
    },
  )
}

let url = (schema, ~message=`Invalid url`) => {
  schema->addRefinement(
    ~metadataId=String.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      `try{new URL(${b->B.Val.var(input)})}catch(_){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Url,
      message,
    },
  )
}

let pattern = (schema, re, ~message=`Invalid`) => {
  schema->addRefinement(
    ~metadataId=String.Refinement.metadataId,
    ~refiner=(b, ~input, ~selfSchema as _, ~path) => {
      let reVal = b->B.val(b->B.embed(re))
      let reVar = b->B.Val.var(reVal)
      `${reVar}.lastIndex=0;if(!${reVar}.test(${b->B.Val.var(input)})){${b->B.fail(
          ~message,
          ~path,
        )}}`
    },
    ~refinement={
      kind: Pattern({re: re}),
      message,
    },
  )
}

let datetime = (schema, ~message=`Invalid datetime string! Must be UTC`) => {
  let refinement = {
    String.Refinement.kind: Datetime,
    message,
  }
  schema
  ->Metadata.set(
    ~id=String.Refinement.metadataId,
    {
      switch schema->Metadata.get(~id=String.Refinement.metadataId) {
      | Some(refinements) => refinements->Stdlib.Array.append(refinement)
      | None => [refinement]
      }
    },
  )
  ->transform(s => {
    parser: string => {
      if String.datetimeRe->Js.Re.test_(string)->not {
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
  | ({rawTagged: Object({items: s1Items})}, {rawTagged: Object({items: s2Items, unknownKeys})}) =>
    let items = []
    let fields = Js.Dict.empty()
    for idx in 0 to s1Items->Js.Array2.length - 1 {
      let item = s1Items->Js.Array2.unsafe_get(idx)
      items->Js.Array2.push(item)->ignore
      fields->Js.Dict.set(item.location, item)
    }
    for idx in 0 to s2Items->Js.Array2.length - 1 {
      let item = s2Items->Js.Array2.unsafe_get(idx)
      if fields->Stdlib.Dict.has(item.location) {
        InternalError.panic(`The field ${item.inlinedLocation} is defined multiple times`)
      }
      items->Js.Array2.push(item)->ignore
      fields->Js.Dict.set(item.location, item)
    }
    make(
      ~name=() => `${s1.name()} & ${s2.name()}`,
      ~rawTagged=Object({
        unknownKeys,
        items,
        fields,
        definition: %raw(`void 0`),
      }),
      ~parseOperationBuilder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
        let s1Result = b->B.parse(~schema=s1, ~input, ~path)
        let s2Result = b->B.parse(~schema=s2, ~input, ~path)
        // TODO: Check that these are objects
        // TODO: Check that s1Result is not mutating input
        b->B.val(`Object.assign(${b->B.Val.inline(s1Result)}, ${b->B.Val.inline(s2Result)})`)
      }),
      ~serializeOperationBuilder=Builder.make((b, ~input as _, ~selfSchema as _, ~path) => {
        b->B.invalidOperation(~path, ~description=`The S.merge serializing is not supported yet`)
      }),
      ~maybeTypeFilter=Some(Object.typeFilter),
      ~metadataMap=Metadata.Map.empty,
    )
  | _ => InternalError.panic("The merge supports only Object schemas")
  }
}

let js_name = name
