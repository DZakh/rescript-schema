@@uncurried
@@warning("-30")

type never

external castAnyToUnknown: 'any => unknown = "%identity"
external castUnknownToAny: unknown => 'any = "%identity"

module Obj = {
  external magic: 'a => 'b = "%identity"
}

module Stdlib = {
  module Proxy = {
    type traps<'a> = {get?: (~target: 'a, ~prop: unknown) => unknown}

    @new
    external make: ('a, traps<'a>) => 'a = "Proxy"
  }

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
    let immutableEmpty = %raw(`{}`)

    @val external internalClass: Js.Types.obj_val => string = "Object.prototype.toString.call"
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

    @get_index
    external unsafeGetOptionBySymbol: (dict<'a>, Js.Types.symbol) => option<'a> = ""

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
  @as("~r")
  mutable // FIXME: Use a better way to check for isSchema
  reverse: unit => t<unknown>,
  @as("b")
  mutable builder: builder,
  @as("f")
  maybeTypeFilter: option<(b, ~inputVar: string) => string>,
  @as("i")
  mutable isAsyncSchema: isAsyncSchema,
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
  | Object({fieldNames: array<string>, fields: dict<t<unknown>>, unknownKeys: unknownKeys})
  | Tuple({items: array<t<unknown>>})
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
  @as("f")
  fieldOf?: item, // FIXME: Don't expose item type?
}
and builder = (b, ~input: val, ~selfSchema: schema<unknown>, ~path: Path.t) => val
and val = {
  @as("v")
  mutable isVar: bool,
  @as("i")
  mutable inline: string,
  @as("s")
  _scope: b,
  @as("a")
  mutable isAsync: bool,
}
and bGlobal = {
  @as("v")
  mutable varCounter: int,
  @as("o")
  mutable flag: int,
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
and flag = int
and schema<'a> = t<'a>
and error = private {flag: flag, code: errorCode, path: Path.t}
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

// A dirty check that this is rescript-schema object
@inline
let isSchemaObject = object => Obj.magic(object)["~r"]
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

module InternalError = {
  %%raw(`
    class RescriptSchemaError extends Error {
      constructor(code, flag, path) {
        super();
        this.flag = flag;
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
  external make: (~code: errorCode, ~flag: int, ~path: Path.t) => error = "RescriptSchemaError"

  let getOrRethrow = (exn: exn) => {
    if %raw("exn&&exn.s===symbol") {
      exn->(Obj.magic: exn => error)
    } else {
      raise(exn)
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

module Flag = {
  @inline let none = 0
  @inline let typeValidation = 1
  @inline let async = 2
  @inline let assertOutput = 4
  @inline let jsonableOutput = 8
  @inline let jsonStringOutput = 16
  @inline let reverse = 32

  external with: (flag, flag) => flag = "%orint"

  let unsafeHas = (acc: flag, flag) => acc->land(flag)->(Obj.magic: int => bool)
  let has = (acc: flag, flag) => acc->land(flag) !== 0
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
      let var = b->varWithoutAllocation
      let varsAllocation = b.varsAllocation
      b.varsAllocation = varsAllocation === "" ? var : varsAllocation ++ "," ++ var
      {isVar: true, _scope: b, isAsync: false, inline: var}
    }

    let val = (b: b, initial: string): val => {
      {isVar: false, inline: initial, _scope: b, isAsync: false}
    }

    let asyncVal = (b: b, initial: string): val => {
      {isVar: false, inline: initial, _scope: b, isAsync: true}
    }

    module Val = {
      module Object = {
        type t = {
          ...val,
          @as("j")
          mutable join: (string, string) => string,
          @as("c")
          mutable asyncCount: int,
          @as("p")
          mutable promiseAllContent: string,
          @as("f")
          fields: Js.Dict.t<val>,
        }

        let objectJoin = (inlinedLocation, value) => {
          `${inlinedLocation}:${value},`
        }

        let arrayJoin = (_inlinedLocation, value) => {
          value ++ ","
        }

        let make = (b, ~isArray): t => {
          {
            isVar: false,
            inline: "",
            _scope: b,
            isAsync: false,
            join: isArray ? arrayJoin : objectJoin,
            asyncCount: 0,
            promiseAllContent: "",
            fields: Js.Dict.empty(),
          }
        }

        @inline
        let add = (objectVal, inlinedLocation, val: val) => {
          objectVal.fields->Js.Dict.set(inlinedLocation, val)
          if val.isAsync {
            objectVal.promiseAllContent = objectVal.promiseAllContent ++ val.inline ++ ","
            objectVal.inline =
              objectVal.inline ++ objectVal.join(inlinedLocation, `a[${%raw(`objectVal.c++`)}]`)
          } else {
            objectVal.inline = objectVal.inline ++ objectVal.join(inlinedLocation, val.inline)
          }
        }

        let complete = (objectVal, ~isArray) => {
          objectVal.inline = isArray
            ? "[" ++ objectVal.inline ++ "]"
            : "{" ++ objectVal.inline ++ "}"
          if objectVal.asyncCount->Obj.magic {
            objectVal.isAsync = true
            objectVal.inline = `Promise.all([${objectVal.promiseAllContent}]).then(a=>(${objectVal.inline}))`
          }
          (objectVal :> val)
        }
      }

      let var = (b: b, val: val) => {
        if val.isVar {
          val.inline
        } else {
          let var = b->varWithoutAllocation
          let allocation = switch val.inline {
          | "" => var
          | i => `${var}=${i}`
          }
          let varsAllocation = val._scope.varsAllocation
          val._scope.varsAllocation = varsAllocation === ""
            ? allocation
            : varsAllocation ++ "," ++ allocation
          val.isVar = true
          val.inline = var
          var
        }
      }

      let push = (b: b, input: val, val: val) => {
        `${b->var(input)}.push(${val.inline})`
      }

      let addKey = (b: b, input: val, key, val: val) => {
        `${b->var(input)}[${key}]=${val.inline}`
      }

      let set = (b: b, input: val, val) => {
        if input === val {
          ""
        } else {
          let inputVar = b->var(input)
          switch (input, val) {
          | ({isAsync: false}, {isAsync: true}) => {
              input.isAsync = true
              `${inputVar}=${val.inline}`
            }
          | ({isAsync: false}, {isAsync: false})
          | ({isAsync: true}, {isAsync: true}) =>
            `${inputVar}=${val.inline}`
          | ({isAsync: true}, {isAsync: false}) => `${inputVar}=Promise.resolve(${val.inline})`
          }
        }
      }

      @inline
      let get = (b, targetVal: val, inlinedLocation, ~path) => {
        if (targetVal->Obj.magic)["f"] {
          (targetVal->Obj.magic)["f"]->Js.Dict.unsafeGet(inlinedLocation)
        } else {
          let targetVar = if targetVal.isVar {
            targetVal.inline
          } else {
            let scopedInput = b->allocateVal
            b.code = b.code ++ b->set(scopedInput, targetVal) ++ ";"
            scopedInput.inline
          }
          b->val(`${targetVar}${path}`)
        }
      }

      let setInlined = (b: b, input: val, inlined) => {
        `${b->var(input)}=${inlined}`
      }

      let map = (b: b, inlinedFn, input: val) => {
        b->val(`${inlinedFn}(${input.inline})`)
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
          isVar: true,
          _scope: bb,
          inline: bb->varWithoutAllocation,
          isAsync: false,
        }
        let operationOutputVal = operation(bb, ~input=operationInput)
        let operationCode = bb->allocateScope

        b->asyncVal(
          `${input.inline}.then(${b->Val.var(
              operationInput,
            )}=>{${operationCode}return ${operationOutputVal.inline}})`,
        )
      } else {
        operation(b, ~input)
      }
    }

    let raise = (b: b, ~code, ~path) => {
      Stdlib.Exn.raiseAny(InternalError.make(~code, ~flag=b.global.flag, ~path))
    }

    let embedSyncOperation = (b: b, ~input, ~fn: 'input => 'output) => {
      if input.isAsync {
        b->asyncVal(`${input.inline}.then(${b->embed(fn)})`)
      } else {
        b->Val.map(b->embed(fn), input)
      }
    }

    let embedAsyncOperation = (b: b, ~input, ~fn: 'input => unit => promise<'output>) => {
      if !(b.global.flag->Flag.unsafeHas(Flag.async)) {
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
      if b.global.flag->Flag.unsafeHas(Flag.jsonableOutput) {
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
        let output = input === fnOutput ? input : {isVar: false, _scope: b, inline: "", isAsync}

        let catchCode = switch maybeResolveVal {
        | None => _ => `${catchCode}}throw ${errorVar}`
        | Some(resolveVal) =>
          catchLocation =>
            catchCode ++
            switch catchLocation {
            | #0 => b->Val.set(output, resolveVal)
            | #1 => `return ${resolveVal.inline}`
            } ++
            `}else{throw ${errorVar}}`
        }

        b.code =
          prevCode ++
          `try{${b.code}${switch isAsync {
            | true =>
              b->Val.setInlined(output, `${fnOutput.inline}.catch(${errorVar}=>{${catchCode(#1)}})`)
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
              | Some(var) => `'["'+${var}+'"]'+` // FIXME: Don't add "" for int var
              | _ => ""
              }}${errorVar}.path`
            None
          },
          b => fn(b, ~input, ~path=Path.empty),
        ) catch {
        | _ =>
          let error = %raw(`exn`)->InternalError.getOrRethrow
          Stdlib.Exn.raiseAny(
            InternalError.make(
              ~path=path->Path.concat(Path.dynamic)->Path.concat(error.path),
              ~code=error.code,
              ~flag=error.flag,
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
        if schema->isLiteralSchema || b.global.flag->Flag.unsafeHas(Flag.typeValidation) =>
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

  let compile = (builder, ~schema, ~flag) => {
    if (
      flag->Flag.unsafeHas(Flag.jsonableOutput) &&
        schema.reverse().tagged->unsafeGetVarianTag === "Option"
    ) {
      Stdlib.Exn.raiseAny(
        InternalError.make(~code=InvalidJsonSchema(schema), ~flag, ~path=Path.empty),
      )
    }

    let b = {
      code: "",
      varsAllocation: "",
      isAllocated: false,
      global: {
        varCounter: -1,
        embeded: [],
        flag,
      },
    }
    let input = {isVar: true, _scope: b, isAsync: false, inline: intitialInputVar}

    let output = builder(b, ~input, ~selfSchema=schema, ~path=Path.empty)
    schema.isAsyncSchema = Value(output.isAsync)

    if b.varsAllocation !== "" {
      b.code = `let ${b.varsAllocation};${b.code}`
    }

    if flag->Flag.unsafeHas(Flag.typeValidation) || schema->isLiteralSchema {
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
        flag->Flag.unsafeHas(
          Flag.assertOutput
          ->Flag.with(Flag.async)
          ->Flag.with(Flag.jsonStringOutput),
        )
      )
    ) {
      noopOperation
    } else {
      let inlinedOutput = ref(
        if flag->Flag.unsafeHas(Flag.assertOutput) {
          `void 0`
        } else {
          output.inline
        },
      )
      if flag->Flag.unsafeHas(Flag.jsonStringOutput) {
        inlinedOutput := `JSON.stringify(${inlinedOutput.contents})`
      }
      if flag->Flag.unsafeHas(Flag.async) && !output.isAsync {
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

let operationFn = (s, o) => {
  let s = s->toUnknown
  if %raw(`o in s`) {
    %raw(`s[o]`)
  } else {
    let ss = o->Flag.unsafeHas(Flag.reverse) ? s.reverse() : s
    let f = ss.builder->Builder.compile(~schema=ss, ~flag=o)
    let _ = %raw(`s[o] = f`)
    f
  }
}

type rec input<'value, 'computed> =
  | Value: input<'value, 'value>
  | Any: input<'value, 'any>
  | Unknown: input<'value, unknown>
  | Json: input<'value, Js.Json.t>
  | JsonString: input<'value, string>
type rec output<'value, 'computed> =
  | Value: output<'value, 'value>
  | Unknown: output<'value, unknown>
  | Assert: output<'value, unit>
  | Json: output<'value, Js.Json.t>
  | JsonString: output<'value, string>
type rec mode<'output, 'computed> =
  | Sync: mode<'output, 'output>
  | Async: mode<'output, promise<'output>>

@@warning("-37")
type internalInput =
  | Value
  | Any
  | Unknown
  | Json
  | JsonString
type internalOutput =
  | Value
  | Unknown
  | Assert
  | Json
  | JsonString
type internalMode =
  | Sync
  | Async
@@warning("+37")

let compile = (
  schema: t<'value>,
  ~input: input<'value, 'input>,
  ~output: output<'value, 'transformedOutput>,
  ~mode: mode<'transformedOutput, 'output>,
  ~typeValidation,
): ('input => 'output) => {
  let output = output->(Obj.magic: output<'value, 'transformedOutput> => internalOutput)
  let input = input->(Obj.magic: input<'schemaInput, 'input> => internalInput)
  let mode = mode->(Obj.magic: mode<'transformedOutput, 'output> => internalMode)

  let schema = schema->toUnknown

  let flag = ref(Flag.none)
  switch output {
  | Value
  | Unknown => ()
  | Assert => flag := flag.contents->Flag.with(Flag.assertOutput)
  | Json => flag := flag.contents->Flag.with(Flag.jsonableOutput)
  | JsonString =>
    flag := flag.contents->Flag.with(Flag.jsonableOutput->Flag.with(Flag.jsonStringOutput))
  }
  switch mode {
  | Sync => ()
  | Async => flag := flag.contents->Flag.with(Flag.async)
  }
  if typeValidation {
    flag := flag.contents->Flag.with(Flag.typeValidation)
  }
  if input === Value {
    if output === Value {
      InternalError.panic(`Can't compile Value input to Value output`)
    }
    flag := flag.contents->Flag.with(Flag.reverse)
  }
  let fn = schema->operationFn(flag.contents)->Obj.magic

  switch input {
  | JsonString =>
    let flag = flag.contents
    jsonString => {
      try jsonString->Obj.magic->Js.Json.parseExn->fn catch {
      | _ =>
        Stdlib.Exn.raiseAny(
          InternalError.make(~code=OperationFailed(%raw(`exn.message`)), ~flag, ~path=Path.empty),
        )
      }
    }
  | _ => fn
  }
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
          flag: Flag.async,
        },
      }
      let input = {
        isVar: true,
        _scope: b,
        isAsync: false,
        inline: Builder.intitialInputVar,
      }
      let output = schema.builder(b, ~input, ~selfSchema=schema, ~path=Path.empty)
      schema.isAsyncSchema = Value(output.isAsync)
      schema.isAsyncSchema->(Obj.magic: isAsyncSchema => bool)
    } catch {
    | _ => {
        let _ = %raw(`exn`)->InternalError.getOrRethrow
        false
      }
    }
  | Value(v) => v
  }
}

let reverse = schema => {
  schema.reverse()
}

// =============
// Operations
// =============

@inline
let parseOrThrow = (any, schema) => {
  (schema->operationFn(Flag.typeValidation))(any)
}

let parseJsonStringOrThrow = (jsonString: string, schema: t<'value>): 'value => {
  try {
    jsonString->Js.Json.parseExn
  } catch {
  | _ =>
    Stdlib.Exn.raiseAny(
      InternalError.make(
        ~code=OperationFailed(%raw(`exn.message`)),
        ~flag=Flag.typeValidation,
        ~path=Path.empty,
      ),
    )
  }->parseOrThrow(schema)
}

let parseAsyncOrThrow = (any, schema) => {
  (schema->operationFn(Flag.async->Flag.with(Flag.typeValidation)))(any)
}

let convertOrThrow = (input, schema) => {
  (schema->operationFn(Flag.none))(input)
}

let convertToJsonOrThrow = (any, schema) => {
  (schema->operationFn(Flag.jsonableOutput))(any)
}

let convertToJsonStringOrThrow = (input, schema) => {
  (schema->operationFn(Flag.jsonableOutput->Flag.with(Flag.jsonStringOutput)))(input)
}

let convertAsyncOrThrow = (any, schema) => {
  (schema->operationFn(Flag.async))(any)
}

let reverseConvertOrThrow = (value, schema) => {
  (schema->operationFn(Flag.reverse))(value)
}

@inline
let reverseConvertToJsonOrThrow = (value, schema) => {
  (schema->operationFn(Flag.jsonableOutput->Flag.with(Flag.reverse)))(value)
}

let reverseConvertToJsonStringOrThrow = (value: 'value, schema: t<'value>, ~space=0): string => {
  value->reverseConvertToJsonOrThrow(schema)->Js.Json.stringifyWithSpace(space)
}

let assertOrThrow = (any, schema) => {
  (schema->operationFn(Flag.typeValidation->Flag.with(Flag.assertOutput)))(any)
}

let wrapExnToFailure = exn => {
  if %raw("exn&&exn.s===symbol") {
    Failure({error: exn->(Obj.magic: exn => error)})
  } else {
    raise(exn)
  }
}

let js_safe = fn => {
  try {
    Success({
      value: fn(),
    })
  } catch {
  | _ => wrapExnToFailure(%raw(`exn`))
  }
}

let js_safeAsync = fn => {
  try {
    fn()->Stdlib.Promise.thenResolveWithCatch(value => Success({value: value}), wrapExnToFailure)
  } catch {
  | _ => Stdlib.Promise.resolve(wrapExnToFailure(%raw(`exn`)))
  }
}

let makeReverseSchema = (~name, ~tagged, ~metadataMap, ~builder, ~maybeTypeFilter) => {
  tagged,
  builder,
  isAsyncSchema: Unknown,
  maybeTypeFilter,
  name,
  metadataMap,
  reverse: Reverse.toSelf,
}

let makeSchema = (
  ~name,
  ~tagged,
  ~metadataMap,
  ~builder,
  ~maybeTypeFilter,
  ~reverse: unit => t<'v>,
) => {
  tagged,
  builder,
  isAsyncSchema: Unknown,
  maybeTypeFilter,
  name,
  metadataMap,
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
    original.reverse = () => reversed
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
    "~r": () => {
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
  let schema = fn(placeholder)->toUnknown

  // maybeTypeFilter
  (placeholder->Obj.magic)["f"] = schema.maybeTypeFilter

  let initialParseOperationBuilder = schema.builder
  schema.builder = Builder.make((b, ~input, ~selfSchema, ~path) => {
    let bb = b->B.scope
    let opOutput = initialParseOperationBuilder(bb, ~input, ~selfSchema, ~path=Path.empty)
    let opBodyCode = bb->B.allocateScope ++ `return ${opOutput.inline}`
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
    let initialReversed = initialReverse()
    let reversed = makeReverseSchema(
      ~name=initialReversed.name,
      ~tagged=initialReversed.tagged,
      ~metadataMap=initialReversed.metadataMap,
      ~builder=Builder.make((b, ~input, ~selfSchema, ~path) => {
        let bb = b->B.scope
        let opOutput = initialReversed.builder(bb, ~input, ~selfSchema, ~path=Path.empty)
        let opBodyCode = bb->B.allocateScope ++ `return ${opOutput.inline}`
        b.code = b.code ++ `let ${r}=${b->B.Val.var(input)}=>{${opBodyCode}};`
        b->B.withPathPrepend(~input, ~path, (b, ~input, ~path as _) => b->B.Val.map(r, input))
      }),
      ~maybeTypeFilter=initialReversed.maybeTypeFilter,
    )
    reversed.reverse = () => schema
    schema.reverse = () => reversed
    reversed
  }

  schema->castUnknownSchemaToAnySchema
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
          let input = if b.code === "" && input.isVar {
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
  let isNode = (definition: 'any) =>
    definition->Stdlib.Type.typeof === #object && definition !== %raw(`null`)

  let toConstant = (Obj.magic: t<'embeded> => unknown)
  let toNode = (Obj.magic: t<'embeded> => node<'embeded>)

  @inline
  let toEmbededItem = (definition: t<'embeded>): option<item> =>
    definition->Obj.magic->Stdlib.Dict.unsafeGetOptionBySymbol(itemSymbol)
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
        !(b.global.flag->Flag.unsafeHas(Flag.typeValidation)) &&
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

      let output = isTransformed
        ? {isVar: false, _scope: b, isAsync: itemOutput.isAsync, inline: ""}
        : input

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
        input.inline,
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
          b->B.asyncVal(`Promise.all(${output.inline})`)
        } else {
          output
        }
      }),
      ~maybeTypeFilter=Some(typeFilter),
      ~reverse=Reverse.onlyChild(~factory, ~schema),
    )
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

  @inline
  let addItemOutput = (~outputs, inlinedLocation, output) => {
    outputs->Js.Dict.set(inlinedLocation, output)
  }

  let toOutputVal = (b, ~outputs, ~outputDefinition) => {
    let output = {
      let rec getItemOutput = item => {
        switch item {
        | {fieldOf: item, inlinedLocation, path} =>
          b->B.Val.get(item->getItemOutput, inlinedLocation, ~path)
        | _ => outputs->Js.Dict.unsafeGet(item.inlinedLocation)
        }
      }

      let rec definitionToOutput = (definition: Definition.t<item>) => {
        if definition->Definition.isNode {
          switch definition->Definition.toEmbededItem {
          | Some(item) => item->getItemOutput
          | None => {
              let node = definition->Definition.toNode
              let isArray = Stdlib.Array.isArray(node)
              let keys = node->Js.Dict.keys

              let objectVal = b->B.Val.Object.make(~isArray)

              for idx in 0 to keys->Js.Array2.length - 1 {
                let key = keys->Js.Array2.unsafe_get(idx)
                let definition = node->Js.Dict.unsafeGet(key)
                let output = definition->definitionToOutput

                objectVal->B.Val.Object.add(
                  isArray ? key : key->Stdlib.Inlined.Value.fromString,
                  output,
                )
              }
              objectVal->B.Val.Object.complete(~isArray)
            }
          }
        } else {
          let constant = definition->Definition.toConstant
          b->B.val(b->B.embed(constant))
        }
      }
      outputDefinition
      ->(Obj.magic: unknown => Definition.t<item>)
      ->definitionToOutput
    }

    output
  }

  let typeFilter = (_b, ~inputVar) => `!${inputVar}||${inputVar}.constructor!==Object`

  let objectStrictModeCheck = (b, ~input, ~inlinedLocations, ~unknownKeys, ~path) => {
    if unknownKeys === Strict && b.global.flag->Flag.unsafeHas(Flag.typeValidation) {
      let key = b->B.allocateVal
      let keyVar = key.inline
      b.code = b.code ++ `for(${keyVar} in ${input.inline}){if(`
      switch inlinedLocations {
      | [] => b.code = b.code ++ "true"
      | _ =>
        for idx in 0 to inlinedLocations->Js.Array2.length - 1 {
          let inlinedLocation = inlinedLocations->Js.Array2.unsafe_get(idx)
          if idx !== 0 {
            b.code = b.code ++ "&&"
          }
          b.code = b.code ++ `${keyVar}!==${inlinedLocation}`
        }
      }
      b.code =
        b.code ++
        `){${b->B.failWithArg(~path, exccessFieldName => ExcessField(exccessFieldName), keyVar)}}}`
    }
  }

  @inline
  let processInputItems = (
    parentB: b,
    ~outputs,
    ~input,
    ~items,
    ~path,
    ~inlinedLocations,
    ~unknownKeys,
  ) => {
    let b = parentB->B.scope

    let inputVar = b->B.Val.var(input)
    let typeFilters = ref("")

    for idx in 0 to items->Js.Array2.length - 1 {
      let schema = items->Js.Array2.unsafe_get(idx)
      let inlinedLocation = inlinedLocations->Js.Array2.unsafe_get(idx)
      let itemPath = inlinedLocation->Path.fromInlinedLocation

      let itemInput = b->B.val(`${inputVar}${itemPath}`)
      let path = path->Path.concat(itemPath)
      let isLiteral = schema->isLiteralSchema

      switch schema.maybeTypeFilter {
      | Some(typeFilter) if isLiteral =>
        // Check literal fields first, because they are most often used as discriminants
        typeFilters :=
          b->B.typeFilterCode(~schema, ~typeFilter, ~input=itemInput, ~path) ++ typeFilters.contents
      | Some(typeFilter) if b.global.flag->Flag.unsafeHas(Flag.typeValidation) =>
        typeFilters :=
          typeFilters.contents ++ b->B.typeFilterCode(~schema, ~typeFilter, ~input=itemInput, ~path)
      | _ => ()
      }

      addItemOutput(~outputs, inlinedLocation, b->B.parse(~schema, ~input=itemInput, ~path))
    }

    b->objectStrictModeCheck(~input, ~inlinedLocations, ~unknownKeys, ~path)

    b.code = typeFilters.contents ++ b.code
    parentB.code = parentB.code ++ b->B.allocateScope
  }

  let builder = (~definition as outputDefinition, ~items, ~inlinedLocations) => (
    b,
    ~input,
    ~selfSchema,
    ~path,
  ) => {
    let outputs = Js.Dict.empty()
    let unknownKeys = (selfSchema->classify->Obj.magic)["unknownKeys"]
    b->processInputItems(~outputs, ~input, ~items, ~path, ~inlinedLocations, ~unknownKeys)
    b->toOutputVal(~outputs, ~outputDefinition)
  }

  type serializeCtx = {@as("d") mutable discriminantCode: string}

  let name = () => {
    let tagged = (%raw(`this`))["t"]
    // TODO: Remove quotes around field name
    `Object({${tagged["fieldNames"]
      ->Js.Array2.map(fieldName => {
        `"${fieldName}": ${(tagged["fields"]->Js.Dict.unsafeGet(fieldName)).name()}`
      })
      ->Js.Array2.joinWith(", ")}})`
  }

  let makeReverseOutput = (b, ~kind, ~items, ~inlinedLocations, ~outputs, ~path) => {
    let fallbackOutput = (schema, ~inlinedLocation, ~path) => {
      if schema->isLiteralSchema {
        b->B.val(b->B.embed(schema->Literal.unsafeFromSchema->Literal.value))
      } else {
        b->B.invalidOperation(~path, ~description=`Schema for ${inlinedLocation} isn't registered`)
      }
    }
    let schemaOutput = (~items, ~inlinedLocations, ~isArray, ~path) => {
      let objectVal = b->B.Val.Object.make(~isArray)
      for idx in 0 to items->Js.Array2.length - 1 {
        let schema = items->Js.Array2.unsafe_get(idx)
        let inlinedLocation = inlinedLocations->Js.Array2.unsafe_get(idx)
        let itemOutput = switch outputs->Stdlib.Dict.unsafeGetOption(inlinedLocation) {
        | Some(o) => o
        | None => schema->fallbackOutput(~inlinedLocation, ~path)
        }
        objectVal->B.Val.Object.add(inlinedLocation, itemOutput)
      }
      objectVal->B.Val.Object.complete(~isArray)
    }

    switch kind {
    | #To =>
      let schema = items->Js.Array2.unsafe_get(0)
      let inlinedLocation = inlinedLocations->Js.Array2.unsafe_get(0)
      switch outputs->Stdlib.Dict.unsafeGetOption(inlinedLocation) {
      | Some(o) => o
      | None => schema->fallbackOutput(~inlinedLocation, ~path)
      }
    | #Object => schemaOutput(~items, ~inlinedLocations, ~isArray=false, ~path)
    | #Array => schemaOutput(~items, ~inlinedLocations, ~isArray=true, ~path)
    }
  }

  let rec proxify = (item: item): 'a =>
    Stdlib.Object.immutableEmpty->Stdlib.Proxy.make({
      get: (~target as _, ~prop) => {
        if prop === itemSymbol->Obj.magic {
          item->Obj.magic
        } else {
          let location = prop->(Obj.magic: unknown => string)
          let inlinedLocation = location->Stdlib.Inlined.Value.fromString

          {
            location,
            inlinedLocation,
            path: inlinedLocation->Path.fromInlinedLocation,
            schema: %raw(`null`),
            fieldOf: item,
          }
          ->proxify
          ->Obj.magic
        }
      },
    })

  let rec reverse = (~definition as inputDefinition, ~kind, ~items, ~inlinedLocations) => () => {
    let inputDefinition = inputDefinition->(Obj.magic: unknown => Definition.t<item>)

    makeReverseSchema(
      ~maybeTypeFilter=None,
      ~name=primitiveName,
      ~tagged=Unknown,
      ~metadataMap=Metadata.Map.empty,
      ~builder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
        if b.global.flag->Flag.unsafeHas(Flag.typeValidation) {
          b->B.invalidOperation(
            ~path,
            ~description="Type validation mode is not supported. Use convert operation instead",
          )
        }

        let inputVar = b->B.Val.var(input)

        let ctx: serializeCtx = {discriminantCode: ""}
        let outputs = Js.Dict.empty()

        let rec definitionToOutput = (definition: Definition.t<item>, ~outputPath) => {
          if definition->Definition.isNode {
            switch definition->Definition.toEmbededItem {
            | Some({fieldOf: _}) =>
              b->B.invalidOperation(~description="Destructuring of items is not supported", ~path)
            | Some(item) =>
              switch outputs->Stdlib.Dict.unsafeGetOption(item.inlinedLocation) {
              | Some(embededOutput) => {
                  let {schema} = item
                  let itemInput =
                    outputPath === Path.empty ? input : b->B.val(`${inputVar}${outputPath}`)
                  let itemOutput =
                    b->B.parse(
                      ~schema=schema.reverse(),
                      ~input=itemInput,
                      ~path=path->Path.concat(outputPath),
                    )

                  b.code =
                    b.code ++
                    `if(${b->B.Val.var(embededOutput)}!==${b->B.Val.var(itemOutput)}){${b->B.fail(
                        ~message=`Multiple sources provided not equal data for ${item.inlinedLocation}`,
                        ~path,
                      )}}`
                }

              | None =>
                let {schema} = item
                let itemInput =
                  outputPath === Path.empty ? input : b->B.val(`${inputVar}${outputPath}`)
                let itemOutput =
                  b->B.parse(
                    ~schema=schema.reverse(),
                    ~input=itemInput,
                    ~path=path->Path.concat(outputPath),
                  )
                addItemOutput(~outputs, item.inlinedLocation, itemOutput)
              }
            | None => {
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
        inputDefinition->definitionToOutput(~outputPath=Path.empty)
        b.code = ctx.discriminantCode ++ b.code

        b->makeReverseOutput(~items, ~inlinedLocations, ~kind, ~outputs, ~path)
      }),
    )
  }
  and to = {
    (schema: t<'value>, definer: 'value => 'variant): t<'variant> => {
      let schema = schema->toUnknown
      let inlinedLocation = `""`

      let item: item = {
        schema,
        path: Path.empty,
        location: "",
        inlinedLocation,
      }
      let definition: unknown = definer(item->proxify)->Obj.magic

      makeSchema(
        ~name=schema.name,
        ~tagged=schema.tagged,
        ~builder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
          let outputs = Js.Dict.empty()
          let itemOutput = b->B.parse(~schema, ~input, ~path)
          addItemOutput(~outputs, inlinedLocation, itemOutput)
          b->toOutputVal(~outputs, ~outputDefinition=definition)
        }),
        ~maybeTypeFilter=schema.maybeTypeFilter,
        ~metadataMap=schema.metadataMap,
        ~reverse=reverse(
          ~definition,
          ~items=[schema],
          ~inlinedLocations=[inlinedLocation],
          ~kind=#To,
        ),
      )
    }
  }
  and factory:
    type value. (s => value) => schema<value> =
    definer => {
      let fieldNames = []
      let inlinedLocations = []
      let fields = Js.Dict.empty()
      let items = []

      let ctx = {
        let flatten = schema => {
          // if schema.definer->Obj.magic {
          //   (schema.definer->Obj.magic)(%raw(`this`))
          // } else {
          InternalError.panic(`The ${schema.name()} schema can't be flattened`)
          // }
        }

        let field:
          type value. (string, schema<value>) => value =
          (fieldName, schema) => {
            let schema = schema->toUnknown
            let inlinedLocation = fieldName->Stdlib.Inlined.Value.fromString
            switch fields->Stdlib.Dict.unsafeGetOption(fieldName) {
            | Some(_) =>
              // if item.schema.definer->Obj.magic && schema.definer->Obj.magic {
              //   (schema.definer->Obj.magic)(item.schema.definerCtx->Obj.magic)->(
              //     Obj.magic: unknown => value
              //   )
              // } else {
              InternalError.panic(
                `The field ${inlinedLocation} defined twice with incompatible schemas`,
              )
            // }
            | None => {
                // let schema = if schema.definer->Obj.magic {
                //   factory(schema.definer->Obj.magic)
                // } else {
                //   schema
                // }
                let item: item = {
                  schema,
                  location: fieldName,
                  inlinedLocation,
                  path: inlinedLocation->Path.fromInlinedLocation,
                }
                fields->Js.Dict.set(fieldName, schema)
                fieldNames->Js.Array2.push(fieldName)->ignore
                inlinedLocations->Js.Array2.push(inlinedLocation)->ignore
                items->Js.Array2.push(schema)->ignore
                // if schema.definer->Obj.magic {
                //   schema->getOutputDefinition->(Obj.magic: unknown => value)
                // } else {
                item->proxify
                // }
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
            | Some(_) =>
              // if item.schema.definer->Obj.magic {
              //   (item.schema.definerCtx->(Obj.magic: option<char> => ctx)).field(
              //     nestedFieldName,
              //     schema,
              //   )->(Obj.magic: unknown => value)
              // } else {
              InternalError.panic(
                `The field ${fieldName->Stdlib.Inlined.Value.fromString} defined twice with incompatible schemas`,
              )
            // }
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
          fieldNames,
          fields,
          unknownKeys: globalConfig.defaultUnknownKeys,
        }),
        builder: builder(~definition, ~items, ~inlinedLocations),
        isAsyncSchema: Unknown,
        maybeTypeFilter: Some(typeFilter),
        name,
        metadataMap: Metadata.Map.empty,
        reverse: reverse(~definition, ~items, ~inlinedLocations, ~kind=#Object),
      }
    }

  let setUnknownKeys = (schema, unknownKeys) => {
    switch schema->classify {
    | Object({unknownKeys: schemaUnknownKeys, fieldNames, fields})
      if schemaUnknownKeys !== unknownKeys => {
        name: schema.name,
        tagged: Object({
          unknownKeys,
          fieldNames,
          fields,
        }),
        builder: schema.builder,
        maybeTypeFilter: schema.maybeTypeFilter,
        isAsyncSchema: schema.isAsyncSchema,
        metadataMap: schema.metadataMap,
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

module Tuple = {
  type s = {
    item: 'value. (int, t<'value>) => 'value,
    tag: 'value. (int, 'value) => unit,
  }

  let name = () => {
    `Tuple(${(%raw(`this`))["t"]["items"]
      ->Js.Array2.map(schema => schema.name())
      ->Js.Array2.joinWith(", ")})`
  }

  @inline
  let typeFilter = (~length) => (b, ~inputVar) =>
    b->Array.typeFilter(~inputVar) ++ `||${inputVar}.length!==${length->Stdlib.Int.unsafeToString}`

  let factory = definer => {
    let items = []
    let inlinedLocations = []

    let ctx: s = {
      let item:
        type value. (int, schema<value>) => value =
        (idx, schema) => {
          let schema = schema->toUnknown
          let inlinedLocation = idx->Js.Int.toString
          if items->Stdlib.Array.has(idx) {
            InternalError.panic(`The item ${inlinedLocation} is defined multiple times`)
          } else {
            let item: item = {
              schema,
              location: inlinedLocation,
              inlinedLocation,
              path: inlinedLocation->Path.fromInlinedLocation,
            }
            items->Js.Array2.unsafe_set(idx, schema)
            inlinedLocations->Js.Array2.unsafe_set(idx, inlinedLocation)
            item->Object.proxify
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
        let inlinedLocation = idx->Js.Int.toString
        items->Js.Array2.unsafe_set(idx, schema)
        inlinedLocations->Js.Array2.unsafe_set(idx, inlinedLocation)
      }
    }

    makeSchema(
      ~name,
      ~tagged=Tuple({
        items: items,
      }),
      ~builder=Object.builder(~definition, ~items, ~inlinedLocations),
      ~maybeTypeFilter=Some(typeFilter(~length)),
      ~metadataMap=Metadata.Map.empty,
      ~reverse=Object.reverse(~definition, ~items, ~inlinedLocations, ~kind=#Array),
    )
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
          `try{${jsonVal.inline}=JSON.parse(${input.inline})}catch(t){${b->B.failWithArg(
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
            let prevOperation = b.global.flag
            b.global.flag = prevOperation->Flag.with(Flag.jsonableOutput)
            if reversed.tagged->unsafeGetVarianTag === "Option" {
              b->B.raise(~code=InvalidJsonSchema(reversed), ~path=Path.empty)
            }
            let output =
              b->B.val(
                `JSON.stringify(${(b->B.parse(~schema=reversed, ~input, ~path)).inline}${space > 0
                    ? `,null,${space->Stdlib.Int.unsafeToString}`
                    : ""})`,
              )
            b.global.flag = prevOperation
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

          if isMultiple && !(b.global.flag->Flag.unsafeHas(Flag.typeValidation)) {
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
        | _ => "throw " ++ b->B.embed(%raw(`exn`)->InternalError.getOrRethrow)
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
            b->B.asyncVal(`Promise.resolve(${output.inline})`)
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

  let builder = (~items, ~inlinedLocations, ~isArray) => (parentB, ~input, ~selfSchema, ~path) => {
    let unknownKeys = (selfSchema->classify->Obj.magic)["unknownKeys"]

    let b = parentB->B.scope

    let typeFilters = ref("")
    let inputVar = b->B.Val.var(input)
    let objectVal = b->B.Val.Object.make(~isArray)

    for idx in 0 to items->Js.Array2.length - 1 {
      let schema = items->Js.Array2.unsafe_get(idx)
      let inlinedLocation = inlinedLocations->Js.Array2.unsafe_get(idx)
      let itemPath = inlinedLocation->Path.fromInlinedLocation

      let itemInput = b->B.val(`${inputVar}${itemPath}`)
      let path = path->Path.concat(itemPath)
      let isLiteral = schema->isLiteralSchema

      switch schema.maybeTypeFilter {
      | Some(typeFilter) if isLiteral =>
        // Check literal fields first, because they are most often used as discriminants
        typeFilters :=
          b->B.typeFilterCode(~schema, ~typeFilter, ~input=itemInput, ~path) ++ typeFilters.contents
      | Some(typeFilter) if b.global.flag->Flag.unsafeHas(Flag.typeValidation) =>
        typeFilters :=
          typeFilters.contents ++ b->B.typeFilterCode(~schema, ~typeFilter, ~input=itemInput, ~path)
      | _ => ()
      }

      objectVal->B.Val.Object.add(inlinedLocation, b->B.parse(~schema, ~input=itemInput, ~path))
    }

    b->Object.objectStrictModeCheck(~input, ~inlinedLocations, ~unknownKeys, ~path)

    b.code = typeFilters.contents ++ b.code
    parentB.code = parentB.code ++ b->B.allocateScope

    if (
      (unknownKeys !== Strip || b.global.flag->Flag.unsafeHas(Flag.reverse)) &&
        selfSchema === selfSchema.reverse()
    ) {
      input
    } else {
      objectVal->B.Val.Object.complete(~isArray)
    }
  }

  let rec definitionToSchema = (definition: unknown) => {
    if definition->Definition.isNode {
      if definition->isSchemaObject {
        definition->(Obj.magic: unknown => schema<unknown>)
      } else if definition->Stdlib.Array.isArray {
        let node = definition->(Obj.magic: unknown => array<unknown>)
        let length = node->Js.Array2.length
        let inlinedLocations = Belt.Array.makeUninitializedUnsafe(length)
        let reversedItems = Belt.Array.makeUninitializedUnsafe(length)
        let isTransformed = ref(false)
        for idx in 0 to node->Js.Array2.length - 1 {
          let schema = node->Js.Array2.unsafe_get(idx)->definitionToSchema
          let reversed = schema.reverse()
          node->Js.Array2.unsafe_set(idx, schema->(Obj.magic: t<unknown> => unknown))
          reversedItems->Js.Array2.unsafe_set(idx, reversed)
          inlinedLocations->Js.Array2.unsafe_set(idx, idx->Js.Int.toString)

          if !isTransformed.contents && schema !== reversed {
            isTransformed := true
          }
        }
        let items = node->(Obj.magic: array<unknown> => array<t<unknown>>)
        let maybeTypeFilter = Some(Tuple.typeFilter(~length))
        makeSchema(
          ~name=Tuple.name,
          ~tagged=Tuple({
            items: items,
          }),
          ~builder=builder(~items, ~inlinedLocations, ~isArray=true),
          ~maybeTypeFilter,
          ~metadataMap=Metadata.Map.empty,
          ~reverse=isTransformed.contents
            ? () =>
                makeReverseSchema(
                  ~name=Tuple.name,
                  ~tagged=Tuple({
                    items: reversedItems,
                  }),
                  ~builder=builder(~items=reversedItems, ~inlinedLocations, ~isArray=true),
                  ~maybeTypeFilter,
                  ~metadataMap=Metadata.Map.empty,
                )
            : Reverse.toSelf,
        )
      } else {
        let node = definition->(Obj.magic: unknown => dict<unknown>)
        let fieldNames = node->Js.Dict.keys
        let length = fieldNames->Js.Array2.length
        let items = Belt.Array.makeUninitializedUnsafe(length)
        let inlinedLocations = Belt.Array.makeUninitializedUnsafe(length)
        let reversedItems = Belt.Array.makeUninitializedUnsafe(length)
        let reversedFields = Js.Dict.empty()
        let isTransformed = ref(false)
        for idx in 0 to length - 1 {
          let location = fieldNames->Js.Array2.unsafe_get(idx)
          let inlinedLocation = `"${location}"` // FIXME: Test a location with "
          let schema = node->Js.Dict.unsafeGet(location)->definitionToSchema
          let reversed = schema.reverse()
          items->Js.Array2.unsafe_set(idx, schema)
          inlinedLocations->Js.Array2.unsafe_set(idx, inlinedLocation)
          reversedItems->Js.Array2.unsafe_set(idx, reversed)
          reversedFields->Js.Dict.set(fieldNames->Js.Array2.unsafe_get(idx), reversed)
          node->Js.Dict.set(location, schema->(Obj.magic: t<unknown> => unknown))
          if !isTransformed.contents && schema !== reversed {
            isTransformed := true
          }
        }
        makeSchema(
          ~name=Object.name,
          ~tagged=Object({
            fieldNames,
            fields: node->(Obj.magic: dict<unknown> => dict<t<unknown>>),
            unknownKeys: globalConfig.defaultUnknownKeys,
          }),
          ~builder=builder(~items, ~inlinedLocations, ~isArray=false),
          ~maybeTypeFilter=Some(Object.typeFilter),
          ~metadataMap=Metadata.Map.empty,
          ~reverse=isTransformed.contents
            ? () => {
                makeReverseSchema(
                  ~name=Object.name,
                  ~tagged=Object({
                    fieldNames,
                    fields: reversedFields,
                    unknownKeys: globalConfig.defaultUnknownKeys,
                  }),
                  ~builder=builder(~items=reversedItems, ~inlinedLocations, ~isArray=false),
                  ~maybeTypeFilter=Some(Object.typeFilter),
                  ~metadataMap=Metadata.Map.empty,
                )
              }
            : Reverse.toSelf,
        )
      }
    } else {
      literal(definition)
    }
  }

  let matches:
    type value. schema<value> => value =
    schema => schema->(Obj.magic: schema<value> => value)

  let ctx = {
    matches: matches,
  }

  let factory = definer => {
    definer(ctx->(Obj.magic: s => 'value))
    ->(Obj.magic: 'definition => unknown)
    ->definitionToSchema
    ->castUnknownSchemaToAnySchema
  }
}

let schema = Schema.factory

let js_schema = Schema.definitionToSchema

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
    | InvalidJsonSchema(schema) => `The ${schema.name()} schema is not compatible with JSON`
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
    let op = error.flag

    let text = ref(
      "Failed " ++ if op->Flag.unsafeHas(Flag.typeValidation) {
        if op->Flag.unsafeHas(Flag.assertOutput) {
          "asserting"
        } else {
          "parsing"
        }
      } else {
        "converting"
      },
    )

    if op->Flag.unsafeHas(Flag.reverse) {
      text := text.contents ++ " reverse"
    }
    if op->Flag.unsafeHas(Flag.async) {
      text := text.contents ++ " async"
    }
    if op->Flag.unsafeHas(Flag.jsonableOutput) {
      text :=
        text.contents ++ " to JSON" ++ (op->Flag.unsafeHas(Flag.jsonStringOutput) ? " string" : "")
    }

    let pathText = switch error.path {
    | "" => "root"
    | nonEmptyPath => nonEmptyPath
    }
    `${text.contents} at ${pathText}. Reason: ${error->reason}`
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
    | Tuple({items: [s0]}) => `S.tuple1(${s0->internalInline()})`
    | Tuple({items: [s0, s1]}) => `S.tuple2(${s0->internalInline()}, ${s1->internalInline()})`
    | Tuple({items: [s0, s1, s2]}) =>
      `S.tuple3(${s0->internalInline()}, ${s1->internalInline()}, ${s2->internalInline()})`
    | Tuple({items}) =>
      `S.tuple(s => (${items
        ->Js.Array2.mapi((schema, idx) =>
          `s.item(${idx->Stdlib.Int.unsafeToString}, ${schema->internalInline()})`
        )
        ->Js.Array2.joinWith(", ")}))`
    | Object({fieldNames: []}) => `S.object(_ => ())`
    | Object({fieldNames, fields}) =>
      `S.object(s =>
  {
    ${fieldNames
        ->Js.Array2.map(fieldName => {
          let schema = fields->Js.Dict.unsafeGet(fieldName)
          let inlinedLocation = fieldName->Stdlib.Inlined.Value.fromString
          `${inlinedLocation}: s.field(${inlinedLocation}, ${schema->internalInline()})`
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
    | Some(variant) => inlinedSchema ++ `->S.to(v => ${variant}(v))`
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
let variant = Object.to
let to = Object.to
let tuple = Tuple.factory
let tuple1 = v0 => tuple(s => s.item(0, v0))
let tuple2 = (v0, v1) =>
  Schema.definitionToSchema([v0->toUnknown, v1->toUnknown]->Obj.magic)->castUnknownSchemaToAnySchema
let tuple3 = (v0, v1, v2) =>
  Schema.definitionToSchema(
    [v0->toUnknown, v1->toUnknown, v2->toUnknown]->Obj.magic,
  )->castUnknownSchemaToAnySchema
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

// =============
// JS/TS API
// =============

let js_union = values => Union.factory(values->Js.Array2.map(Schema.definitionToSchema))

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

let js_merge = (s1, s2) => {
  switch (s1, s2) {
  | (
      {tagged: Object({fieldNames: s1FieldNames, fields: s1Fields})},
      {tagged: Object({fieldNames: s2FieldNames, fields: s2Fields, unknownKeys})},
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
        InternalError.panic(`The field "${fieldName}" is defined multiple times`)
      }
      fieldNames->Js.Array2.push(fieldName)->ignore
      fields->Js.Dict.set(fieldName, s2Fields->Js.Dict.unsafeGet(fieldName))
    }
    makeSchema(
      ~name=() => `${s1.name()} & ${s2.name()}`,
      ~tagged=Object({
        unknownKeys,
        fieldNames,
        fields,
      }),
      ~builder=Builder.make((b, ~input, ~selfSchema as _, ~path) => {
        let s1Result = b->B.parse(~schema=s1, ~input, ~path)
        let s2Result = b->B.parse(~schema=s2, ~input, ~path)
        // TODO: Check that these are objects
        // TODO: Check that s1Result is not mutating input
        b->B.val(`Object.assign(${s1Result.inline}, ${s2Result.inline})`)
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
    resetOperationsCache(float)
  }
}
