type never
type unknown

module Lib = {
  module Promise = {
    type t<+'a> = Js.Promise.t<'a>

    @send
    external thenResolve: (t<'a>, @uncurry ('a => 'b)) => t<'b> = "then"

    @send external then: (t<'a>, @uncurry ('a => t<'b>)) => t<'b> = "then"

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
      data->Js.typeof === "object" && !Js.Array2.isArray(data) && data !== %raw(`null`)
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
      data->Js.typeof === "number" && x < 2147483648. && x > -2147483649. && x === x->Js.Math.trunc
    }
  }

  module Exn = {
    let throw: exn => 'a = %raw(`function(exn){throw exn}`)
  }
}

module Error = {
  %%raw(`class RescriptStructError extends Error {
    constructor(message) {
      super(message);
      this.name = "RescriptStructError";
    }
  }`)

  let panic = %raw(`function(message){throw new RescriptStructError(message)}`)

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

  module Unreachable = {
    let panic = () => panic("Unreachable")
  }

  module UnknownKeysRequireRecord = {
    let panic = () => panic("Can't set up unknown keys strategy. The struct is not Record")
  }

  module UnionLackingStructs = {
    let panic = () => panic("A Union struct factory require at least two structs")
  }

  let formatPath = path => {
    if path->Js.Array2.length === 0 {
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
    | UnexpectedAsync => "Encountered unexpected asynchronous transform or refine. Use parseAsyncWith instead of parseWith"
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
type operation =
  | Noop
  | Sync((. unknown) => unknown)
  | Async((. unknown, . unit) => Js.Promise.t<unknown>)
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
  safeParseActionFactories: array<actionFactory>,
  @as("mp")
  migrationParseActionFactories: array<actionFactory>,
  @as("sa")
  serializeActionFactories: array<actionFactory>,
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
  | SyncTransform((. unknown) => unknown)
  | AsyncTransform((. unknown) => Js.Promise.t<unknown>)
and actionFactory = (. ~struct: t<unknown>, ~mode: parsingMode) => action

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

let makeOperation = (~actionFactories, ~struct, ~mode) => {
  switch actionFactories {
  | [] => Noop
  | _ =>
    let lastActionIdx = actionFactories->Js.Array2.length - 1
    let lastSyncActionIdxRef = ref(lastActionIdx)
    let actions = []
    for idx in 0 to lastSyncActionIdxRef.contents {
      let actionFactory = actionFactories->Js.Array2.unsafe_get(idx)
      let action = actionFactory(. ~struct, ~mode)
      actions->Js.Array2.push(action)->ignore
      if lastSyncActionIdxRef.contents === lastActionIdx {
        switch action {
        | AsyncTransform(_) => lastSyncActionIdxRef.contents = idx - 1
        | SyncTransform(_) => ()
        }
      }
    }

    let syncOperation = switch lastSyncActionIdxRef.contents === 0 {
    // Shortcut to get a fn of the first SyncTransform
    | true => (actions->Js.Array2.unsafe_get(0)->Obj.magic)._0
    | false =>
      (. input) => {
        let tempOuputRef = ref(input->Obj.magic)
        for idx in 0 to lastSyncActionIdxRef.contents {
          let action = actions->Js.Array2.unsafe_get(idx)
          // Shortcut to get SyncTransform fn
          let newValue = (action->Obj.magic)._0(. tempOuputRef.contents)
          tempOuputRef.contents = newValue
        }
        tempOuputRef.contents
      }
    }

    switch lastActionIdx === lastSyncActionIdxRef.contents {
    | true => Sync(syncOperation)
    | false =>
      Async(
        (. input) => {
          let syncOutput = switch lastSyncActionIdxRef.contents {
          // For the case when an async action is the first
          | -1 => input
          | _ => syncOperation(. input)
          }
          (. ()) => {
            let tempOuputRef = ref(syncOutput->Lib.Promise.resolve)
            for idx in lastSyncActionIdxRef.contents + 1 to lastActionIdx {
              let action = actions->Js.Array2.unsafe_get(idx)
              tempOuputRef.contents =
                tempOuputRef.contents->Lib.Promise.then(tempOutput => {
                  switch action {
                  | SyncTransform(fn) => fn(. tempOutput)->Lib.Promise.resolve
                  | AsyncTransform(fn) => fn(. tempOutput)
                  }
                })
            }
            tempOuputRef.contents
          }
        },
      )
    }
  }
}

let make = (
  ~tagged_t,
  ~safeParseActionFactories,
  ~migrationParseActionFactories,
  ~serializeActionFactories,
  ~metadata as maybeMetadata=?,
  (),
) => {
  let struct = {
    tagged_t: tagged_t,
    safeParseActionFactories: safeParseActionFactories,
    migrationParseActionFactories: migrationParseActionFactories,
    serializeActionFactories: serializeActionFactories,
    serialize: %raw("undefined"),
    parseOperations: %raw("undefined"),
    maybeMetadata: maybeMetadata,
  }
  {
    ...struct,
    serialize: makeOperation(~actionFactories=struct.serializeActionFactories, ~struct, ~mode=Safe),
    parseOperations: {
      safe: makeOperation(~actionFactories=struct.safeParseActionFactories, ~struct, ~mode=Safe),
      migration: makeOperation(
        ~actionFactories=struct.migrationParseActionFactories,
        ~struct,
        ~mode=Migration,
      ),
    },
  }
}

@inline
let getParseOperation = (struct: t<'value>, ~mode: parsingMode): operation => {
  struct.parseOperations->Obj.magic->Js.Dict.unsafeGet(mode->Obj.magic)
}

let parseWith = (any, ~mode=Safe, struct) => {
  try {
    switch struct->getParseOperation(~mode) {
    | Noop => any->Obj.magic->Ok
    | Sync(fn) => fn(. any->Obj.magic)->Obj.magic->Ok
    | Async(_) => Error.Internal.raise(UnexpectedAsync)
    }
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  }
}

let parseAsyncWith = (any, ~mode=Safe, struct) => {
  try {
    switch struct->getParseOperation(~mode) {
    | Noop => any->Obj.magic->Ok->Lib.Promise.resolve->Ok
    | Sync(fn) => fn(. any->Obj.magic)->Ok->Obj.magic->Lib.Promise.resolve->Ok
    | Async(fn) =>
      fn(. any->Obj.magic)(.)
      ->Lib.Promise.thenResolve(value => Ok(value->Obj.magic))
      ->Lib.Promise.catch(exn => {
        switch exn {
        | Error.Internal.Exception(internalError) =>
          internalError->Error.Internal.toParseError->Error
        | _ => exn->Lib.Exn.throw
        }
      })
      ->Ok
    }
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  }
}

@inline
let serializeInner: (~struct: t<'value>, ~value: 'value) => unknown = (~struct, ~value) => {
  switch struct.serialize {
  | Noop => value->unsafeAnyToUnknown
  | Sync(fn) => fn(. value->unsafeAnyToUnknown)
  | Async(_) => Error.Unreachable.panic()
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
  @inline
  let factory = (fn: (. ~struct: t<'value>, ~mode: parsingMode) => action): actionFactory => fn

  @inline
  let make = (action: action): actionFactory => (. ~struct as _, ~mode as _) => action

  let emptyArray: array<actionFactory> = []

  let concatParser = (parsers, parser) => {
    parsers->Js.Array2.concat([parser])
  }

  let concatSerializer = (serializers, serializer) => {
    [serializer]->Js.Array2.concat(serializers)
  }

  let missingParser = make(
    SyncTransform(
      (. _) => {
        Error.Internal.raise(MissingParser)
      },
    ),
  )

  let missingSerializer = make(
    SyncTransform(
      (. _) => {
        Error.Internal.raise(MissingSerializer)
      },
    ),
  )
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
  if maybeRefineParser === None && maybeRefineSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Refine`)
  }

  let maybeParseActionFactory = maybeRefineParser->Lib.Option.map(refineParser => {
    Action.make(
      SyncTransform(
        (. input) => {
          switch (refineParser->Obj.magic)(. input) {
          | None => input
          | Some(reason) => Error.Internal.raise(OperationFailed(reason))
          }
        },
      ),
    )
  })

  make(
    ~tagged_t=struct.tagged_t,
    ~safeParseActionFactories=switch maybeParseActionFactory {
    | Some(parseActionFactory) =>
      struct.safeParseActionFactories->Action.concatParser(parseActionFactory)
    | None => struct.safeParseActionFactories
    },
    ~migrationParseActionFactories=switch maybeParseActionFactory {
    | Some(parseActionFactory) =>
      struct.migrationParseActionFactories->Action.concatParser(parseActionFactory)
    | None => struct.migrationParseActionFactories
    },
    ~serializeActionFactories=switch maybeRefineSerializer {
    | Some(refineSerializer) =>
      struct.serializeActionFactories->Action.concatSerializer(
        Action.make(
          SyncTransform(
            (. input) => {
              switch (refineSerializer->Obj.magic)(. input) {
              | None => input
              | Some(reason) => Error.Internal.raise(OperationFailed(reason))
              }
            },
          ),
        ),
      )
    | None => struct.serializeActionFactories
    },
    ~metadata=?struct.maybeMetadata,
    (),
  )
}

let asyncRefine = (struct, ~parser, ()) => {
  let parseActionFactory = Action.make(
    AsyncTransform(
      (. input) => {
        (parser->Obj.magic)(. input)->Lib.Promise.thenResolve(result => {
          switch result {
          | None => input
          | Some(reason) => Error.Internal.raise(OperationFailed(reason))
          }
        })
      },
    ),
  )

  make(
    ~tagged_t=struct.tagged_t,
    ~safeParseActionFactories=struct.safeParseActionFactories->Action.concatParser(
      parseActionFactory,
    ),
    ~migrationParseActionFactories=struct.migrationParseActionFactories->Action.concatParser(
      parseActionFactory,
    ),
    ~serializeActionFactories=struct.serializeActionFactories,
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
  if maybeTransformationParser === None && maybeTransformationSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Transform`)
  }
  let parseActionFactory = switch maybeTransformationParser {
  | Some(transformationParser) =>
    Action.make(
      SyncTransform(
        (. input) => {
          switch (transformationParser->Obj.magic)(. input) {
          | Ok(transformed) => transformed
          | Error(reason) => Error.Internal.raise(OperationFailed(reason))
          }
        },
      ),
    )
  | None => Action.missingParser
  }
  make(
    ~tagged_t=struct.tagged_t,
    ~safeParseActionFactories=struct.safeParseActionFactories->Action.concatParser(
      parseActionFactory,
    ),
    ~migrationParseActionFactories=struct.migrationParseActionFactories->Action.concatParser(
      parseActionFactory,
    ),
    ~serializeActionFactories=struct.serializeActionFactories->Action.concatSerializer(
      switch maybeTransformationSerializer {
      | Some(transformationSerializer) =>
        Action.make(
          SyncTransform(
            (. input) => {
              switch (transformationSerializer->Obj.magic)(. input) {
              | Ok(value) => value
              | Error(reason) => Error.Internal.raise(OperationFailed(reason))
              }
            },
          ),
        )
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
  if maybeTransformationParser === None && maybeTransformationSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Transform`)
  }

  let parseActionFactory = switch maybeTransformationParser {
  | Some(transformationParser) =>
    Action.factory((. ~struct, ~mode) => SyncTransform(
      (. input) => {
        switch (transformationParser->Obj.magic)(. ~value=input, ~struct, ~mode) {
        | Ok(transformed) => transformed
        | Error(public) => raise(Error.Internal.Exception(public->Error.Internal.fromPublic))
        }
      },
    ))
  | None => Action.missingParser
  }
  make(
    ~tagged_t=struct.tagged_t,
    ~safeParseActionFactories=struct.safeParseActionFactories->Action.concatParser(
      parseActionFactory,
    ),
    ~migrationParseActionFactories=struct.migrationParseActionFactories->Action.concatParser(
      parseActionFactory,
    ),
    ~serializeActionFactories=struct.serializeActionFactories->Action.concatSerializer(
      switch maybeTransformationSerializer {
      | Some(transformationSerializer) =>
        Action.make(
          SyncTransform(
            (. input) => {
              switch (transformationSerializer->Obj.magic)(. ~transformed=input, ~struct) {
              | Ok(value) => value
              | Error(public) => raise(Error.Internal.Exception(public->Error.Internal.fromPublic))
              }
            },
          ),
        )
      | None => Action.missingSerializer
      },
    ),
    ~metadata=?struct.maybeMetadata,
    (),
  )
}

let custom = (~parser as maybeCustomParser=?, ~serializer as maybeCustomSerializer=?, ()) => {
  if maybeCustomParser === None && maybeCustomSerializer === None {
    Error.MissingParserAndSerializer.panic(`Custom struct factory`)
  }

  let parseActions = [
    switch maybeCustomParser {
    | Some(customParser) =>
      Action.factory((. ~struct as _, ~mode) => SyncTransform(
        (. input) => {
          let input = input->unsafeUnknownToAny
          switch customParser(. ~unknown=input, ~mode) {
          | Ok(value) => value->unsafeAnyToUnknown
          | Error(public) => raise(Error.Internal.Exception(public->Error.Internal.fromPublic))
          }
        },
      ))
    | None => Action.missingParser
    },
  ]

  make(
    ~tagged_t=Unknown,
    ~migrationParseActionFactories=parseActions,
    ~safeParseActionFactories=parseActions,
    ~serializeActionFactories=[
      switch maybeCustomSerializer {
      | Some(customSerializer) =>
        Action.make(
          SyncTransform(
            (. input) => {
              let input = input->unsafeUnknownToAny
              switch customSerializer(. ~value=input) {
              | Ok(value) => value->unsafeAnyToUnknown
              | Error(public) => raise(Error.Internal.Exception(public->Error.Internal.fromPublic))
              }
            },
          ),
        )
      | None => Action.missingSerializer
      },
    ],
    (),
  )
}

module Literal = {
  module CommonOperations = {
    module Parser = {
      let literalValueRefinement = Action.factory((. ~struct, ~mode as _) => SyncTransform(
        (. input) => {
          let expectedValue = struct->classify->unsafeGetVariantPayload->unsafeGetVariantPayload
          switch expectedValue === input {
          | true => input
          | false => Error.Internal.UnexpectedValue.raise(~expected=expectedValue, ~received=input)
          }
        },
      ))
    }

    let transformToLiteralValue = Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. _) => {
        struct->classify->unsafeGetVariantPayload->unsafeGetVariantPayload
      },
    ))
  }

  module EmptyNull = {
    let parserRefinement = Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. input) => {
        if input->unsafeUnknownToAny !== Js.Null.empty {
          raiseUnexpectedTypeError(~input, ~struct)
        } else {
          input
        }
      },
    ))

    let serializerTransform = Action.make(
      SyncTransform(
        (. _) => {
          Js.Null.empty->unsafeAnyToUnknown
        },
      ),
    )
  }

  module EmptyOption = {
    let parserRefinement = Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. input) => {
        if input->unsafeUnknownToAny !== Js.Undefined.empty {
          raiseUnexpectedTypeError(~input, ~struct)
        } else {
          input
        }
      },
    ))

    let serializerTransform = Action.make(
      SyncTransform(
        (. _) => {
          Js.Undefined.empty->unsafeAnyToUnknown
        },
      ),
    )
  }

  module NaN = {
    let parserRefinement = Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. input) => {
        if !Js.Float.isNaN(input->unsafeUnknownToAny) {
          raiseUnexpectedTypeError(~input, ~struct)
        } else {
          input
        }
      },
    ))

    let serializerTransform = Action.make(
      SyncTransform(
        (. _) => {
          Js.Float._NaN->unsafeAnyToUnknown
        },
      ),
    )
  }

  module Bool = {
    let parserRefinement = Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. input) => {
        if input->Js.typeof !== "boolean" {
          raiseUnexpectedTypeError(~input, ~struct)
        } else {
          input
        }
      },
    ))
  }

  module String = {
    let parserRefinement = Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. input) => {
        if input->Js.typeof !== "string" {
          raiseUnexpectedTypeError(~input, ~struct)
        } else {
          input
        }
      },
    ))
  }

  module Float = {
    let parserRefinement = Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. input) => {
        if input->Js.typeof !== "number" {
          raiseUnexpectedTypeError(~input, ~struct)
        } else {
          input
        }
      },
    ))
  }

  module Int = {
    let parserRefinement = Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. input) => {
        if !Lib.Int.test(input) {
          raiseUnexpectedTypeError(~input, ~struct)
        } else {
          input
        }
      },
    ))
  }

  module Variant = {
    let factory:
      type literalValue variant. (literal<literalValue>, variant) => t<variant> =
      (innerLiteral, variant) => {
        let tagged_t = Literal(innerLiteral)
        let parserTransform = Action.make(
          SyncTransform(
            (. _) => {
              variant->unsafeAnyToUnknown
            },
          ),
        )
        let serializerRefinement = Action.make(
          SyncTransform(
            (. input) => {
              if input !== variant->unsafeAnyToUnknown {
                Error.Internal.UnexpectedValue.raise(
                  ~expected=variant->unsafeAnyToUnknown,
                  ~received=input,
                )
              } else {
                input
              }
            },
          ),
        )
        switch innerLiteral {
        | EmptyNull =>
          make(
            ~tagged_t,
            ~safeParseActionFactories=[EmptyNull.parserRefinement, parserTransform],
            ~migrationParseActionFactories=[parserTransform],
            ~serializeActionFactories=[serializerRefinement, EmptyNull.serializerTransform],
            (),
          )
        | EmptyOption =>
          make(
            ~tagged_t,
            ~safeParseActionFactories=[EmptyOption.parserRefinement, parserTransform],
            ~migrationParseActionFactories=[parserTransform],
            ~serializeActionFactories=[serializerRefinement, EmptyOption.serializerTransform],
            (),
          )
        | NaN =>
          make(
            ~tagged_t,
            ~safeParseActionFactories=[NaN.parserRefinement, parserTransform],
            ~migrationParseActionFactories=[parserTransform],
            ~serializeActionFactories=[serializerRefinement, NaN.serializerTransform],
            (),
          )
        | Bool(_) =>
          make(
            ~tagged_t,
            ~safeParseActionFactories=[
              Bool.parserRefinement,
              CommonOperations.Parser.literalValueRefinement,
              parserTransform,
            ],
            ~migrationParseActionFactories=[parserTransform],
            ~serializeActionFactories=[
              serializerRefinement,
              CommonOperations.transformToLiteralValue,
            ],
            (),
          )
        | String(_) =>
          make(
            ~tagged_t,
            ~safeParseActionFactories=[
              String.parserRefinement,
              CommonOperations.Parser.literalValueRefinement,
              parserTransform,
            ],
            ~migrationParseActionFactories=[parserTransform],
            ~serializeActionFactories=[
              serializerRefinement,
              CommonOperations.transformToLiteralValue,
            ],
            (),
          )
        | Float(_) =>
          make(
            ~tagged_t,
            ~safeParseActionFactories=[
              Float.parserRefinement,
              CommonOperations.Parser.literalValueRefinement,
              parserTransform,
            ],
            ~migrationParseActionFactories=[parserTransform],
            ~serializeActionFactories=[
              serializerRefinement,
              CommonOperations.transformToLiteralValue,
            ],
            (),
          )
        | Int(_) =>
          make(
            ~tagged_t,
            ~safeParseActionFactories=[
              Int.parserRefinement,
              CommonOperations.Parser.literalValueRefinement,
              parserTransform,
            ],
            ~migrationParseActionFactories=[parserTransform],
            ~serializeActionFactories=[
              serializerRefinement,
              CommonOperations.transformToLiteralValue,
            ],
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
    . unknown,
    Js.Dict.t<t<unknown>>,
  ) => option<string> = %raw(`function(object, innerStructsDict) {
    for (var key in object) {
      if (!Object.prototype.hasOwnProperty.call(innerStructsDict, key)) {
        return key
      }
    }
  }`)

  let serializeActionFactories = [
    Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. input) => {
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
          | Async(_) => Error.Unreachable.panic()
          }
        }
        unknown->unsafeAnyToUnknown
      },
    )),
  ]

  let innerFactory = fieldsArray => {
    let fields = fieldsArray->Js.Dict.fromArray
    let fieldNames = fields->Js.Dict.keys

    let makeParseActions = (~mode) => {
      let noopOps = []
      let syncOps = []
      let asyncOps = []
      for idx in 0 to fieldNames->Js.Array2.length - 1 {
        let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
        let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
        switch fieldStruct->getParseOperation(~mode) {
        | Noop => noopOps->Js.Array2.push((idx, fieldName))->ignore
        | Sync(fn) => syncOps->Js.Array2.push((idx, fieldName, fn))->ignore
        | Async(fn) => {
            syncOps->Js.Array2.push((idx, fieldName, fn->Obj.magic))->ignore
            asyncOps->Js.Array2.push((idx, fieldName))->ignore
          }
        }
      }
      let withAsyncOps = asyncOps->Js.Array2.length > 0

      let parseActions = [
        Action.factory((. ~struct, ~mode) => SyncTransform(
          (. input) => {
            if mode === Safe && input->Lib.Object.test === false {
              raiseUnexpectedTypeError(~input, ~struct)
            }

            let newArray = []

            for idx in 0 to syncOps->Js.Array2.length - 1 {
              let (originalIdx, fieldName, fn) = syncOps->Js.Array2.unsafe_get(idx)
              let fieldData = input->unsafeUnknownToAny->Js.Dict.unsafeGet(fieldName)
              try {
                let value = fn(. fieldData)
                newArray->Lib.Array.set(originalIdx, value)
              } catch {
              | Error.Internal.Exception(internalError) =>
                raise(
                  Error.Internal.Exception(
                    internalError->Error.Internal.prependLocation(fieldName),
                  ),
                )
              }
            }

            for idx in 0 to noopOps->Js.Array2.length - 1 {
              let (originalIdx, fieldName) = noopOps->Js.Array2.unsafe_get(idx)
              let fieldData = input->unsafeUnknownToAny->Js.Dict.unsafeGet(fieldName)
              newArray->Lib.Array.set(originalIdx, fieldData)
            }

            let {unknownKeys} = struct->classify->Obj.magic
            if unknownKeys === Strict && mode === Safe {
              switch getMaybeExcessKey(. input, fields) {
              | Some(excessKey) => Error.Internal.raise(ExcessField(excessKey))
              | None => ()
              }
            }

            withAsyncOps ? newArray->unsafeAnyToUnknown : newArray->Lib.Array.toTuple
          },
        )),
      ]

      if withAsyncOps {
        parseActions
        ->Js.Array2.push(
          Action.make(
            AsyncTransform(
              (. tempArray) => {
                asyncOps
                ->Js.Array2.map(((originalIdx, fieldName)) => {
                  (
                    tempArray->unsafeUnknownToAny->Js.Array2.unsafe_get(originalIdx)->Obj.magic
                  )(.)->Lib.Promise.catch(exn => {
                    switch exn {
                    | Error.Internal.Exception(internalError) =>
                      Error.Internal.Exception(
                        internalError->Error.Internal.prependLocation(fieldName),
                      )
                    | _ => exn
                    }->Lib.Exn.throw
                  })
                })
                ->Lib.Promise.all
                ->Lib.Promise.thenResolve(asyncFieldValues => {
                  asyncFieldValues->Js.Array2.forEachi((fieldValue, idx) => {
                    let (originalIdx, _) = asyncOps->Js.Array2.unsafe_get(idx)
                    tempArray->unsafeUnknownToAny->Lib.Array.set(originalIdx, fieldValue)
                  })
                  tempArray->unsafeAnyToUnknown
                })
              },
            ),
          ),
        )
        ->ignore
      }

      parseActions
    }

    make(
      ~tagged_t=Record({fields: fields, fieldNames: fieldNames, unknownKeys: Strict}),
      ~safeParseActionFactories=makeParseActions(~mode=Safe),
      ~migrationParseActionFactories=makeParseActions(~mode=Migration),
      ~serializeActionFactories,
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
        ~safeParseActionFactories=struct.safeParseActionFactories,
        ~migrationParseActionFactories=struct.migrationParseActionFactories,
        ~serializeActionFactories=struct.serializeActionFactories,
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
        ~safeParseActionFactories=struct.safeParseActionFactories,
        ~migrationParseActionFactories=struct.migrationParseActionFactories,
        ~serializeActionFactories=struct.serializeActionFactories,
        ~metadata=?struct.maybeMetadata,
        (),
      )
    | _ => Error.UnknownKeysRequireRecord.panic()
    }
  }
}

module Never = {
  let actions = [
    Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. input) => {
        raiseUnexpectedTypeError(~input, ~struct)
      },
    )),
  ]

  let factory = () => {
    make(
      ~tagged_t=Never,
      ~safeParseActionFactories=actions,
      ~migrationParseActionFactories=Action.emptyArray,
      ~serializeActionFactories=actions,
      (),
    )
  }
}

module Unknown = {
  let factory = () => {
    make(
      ~tagged_t=Unknown,
      ~safeParseActionFactories=Action.emptyArray,
      ~migrationParseActionFactories=Action.emptyArray,
      ~serializeActionFactories=Action.emptyArray,
      (),
    )
  }
}

module String = {
  let cuidRegex = %re(`/^c[^\s-]{8,}$/i`)
  let uuidRegex = %re(`/^([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[a-f0-9]{4}-[a-f0-9]{12}|00000000-0000-0000-0000-000000000000)$/i`)
  let emailRegex = %re(`/^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i`)

  let parserRefinement = Action.factory((. ~struct, ~mode as _) => SyncTransform(
    (. input) => {
      if input->Js.typeof !== "string" {
        raiseUnexpectedTypeError(~input, ~struct)
      } else {
        input
      }
    },
  ))

  let factory = () => {
    make(
      ~tagged_t=String,
      ~safeParseActionFactories=[parserRefinement],
      ~migrationParseActionFactories=Action.emptyArray,
      ~serializeActionFactories=Action.emptyArray,
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
      switch value->Js.String2.length === length {
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
  let parserRefinement = Action.factory((. ~struct, ~mode as _) => SyncTransform(
    (. input) => {
      if input->Js.typeof !== "boolean" {
        raiseUnexpectedTypeError(~input, ~struct)
      } else {
        input
      }
    },
  ))

  let factory = () => {
    make(
      ~tagged_t=Bool,
      ~safeParseActionFactories=[parserRefinement],
      ~migrationParseActionFactories=Action.emptyArray,
      ~serializeActionFactories=Action.emptyArray,
      (),
    )
  }
}

module Int = {
  let parserRefinement = Action.factory((. ~struct, ~mode as _) => SyncTransform(
    (. input) => {
      if !Lib.Int.test(input) {
        raiseUnexpectedTypeError(~input, ~struct)
      } else {
        input
      }
    },
  ))

  let factory = () => {
    make(
      ~tagged_t=Int,
      ~safeParseActionFactories=[parserRefinement],
      ~migrationParseActionFactories=Action.emptyArray,
      ~serializeActionFactories=Action.emptyArray,
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
  let parserRefinement = Action.factory((. ~struct, ~mode as _) => SyncTransform(
    (. input) => {
      switch input->Js.typeof === "number" {
      | true =>
        if Js.Float.isNaN(input->unsafeUnknownToAny) {
          raiseUnexpectedTypeError(~input, ~struct)
        } else {
          input
        }
      | false => raiseUnexpectedTypeError(~input, ~struct)
      }
    },
  ))

  let factory = () => {
    make(
      ~tagged_t=Float,
      ~safeParseActionFactories=[parserRefinement],
      ~migrationParseActionFactories=Action.emptyArray,
      ~serializeActionFactories=Action.emptyArray,
      (),
    )
  }

  let min = Int.min->Obj.magic
  let max = Int.max->Obj.magic
}

module Date = {
  let parserRefinement = Action.factory((. ~struct, ~mode as _) => SyncTransform(
    (. input) => {
      let factory = struct->classify->unsafeGetVariantPayload
      if (
        !(
          factory->Lib.Factory.factoryOf(input) &&
            !(input->unsafeUnknownToAny->Js.Date.getTime->Js.Float.isNaN)
        )
      ) {
        raiseUnexpectedTypeError(~input, ~struct)
      } else {
        input
      }
    },
  ))

  let factory = () => {
    make(
      ~tagged_t=Instance(%raw(`Date`)),
      ~safeParseActionFactories=[parserRefinement],
      ~migrationParseActionFactories=Action.emptyArray,
      ~serializeActionFactories=Action.emptyArray,
      (),
    )
  }
}

module Null = {
  let serializeActionFactories = [
    Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. input) => {
        switch input->unsafeUnknownToAny {
        | Some(value) =>
          let innerStruct = struct->classify->unsafeGetVariantPayload
          serializeInner(~struct=innerStruct->Obj.magic, ~value)
        | None => Js.Null.empty->unsafeAnyToUnknown
        }
      },
    )),
  ]

  let factory = innerStruct => {
    let makeSyncParseAction = fn => {
      Action.make(
        SyncTransform(
          (. input) => {
            switch input->unsafeUnknownToAny->Js.Null.toOption {
            | Some(innerData) => Some(fn(. innerData))
            | None => None
            }->unsafeAnyToUnknown
          },
        ),
      )
    }

    let makeParseActions = (~mode) => {
      switch innerStruct->getParseOperation(~mode) {
      | Noop => [
          Action.make(
            SyncTransform(
              (. input) => {
                input->unsafeUnknownToAny->Js.Null.toOption->unsafeAnyToUnknown
              },
            ),
          ),
        ]
      | Sync(fn) => [makeSyncParseAction(fn)]
      | Async(fn) => [
          makeSyncParseAction(fn),
          Action.make(
            AsyncTransform(
              (. input) => {
                switch input->unsafeUnknownToAny {
                | Some(asyncFn) =>
                  asyncFn(.)->Lib.Promise.thenResolve(value => Some(value)->unsafeAnyToUnknown)
                | None => None->unsafeAnyToUnknown->Lib.Promise.resolve
                }
              },
            ),
          ),
        ]
      }
    }

    make(
      ~tagged_t=Null(innerStruct),
      ~safeParseActionFactories=makeParseActions(~mode=Safe),
      ~migrationParseActionFactories=makeParseActions(~mode=Migration),
      ~serializeActionFactories,
      (),
    )
  }
}

module Option = {
  let serializeActionFactories = [
    Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. input) => {
        switch input->unsafeUnknownToAny {
        | Some(value) => {
            let innerStruct = struct->classify->unsafeGetVariantPayload
            serializeInner(~struct=innerStruct, ~value)
          }
        | None => Js.Undefined.empty->unsafeAnyToUnknown
        }
      },
    )),
  ]

  let factory = innerStruct => {
    let makeSyncParseAction = fn => {
      Action.make(
        SyncTransform(
          (. input) => {
            switch input->unsafeUnknownToAny {
            | Some(innerData) => Some(fn(. innerData))
            | None => None
            }->unsafeAnyToUnknown
          },
        ),
      )
    }

    let makeParseActions = (~mode) => {
      switch innerStruct->getParseOperation(~mode) {
      | Noop => Action.emptyArray
      | Sync(fn) => [makeSyncParseAction(fn)]
      | Async(fn) => [
          makeSyncParseAction(fn),
          Action.make(
            AsyncTransform(
              (. input) => {
                switch input->unsafeUnknownToAny {
                | Some(asyncFn) =>
                  asyncFn(.)->Lib.Promise.thenResolve(value => Some(value)->unsafeAnyToUnknown)
                | None => None->unsafeAnyToUnknown->Lib.Promise.resolve
                }
              },
            ),
          ),
        ]
      }
    }

    make(
      ~tagged_t=Option(innerStruct),
      ~safeParseActionFactories=makeParseActions(~mode=Safe),
      ~migrationParseActionFactories=makeParseActions(~mode=Migration),
      ~serializeActionFactories,
      (),
    )
  }
}

module Deprecated = {
  let factory = (~message as maybeMessage=?, innerStruct) => {
    let serializeActionFactories = [
      Action.make(
        SyncTransform(
          (. input) => {
            switch input->unsafeUnknownToAny {
            | Some(value) => serializeInner(~struct=innerStruct, ~value)
            | None => %raw(`undefined`)
            }
          },
        ),
      ),
    ]

    let makeSyncParseAction = fn => {
      Action.make(
        SyncTransform(
          (. input) => {
            switch input->unsafeUnknownToAny {
            | Some(innerData) => Some(fn(. innerData))
            | None => None
            }->unsafeAnyToUnknown
          },
        ),
      )
    }

    let makeParseActions = (~mode) => {
      switch innerStruct->getParseOperation(~mode) {
      | Noop => Action.emptyArray
      | Sync(fn) => [makeSyncParseAction(fn)]
      | Async(fn) => [
          makeSyncParseAction(fn),
          Action.make(
            AsyncTransform(
              (. input) => {
                switch input->unsafeUnknownToAny {
                | Some(asyncFn) =>
                  asyncFn(.)->Lib.Promise.thenResolve(value => Some(value)->unsafeAnyToUnknown)
                | None => None->unsafeAnyToUnknown->Lib.Promise.resolve
                }
              },
            ),
          ),
        ]
      }
    }

    make(
      ~tagged_t=Deprecated({struct: innerStruct, maybeMessage: maybeMessage}),
      ~safeParseActionFactories=makeParseActions(~mode=Safe),
      ~migrationParseActionFactories=makeParseActions(~mode=Migration),
      ~serializeActionFactories,
      (),
    )
  }
}

module Array = {
  let factory = innerStruct => {
    let serializeActionFactories = switch innerStruct.serialize {
    | Noop => Action.emptyArray
    | Sync(fn) => [
        Action.make(
          SyncTransform(
            (. input) => {
              let newArray = []
              for idx in 0 to input->unsafeUnknownToAny->Js.Array2.length - 1 {
                let innerData = input->unsafeUnknownToAny->Js.Array2.unsafe_get(idx)
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
              newArray->unsafeAnyToUnknown
            },
          ),
        ),
      ]
    | Async(_) => Error.Unreachable.panic()
    }

    let makeSyncParseAction = fn => {
      Action.make(
        SyncTransform(
          (. input) => {
            let newArray = []
            for idx in 0 to input->unsafeUnknownToAny->Js.Array2.length - 1 {
              let innerData = input->unsafeUnknownToAny->Js.Array2.unsafe_get(idx)
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
            newArray->unsafeAnyToUnknown
          },
        ),
      )
    }

    let makeParseActions = (~mode) => {
      let parseActions = []

      if mode === Safe {
        parseActions
        ->Js.Array2.push(
          Action.factory((. ~struct, ~mode as _) => SyncTransform(
            (. input) => {
              if Js.Array2.isArray(input) === false {
                raiseUnexpectedTypeError(~input, ~struct)
              } else {
                input
              }
            },
          )),
        )
        ->ignore
      }

      switch innerStruct->getParseOperation(~mode) {
      | Noop => ()
      | Sync(fn) => parseActions->Js.Array2.push(makeSyncParseAction(fn))->ignore
      | Async(fn) =>
        parseActions->Js.Array2.push(makeSyncParseAction(fn))->ignore
        parseActions
        ->Js.Array2.push(
          Action.make(
            AsyncTransform(
              (. input) => {
                input
                ->unsafeUnknownToAny
                ->Js.Array2.mapi((asyncFn, idx) => {
                  asyncFn(.)->Lib.Promise.catch(exn => {
                    switch exn {
                    | Error.Internal.Exception(internalError) =>
                      Error.Internal.Exception(
                        internalError->Error.Internal.prependLocation(idx->Js.Int.toString),
                      )
                    | _ => exn
                    }->Lib.Exn.throw
                  })
                })
                ->Lib.Promise.all
                ->Obj.magic
              },
            ),
          ),
        )
        ->ignore
      }

      parseActions
    }

    make(
      ~tagged_t=Array(innerStruct),
      ~safeParseActionFactories=makeParseActions(~mode=Safe),
      ~migrationParseActionFactories=makeParseActions(~mode=Migration),
      ~serializeActionFactories,
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
      switch value->Js.Array2.length === length {
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
  let factory = innerStruct => {
    let serializeActionFactories = switch innerStruct.serialize {
    | Noop => Action.emptyArray
    | Sync(fn) => [
        Action.make(
          SyncTransform(
            (. input) => {
              let newDict = Js.Dict.empty()
              let keys = input->unsafeUnknownToAny->Js.Dict.keys
              for idx in 0 to keys->Js.Array2.length - 1 {
                let key = keys->Js.Array2.unsafe_get(idx)
                let innerData = input->unsafeUnknownToAny->Js.Dict.unsafeGet(key)
                try {
                  let value = fn(. innerData)
                  newDict->Js.Dict.set(key, value)->ignore
                } catch {
                | Error.Internal.Exception(internalError) =>
                  raise(
                    Error.Internal.Exception(internalError->Error.Internal.prependLocation(key)),
                  )
                }
              }
              newDict->unsafeAnyToUnknown
            },
          ),
        ),
      ]
    | Async(_) => Error.Unreachable.panic()
    }

    let makeSyncParseAction = fn => {
      Action.make(
        SyncTransform(
          (. input) => {
            let newDict = Js.Dict.empty()
            let keys = input->unsafeUnknownToAny->Js.Dict.keys
            for idx in 0 to keys->Js.Array2.length - 1 {
              let key = keys->Js.Array2.unsafe_get(idx)
              let innerData = input->unsafeUnknownToAny->Js.Dict.unsafeGet(key)
              try {
                let value = fn(. innerData)
                newDict->Js.Dict.set(key, value)->ignore
              } catch {
              | Error.Internal.Exception(internalError) =>
                raise(Error.Internal.Exception(internalError->Error.Internal.prependLocation(key)))
              }
            }
            newDict->unsafeAnyToUnknown
          },
        ),
      )
    }

    let makeParseActions = (~mode) => {
      let parseActions = []

      if mode === Safe {
        parseActions
        ->Js.Array2.push(
          Action.factory((. ~struct, ~mode as _) => SyncTransform(
            (. input) => {
              if input->Lib.Object.test === false {
                raiseUnexpectedTypeError(~input, ~struct)
              } else {
                input
              }
            },
          )),
        )
        ->ignore
      }

      switch innerStruct->getParseOperation(~mode) {
      | Noop => ()
      | Sync(fn) => parseActions->Js.Array2.push(makeSyncParseAction(fn))->ignore
      | Async(fn) =>
        parseActions->Js.Array2.push(makeSyncParseAction(fn))->ignore
        parseActions
        ->Js.Array2.push(
          Action.make(
            AsyncTransform(
              (. input) => {
                let keys = input->unsafeUnknownToAny->Js.Dict.keys
                keys
                ->Js.Array2.map(key => {
                  let asyncFn = input->unsafeUnknownToAny->Js.Dict.unsafeGet(key)
                  try {
                    asyncFn(.)->Lib.Promise.catch(exn => {
                      switch exn {
                      | Error.Internal.Exception(internalError) =>
                        Error.Internal.Exception(internalError->Error.Internal.prependLocation(key))
                      | _ => exn
                      }->Lib.Exn.throw
                    })
                  } catch {
                  | Error.Internal.Exception(internalError) =>
                    Error.Internal.Exception(
                      internalError->Error.Internal.prependLocation(key),
                    )->Lib.Exn.throw
                  }
                })
                ->Lib.Promise.all
                ->Lib.Promise.thenResolve(values => {
                  let tempDict = Js.Dict.empty()
                  values->Js.Array2.forEachi((value, idx) => {
                    let key = keys->Js.Array2.unsafe_get(idx)
                    tempDict->Js.Dict.set(key, value)
                  })
                  tempDict->unsafeAnyToUnknown
                })
              },
            ),
          ),
        )
        ->ignore
      }

      parseActions
    }

    make(
      ~tagged_t=Dict(innerStruct),
      ~safeParseActionFactories=makeParseActions(~mode=Safe),
      ~migrationParseActionFactories=makeParseActions(~mode=Migration),
      ~serializeActionFactories,
      (),
    )
  }
}

module Default = {
  let factory = (innerStruct, defaultValue) => {
    let serializeActionFactories = [
      Action.make(
        SyncTransform(
          (. input) => {
            serializeInner(~struct=innerStruct, ~value=Some(input->unsafeUnknownToAny))
          },
        ),
      ),
    ]

    let makeParseActions = (~mode) => {
      switch innerStruct->getParseOperation(~mode) {
      | Noop => [
          Action.make(
            SyncTransform(
              (. input) => {
                switch input->unsafeUnknownToAny {
                | Some(output) => output
                | None => defaultValue
                }->unsafeAnyToUnknown
              },
            ),
          ),
        ]
      | Sync(fn) => [
          Action.make(
            SyncTransform(
              (. input) => {
                switch fn(. input)->unsafeUnknownToAny {
                | Some(output) => output
                | None => defaultValue
                }->unsafeAnyToUnknown
              },
            ),
          ),
        ]
      | Async(fn) => [
          Action.make(
            AsyncTransform(
              (. input) => {
                fn(. input)(.)->Lib.Promise.thenResolve(value => {
                  switch value->unsafeUnknownToAny {
                  | Some(output) => output
                  | None => defaultValue
                  }->unsafeAnyToUnknown
                })
              },
            ),
          ),
        ]
      }
    }

    make(
      ~tagged_t=Default({struct: innerStruct, value: defaultValue}),
      ~safeParseActionFactories=makeParseActions(~mode=Safe),
      ~migrationParseActionFactories=makeParseActions(~mode=Migration),
      ~serializeActionFactories,
      (),
    )
  }
}

module Tuple = {
  let serializeActionFactories = [
    Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. input) => {
        let innerStructs = struct->classify->unsafeGetVariantPayload
        let numberOfStructs = innerStructs->Js.Array2.length
        let inputArray =
          numberOfStructs === 1 ? [input->unsafeUnknownToAny] : input->unsafeUnknownToAny

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
          | Async(_) => Error.Unreachable.panic()
          }
        }
        newArray->unsafeAnyToUnknown
      },
    )),
  ]

  let innerFactory = structs => {
    let makeParseActions = (~mode) => {
      let numberOfStructs = structs->Js.Array2.length

      let noopOps = []
      let syncOps = []
      let asyncOps = []
      for idx in 0 to structs->Js.Array2.length - 1 {
        let innerStruct = structs->Js.Array2.unsafe_get(idx)
        switch innerStruct->getParseOperation(~mode) {
        | Noop => noopOps->Js.Array2.push(idx)->ignore
        | Sync(fn) => syncOps->Js.Array2.push((idx, fn))->ignore
        | Async(fn) => {
            syncOps->Js.Array2.push((idx, fn->Obj.magic))->ignore
            asyncOps->Js.Array2.push(idx)->ignore
          }
        }
      }
      let withAsyncOps = asyncOps->Js.Array2.length > 0

      let parseActions = [
        Action.factory((. ~struct, ~mode) => SyncTransform(
          (. input) => {
            if mode === Safe {
              switch Js.Array2.isArray(input) {
              | true =>
                let numberOfInputItems = input->unsafeUnknownToAny->Js.Array2.length
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

            for idx in 0 to syncOps->Js.Array2.length - 1 {
              let (originalIdx, fn) = syncOps->Js.Array2.unsafe_get(idx)
              let innerData = input->unsafeUnknownToAny->Js.Array2.unsafe_get(originalIdx)
              try {
                let value = fn(. innerData)
                newArray->Lib.Array.set(originalIdx, value)
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
              let innerData = input->unsafeUnknownToAny->Js.Array2.unsafe_get(originalIdx)
              newArray->Lib.Array.set(originalIdx, innerData)
            }

            switch withAsyncOps {
            | true => newArray->unsafeAnyToUnknown
            | false =>
              switch numberOfStructs {
              | 0 => ()->unsafeAnyToUnknown
              | 1 => newArray->Js.Array2.unsafe_get(0)->unsafeAnyToUnknown
              | _ => newArray->unsafeAnyToUnknown
              }
            }
          },
        )),
      ]

      if withAsyncOps {
        parseActions
        ->Js.Array2.push(
          Action.make(
            AsyncTransform(
              (. tempArray) => {
                asyncOps
                ->Js.Array2.map(originalIdx => {
                  (
                    tempArray->unsafeUnknownToAny->Js.Array2.unsafe_get(originalIdx)->Obj.magic
                  )(.)->Lib.Promise.catch(exn => {
                    switch exn {
                    | Error.Internal.Exception(internalError) =>
                      Error.Internal.Exception(
                        internalError->Error.Internal.prependLocation(originalIdx->Js.Int.toString),
                      )
                    | _ => exn
                    }->Lib.Exn.throw
                  })
                })
                ->Lib.Promise.all
                ->Lib.Promise.thenResolve(values => {
                  values->Js.Array2.forEachi((value, idx) => {
                    let originalIdx = asyncOps->Js.Array2.unsafe_get(idx)
                    tempArray->unsafeUnknownToAny->Lib.Array.set(originalIdx, value)
                  })
                  tempArray->unsafeUnknownToAny->Lib.Array.toTuple->unsafeAnyToUnknown
                })
              },
            ),
          ),
        )
        ->ignore
      }

      parseActions
    }

    make(
      ~tagged_t=Tuple(structs),
      ~safeParseActionFactories=makeParseActions(~mode=Safe),
      ~migrationParseActionFactories=makeParseActions(~mode=Migration),
      ~serializeActionFactories,
      (),
    )
  }

  let factory = Lib.Fn.callWithArguments(innerFactory)
}

module Union = {
  exception HackyValidValue(unknown)

  let serializeActionFactories = [
    Action.factory((. ~struct, ~mode as _) => SyncTransform(
      (. input) => {
        let innerStructs = struct->classify->unsafeGetVariantPayload

        let idxRef = ref(0)
        let maybeLastErrorRef = ref(None)
        let maybeNewValueRef = ref(None)
        while (
          idxRef.contents < innerStructs->Js.Array2.length && maybeNewValueRef.contents === None
        ) {
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
      },
    )),
  ]

  let factory = structs => {
    if structs->Js.Array2.length < 2 {
      Error.UnionLackingStructs.panic()
    }

    let parseActions = {
      let noopOps = []
      let syncOps = []
      let asyncOps = []
      for idx in 0 to structs->Js.Array2.length - 1 {
        let innerStruct = structs->Js.Array2.unsafe_get(idx)
        switch innerStruct->getParseOperation(~mode=Safe) {
        | Noop => noopOps->Js.Array2.push()->ignore
        | Sync(fn) => syncOps->Js.Array2.push((idx, fn))->ignore
        | Async(fn) => asyncOps->Js.Array2.push((idx, fn))->ignore
        }
      }
      let withAsyncOps = asyncOps->Js.Array2.length > 0

      if noopOps->Js.Array2.length > 0 {
        Action.emptyArray
      } else {
        let parseActions = [
          Action.make(
            SyncTransform(
              (. input) => {
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
                      errorsRef.contents->Lib.Array.set(originalIdx, internalError)
                      idxRef.contents = idxRef.contents->Lib.Int.plus(1)
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
                  }->unsafeAnyToUnknown
                }
              },
            ),
          ),
        ]

        if withAsyncOps {
          parseActions
          ->Js.Array2.push(
            Action.make(
              AsyncTransform(
                (. input) => {
                  let input = input->unsafeUnknownToAny
                  switch input["maybeSyncValue"] {
                  | Some(syncValue) => syncValue->Lib.Promise.resolve
                  | None =>
                    asyncOps
                    ->Js.Array2.map(((originalIdx, fn)) => {
                      try {
                        fn(. input["originalInput"])(.)->Lib.Promise.thenResolveWithCatch(
                          value => raise(HackyValidValue(value)),
                          exn =>
                            switch exn {
                            | Error.Internal.Exception(internalError) =>
                              input["tempErrors"]->Lib.Array.set(originalIdx, internalError)
                            | _ => exn->Lib.Exn.throw
                            },
                        )
                      } catch {
                      | Error.Internal.Exception(internalError) =>
                        input["tempErrors"]
                        ->Lib.Array.set(originalIdx, internalError)
                        ->Lib.Promise.resolve
                      }
                    })
                    ->Lib.Promise.all
                    ->Lib.Promise.thenResolveWithCatch(
                      _ => {
                        Error.Internal.raise(
                          InvalidUnion(
                            input["tempErrors"]->Js.Array2.map(Error.Internal.toParseError),
                          ),
                        )
                      },
                      exn => {
                        switch exn {
                        | HackyValidValue(value) => value
                        | _ => exn->Lib.Exn.throw
                        }
                      },
                    )
                  }
                },
              ),
            ),
          )
          ->ignore
        }

        parseActions
      }
    }

    make(
      ~tagged_t=Union(structs),
      ~safeParseActionFactories=parseActions,
      ~migrationParseActionFactories=parseActions,
      ~serializeActionFactories,
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
