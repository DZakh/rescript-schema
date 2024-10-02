@@uncurried
@@warning("-30")

type never

external castAnyToUnknown: 'any => unknown = "%identity"
external castUnknownToAny: unknown => 'any = "%identity"

module Obj = {
  external magic: 'a => 'b = "%identity"
}

module Stdlib = {
  module Option = {
    external unsafeUnwrap: option<'a> => 'a = "%identity"
  }

  module Type = {
    type t = [#undefined | #object | #boolean | #number | #bigint | #string | #symbol | #function]

    external typeof: 'a => t = "#typeof"
  }

  module Promise = {
    type t<+'a> = promise<'a>

    @send
    external thenResolveWithCatch: (t<'a>, 'a => 'b, exn => 'b) => t<'b> = "then"

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

    @get_index
    external unsafeGetOption: (dict<'a>, string) => option<'a> = ""

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
type isAsyncSchema = | @as(0) Unknown | Value(bool)
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
  @as("r")
  mutable reverse: unit => t<unknown>,
  @as("b")
  mutable builder: builder,
  @as("f")
  maybeTypeFilter: option<(b, ~inputVar: string) => string>,
  @as("i")
  mutable isAsyncSchema: isAsyncSchema,
  @as("d")
  mutable // Use char to unsafely prevent Caml_option applications
  definer?: char,
  @as("c")
  mutable definerCtx?: char,
  @as("m")
  metadataMap: dict<unknown>,
  @as("parseOrThrow")
  mutable parseOrRaise: unknown => unknown,
  @as("parse")
  jsParse: unknown => jsResult<unknown>,
  @as("parseAsync")
  jsParseAsync: unknown => promise<jsResult<unknown>>,
  @as("serialize")
  jsSerialize: unknown => jsResult<unknown>,
  @as("serializeOrThrow")
  mutable serializeToUnknownOrRaise: unknown => unknown,
  @as("serializeToJsonOrThrow")
  mutable serializeOrRaise: unknown => Js.Json.t,
  @as("assert")
  mutable assertOrRaise: unknown => unit,
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
  mutable operation: int,
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
  | Parse
  | ParseAsync
  | SerializeToJson
  | SerializeToUnknown
  | Assert
and schema<'a> = t<'a>
and error = private {operation: operation, code: errorCode, path: Path.t}
and errorCode =
  | OperationFailed(string)
  | InvalidOperation({description: string})
  | InvalidType({expected: schema<unknown>, received: unknown})
  | ExcessField(string)
  | InvalidUnion(array<error>)
  | UnexpectedAsync
  | InvalidJsonSchema(schema<unknown>)
@tag("success")
and jsResult<'value> = | @as(true) Success({value: 'value}) | @as(false) Failure({error: error})

type exn += private Raised(error)

external castUnknownSchemaToAnySchema: t<unknown> => t<'any> = "%identity"
external toUnknown: t<'any> => t<unknown> = "%identity"

let unsafeGetVariantPayload = variant => (variant->Obj.magic)["_0"]
let unsafeGetVarianTag = (variant): string => (variant->Obj.magic)["TAG"]
let unsafeGetErrorPayload = variant => (variant->Obj.magic)["_1"]

@inline
let isLiteralSchema = schema => schema.tagged->unsafeGetVarianTag === "Literal"
@inline
let isPrimitiveSchema = schema => schema.tagged->Js.typeof === "string"

type globalConfig = {
  @as("r")
  mutable recCounter: int,
  @as("u")
  mutable defaultUnknownKeys: unknownKeys,
  @as("n")
  mutable disableNanNumberCheck: bool,
}

type globalConfigOverride = {
  defaultUnknownKeys?: unknownKeys,
  disableNanNumberCheck?: bool,
}

let initialDefaultUnknownKeys = Strip
let initialDisableNanNumberProtection = false
let globalConfig = {
  recCounter: 0,
  defaultUnknownKeys: initialDefaultUnknownKeys,
  disableNanNumberCheck: initialDisableNanNumberProtection,
}

let toJsResult = (result: result<'value, error>): jsResult<'value> => {
  switch result {
  | Ok(value) => Success({value: value})
  | Error(error) => Failure({error: error})
  }
}

module InternalError = {
  %%raw(`
    // let index = 0;
    class RescriptSchemaError extends Error {
      constructor(code, operation, path) {
        // console.log(index)
        // index = index + 1;
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
  let panic = message => Stdlib.Exn.raiseError(Stdlib.Exn.makeError(`[rescript-schema] ${message}`))
}

type s<'value> = {
  schema: t<'value>,
  fail: 'a. (string, ~path: Path.t=?) => 'a,
}

@inline
let classify = schema => schema.tagged

module Operation = {
  module Flag = {
    @inline let typeValidation = 1
    @inline let async = 2
    @inline let assertOutput = 4
    @inline let jsonableOutput = 8
    @inline let jsonStringOutput = 16
  }

  type t = int

  let make = () => 0

  let addFlag = (operation: t, flag): t => operation->lor(flag)

  let unsafeHasFlag = (operation: t, flag) => operation->land(flag)->(Obj.magic: int => bool)

  // TODO: Replace public with Operation.t in v9
  @inline
  let toPublic = (operation: t) => {
    if operation->unsafeHasFlag(Flag.assertOutput) {
      Assert
    } else if operation->unsafeHasFlag(Flag.typeValidation) {
      if operation->unsafeHasFlag(Flag.async) {
        ParseAsync
      } else {
        Parse
      }
    } else if operation->unsafeHasFlag(Flag.jsonableOutput) {
      SerializeToJson
    } else {
      SerializeToUnknown
    }
  }
}

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
            let allocation = switch val._initial {
            | Some(i) => `${var}=${i}`
            | None => var
            }
            let varsAllocation = val._scope.varsAllocation
            val._scope.varsAllocation = varsAllocation === ""
              ? allocation
              : varsAllocation ++ "," ++ allocation
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
            `${b->var(input)}=Promise.resolve(${b->inline(val)})`
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
          `${b->Val.inline(input)}.then(${b->Val.var(
              operationInput,
            )}=>{${operationCode}return ${b->Val.inline(operationOutputVal)}})`,
        )
      } else {
        operation(b, ~input)
      }
    }

    let raise = (b: b, ~code, ~path) => {
      Stdlib.Exn.raiseAny(
        InternalError.make(~code, ~operation=b.global.operation->Operation.toPublic, ~path),
      )
    }

    let embedSyncOperation = (b: b, ~input, ~fn: 'input => 'output) => {
      if input.isAsync {
        b->asyncVal(`${b->Val.inline(input)}.then(${b->embed(fn)})`)
      } else {
        b->Val.map(b->embed(fn), input)
      }
    }

    let embedAsyncOperation = (b: b, ~input, ~fn: 'input => unit => promise<'output>) => {
      if !(b.global.operation->Operation.unsafeHasFlag(Operation.Flag.async)) {
        b->raise(~code=UnexpectedAsync, ~path=Path.empty)
      }
      let val = b->embedSyncOperation(~input, ~fn=v => fn(v)())
      val.isAsync = true
      val
    }

    let failWithArg = (b: b, ~path, fn: 'arg => errorCode, arg) => {
      `${b->embed(arg => {
          b->raise(~path, ~code=fn(arg))
        })}(${arg})`
    }

    let fail = (b: b, ~message, ~path) => {
      `${b->embed(() => {
          b->raise(~path, ~code=OperationFailed(message))
        })}()`
    }

    let effectCtx = (b, ~selfSchema, ~path) => {
      schema: selfSchema->castUnknownSchemaToAnySchema,
      fail: (message, ~path as customPath=Path.empty) => {
        b->raise(~path=path->Path.concat(customPath), ~code=OperationFailed(message))
      },
    }

    let registerInvalidJson = (b, ~selfSchema, ~path) => {
      if b.global.operation->Operation.unsafeHasFlag(Operation.Flag.jsonableOutput) {
        b->raise(~path, ~code=InvalidJsonSchema(selfSchema))
      }
    }

    let invalidOperation = (b: b, ~path, ~description) => {
      b->raise(~path, ~code=InvalidOperation({description: description}))
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

      if fnOutput === input && b.code === "" {
        fnOutput
      } else {
        let isAsync = fnOutput.isAsync
        let output = input === fnOutput ? input : {_scope: b, isAsync}

        let catchCode = switch maybeResolveVal {
        | None => _ => `${catchCode}}throw ${errorVar}`
        | Some(resolveVal) =>
          catchLocation =>
            catchCode ++
            switch catchLocation {
            | #0 => b->Val.set(output, resolveVal)
            | #1 => `return ${b->Val.inline(resolveVal)}`
            } ++
            `}else{throw ${errorVar}}`
        }

        b.code =
          prevCode ++
          `try{${b.code}${switch isAsync {
            | true =>
              b->Val.setInlined(
                output,
                `${b->Val.inline(fnOutput)}.catch(${errorVar}=>{${catchCode(#1)}})`,
              )
            | false => b->Val.set(output, fnOutput)
            }}}catch(${errorVar}){${catchCode(#0)}}`

        output
      }
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
          Stdlib.Exn.raiseAny(
            InternalError.make(
              ~path=path->Path.concat(Path.dynamic)->Path.concat(error.path),
              ~code=error.code,
              ~operation=error.operation,
            ),
          )
        }
      }
    }

    let typeFilterCode = (b: b, ~typeFilter, ~schema, ~input, ~path) => {
      let inputVar = b->Val.var(input)
      `if(${b->typeFilter(~inputVar)}){${b->failWithArg(
          ~path,
          input => InvalidType({
            expected: schema,
            received: input,
          }),
          inputVar,
        )}}`
    }

    @inline
    let parse = (b: b, ~schema, ~input, ~path) => {
      schema.builder(b, ~input, ~selfSchema=schema, ~path)
    }

    let parseWithTypeCheck = (b: b, ~schema, ~input, ~path) => {
      switch schema.maybeTypeFilter {
      | Some(typeFilter)
        if schema->isLiteralSchema ||
          b.global.operation->Operation.unsafeHasFlag(Operation.Flag.typeValidation) =>
        b.code = b.code ++ b->typeFilterCode(~schema, ~typeFilter, ~input, ~path)
        let bb = b->scope
        let val = bb->parse(~schema, ~input, ~path)
        b.code = b.code ++ bb->allocateScope
        val
      | _ => b->parse(~schema, ~input, ~path)
      }
    }
  }

  let noop = make((_b, ~input, ~selfSchema as _, ~path as _) => input)

  let invalidJson = make((b, ~input, ~selfSchema, ~path) => {
    b->B.registerInvalidJson(~selfSchema, ~path)
    input
  })

  let noopOperation = i => i->Obj.magic

  @inline
  let intitialInputVar = "i"

  let compile = (builder, ~schema, ~operation) => {
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
    schema.isAsyncSchema = Value(output.isAsync)

    if b.varsAllocation !== "" {
      b.code = `let ${b.varsAllocation};${b.code}`
    }

    if (
      operation->Operation.unsafeHasFlag(Operation.Flag.typeValidation) || schema->isLiteralSchema
    ) {
      switch schema.maybeTypeFilter {
      | Some(typeFilter) =>
        b.code = b->B.typeFilterCode(~schema, ~typeFilter, ~input, ~path=Path.empty) ++ b.code
      | _ => ()
      }
    }

    if (
      b.code === "" &&
      output === input &&
      !(
        operation->Operation.unsafeHasFlag(
          Operation.make()
          ->Operation.addFlag(Operation.Flag.assertOutput)
          ->Operation.addFlag(Operation.Flag.async)
          ->Operation.addFlag(Operation.Flag.jsonStringOutput),
        )
      )
    ) {
      noopOperation
    } else {
      let inlinedOutput = ref(
        if operation->Operation.unsafeHasFlag(Operation.Flag.assertOutput) {
          `void 0`
        } else {
          b->B.Val.inline(output)
        },
      )
      if operation->Operation.unsafeHasFlag(Operation.Flag.jsonStringOutput) {
        inlinedOutput := `JSON.stringify(${inlinedOutput.contents})`
      }
      if operation->Operation.unsafeHasFlag(Operation.Flag.async) && !output.isAsync {
        inlinedOutput := `Promise.resolve(${inlinedOutput.contents})`
      }

      let inlinedFunction = `${intitialInputVar}=>{${b.code}return ${inlinedOutput.contents}}`

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

type rec input<'input, 'computed> =
  | Input: input<'input, 'input>
  | Any: input<'input, 'any>
  | Unknown: input<'input, unknown>
  | Json: input<'input, Js.Json.t>
  | JsonString: input<'input, string>
type rec output<'output, 'computed> =
  | Output: output<'output, 'output>
  | Unknown: output<'output, unknown>
  | Assert: output<'output, unit>
  | Json: output<'output, Js.Json.t>
  | JsonString: output<'output, string>
type rec mode<'output, 'computed> =
  | Sync: mode<'output, 'output>
  | Async: mode<'output, promise<'output>>

@@warning("-37")
type internalInput =
  | Input
  | Any
  | Unknown
  | Json
  | JsonString
type internalOutput =
  | Output
  | Unknown
  | Assert
  | Json
  | JsonString
type internalMode =
  | Sync
  | Async
@@warning("+37")

let compile = (
  schema: t<'schemaOutput>,
  ~input: input<unknown, 'input>,
  ~output: output<'schemaOutput, 'transformedOutput>,
  ~mode: mode<'transformedOutput, 'output>,
  ~typeValidation,
): ('input => 'output) => {
  let schema = schema->toUnknown
  let output = output->(Obj.magic: output<'schemaOutput, 'transformedOutput> => internalOutput)
  let input = input->(Obj.magic: input<'schemaInput, 'input> => internalInput)
  let mode = mode->(Obj.magic: mode<'transformedOutput, 'output> => internalMode)

  let operation = ref(Operation.make())
  switch output {
  | Output
  | Unknown => ()
  | Assert => operation := operation.contents->Operation.addFlag(Operation.Flag.assertOutput)
  | Json => operation := operation.contents->Operation.addFlag(Operation.Flag.jsonableOutput)
  | JsonString =>
    operation :=
      operation.contents->Operation.addFlag(
        Operation.make()
        ->Operation.addFlag(Operation.Flag.jsonableOutput)
        ->Operation.addFlag(Operation.Flag.jsonStringOutput),
      )
  }
  switch mode {
  | Sync => ()
  | Async => operation := operation.contents->Operation.addFlag(Operation.Flag.async)
  }
  if typeValidation {
    operation := operation.contents->Operation.addFlag(Operation.Flag.typeValidation)
  }
  let fn = schema.builder->Builder.compile(~schema, ~operation=operation.contents)->Obj.magic

  let fn = switch input {
  | JsonString =>
    jsonString =>
      try jsonString->Obj.magic->Js.Json.parseExn->fn catch {
      | Js.Exn.Error(error) =>
        Stdlib.Exn.raiseAny(
          InternalError.make(
            ~code=OperationFailed(error->Js.Exn.message->(Obj.magic: option<string> => string)),
            ~operation=Parse,
            ~path=Path.empty,
          ),
        )
      }
  | _ => fn
  }
  fn
}

module Reverse = {
  let toSelf = () => {
    %raw(`this`)
  }

  let onlyChild = (~factory, ~schema) => {
    () => {
      let reversed = schema.reverse()
      if reversed === schema {
        %raw(`this`)
      } else {
        factory(reversed->castUnknownSchemaToAnySchema)->toUnknown
      }
    }
  }
}

module Literal = {
  open Stdlib

  type rec internal = {
    kind: kind,
    value: unknown,
    @as("s")
    string: string,
    @as("f")
    filterBuilder: (b, ~inputVar: string, ~literal: literal) => string,
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

  let arrayFilterBuilder = (b, ~inputVar, ~literal) => {
    let items = (literal->toInternal).items->(Obj.magic: option<unknown> => array<internal>)

    `${inputVar}!==${b->B.embed(
        literal->value,
      )}&&(!Array.isArray(${inputVar})||${inputVar}.length!==${items
      ->Js.Array2.length
      ->Stdlib.Int.unsafeToString}` ++
    (items->Js.Array2.length > 0
      ? "||" ++
        items
        ->Js.Array2.mapi((literal, idx) =>
          b->literal.filterBuilder(
            ~inputVar=`${inputVar}[${idx->Stdlib.Int.unsafeToString}]`,
            ~literal=literal->toPublic,
          )
        )
        ->Js.Array2.joinWith("||")
      : "") ++ ")"
  }

  let dictFilterBuilder = (b, ~inputVar, ~literal) => {
    let items = (literal->toInternal).items->(Obj.magic: option<unknown> => dict<internal>)
    let fields = items->Js.Dict.keys
    let numberOfFields = fields->Js.Array2.length

    `${inputVar}!==${b->B.embed(
        value,
      )}&&(!${inputVar}||${inputVar}.constructor!==Object||Object.keys(${inputVar}).length!==${numberOfFields->Stdlib.Int.unsafeToString}` ++
    (numberOfFields > 0
      ? "||" ++
        fields
        ->Js.Array2.map(field => {
          let literal = items->Js.Dict.unsafeGet(field)
          b->literal.filterBuilder(
            ~inputVar=`${inputVar}[${field->Stdlib.Inlined.Value.fromString}]`,
            ~literal=literal->toPublic,
          )
        })
        ->Js.Array2.joinWith("||")
      : "") ++ ")"
  }

  let inlinedStrictEqualFilterBuilder = (_, ~inputVar, ~literal) =>
    `${inputVar}!==${literal->toString}`

  let strictEqualFilterBuilder = (b, ~inputVar, ~literal) =>
    `${inputVar}!==${b->B.embed(literal->value)}`

  let undefined = {
    kind: Undefined,
    value: %raw(`undefined`),
    string: "undefined",
    isJsonable: false,
    filterBuilder: inlinedStrictEqualFilterBuilder,
  }

  let null = {
    kind: Null,
    value: %raw(`null`),
    string: "null",
    isJsonable: true,
    filterBuilder: inlinedStrictEqualFilterBuilder,
  }

  let nan = {
    kind: NaN,
    value: %raw(`NaN`),
    string: "NaN",
    isJsonable: false,
    filterBuilder: (_, ~inputVar, ~literal as _) => `!Number.isNaN(${inputVar})`,
  }

  let string = value => {
    {
      kind: String,
      value: value->castAnyToUnknown,
      string: Stdlib.Inlined.Value.fromString(value),
      isJsonable: true,
      filterBuilder: inlinedStrictEqualFilterBuilder,
    }
  }

  let boolean = value => {
    {
      kind: Boolean,
      value: value->castAnyToUnknown,
      string: value ? "true" : "false",
      isJsonable: true,
      filterBuilder: inlinedStrictEqualFilterBuilder,
    }
  }

  let number = value => {
    {
      kind: Number,
      value: value->castAnyToUnknown,
      string: value->Js.Float.toString,
      isJsonable: true,
      filterBuilder: inlinedStrictEqualFilterBuilder,
    }
  }

  let symbol = value => {
    {
      kind: Symbol,
      value: value->castAnyToUnknown,
      string: value->Symbol.toString,
      isJsonable: false,
      filterBuilder: strictEqualFilterBuilder,
    }
  }

  let bigint = value => {
    {
      kind: BigInt,
      value: value->castAnyToUnknown,
      string: value->BigInt.toString,
      isJsonable: false,
      filterBuilder: inlinedStrictEqualFilterBuilder,
    }
  }

  let function = value => {
    {
      kind: Function,
      value: value->castAnyToUnknown,
      string: value->Stdlib.Function.toString,
      isJsonable: false,
      filterBuilder: strictEqualFilterBuilder,
    }
  }

  let object = value => {
    {
      kind: Object,
      value: value->castAnyToUnknown,
      string: value->Object.internalClass,
      isJsonable: false,
      filterBuilder: strictEqualFilterBuilder,
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
      filterBuilder: dictFilterBuilder,
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
      filterBuilder: arrayFilterBuilder,
    }
  }

  @inline
  let parse = any => any->parseInternal->toPublic

  @inline
  let unsafeFromSchema = (schema): literal => {
    schema->classify->unsafeGetVariantPayload
  }
}

let isAsync = schema => {
  let schema = schema->toUnknown
  switch schema.isAsyncSchema {
  | Unknown =>
    try {
      let b = {
        code: "",
        varsAllocation: "",
        isAllocated: false,
        global: {
          varCounter: -1,
          embeded: [],
          operation: Operation.make()->Operation.addFlag(Operation.Flag.async),
        },
      }
      let input = {_var: "i", _scope: b, isAsync: false}
      let output = schema.builder(b, ~input, ~selfSchema=schema, ~path=Path.empty)
      schema.isAsyncSchema = Value(output.isAsync)
      schema.isAsyncSchema->(Obj.magic: isAsyncSchema => bool)
    } catch {
    | exn => {
        let _ = exn->InternalError.getOrRethrow
        false
      }
    }
  | Value(v) => v
  }
}
let isAsyncParse = isAsync

let reverse = schema => {
  schema.reverse()
}

// =============
// Operations
// =============

@inline
let callMemoizedOperation = (schema, operation, input) => {
  let schema = schema->toUnknown
  if (schema->Obj.magic->Js.Dict.unsafeGet(operation->Stdlib.Int.unsafeToString): bool) {
    ()
  } else {
    schema
    ->Obj.magic
    ->Js.Dict.set(
      operation->Stdlib.Int.unsafeToString,
      schema.builder->Builder.compile(~schema, ~operation),
    )
  }
  (schema->Obj.magic->Js.Dict.unsafeGet(operation->Stdlib.Int.unsafeToString))(input)
}

let wrapExnToError = exn => {
  if %raw("exn&&exn.s===symbol") {
    Error(exn->(Obj.magic: exn => error))
  } else {
    raise(exn)
  }
}

@inline
let useSyncOperation = (schema, operation, input) => {
  try {
    schema
    ->callMemoizedOperation(operation, input)
    ->Ok
  } catch {
  | _ => wrapExnToError(%raw(`exn`))
  }
}

let asyncPrepareOk = value => Ok(value->castUnknownToAny)

@inline
let useAsyncOperation = (schema, operation, input) => {
  try {
    schema
    ->callMemoizedOperation(operation->Operation.addFlag(Operation.Flag.async), input)
    ->Stdlib.Promise.thenResolveWithCatch(asyncPrepareOk, wrapExnToError)
  } catch {
  | _ => wrapExnToError(%raw(`exn`))->Stdlib.Promise.resolve
  }
}

let convertAnyWith = (any, schema) => {
  schema->useSyncOperation(Operation.make(), any)
}

let convertAnyToJsonWith = (any, schema) => {
  schema->useSyncOperation(Operation.make()->Operation.addFlag(Operation.Flag.jsonableOutput), any)
}

let convertAnyToJsonStringWith = (any, schema) => {
  schema->useSyncOperation(
    Operation.make()->Operation.addFlag(Operation.Flag.jsonStringOutput),
    any,
  )
}

let convertAnyAsyncWith = (any, schema) => {
  schema->useAsyncOperation(Operation.make(), any)
}

@inline
let parseAnyOrRaiseWith = (any, schema) => {
  schema.parseOrRaise(any->castAnyToUnknown)->castUnknownToAny
}

let assertAnyWith = (any, schema) => {
  schema.assertOrRaise(any->castAnyToUnknown)
}

let assertOrRaiseWith = assertAnyWith

let parseAnyWith = (any, schema) => {
  try {
    parseAnyOrRaiseWith(any->castAnyToUnknown, schema)->castUnknownToAny->Ok
  } catch {
  | exn => exn->InternalError.getOrRethrow->Error
  }
}

let parseWith: (Js.Json.t, t<'value>) => result<'value, error> = parseAnyWith

let parseOrRaiseWith: (Js.Json.t, t<'value>) => 'value = parseAnyOrRaiseWith

let parseAnyAsyncWith = (any, schema) => {
  schema->useAsyncOperation(Operation.make()->Operation.addFlag(Operation.Flag.typeValidation), any)
}

let parseAsyncWith = parseAnyAsyncWith

let serializeOrRaiseWith = (value, schema) => {
  schema.serializeOrRaise(value->castAnyToUnknown)
}

let serializeWith = (value, schema) => {
  try {
    serializeOrRaiseWith(value, schema)->Ok
  } catch {
  | exn => exn->InternalError.getOrRethrow->Error
  }
}

@inline
let serializeToUnknownOrRaiseWith = (value, schema) => {
  schema.serializeToUnknownOrRaise(value->castAnyToUnknown)
}

let serializeToUnknownWith = (value, schema) => {
  try {
    serializeToUnknownOrRaiseWith(value, schema)->Ok
  } catch {
  | exn => exn->InternalError.getOrRethrow->Error
  }
}

let serializeToJsonStringOrRaiseWith = (value: 'value, schema: t<'value>, ~space=0): string => {
  value->serializeOrRaiseWith(schema)->Js.Json.stringifyWithSpace(space)
}

let serializeToJsonStringWith = (value: 'value, schema: t<'value>, ~space=0): result<
  string,
  error,
> => {
  try {
    serializeToJsonStringOrRaiseWith(value, schema, ~space)->Ok
  } catch {
  | exn => exn->InternalError.getOrRethrow->Error
  }
}

let parseJsonStringWith = (jsonString: string, schema: t<'value>): result<'value, error> => {
  switch try {
    jsonString->Js.Json.parseExn->Ok
  } catch {
  | Js.Exn.Error(error) =>
    Error(
      InternalError.make(
        ~code=OperationFailed(error->Js.Exn.message->(Obj.magic: option<string> => string)),
        ~operation=Parse,
        ~path=Path.empty,
      ),
    )
  } {
  | Ok(json) => json->parseWith(schema)
  | Error(_) as e => e
  }
}

let initialParseOrRaise = unknown => {
  let schema = %raw(`this`)
  let operation =
    schema.builder->Builder.compile(
      ~schema,
      ~operation=Operation.make()->Operation.addFlag(Operation.Flag.typeValidation),
    )
  schema.parseOrRaise = operation
  operation(unknown)
}

let initialAssertOrRaise = unknown => {
  let schema = %raw(`this`)
  let operation = schema.builder->Builder.compile(
    ~schema,
    ~operation=Operation.make()
    ->Operation.addFlag(Operation.Flag.typeValidation)
    ->Operation.addFlag(Operation.Flag.assertOutput),
  )
  schema.assertOrRaise = operation
  operation(unknown)
}

let initialSerializeToUnknownOrRaise = unknown => {
  let schema = %raw(`this`)
  let reversed = schema.reverse()
  let operation = reversed.builder->Builder.compile(~schema=reversed, ~operation=Operation.make())
  schema.serializeToUnknownOrRaise = operation
  operation(unknown)
}

let initialSerializeOrRaise = unknown => {
  let schema = %raw(`this`)
  if schema.tagged->unsafeGetVarianTag === "Option" {
    Stdlib.Exn.raiseAny(
      InternalError.make(
        ~code=InvalidJsonSchema(schema),
        ~operation=SerializeToJson,
        ~path=Path.empty,
      ),
    )
  }
  let reversed = schema.reverse()
  let operation =
    reversed.builder->Builder.compile(
      ~schema=reversed,
      ~operation=Operation.make()->Operation.addFlag(Operation.Flag.jsonableOutput),
    )
  schema.serializeOrRaise = operation
  operation(unknown)
}

let jsParse = unknown => {
  try {
    Success({
      value: (%raw(`this`)).parseOrRaise(unknown),
    })
  } catch {
  | exn => Failure({error: exn->InternalError.getOrRethrow})
  }
}

let jsParseAsync = data => {
  data->parseAnyAsyncWith(%raw(`this`))->Stdlib.Promise.thenResolve(toJsResult)
}

let jsSerialize = value => {
  try {
    Success({
      value: serializeToUnknownOrRaiseWith(value, %raw(`this`))->castUnknownToAny,
    })
  } catch {
  | exn => Failure({error: exn->InternalError.getOrRethrow})
  }
}

let makeReverseSchema = (~name, ~tagged, ~metadataMap, ~builder, ~maybeTypeFilter) => {
  tagged,
  builder,
  isAsyncSchema: Unknown,
  maybeTypeFilter,
  name,
  metadataMap,
  parseOrRaise: initialParseOrRaise,
  serializeToUnknownOrRaise: initialSerializeToUnknownOrRaise,
  serializeOrRaise: initialSerializeOrRaise,
  assertOrRaise: initialAssertOrRaise,
  jsParse,
  jsParseAsync,
  jsSerialize,
  reverse: Reverse.toSelf,
}

let makeSchema = (~name, ~tagged, ~metadataMap, ~builder, ~maybeTypeFilter, ~reverse) => {
  tagged,
  builder,
  isAsyncSchema: Unknown,
  maybeTypeFilter,
  name,
  metadataMap,
  parseOrRaise: initialParseOrRaise,
  serializeToUnknownOrRaise: initialSerializeToUnknownOrRaise,
  serializeOrRaise: initialSerializeOrRaise,
  assertOrRaise: initialAssertOrRaise,
  jsParse,
  jsParseAsync,
  jsSerialize,
  reverse: () => {
    let original = %raw(`this`)
    let reversed = (reverse->Obj.magic)["call"](original)

    // Copy primitive reversed schema to prevent mutating original reverse function
    let reversed = if original !== reversed && reversed->isPrimitiveSchema {
      makeReverseSchema(
        ~name=reversed.name,
        ~tagged=reversed.tagged,
        ~metadataMap=reversed.metadataMap,
        ~builder=reversed.builder,
        ~maybeTypeFilter=reversed.maybeTypeFilter,
      )
    } else {
      reversed
    }
    reversed.reverse = () => original
    reversed
  },
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
    makeSchema(
      ~name=schema.name,
      ~builder=schema.builder,
      ~tagged=schema.tagged,
      ~maybeTypeFilter=schema.maybeTypeFilter,
      ~metadataMap,
      ~reverse=() => {
        let schema = schema.reverse()
        makeReverseSchema(
          ~name=schema.name,
          ~builder=schema.builder,
          ~tagged=schema.tagged,
          ~maybeTypeFilter=schema.maybeTypeFilter,
          ~metadataMap,
        )
      },
    )
  }
}

let primitiveName = () => {
  (%raw(`this`): t<'a>).tagged->(Obj.magic: tagged => string)
}

let containerName = () => {
  let tagged = (%raw(`this`): t<'a>).tagged
  `${tagged->unsafeGetVarianTag}(${(tagged->unsafeGetVariantPayload).name()})`
}

let makePrimitiveSchema = (~tagged, ~builder, ~maybeTypeFilter) => {
  makeSchema(
    ~name=primitiveName,
    ~metadataMap=Metadata.Map.empty,
    ~tagged,
    ~builder,
    ~maybeTypeFilter,
    ~reverse=Reverse.toSelf,
  )
}

let recursive = fn => {
  let r = "r" ++ globalConfig.recCounter->Stdlib.Int.unsafeToString
  globalConfig.recCounter = globalConfig.recCounter + 1

  let placeholder: t<'value> = {
    // metadataMap
    "m": Metadata.Map.empty,
    // tagged
    "t": Unknown,
    // name
    "n": () => "<recursive>",
    // builder
    "b": Builder.make((b, ~input, ~selfSchema as _, ~path as _) => {
      b->B.transform(~input, (b, ~input) => {
        b->B.Val.map(r, input)
      })
    }),
    "r": () => {
      makeReverseSchema(
        ~tagged=Unknown,
        ~name=primitiveName,
        ~builder=Builder.make((b, ~input, ~selfSchema as _, ~path as _) => {
          b->B.Val.map(r, input)
        }),
        ~maybeTypeFilter=None,
        ~metadataMap=Metadata.Map.empty,
      )
    },
  }->Obj.magic
  let schema = fn(placeholder)

  // maybeTypeFilter
  (placeholder->Obj.magic)["f"] = schema.maybeTypeFilter

  // Don't allow destructuring for recursive schemas
  schema.definer = None
  schema.definerCtx = None

  let initialParseOperationBuilder = schema.builder
  schema.builder = Builder.make((b, ~input, ~selfSchema, ~path) => {
    let bb = b->B.scope
    let opOutput = initialParseOperationBuilder(bb, ~input, ~selfSchema, ~path=Path.empty)
    let opBodyCode = bb->B.allocateScope ++ `return ${b->B.Val.inline(opOutput)}`
    b.code = b.code ++ `let ${r}=${b->B.Val.var(input)}=>{${opBodyCode}};`
    b->B.withPathPrepend(~input, ~path, (b, ~input, ~path as _) => {
      b->B.transform(
        ~input,
        (b, ~input) => {
          let output = b->B.Val.map(r, input)
          if opOutput.isAsync {
            output.isAsync = true
            placeholder.builder = Builder.make(
              (b, ~input, ~selfSchema as _, ~path as _) => {
                b->B.transform(
                  ~input,
                  (b, ~input) => {
                    let output = b->B.Val.map(r, input)
                    output.isAsync = true
                    output
                  },
                )
              },
            )
          }
          output
        },
      )
    })
  })

  let initialReverse = (schema.reverse->Obj.magic)["bind"](schema)
  schema.reverse = () => {
    let reversed = initialReverse()
    makeReverseSchema(
      ~name=reversed.name,
      ~tagged=reversed.tagged,
      ~metadataMap=reversed.metadataMap,
      ~builder=Builder.make((b, ~input, ~selfSchema, ~path) => {
        let bb = b->B.scope
        let opOutput = reversed.builder(bb, ~input, ~selfSchema, ~path=Path.empty)
        let opBodyCode = bb->B.allocateScope ++ `return ${b->B.Val.inline(opOutput)}`
        b.code = b.code ++ `let ${r}=${b->B.Val.var(input)}=>{${opBodyCode}};`
        b->B.withPathPrepend(~input, ~path, (b, ~input, ~path as _) => b->B.Val.map(r, input))
      }),
      ~maybeTypeFilter=reversed.maybeTypeFilter,
    )
  }

  schema
}

let setName = (schema, name) => {
  makeSchema(
    ~name=() => name,
    ~builder=schema.builder,
    ~tagged=schema.tagged,
    ~maybeTypeFilter=schema.maybeTypeFilter,
    ~metadataMap=schema.metadataMap,
    ~reverse=() => schema.reverse(), // TODO: test better
  )
}

let removeTypeValidation = schema => {
  makeSchema(
    ~name=schema.name,
    ~builder=schema.builder,
    ~tagged=schema.tagged,
    ~maybeTypeFilter=None,
    ~metadataMap=schema.metadataMap,
    ~reverse=() => schema.reverse(), // TODO: test better or use bind?
  )
}

let internalRefine = (schema, refiner) => {
  let schema = schema->toUnknown
  makeSchema(
    ~name=schema.name,
    ~tagged=schema.tagged,
    ~builder=Builder.make((b, ~input, ~selfSchema, ~path) => {
      b->B.transform(
        ~input=b->B.parse(~schema, ~input, ~path),
        (b, ~input) => {
          let input = if b.code === "" && input._var !== None {
            input
          } else {
            let scopedInput = b->B.allocateVal
            b.code = b.code ++ b->B.Val.set(scopedInput, input) ++ ";"
            scopedInput
          }
          let rCode = refiner(b, ~inputVar=b->B.Val.var(input), ~selfSchema, ~path)
          b.code = b.code ++ rCode
          input
        },
      )
    }),
    ~maybeTypeFilter=schema.maybeTypeFilter,
    ~metadataMap=schema.metadataMap,
    ~reverse=() => {
      let schema = schema.reverse()
      makeReverseSchema(
        ~name=schema.name,
        ~tagged=schema.tagged,
        ~builder=(b, ~input, ~selfSchema, ~path) => {
          b->B.parse(
            ~schema,
            ~input=b->B.transform(~input, (b, ~input) => {
              b.code = b.code ++ refiner(b, ~inputVar=b->B.Val.var(input), ~selfSchema, ~path)
              input
            }),
            ~path,
          )
        },
        ~maybeTypeFilter=schema.maybeTypeFilter,
        ~metadataMap=schema.metadataMap,
      )
    },
  )
}

let refine: (t<'value>, s<'value> => 'value => unit) => t<'value> = (schema, refiner) => {
  schema->internalRefine((b, ~inputVar, ~selfSchema, ~path) => {
    `${b->B.embed(refiner(b->B.effectCtx(~selfSchema, ~path)))}(${inputVar});`
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
  makeSchema(
    ~name=schema.name,
    ~tagged=schema.tagged,
    ~builder=Builder.make((b, ~input, ~selfSchema, ~path) => {
      let input = b->B.parse(~schema, ~input, ~path)

      switch transformer(b->B.effectCtx(~selfSchema, ~path)) {
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
    ~maybeTypeFilter=schema.maybeTypeFilter,
    ~metadataMap=schema.metadataMap,
    ~reverse=() => {
      let schema = schema.reverse()
      makeReverseSchema(
        ~name=primitiveName,
        ~tagged=Unknown,
        ~builder=(b, ~input, ~selfSchema, ~path) => {
          switch transformer(b->B.effectCtx(~selfSchema, ~path)) {
          | {serializer} =>
            b->B.parse(~schema, ~input=b->B.embedSyncOperation(~input, ~fn=serializer), ~path)
          | {parser: ?None, asyncParser: ?None, serializer: ?None} =>
            b->B.parse(~schema, ~input, ~path)
          | {serializer: ?None, asyncParser: ?Some(_)}
          | {serializer: ?None, parser: ?Some(_)} =>
            b->B.invalidOperation(~path, ~description=`The S.transform serializer is missing`)
          }
        },
        ~maybeTypeFilter=None,
        ~metadataMap=Metadata.Map.empty,
      )
    },
  )
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
  makeSchema(
    ~name=() => name,
    ~metadataMap=Metadata.Map.empty,
    ~tagged=Unknown,
    ~builder=Builder.make((b, ~input, ~selfSchema, ~path) => {
      b->B.registerInvalidJson(~selfSchema, ~path)
      switch definer(b->B.effectCtx(~selfSchema, ~path)) {
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
    ~maybeTypeFilter=None,
    ~reverse=() => {
      makeReverseSchema(
        ~name=() => name,
        ~tagged=Unknown,
        ~builder=Builder.make((b, ~input, ~selfSchema, ~path) => {
          b->B.registerInvalidJson(~selfSchema, ~path)
          switch definer(b->B.effectCtx(~selfSchema, ~path)) {
          | {serializer} => b->B.embedSyncOperation(~input, ~fn=serializer)
          | {parser: ?None, asyncParser: ?None, serializer: ?None} => input
          | {serializer: ?None, asyncParser: ?Some(_)}
          | {serializer: ?None, parser: ?Some(_)} =>
            b->B.invalidOperation(~path, ~description=`The S.custom serializer is missing`)
          }
        }),
        ~metadataMap=Metadata.Map.empty,
        ~maybeTypeFilter=None,
      )
    },
  )
}

let literal = value => {
  let value = value->castAnyToUnknown
  let literal = value->Literal.parse
  let internalLiteral = literal->Literal.toInternal

  makeSchema(
    ~name=() => literal->Literal.toString,
    ~metadataMap=Metadata.Map.empty,
    ~tagged=Literal(literal),
    ~builder=literal->Literal.isJsonable ? Builder.noop : Builder.invalidJson,
    ~maybeTypeFilter=Some((b, ~inputVar) => b->internalLiteral.filterBuilder(~inputVar, ~literal)),
    ~reverse=Reverse.toSelf,
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

module Option = {
  type default = Value(unknown) | Callback(unit => unknown)

  let defaultMetadataId: Metadata.Id.t<default> = Metadata.Id.make(
    ~namespace="rescript-schema",
    ~name="Option.default",
  )

  let default = schema => schema->Metadata.get(~id=defaultMetadataId)

  let makeBuilder = (~isNullInput, ~isNullOutput) =>
    Builder.make((b, ~input, ~selfSchema, ~path) => {
      let childSchema = selfSchema->classify->unsafeGetVariantPayload
      let childSchemaTag = childSchema->classify->unsafeGetVarianTag

      let bb = b->B.scope
      let itemInput = if (
        !(b.global.operation->Operation.unsafeHasFlag(Operation.Flag.typeValidation)) &&
        (childSchema->classify === Unknown ||
        childSchemaTag === "Option" ||
        (childSchemaTag === "Literal" &&
          (childSchema->classify->unsafeGetVariantPayload: literal)->Literal.value ===
            %raw(`void 0`)))
      ) {
        bb->B.val(`${bb->B.embed(%raw("Caml_option.valFromOption"))}(${b->B.Val.var(input)})`)
      } else {
        input
      }

      let itemOutput = bb->B.parse(~schema=childSchema, ~input=itemInput, ~path)
      let itemCode = bb->B.allocateScope

      let inputLiteral = isNullInput ? "null" : "void 0"
      let ouputLiteral = isNullOutput ? "null" : "void 0"

      let isTransformed = inputLiteral !== ouputLiteral || itemOutput !== input

      let output = isTransformed ? {_scope: b, isAsync: itemOutput.isAsync} : input

      if itemCode !== "" || isTransformed {
        b.code =
          b.code ++
          `if(${b->B.Val.var(input)}!==${inputLiteral}){${itemCode}${b->B.Val.set(
              output,
              itemOutput,
            )}}${inputLiteral !== ouputLiteral || output.isAsync
              ? `else{${b->B.Val.set(output, b->B.val(ouputLiteral))}}`
              : ""}`
      }

      output
    })

  let maybeTypeFilter = (~schema, ~inlinedNoneValue) => {
    switch schema.maybeTypeFilter {
    | Some(typeFilter) =>
      Some(
        (b, ~inputVar) => {
          `${inputVar}!==${inlinedNoneValue}&&(${b->typeFilter(~inputVar)})`
        },
      )
    | None => None
    }
  }

  let rec factory = schema => {
    let schema = schema->toUnknown
    makeSchema(
      ~name=containerName,
      ~metadataMap=Metadata.Map.empty,
      ~tagged=Option(schema),
      ~builder=makeBuilder(~isNullInput=false, ~isNullOutput=false),
      ~maybeTypeFilter=maybeTypeFilter(~schema, ~inlinedNoneValue="void 0"),
      ~reverse=Reverse.onlyChild(~factory, ~schema),
    )
  }

  let getWithDefault = (schema, default) => {
    let schema = schema->(Obj.magic: t<option<'value>> => t<unknown>)
    makeSchema(
      ~name=schema.name,
      ~metadataMap=schema.metadataMap->Metadata.Map.set(~id=defaultMetadataId, default),
      ~tagged=schema.tagged,
      ~builder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
        b->B.transform(
          ~input=b->B.parse(~schema, ~input, ~path),
          (b, ~input) => {
            let inputVar = b->B.Val.var(input)
            b->B.val(
              `${inputVar}===void 0?${switch default {
                | Value(v) => b->B.embed(v)
                | Callback(cb) => `${b->B.embed(cb)}()`
                }}:${inputVar}`,
            )
          },
        )
      }),
      ~maybeTypeFilter=schema.maybeTypeFilter,
      ~reverse=() => {
        let reversed = schema.reverse()
        if reversed.tagged->unsafeGetVarianTag === "Option" {
          reversed.tagged->unsafeGetVariantPayload
        } else {
          reversed
        }
      },
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
    makeSchema(
      ~name=containerName,
      ~metadataMap=Metadata.Map.empty,
      ~tagged=Null(schema),
      ~builder=Option.makeBuilder(~isNullInput=true, ~isNullOutput=false),
      ~maybeTypeFilter=Option.maybeTypeFilter(~schema, ~inlinedNoneValue="null"),
      ~reverse=() => {
        let child = schema.reverse()
        makeReverseSchema(
          ~name=containerName,
          ~tagged=Option(child),
          ~builder=Option.makeBuilder(~isNullInput=false, ~isNullOutput=true),
          ~maybeTypeFilter=Option.maybeTypeFilter(~schema, ~inlinedNoneValue="void 0"),
          ~metadataMap=Metadata.Map.empty,
        )
      },
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
      b->B.failWithArg(
        ~path,
        input => InvalidType({
          expected: selfSchema,
          received: input,
        }),
        b->B.Val.inline(input),
      ) ++ ";"
    input
  })

  let schema = makeSchema(
    ~name=primitiveName,
    ~metadataMap=Metadata.Map.empty,
    ~tagged=Never,
    ~builder,
    ~maybeTypeFilter=None,
    ~reverse=Reverse.toSelf,
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

  let typeFilter = (_b, ~inputVar) => `!Array.isArray(${inputVar})`

  let rec factory = schema => {
    let schema = schema->toUnknown
    makeSchema(
      ~name=containerName,
      ~metadataMap=Metadata.Map.empty,
      ~tagged=Array(schema),
      ~builder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
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

        if isTransformed || itemCode !== "" {
          b.code =
            b.code ++
            `for(let ${iteratorVar}=0;${iteratorVar}<${inputVar}.length;++${iteratorVar}){${itemCode}${isTransformed
                ? b->B.Val.push(output, itemOutput)
                : ""}}`
        }

        if itemOutput.isAsync {
          b->B.asyncVal(`Promise.all(${b->B.Val.inline(output)})`)
        } else {
          output
        }
      }),
      ~maybeTypeFilter=Some(typeFilter),
      ~reverse=Reverse.onlyChild(~factory, ~schema),
    )
  }
}

module Tuple = {
  type s = {
    item: 'value. (int, t<'value>) => 'value,
    tag: 'value. (int, 'value) => unit,
  }
}

module Object = {
  type rec s = {
    @as("f") field: 'value. (string, t<'value>) => 'value,
    fieldOr: 'value. (string, t<'value>, 'value) => 'value,
    tag: 'value. (string, 'value) => unit,
    nestedField: 'value. (string, string, t<'value>) => 'value,
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

  @unboxed
  type variantSerializeOutput =
    Registered(val) | @as(0) Unregistered | @as(1) RegisteredMultipleTimes

  let typeFilter = (_b, ~inputVar) => `!${inputVar}||${inputVar}.constructor!==Object`

  let getItems = (schema): array<item> => (schema->classify->Obj.magic)["items"]
  let getDefinition = schema => (schema->classify->Obj.magic)["definition"]

  let builder = (b, ~input, ~selfSchema, ~path) => {
    let asyncOutputs = []
    let outputs = Stdlib.WeakMap.make()

    let rec parseItems = (b: b, ~input, ~schema, ~path) => {
      let inputVar = b->B.Val.var(input)

      let items = schema->getItems
      let isObject = schema->classify->unsafeGetVarianTag === "Object"

      for idx in 0 to items->Js.Array2.length - 1 {
        let prevCode = b.code
        b.code = ""

        let item = items->Js.Array2.unsafe_get(idx)
        let {schema, path: itemPath} = item
        let itemInput = b->B.val(`${inputVar}${itemPath}`)
        let path = path->Path.concat(itemPath)
        let isLiteral = schema->isLiteralSchema

        switch schema.maybeTypeFilter {
        | Some(typeFilter)
          if isLiteral ||
          b.global.operation->Operation.unsafeHasFlag(Operation.Flag.typeValidation) =>
          b.code = b.code ++ b->B.typeFilterCode(~schema, ~typeFilter, ~input=itemInput, ~path)
        | _ => ()
        }

        if isObject && schema.definer->Obj.magic {
          let bb = b->B.scope
          bb->parseItems(~input=itemInput, ~schema, ~path)
          b.code = prevCode ++ b.code ++ bb->B.allocateScope
        } else {
          let itemOutput = b->B.parse(~schema, ~input=itemInput, ~path)
          let itemOutput = if itemOutput.isAsync {
            let index = asyncOutputs->Js.Array2.length
            asyncOutputs->Js.Array2.push(itemOutput)->ignore
            b->B.val(`a[${index->Stdlib.Int.unsafeToString}]`)
          } else {
            itemOutput
          }

          let _ = outputs->Stdlib.WeakMap.set(item, itemOutput)

          // Parse literal fields first, because they are most often used as discriminants
          if isLiteral {
            b.code = b.code ++ prevCode
          } else {
            b.code = prevCode ++ b.code
          }
        }
      }

      if (
        isObject &&
        (selfSchema->classify->Obj.magic)["unknownKeys"] === Strict &&
        b.global.operation->Operation.unsafeHasFlag(Operation.Flag.typeValidation)
      ) {
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
          `){${b->B.failWithArg(
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

    if asyncOutputs->Js.Array2.length === 0 {
      b->B.val(syncOutput)
    } else {
      b->B.asyncVal(
        `Promise.all([${asyncOutputs
          ->Js.Array2.map(val => b->B.Val.inline(val))
          ->Js.Array2.toString}]).then(a=>(${syncOutput}))`,
      )
    }
  }

  type serializeCtx = {@as("d") mutable discriminantCode: string}

  let name = () => {
    `Object({${%raw(`this`)
      ->getItems
      ->Js.Array2.map(item => {
        `${item.inlinedLocation}: ${item.schema.name()}`
      })
      ->Js.Array2.joinWith(", ")}})`
  }

  let rec reverse = () => {
    let original = %raw(`this`)
    makeReverseSchema(
      ~maybeTypeFilter=None,
      ~name=primitiveName,
      ~tagged=Unknown,
      ~metadataMap=Metadata.Map.empty,
      ~builder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
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
                  b->B.parse(
                    ~schema=schema.reverse(),
                    ~input=itemInput,
                    ~path=path->Path.concat(outputPath),
                  )

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
            let tag = definition->Definition.toConstant
            let tagSchema = literal(tag)
            let itemInputVar = `${inputVar}${outputPath}`
            ctx.discriminantCode =
              ctx.discriminantCode ++
              `if(${(tagSchema.maybeTypeFilter->Stdlib.Option.unsafeUnwrap)(
                  b,
                  ~inputVar=itemInputVar,
                )}){${b->B.failWithArg(
                  ~path=path->Path.concat(outputPath),
                  received => InvalidType({
                    expected: tagSchema,
                    received,
                  }),
                  itemInputVar,
                )}}`
          }
        }
        original->getDefinition->definitionToOutput(~outputPath=Path.empty)
        b.code = ctx.discriminantCode ++ b.code

        let rec toRaw = (~schema, ~path) => {
          let items = schema->getItems
          let isObject = schema->classify->unsafeGetVarianTag === "Object"

          let output = ref("")
          for idx in 0 to items->Js.Array2.length - 1 {
            let item = items->Js.Array2.unsafe_get(idx)

            let itemOutput = switch embededOutputs->Stdlib.WeakMap.get(item) {
            | Some(o) => b->B.Val.inline(o)
            | None =>
              let itemSchema = item.schema
              if itemSchema->isLiteralSchema {
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

        b->B.val(toRaw(~schema=original, ~path))
      }),
    )
  }
  and tuple = definer => {
    let items = []
    let ctx: Tuple.s = {
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
    let definition = definer((ctx :> Tuple.s))->(Obj.magic: 'any => unknown)

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

    makeSchema(
      ~name=() => `Tuple(${items->Js.Array2.map(i => i.schema.name())->Js.Array2.joinWith(", ")})`,
      ~tagged=Tuple({
        items,
        definition,
      }),
      ~builder,
      ~maybeTypeFilter=Some(
        (b, ~inputVar) =>
          b->Array.typeFilter(~inputVar) ++
            `||${inputVar}.length!==${length->Stdlib.Int.unsafeToString}`,
      ),
      ~metadataMap=Metadata.Map.empty,
      ~reverse,
    )
  }
  and variant = {
    (schema: t<'value>, definer: 'value => 'variant): t<'variant> => {
      let schema = schema->toUnknown
      if schema.definer->Obj.magic {
        factory((ctx => definer((schema.definer->Obj.magic)(ctx)))->Obj.magic)
      } else {
        makeSchema(
          ~name=schema.name,
          ~tagged=schema.tagged,
          ~builder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
            b->B.embedSyncOperation(~input=b->B.parse(~schema, ~input, ~path), ~fn=definer)
          }),
          ~maybeTypeFilter=schema.maybeTypeFilter,
          ~metadataMap=schema.metadataMap,
          ~reverse=() => {
            let original = %raw(`this`)
            let reversed = schema.reverse()
            makeReverseSchema(
              ~maybeTypeFilter=None,
              ~name=primitiveName,
              ~tagged=Unknown,
              ~metadataMap=Metadata.Map.empty,
              ~builder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
                let inputVar = b->B.Val.var(input)

                let definition =
                  definer(symbol->(Obj.magic: Stdlib.Symbol.t => 'value))->(
                    Obj.magic: 'variant => Definition.t<Stdlib.Symbol.t>
                  )

                let output = {
                  // TODO: Check that it might be not an object in union
                  let rec definitionToValue = (
                    definition: Definition.t<Stdlib.Symbol.t>,
                    ~valuePath,
                  ) => {
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
                      let tag = definition->Definition.toConstant
                      let tagSchema = literal(tag)
                      let tagVal = valuePath === "" ? input : b->B.val(`${inputVar}${valuePath}`)
                      let tagInputVar = b->B.Val.var(tagVal)
                      b.code =
                        b.code ++
                        `if(${(tagSchema.maybeTypeFilter->Stdlib.Option.unsafeUnwrap)(
                            b,
                            ~inputVar=tagInputVar,
                          )}){${b->B.failWithArg(
                            ~path=path->Path.concat(valuePath),
                            received => InvalidType({
                              expected: tagSchema,
                              received,
                            }),
                            tagInputVar,
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
                | Registered(var) => b->B.parse(~schema=reversed, ~input=var, ~path)
                | Unregistered =>
                  if original->isLiteralSchema {
                    b->B.parse(
                      ~schema=reversed,
                      ~input=b->B.val(
                        b->B.embed(original->Literal.unsafeFromSchema->Literal.value),
                      ),
                      ~path,
                    )
                  } else {
                    b->B.invalidOperation(
                      ~path,
                      ~description=`The S.variant's value is not registered`,
                    )
                  }
                }
              }),
            )
          },
        )
      }
    }
  }
  and factory:
    type value. (s => value) => schema<value> =
    definer => {
      let fields = Js.Dict.empty()
      let items = []

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
            switch fields->Stdlib.Dict.unsafeGetOption(fieldName) {
            | Some(item: item) =>
              if item.schema.definer->Obj.magic && schema.definer->Obj.magic {
                (schema.definer->Obj.magic)(item.schema.definerCtx->Obj.magic)->(
                  Obj.magic: unknown => value
                )
              } else {
                InternalError.panic(
                  `The field ${inlinedLocation} defined twice with incompatible schemas`,
                )
              }
            | None => {
                let schema = if schema.definer->Obj.magic {
                  factory(schema.definer->Obj.magic)
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
          }

        let tag = (tag, asValue) => {
          let _ = field(tag, literal(asValue))
        }

        let fieldOr = (fieldName, schema, or) => {
          field(fieldName, Option.factory(schema)->Option.getOr(or))
        }

        let nestedField:
          type value. (string, string, t<value>) => value =
          (fieldName, nestedFieldName, schema) => {
            let schema = schema->toUnknown
            switch fields->Stdlib.Dict.unsafeGetOption(fieldName) {
            | Some(item: item) =>
              if item.schema.definer->Obj.magic {
                (item.schema.definerCtx->(Obj.magic: option<char> => ctx)).field(
                  nestedFieldName,
                  schema,
                )->(Obj.magic: unknown => value)
              } else {
                InternalError.panic(
                  `The field ${fieldName->Stdlib.Inlined.Value.fromString} defined twice with incompatible schemas`,
                )
              }
            | None =>
              field(fieldName, factory(s => s.field(nestedFieldName, schema)))->(
                Obj.magic: unknown => value
              )
            }
          }

        {
          // js/ts methods
          _jsField: field,
          // methods
          field,
          fieldOr,
          tag,
          nestedField,
          flatten,
        }
      }

      let definition = definer((ctx :> s))->(Obj.magic: value => unknown)

      {
        tagged: Object({
          items,
          fields,
          unknownKeys: globalConfig.defaultUnknownKeys,
          definition,
        }),
        builder,
        isAsyncSchema: Unknown,
        maybeTypeFilter: Some(typeFilter),
        name,
        metadataMap: Metadata.Map.empty,
        definer: definer->Obj.magic,
        definerCtx: ctx->Obj.magic,
        parseOrRaise: initialParseOrRaise,
        serializeToUnknownOrRaise: initialSerializeToUnknownOrRaise,
        serializeOrRaise: initialSerializeOrRaise,
        assertOrRaise: initialAssertOrRaise,
        jsParse,
        jsParseAsync,
        jsSerialize,
        reverse,
      }
    }

  let setUnknownKeys = (schema, unknownKeys) => {
    switch schema->classify {
    | Object({unknownKeys: schemaUnknownKeys, items, fields, definition})
      if schemaUnknownKeys !== unknownKeys => {
        name: schema.name,
        tagged: Object({
          unknownKeys,
          items,
          fields,
          definition,
        }),
        builder: schema.builder,
        maybeTypeFilter: schema.maybeTypeFilter,
        isAsyncSchema: schema.isAsyncSchema,
        metadataMap: schema.metadataMap,
        definer: ?schema.definer,
        definerCtx: ?schema.definerCtx,
        parseOrRaise: initialParseOrRaise,
        serializeToUnknownOrRaise: initialSerializeToUnknownOrRaise,
        serializeOrRaise: initialSerializeOrRaise,
        assertOrRaise: initialAssertOrRaise,
        jsParse,
        jsParseAsync,
        jsSerialize,
        reverse: schema.reverse,
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

module Dict = {
  let rec factory = schema => {
    let schema = schema->toUnknown
    makeSchema(
      ~name=containerName,
      ~metadataMap=Metadata.Map.empty,
      ~tagged=Dict(schema),
      ~builder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
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

        if isTransformed || itemCode !== "" {
          b.code =
            b.code ++
            `for(let ${keyVar} in ${inputVar}){${itemCode}${isTransformed
                ? b->B.Val.addKey(output, keyVar, itemOutput)
                : ""}}`
        }

        if itemOutput.isAsync {
          let resolveVar = b->B.varWithoutAllocation
          let rejectVar = b->B.varWithoutAllocation
          let asyncParseResultVar = b->B.varWithoutAllocation
          let counterVar = b->B.varWithoutAllocation
          let outputVar = b->B.Val.var(output)
          b->B.asyncVal(
            `new Promise((${resolveVar},${rejectVar})=>{let ${counterVar}=Object.keys(${outputVar}).length;for(let ${keyVar} in ${outputVar}){${outputVar}[${keyVar}].then(${asyncParseResultVar}=>{${outputVar}[${keyVar}]=${asyncParseResultVar};if(${counterVar}--===1){${resolveVar}(${outputVar})}},${rejectVar})}})`,
          )
        } else {
          output
        }
      }),
      ~maybeTypeFilter=Some(Object.typeFilter),
      ~reverse=Reverse.onlyChild(~factory, ~schema),
    )
  }
}

module Unknown = {
  let schema = makeSchema(
    ~name=primitiveName,
    ~tagged=Unknown,
    ~builder=Builder.invalidJson,
    ~metadataMap=Metadata.Map.empty,
    ~maybeTypeFilter=None,
    ~reverse=Reverse.toSelf,
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
  let uuidRegex = %re(`/^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$/i`)
  // Adapted from https://stackoverflow.com/a/46181/1550155
  let emailRegex = %re(`/^(?!\.)(?!.*\.\.)([A-Z0-9_'+\-\.]*)[A-Z0-9_+-]@([A-Z0-9][A-Z0-9\-]*\.)+[A-Z]{2,}$/i`)
  // Adapted from https://stackoverflow.com/a/3143231
  let datetimeRe = %re(`/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$/`)

  let typeFilter = (_b, ~inputVar) => `typeof ${inputVar}!=="string"`

  let schema = makePrimitiveSchema(
    ~tagged=String,
    ~builder=Builder.noop,
    ~maybeTypeFilter=Some(typeFilter),
  )
}

module JsonString = {
  let factory = (schema, ~space=0) => {
    let schema = schema->toUnknown
    makeSchema(
      ~name=primitiveName,
      ~metadataMap=Metadata.Map.empty,
      ~tagged=String,
      ~builder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
        let jsonVal = b->B.allocateVal

        b.code =
          b.code ++
          `try{${b->B.Val.set(
              jsonVal,
              b->B.Val.map("JSON.parse", input),
            )}}catch(t){${b->B.failWithArg(
              ~path,
              message => OperationFailed(message),
              "t.message",
            )}}`

        let bb = b->B.scope
        let val = bb->B.parseWithTypeCheck(~schema, ~input=jsonVal, ~path)
        b.code = b.code ++ bb->B.allocateScope
        val
      }),
      ~maybeTypeFilter=Some(String.typeFilter),
      ~reverse=() => {
        let reversed = schema.reverse()
        makeReverseSchema(
          ~name=reversed.name,
          ~tagged=reversed.tagged,
          ~metadataMap=reversed.metadataMap,
          ~builder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
            let prevOperation = b.global.operation
            b.global.operation = prevOperation->Operation.addFlag(Operation.Flag.jsonableOutput)
            if reversed.tagged->unsafeGetVarianTag === "Option" {
              b->B.raise(~code=InvalidJsonSchema(reversed), ~path=Path.empty)
            }
            let output =
              b->B.val(
                `JSON.stringify(${b->B.Val.inline(
                    b->B.parse(~schema=reversed, ~input, ~path),
                  )}${space > 0 ? `,null,${space->Stdlib.Int.unsafeToString}` : ""})`,
              )
            b.global.operation = prevOperation
            output
          }),
          ~maybeTypeFilter=reversed.maybeTypeFilter,
        )
      },
    )
  }
}

module Bool = {
  let typeFilter = (_b, ~inputVar) => `typeof ${inputVar}!=="boolean"`

  let schema = makePrimitiveSchema(
    ~tagged=Bool,
    ~builder=Builder.noop,
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

  let typeFilter = (_b, ~inputVar) =>
    `typeof ${inputVar}!=="number"||${inputVar}>2147483647||${inputVar}<-2147483648||${inputVar}%1!==0`

  let schema = makePrimitiveSchema(
    ~tagged=Int,
    ~builder=Builder.noop,
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

  let typeFilter = (_b, ~inputVar) =>
    `typeof ${inputVar}!=="number"` ++ if globalConfig.disableNanNumberCheck {
      ""
    } else {
      `||Number.isNaN(${inputVar})`
    }

  let schema = makePrimitiveSchema(
    ~tagged=Float,
    ~builder=Builder.noop,
    ~maybeTypeFilter=Some(typeFilter),
  )
}

module BigInt = {
  let typeFilter = (_b, ~inputVar) => `typeof ${inputVar}!=="bigint"`

  let schema = makePrimitiveSchema(
    ~tagged=Unknown, // TODO: Add BigInt in v9
    ~builder=Builder.invalidJson,
    ~maybeTypeFilter=Some(typeFilter),
  )
  (schema->Obj.magic)["n"] = %raw(`() => "BigInt"`)
}

module Union = {
  let parse = (b, ~schemas, ~path, ~input, ~output) => {
    let isMultiple = schemas->Js.Array2.length > 1
    let rec loop = (idx, errorCodes) => {
      if idx === schemas->Js.Array2.length {
        b->B.failWithArg(
          ~path,
          internalErrors => {
            InvalidUnion(internalErrors)
          },
          `[${errorCodes}]`,
        )
      } else {
        let schema = schemas->Js.Array2.unsafe_get(idx)
        let parserCode = try {
          let bb = b->B.scope
          let itemOutput = bb->B.parse(~schema, ~input, ~path=Path.empty)

          if (
            isMultiple &&
            !(b.global.operation->Operation.unsafeHasFlag(Operation.Flag.typeValidation))
          ) {
            let reversed = schema.reverse()
            switch reversed.maybeTypeFilter {
            | Some(typeFilter) =>
              let code =
                bb->B.typeFilterCode(
                  ~schema=reversed,
                  ~typeFilter,
                  ~input=itemOutput,
                  ~path=Path.empty,
                )
              bb.code = bb.code ++ code

            | None => ()
            }
          }

          if itemOutput !== input {
            bb.code = bb.code ++ bb->B.Val.set(output, itemOutput)
          }

          bb->B.allocateScope
        } catch {
        | exn => "throw " ++ b->B.embed(exn->InternalError.getOrRethrow)
        }
        if isMultiple {
          let errorVar = `e` ++ idx->Stdlib.Int.unsafeToString
          `try{${parserCode}}catch(${errorVar}){` ++
          loop(idx + 1, errorCodes ++ errorVar ++ ",") ++ "}"
        } else {
          parserCode
        }
      }
    }
    loop(0, "")
  }

  let rec factory = schemas => {
    let schemas: array<t<unknown>> = schemas->Obj.magic

    switch schemas {
    | [] => InternalError.panic("S.union requires at least one item")
    | [schema] => schema->castUnknownSchemaToAnySchema
    | _ =>
      makeSchema(
        ~name=() => `Union(${schemas->Js.Array2.map(s => s.name())->Js.Array2.joinWith(", ")})`,
        ~metadataMap=Metadata.Map.empty,
        ~tagged=Union(schemas),
        ~builder=Builder.make((b, ~input, ~selfSchema, ~path) => {
          let schemas = selfSchema->classify->unsafeGetVariantPayload
          let inputVar = b->B.Val.var(input)
          let output = b->B.val(inputVar)

          let byTypeFilter = Js.Dict.empty()
          let typeFilters = []
          for idx in 0 to schemas->Js.Array2.length - 1 {
            let schema = schemas->Js.Array2.unsafe_get(idx)
            let typeFilterCode = switch schema.maybeTypeFilter {
            | Some(typeFilter) => b->typeFilter(~inputVar)
            | None => ""
            }

            switch byTypeFilter->Js.Dict.get(typeFilterCode) {
            | Some(schemas) => schemas->Js.Array2.push(schema)->ignore
            | None => {
                typeFilters->Js.Array2.push(typeFilterCode)->ignore
                byTypeFilter->Js.Dict.set(typeFilterCode, [schema])
              }
            }
          }

          let rec loopTypeFilters = (idx, maybeUnknownParser) => {
            if idx === typeFilters->Js.Array2.length {
              switch maybeUnknownParser {
              | None =>
                b->B.failWithArg(
                  ~path,
                  received => InvalidType({
                    expected: selfSchema,
                    received,
                  }),
                  inputVar,
                )
              | Some(unknownParserCode) => unknownParserCode
              }
            } else {
              let typeFilterCode = typeFilters->Js.Array2.unsafe_get(idx)
              let schemas = byTypeFilter->Js.Dict.unsafeGet(typeFilterCode)

              let parserCode = parse(b, ~schemas, ~path, ~input, ~output)

              switch typeFilterCode {
              | "" => loopTypeFilters(idx + 1, Some(parserCode))
              | _ =>
                `if(${typeFilterCode}){` ++
                loopTypeFilters(idx + 1, maybeUnknownParser) ++
                switch parserCode {
                | "" => ""
                | _ => `}else{` ++ parserCode
                } ++ `}`
              }
            }
          }
          b.code = b.code ++ loopTypeFilters(0, None)

          if output.isAsync {
            b->B.asyncVal(`Promise.resolve(${b->B.Val.inline(output)})`)
          } else {
            output
          }
        }),
        ~maybeTypeFilter=None,
        ~reverse=() => {
          let original = %raw(`this`)
          let schemas = original->classify->unsafeGetVariantPayload
          factory(schemas->Js.Array2.map(s => s.reverse()->castUnknownSchemaToAnySchema))
        },
      )
    }
  }
}

let enum = values => Union.factory(values->Js.Array2.map(literal))

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
    makeSchema(
      ~name=schema.name,
      ~tagged=Union(
        unionSchemas->Js.Array2.map(unionSchema =>
          unionSchema->castUnknownSchemaToAnySchema->preprocess(transformer)->toUnknown
        ),
      ),
      ~builder=schema.builder,
      ~maybeTypeFilter=schema.maybeTypeFilter,
      ~metadataMap=schema.metadataMap,
      ~reverse=schema.reverse,
    )
  | _ =>
    makeSchema(
      ~name=schema.name,
      ~tagged=schema.tagged,
      ~builder=Builder.make((b, ~input, ~selfSchema, ~path) => {
        switch transformer(b->B.effectCtx(~selfSchema, ~path)) {
        | {parser, asyncParser: ?None} =>
          b->B.parseWithTypeCheck(
            ~schema,
            ~input=b->B.embedSyncOperation(~input, ~fn=parser),
            ~path,
          )
        | {parser: ?None, asyncParser} =>
          b->B.transform(
            ~input=b->B.embedAsyncOperation(~input, ~fn=asyncParser),
            (b, ~input) => {
              b->B.parseWithTypeCheck(~schema, ~input, ~path)
            },
          )
        | {parser: ?None, asyncParser: ?None} => b->B.parseWithTypeCheck(~schema, ~input, ~path)
        | {parser: _, asyncParser: _} =>
          b->B.invalidOperation(
            ~path,
            ~description=`The S.preprocess doesn't allow parser and asyncParser at the same time. Remove parser in favor of asyncParser`,
          )
        }
      }),
      ~maybeTypeFilter=None,
      ~metadataMap=schema.metadataMap,
      ~reverse=() => {
        let reversed = schema.reverse()
        makeReverseSchema(
          ~name=primitiveName,
          ~tagged=Unknown,
          ~builder=(b, ~input, ~selfSchema as _, ~path) => {
            let input = b->B.parse(~schema=reversed, ~input, ~path)
            switch transformer(b->B.effectCtx(~selfSchema=schema, ~path)) {
            | {serializer} => b->B.embedSyncOperation(~input, ~fn=serializer)
            | {serializer: ?None} => input
            }
          },
          ~maybeTypeFilter=None,
          // TODO: Test how metadata should work for reversed schemas
          ~metadataMap=Metadata.Map.empty,
        )
      },
    )
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

let rec json = (~validate) =>
  makeSchema(
    ~tagged=JSON({validated: validate}),
    ~maybeTypeFilter=None,
    ~metadataMap=Metadata.Map.empty,
    ~name=() => "JSON",
    ~builder=validate
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
              b->B.raise(
                ~path,
                ~code=InvalidType({
                  expected: selfSchema,
                  received: input,
                }),
              )
            }
          }

          b->B.Val.map(b->B.embed(parse), input)
        })
      : Builder.noop,
    ~reverse=() => validate ? json(~validate=false)->toUnknown : %raw(`this`),
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
  makeSchema(
    ~name=schema.name,
    ~builder=Builder.make((b, ~input, ~selfSchema, ~path) => {
      let inputVar = b->B.Val.var(input)

      b->B.withCatch(
        ~input,
        ~catch=(b, ~errorVar) => Some(
          b->B.val(
            `${b->B.embed(
                (input, internalError) =>
                  getFallbackValue({
                    Catch.input,
                    error: internalError,
                    schema: selfSchema->castUnknownSchemaToAnySchema,
                    fail: (message, ~path as customPath=Path.empty) => {
                      b->B.raise(
                        ~path=path->Path.concat(customPath),
                        ~code=OperationFailed(message),
                      )
                    },
                  }),
              )}(${inputVar},${errorVar})`,
          ),
        ),
        b => {
          b->B.parseWithTypeCheck(~schema, ~input, ~path)
        },
      )
    }),
    ~tagged=schema.tagged,
    ~maybeTypeFilter=None,
    ~metadataMap=schema.metadataMap,
    ~reverse=() => schema.reverse(),
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
        Object.tuple(s => {
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
          let objectDefinition = Js.Dict.empty()
          let keys = node->Js.Dict.keys
          for idx in 0 to keys->Js.Array2.length - 1 {
            let key = keys->Js.Array2.unsafe_get(idx)
            let definition = node->Js.Dict.unsafeGet(key)
            objectDefinition->Js.Dict.set(
              key,
              s.field(key, definition->definitionToSchema(~embededSet))->(
                Obj.magic: unknown => Definition.t<schema<unknown>>
              ),
            )
          }
          objectDefinition
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

  let rec reason = (error: error, ~nestedLevel=0) => {
    switch error.code {
    | OperationFailed(reason) => reason
    | InvalidOperation({description}) => description
    | UnexpectedAsync => "Encountered unexpected async transform or refine. Use ParseAsync operation instead"
    | ExcessField(fieldName) =>
      `Encountered disallowed excess key ${fieldName->Stdlib.Inlined.Value.fromString} on an object`
    | InvalidType({expected, received}) =>
      `Expected ${expected.name()}, received ${received->Literal.parse->Literal.toString}`
    | InvalidJsonSchema(schema) => `The schema ${schema.name()} is not compatible with JSON`
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

  let reason = error => reason(error)

  let message = (error: error) => {
    let operation = switch error.operation {
    | SerializeToUnknown => "serializing"
    | SerializeToJson => "serializing to JSON"
    | Parse => "parsing"
    | ParseAsync => "parsing async"
    | Assert => "asserting"
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
            `->S.email(~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Url, message} => `->S.url(~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Uuid, message} =>
            `->S.uuid(~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Cuid, message} =>
            `->S.cuid(~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Min({length}), message} =>
            `->S.stringMinLength(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Max({length}), message} =>
            `->S.stringMaxLength(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
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
            `->S.arrayMaxLength(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
          | {kind: Min({length}), message} =>
            `->S.arrayMinLength(${length->Stdlib.Int.unsafeToString}, ~message=${message->Stdlib.Inlined.Value.fromString})`
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
let bigint = BigInt.schema
let null = Null.factory
let option = Option.factory
let array = Array.factory
let dict = Dict.factory
let variant = Object.variant
let tuple = Object.tuple
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
    ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
      `if(${inputVar}<${b->B.embed(minValue)}){${b->B.fail(~message, ~path)}}`
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
    ~metadataId=Int.Refinement.metadataId,
    ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
      `if(${inputVar}<1||${inputVar}>65535){${b->B.fail(~message, ~path)}}`
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
    ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
      `if(${inputVar}<${b->B.embed(minValue)}){${b->B.fail(~message, ~path)}}`
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
    ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
      `if(${inputVar}>${b->B.embed(maxValue)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Max({value: maxValue}),
      message,
    },
  )
}

let arrayMinLength = (schema, length, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `Array must be ${length->Stdlib.Int.unsafeToString} or more items long`
  }
  schema->addRefinement(
    ~metadataId=Array.Refinement.metadataId,
    ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
      `if(${inputVar}.length<${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Min({length: length}),
      message,
    },
  )
}

let arrayMaxLength = (schema, length, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `Array must be ${length->Stdlib.Int.unsafeToString} or fewer items long`
  }
  schema->addRefinement(
    ~metadataId=Array.Refinement.metadataId,
    ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
      `if(${inputVar}.length>${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
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
    ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
      `if(${inputVar}.length!==${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Length({length: length}),
      message,
    },
  )
}

let stringMinLength = (schema, length, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `String must be ${length->Stdlib.Int.unsafeToString} or more characters long`
  }
  schema->addRefinement(
    ~metadataId=String.Refinement.metadataId,
    ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
      `if(${inputVar}.length<${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
    },
    ~refinement={
      kind: Min({length: length}),
      message,
    },
  )
}

let stringMaxLength = (schema, length, ~message as maybeMessage=?) => {
  let message = switch maybeMessage {
  | Some(m) => m
  | None => `String must be ${length->Stdlib.Int.unsafeToString} or fewer characters long`
  }
  schema->addRefinement(
    ~metadataId=String.Refinement.metadataId,
    ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
      `if(${inputVar}.length>${b->B.embed(length)}){${b->B.fail(~message, ~path)}}`
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
    ~metadataId=String.Refinement.metadataId,
    ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
      `if(!${b->B.embed(String.emailRegex)}.test(${inputVar})){${b->B.fail(~message, ~path)}}`
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
    ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
      `if(!${b->B.embed(String.uuidRegex)}.test(${inputVar})){${b->B.fail(~message, ~path)}}`
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
    ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
      `if(!${b->B.embed(String.cuidRegex)}.test(${inputVar})){${b->B.fail(~message, ~path)}}`
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
    ~metadataId=String.Refinement.metadataId,
    ~refiner=(b, ~inputVar, ~selfSchema as _, ~path) => {
      let reVal = b->B.val(b->B.embed(re))
      let reVar = b->B.Val.var(reVal)
      `${reVar}.lastIndex=0;if(!${reVar}.test(${inputVar})){${b->B.fail(~message, ~path)}}`
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

let unwrap = result => {
  switch result {
  | Ok(v) => v
  | Error(error) => Stdlib.Exn.raiseAny(error)
  }
}

// =============
// JS/TS API
// =============

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
        // A dirty check that this is rescript-schema object
        let schema = if Obj.magic(schema) && Obj.magic(schema)["serializeToJsonOrThrow"] {
          schema
        } else {
          literal(Obj.magic(schema))
        }
        definition->Js.Dict.set(fieldName, s.field(fieldName, schema))
      }
      definition
    })
  }
}

let js_merge = (s1, s2) => {
  switch (s1, s2) {
  | ({tagged: Object({items: s1Items})}, {tagged: Object({items: s2Items, unknownKeys})}) =>
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
    makeSchema(
      ~name=() => `${s1.name()} & ${s2.name()}`,
      ~tagged=Object({
        unknownKeys,
        items,
        fields,
        definition: %raw(`void 0`),
      }),
      ~builder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
        let s1Result = b->B.parse(~schema=s1, ~input, ~path)
        let s2Result = b->B.parse(~schema=s2, ~input, ~path)
        // TODO: Check that these are objects
        // TODO: Check that s1Result is not mutating input
        b->B.val(`Object.assign(${b->B.Val.inline(s1Result)}, ${b->B.Val.inline(s2Result)})`)
      }),
      ~maybeTypeFilter=Some(Object.typeFilter),
      ~metadataMap=Metadata.Map.empty,
      ~reverse=() =>
        makeReverseSchema(
          ~name=primitiveName,
          ~tagged=Unknown,
          ~builder=Builder.make((b, ~input as _, ~selfSchema as _, ~path) => {
            b->B.invalidOperation(
              ~path,
              ~description=`The S.merge serializing is not supported yet`,
            )
          }),
          ~maybeTypeFilter=None,
          ~metadataMap=Metadata.Map.empty,
        ),
    )
  | _ => InternalError.panic("The merge supports only Object schemas")
  }
}

let js_name = name

let resetOperationsCache: schema<'value> => unit = %raw(`(schema) => {
  for (let key in schema) {
    if (+key) {
      delete schema[key];
    }
  }
}`)

let setGlobalConfig = override => {
  globalConfig.recCounter = 0
  globalConfig.defaultUnknownKeys = switch override.defaultUnknownKeys {
  | Some(unknownKeys) => unknownKeys
  | None => initialDefaultUnknownKeys
  }
  let prevDisableNanNumberCheck = globalConfig.disableNanNumberCheck
  globalConfig.disableNanNumberCheck = switch override.disableNanNumberCheck {
  | Some(disableNanNumberCheck) => disableNanNumberCheck
  | None => initialDisableNanNumberProtection
  }
  if prevDisableNanNumberCheck != globalConfig.disableNanNumberCheck {
    float.assertOrRaise = initialAssertOrRaise
    float.parseOrRaise = initialParseOrRaise
    resetOperationsCache(float)
  }
}

let js_unwrap = (result: jsResult<'value>): 'value => {
  switch result {
  | Success({value}) => value
  | Failure({error}) => Stdlib.Exn.raiseAny(error)
  }
}
