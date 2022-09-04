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
      %raw(`arguments`)
    }

    @inline
    let call1 = (fn: 'arg1 => 'return, arg1: 'arg1): 'return => {
      Obj.magic(fn)(. arg1)
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
    let map = (option, fn) =>
      switch option {
      | Some(value) => Some(fn(value))
      | None => None
      }

    @inline
    let flatMap = (option, fn) =>
      switch option {
      | Some(value) => fn(value)
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

  module Dict = {
    @val
    external immutableShallowMerge: (
      @as(json`{}`) _,
      Js.Dict.t<'a>,
      Js.Dict.t<'a>,
    ) => Js.Dict.t<'a> = "Object.assign"
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
      raise(Exception({code, path: []}))
    }

    let toParseError = (internalError: t): public => {
      {operation: Parsing, code: internalError.code, path: internalError.path}
    }

    let toSerializeError = (internalError: t): public => {
      {operation: Serializing, code: internalError.code, path: internalError.path}
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

  let raiseCustom = error => {
    raise(Internal.Exception(error->Internal.fromPublic))
  }

  let raise = message => {
    raise(Internal.Exception({code: OperationFailed(message), path: []}))
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

exception Raised(Error.t)

type rec literal<'value> =
  | String(string): literal<string>
  | Int(int): literal<int>
  | Float(float): literal<float>
  | Bool(bool): literal<bool>
  | EmptyNull: literal<unit>
  | EmptyOption: literal<unit>
  | NaN: literal<unit>

type recordUnknownKeys =
  | Strict
  | Strip
type operation =
  | NoopOperation
  | SyncOperation((. unknown) => unknown)
  | AsyncOperation((. unknown, . unit) => Js.Promise.t<unknown>)

type rec t<'value> = {
  @as("n")
  name: string,
  @as("t")
  tagged: tagged,
  @as("pf")
  parseActionFactories: array<actionFactory>,
  @as("sf")
  serializeActionFactories: array<actionFactory>,
  @as("s")
  serialize: operation,
  @as("p")
  parse: operation,
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
  | Literal(literal<unknown>)
  | Option(t<unknown>)
  | Null(t<unknown>)
  | Array(t<unknown>)
  | Record({
      fields: Js.Dict.t<t<unknown>>,
      fieldNames: array<string>,
      unknownKeys: recordUnknownKeys,
    })
  | Tuple(array<t<unknown>>)
  | Union(array<t<unknown>>)
  | Dict(t<unknown>)
  | Date
and field<'value> = (string, t<'value>)
and action<'input, 'output> =
  | Sync('input => 'output)
  | Async('input => Js.Promise.t<'output>)
and actionFactory = (~struct: t<unknown>) => action<unknown, unknown>

external castAnyToUnknown: 'any => unknown = "%identity"
external castUnknownToAny: unknown => 'any = "%identity"
external castActionFactoryToUncurried: (
  actionFactory,
  . ~struct: t<unknown>,
) => action<unknown, unknown> = "%identity"

type payloadedVariant<'payload> = {_0: 'payload}

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
    let make = (~id: Id.t<'metadata>, ~metadata: 'metadata) => {
      let metadataChange = Js.Dict.empty()
      metadataChange->Js.Dict.set(id->Id.toKey, metadata)
      metadataChange->castDictOfAnyToUnknown
    }
  }

  let get = (struct, ~id: Id.t<'metadata>): option<'metadata> => {
    struct.maybeMetadataDict->Lib.Option.flatMap(metadataDict => {
      metadataDict->Js.Dict.get(id->Id.toKey)->Obj.magic
    })
  }

  let set = (struct, ~id: Id.t<'metadata>, ~metadata: 'metadata) => {
    {
      ...struct,
      maybeMetadataDict: Some(
        Lib.Dict.immutableShallowMerge(
          struct.maybeMetadataDict->Belt.Option.getUnsafe,
          Change.make(~id, ~metadata),
        ),
      ),
    }
  }
}

@inline
let classify = struct => struct.tagged

@inline
let name = struct => struct.name

@inline
let isAsyncParse = struct =>
  switch struct.parse {
  | AsyncOperation(_) => true
  | NoopOperation
  | SyncOperation(_) => false
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
      | JSObject(_) => "Object"
      | JSFunction(_) => "Function"
      | JSUndefined => "Option"
      | JSSymbol(_) => "Symbol"
      | JSBigInt(_) => "BigInt"
      },
    }),
  )
}

let makeOperation = (~actionFactories, ~struct) => {
  switch actionFactories {
  | [] => NoopOperation
  | _ =>
    let lastActionIdx = actionFactories->Js.Array2.length - 1
    let lastSyncActionIdxRef = ref(lastActionIdx)
    let actions = []
    for idx in 0 to lastSyncActionIdxRef.contents {
      let actionFactory = actionFactories->Js.Array2.unsafe_get(idx)
      let action = (actionFactory->castActionFactoryToUncurried)(. ~struct)
      actions->Js.Array2.push(action)->ignore
      if lastSyncActionIdxRef.contents === lastActionIdx {
        switch action {
        | Async(_) => lastSyncActionIdxRef.contents = idx - 1
        | Sync(_) => ()
        }
      }
    }

    let syncOperation = switch lastSyncActionIdxRef.contents === 0 {
    // Shortcut to get a fn of the first Sync
    | true => (actions->Js.Array2.unsafe_get(0)->Obj.magic)._0
    | false =>
      (. input) => {
        let tempOuputRef = ref(input->Obj.magic)
        for idx in 0 to lastSyncActionIdxRef.contents {
          let action = actions->Js.Array2.unsafe_get(idx)
          // Shortcut to get Sync fn
          let newValue = (action->Obj.magic)._0(. tempOuputRef.contents)
          tempOuputRef.contents = newValue
        }
        tempOuputRef.contents
      }
    }

    switch lastActionIdx === lastSyncActionIdxRef.contents {
    | true => SyncOperation(syncOperation)
    | false =>
      AsyncOperation(
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
                  | Sync(fn) => fn->Lib.Fn.call1(tempOutput)->Lib.Promise.resolve
                  | Async(fn) => fn->Lib.Fn.call1(tempOutput)
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
  ~name,
  ~tagged,
  ~parseActionFactories,
  ~serializeActionFactories,
  ~metadataDict as maybeMetadataDict=?,
  (),
) => {
  let struct = {
    name,
    tagged,
    parseActionFactories,
    serializeActionFactories,
    serialize: %raw("undefined"),
    parse: %raw("undefined"),
    maybeMetadataDict,
  }
  {
    ...struct,
    serialize: makeOperation(~actionFactories=struct.serializeActionFactories, ~struct),
    parse: makeOperation(~actionFactories=struct.parseActionFactories, ~struct),
  }
}

let parseWith = (any, struct) => {
  try {
    switch struct.parse {
    | NoopOperation => any->Obj.magic->Ok
    | SyncOperation(fn) => fn(. any->Obj.magic)->Obj.magic->Ok
    | AsyncOperation(_) => Error.Internal.raise(UnexpectedAsync)
    }
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  }
}

let parseOrRaiseWith = (any, struct) => {
  try {
    switch struct.parse {
    | NoopOperation => any->Obj.magic
    | SyncOperation(fn) => fn(. any->Obj.magic)->Obj.magic
    | AsyncOperation(_) => Error.Internal.raise(UnexpectedAsync)
    }
  } catch {
  | Error.Internal.Exception(internalError) =>
    raise(Raised(internalError->Error.Internal.toParseError))
  }
}

let parseAsyncWith = (any, struct) => {
  try {
    switch struct.parse {
    | NoopOperation => any->Obj.magic->Ok->Lib.Promise.resolve
    | SyncOperation(fn) => fn(. any->Obj.magic)->Ok->Obj.magic->Lib.Promise.resolve
    | AsyncOperation(fn) =>
      fn(. any->Obj.magic)(.)
      ->Lib.Promise.thenResolve(value => Ok(value->Obj.magic))
      ->Lib.Promise.catch(exn => {
        switch exn {
        | Error.Internal.Exception(internalError) =>
          internalError->Error.Internal.toParseError->Error
        | _ => exn->Lib.Exn.throw
        }
      })
    }
  } catch {
  | Error.Internal.Exception(internalError) =>
    internalError->Error.Internal.toParseError->Error->Lib.Promise.resolve
  }
}

let parseAsyncInStepsWith = (any, struct) => {
  try {
    switch struct.parse {
    | NoopOperation => () => any->Obj.magic->Ok->Lib.Promise.resolve
    | SyncOperation(fn) => {
        let syncValue = fn(. any->castAnyToUnknown)->castUnknownToAny
        () => syncValue->Ok->Lib.Promise.resolve
      }

    | AsyncOperation(fn) => {
        let asyncFn = fn(. any->castAnyToUnknown)
        () =>
          asyncFn(.)
          ->Lib.Promise.thenResolve(value => Ok(value->Obj.magic))
          ->Lib.Promise.catch(exn => {
            switch exn {
            | Error.Internal.Exception(internalError) =>
              internalError->Error.Internal.toParseError->Error
            | _ => exn->Lib.Exn.throw
            }
          })
      }
    }->Ok
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  }
}

@inline
let serializeInner: (~struct: t<'value>, ~value: 'value) => unknown = (~struct, ~value) => {
  switch struct.serialize {
  | NoopOperation => value->castAnyToUnknown
  | SyncOperation(fn) => fn(. value->castAnyToUnknown)
  | AsyncOperation(_) => Error.Unreachable.panic()
  }
}

let serializeWith = (value, struct) => {
  try {
    serializeInner(~struct, ~value)->Ok
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toSerializeError->Error
  }
}

let serializeOrRaiseWith = (value, struct) => {
  try {
    serializeInner(~struct, ~value)
  } catch {
  | Error.Internal.Exception(internalError) =>
    raise(Raised(internalError->Error.Internal.toSerializeError))
  }
}

module Action = {
  @inline
  let factory = (fn: (~struct: t<'value>) => action<'input, 'output>): actionFactory =>
    fn->Obj.magic

  @inline
  let make = (action: action<'input, 'output>): actionFactory => (~struct as _) => action->Obj.magic

  let emptyArray: array<actionFactory> = []

  let concatParser = (parsers, parser) => {
    parsers->Js.Array2.concat([parser])
  }

  let concatSerializer = (serializers, serializer) => {
    [serializer]->Js.Array2.concat(serializers)
  }

  let missingParser = make(
    Sync(
      _ => {
        Error.Internal.raise(MissingParser)
      },
    ),
  )

  let missingSerializer = make(
    Sync(
      _ => {
        Error.Internal.raise(MissingSerializer)
      },
    ),
  )
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

  let maybeParseActionFactory = maybeRefineParser->Lib.Option.map(refineParser => {
    Action.make(
      Sync(
        input => {
          let () = refineParser->Lib.Fn.call1(input)
          input
        },
      ),
    )
  })

  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseActionFactories=switch maybeParseActionFactory {
    | Some(parseActionFactory) =>
      struct.parseActionFactories->Action.concatParser(parseActionFactory)
    | None => struct.parseActionFactories
    },
    ~serializeActionFactories=switch maybeRefineSerializer {
    | Some(refineSerializer) =>
      struct.serializeActionFactories->Action.concatSerializer(
        Action.make(
          Sync(
            input => {
              let () = refineSerializer->Lib.Fn.call1(input)
              input
            },
          ),
        ),
      )
    | None => struct.serializeActionFactories
    },
    ~metadataDict=?struct.maybeMetadataDict,
    (),
  )
}

let asyncRefine = (struct, ~parser, ()) => {
  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseActionFactories=struct.parseActionFactories->Action.concatParser(
      Action.make(
        Async(
          input => {
            parser
            ->Lib.Fn.call1(input)
            ->Lib.Promise.thenResolve(() => {
              input
            })
          },
        ),
      ),
    ),
    ~serializeActionFactories=struct.serializeActionFactories,
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
  ~parser as maybeTransformationParser=?,
  ~serializer as maybeTransformationSerializer=?,
  (),
) => {
  if maybeTransformationParser === None && maybeTransformationSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Transform`)
  }

  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseActionFactories=struct.parseActionFactories->Action.concatParser(
      switch maybeTransformationParser {
      | Some(transformationParser) => Action.make(Sync(transformationParser->Obj.magic))
      | None => Action.missingParser
      },
    ),
    ~serializeActionFactories=struct.serializeActionFactories->Action.concatSerializer(
      switch maybeTransformationSerializer {
      | Some(transformationSerializer) => Action.make(Sync(transformationSerializer->Obj.magic))
      | None => Action.missingSerializer
      },
    ),
    ~metadataDict=?struct.maybeMetadataDict,
    (),
  )
}

let advancedTransform: (
  t<'value>,
  ~parser: (~struct: t<'value>) => action<'value, 'transformed>=?,
  ~serializer: (~struct: t<'value>) => action<'transformed, 'value>=?,
  unit,
) => t<'transformed> = (
  struct,
  ~parser as maybeTransformationParser=?,
  ~serializer as maybeTransformationSerializer=?,
  (),
) => {
  if maybeTransformationParser === None && maybeTransformationSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Transform`)
  }

  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseActionFactories=struct.parseActionFactories->Action.concatParser(
      switch maybeTransformationParser {
      | Some(transformationParser) => transformationParser->Obj.magic
      | None => Action.missingParser
      },
    ),
    ~serializeActionFactories=struct.serializeActionFactories->Action.concatSerializer(
      switch maybeTransformationSerializer {
      | Some(transformationSerializer) => transformationSerializer->Obj.magic
      | None => Action.missingSerializer
      },
    ),
    ~metadataDict=?struct.maybeMetadataDict,
    (),
  )
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
    ~parseActionFactories=[
      switch maybeCustomParser {
      | Some(customParser) =>
        Action.factory((~struct as _) => Sync(
          input => {
            customParser(. ~unknown=input)
          },
        ))
      | None => Action.missingParser
      },
    ],
    ~serializeActionFactories=[
      switch maybeCustomSerializer {
      | Some(customSerializer) => Action.make(Sync(customSerializer->Obj.magic))
      | None => Action.missingSerializer
      },
    ],
    (),
  )
}

module Literal = {
  module Variant = {
    let factory:
      type literalValue variant. (literal<literalValue>, variant) => t<variant> =
      (innerLiteral, variant) => {
        let tagged = Literal(innerLiteral->Obj.magic)

        let makeParseActionFactories = (~literalValue, ~test) => {
          [
            Action.factory((~struct) => Sync(
              input => {
                if test->Lib.Fn.call1(input) {
                  if literalValue->castAnyToUnknown === input {
                    variant
                  } else {
                    Error.Internal.UnexpectedValue.raise(~expected=literalValue, ~received=input)
                  }
                } else {
                  raiseUnexpectedTypeError(~input, ~struct)
                }
              },
            )),
          ]
        }

        let makeSerializeActionFactories = output => {
          [
            Action.make(
              Sync(
                input => {
                  if input === variant {
                    output
                  } else {
                    Error.Internal.UnexpectedValue.raise(~expected=variant, ~received=input)
                  }
                },
              ),
            ),
          ]
        }

        switch innerLiteral {
        | EmptyNull =>
          make(
            ~name="EmptyNull Literal (null)",
            ~tagged,
            ~parseActionFactories=[
              Action.factory((~struct) => Sync(
                input => {
                  if input === Js.Null.empty {
                    variant
                  } else {
                    raiseUnexpectedTypeError(~input, ~struct)
                  }
                },
              )),
            ],
            ~serializeActionFactories=makeSerializeActionFactories(Js.Null.empty),
            (),
          )
        | EmptyOption =>
          make(
            ~name="EmptyOption Literal (undefined)",
            ~tagged,
            ~parseActionFactories=[
              Action.factory((~struct) => Sync(
                input => {
                  if input === Js.Undefined.empty {
                    variant
                  } else {
                    raiseUnexpectedTypeError(~input, ~struct)
                  }
                },
              )),
            ],
            ~serializeActionFactories=makeSerializeActionFactories(Js.Undefined.empty),
            (),
          )
        | NaN =>
          make(
            ~name="NaN Literal (NaN)",
            ~tagged,
            ~parseActionFactories=[
              Action.factory((~struct) => Sync(
                input => {
                  if Js.Float.isNaN(input) {
                    variant
                  } else {
                    raiseUnexpectedTypeError(~input, ~struct)
                  }
                },
              )),
            ],
            ~serializeActionFactories=makeSerializeActionFactories(Js.Float._NaN),
            (),
          )
        | Bool(bool) =>
          make(
            ~name=j`Bool Literal ($bool)`,
            ~tagged,
            ~parseActionFactories=makeParseActionFactories(~literalValue=bool, ~test=input =>
              input->Js.typeof === "boolean"
            ),
            ~serializeActionFactories=makeSerializeActionFactories(bool),
            (),
          )
        | String(string) =>
          make(
            ~name=`String Literal ("${string}")`,
            ~tagged,
            ~parseActionFactories=makeParseActionFactories(~literalValue=string, ~test=input =>
              input->Js.typeof === "string"
            ),
            ~serializeActionFactories=makeSerializeActionFactories(string),
            (),
          )
        | Float(float) =>
          make(
            ~name=`Float Literal (${float->Js.Float.toString})`,
            ~tagged,
            ~parseActionFactories=makeParseActionFactories(~literalValue=float, ~test=input =>
              input->Js.typeof === "number"
            ),
            ~serializeActionFactories=makeSerializeActionFactories(float),
            (),
          )
        | Int(int) =>
          make(
            ~name=`Int Literal (${int->Js.Int.toString})`,
            ~tagged,
            ~parseActionFactories=makeParseActionFactories(~literalValue=int, ~test=input =>
              input->Lib.Int.test
            ),
            ~serializeActionFactories=makeSerializeActionFactories(int),
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

  let factory = (
    () => {
      let fieldsArray = Lib.Fn.getArguments()
      let fields = fieldsArray->Js.Dict.fromArray
      let fieldNames = fields->Js.Dict.keys

      make(
        ~name="Record",
        ~tagged=Record({fields, fieldNames, unknownKeys: Strip}),
        ~parseActionFactories={
          let noopOps = []
          let syncOps = []
          let asyncOps = []
          for idx in 0 to fieldNames->Js.Array2.length - 1 {
            let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
            let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
            switch fieldStruct.parse {
            | NoopOperation => noopOps->Js.Array2.push((idx, fieldName))->ignore
            | SyncOperation(fn) => syncOps->Js.Array2.push((idx, fieldName, fn))->ignore
            | AsyncOperation(fn) => {
                syncOps->Js.Array2.push((idx, fieldName, fn->Obj.magic))->ignore
                asyncOps->Js.Array2.push((idx, fieldName))->ignore
              }
            }
          }
          let withAsyncOps = asyncOps->Js.Array2.length > 0

          let parseActionFactories = [
            Action.factory((~struct) => Sync(
              input => {
                if input->Lib.Object.test === false {
                  raiseUnexpectedTypeError(~input, ~struct)
                }

                let newArray = []

                for idx in 0 to syncOps->Js.Array2.length - 1 {
                  let (originalIdx, fieldName, fn) = syncOps->Js.Array2.unsafe_get(idx)
                  let fieldData = input->Js.Dict.unsafeGet(fieldName)
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
                  let fieldData = input->Js.Dict.unsafeGet(fieldName)
                  newArray->Lib.Array.set(originalIdx, fieldData)
                }

                let {unknownKeys} = struct->classify->Obj.magic
                if unknownKeys === Strict {
                  switch getMaybeExcessKey(. input->castAnyToUnknown, fields) {
                  | Some(excessKey) => Error.Internal.raise(ExcessField(excessKey))
                  | None => ()
                  }
                }

                withAsyncOps ? newArray->castAnyToUnknown : newArray->Lib.Array.toTuple
              },
            )),
          ]

          if withAsyncOps {
            parseActionFactories
            ->Js.Array2.push(
              Action.make(
                Async(
                  tempArray => {
                    asyncOps
                    ->Js.Array2.map(((originalIdx, fieldName)) => {
                      (
                        tempArray->castUnknownToAny->Js.Array2.unsafe_get(originalIdx)->Obj.magic
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
                        tempArray->castUnknownToAny->Lib.Array.set(originalIdx, fieldValue)
                      })
                      tempArray
                    })
                  },
                ),
              ),
            )
            ->ignore
          }

          parseActionFactories
        },
        ~serializeActionFactories=[
          Action.factory((~struct as _) => Sync(
            input => {
              let unknown = Js.Dict.empty()
              let fieldValues =
                fieldNames->Js.Array2.length <= 1 ? [input]->Obj.magic : input->Obj.magic
              for idx in 0 to fieldNames->Js.Array2.length - 1 {
                let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
                let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
                let fieldValue = fieldValues->Js.Array2.unsafe_get(idx)
                switch fieldStruct.serialize {
                | NoopOperation => unknown->Js.Dict.set(fieldName, fieldValue)
                | SyncOperation(fn) =>
                  try {
                    let fieldData = fn(. fieldValue)
                    unknown->Js.Dict.set(fieldName, fieldData)
                  } catch {
                  | Error.Internal.Exception(internalError) =>
                    raise(
                      Error.Internal.Exception(
                        internalError->Error.Internal.prependLocation(fieldName),
                      ),
                    )
                  }
                | AsyncOperation(_) => Error.Unreachable.panic()
                }
              }
              unknown
            },
          )),
        ],
        (),
      )
    }
  )->Obj.magic

  let strip = struct => {
    let tagged = struct->classify
    switch tagged {
    | Record({fields, fieldNames}) =>
      make(
        ~name=struct.name,
        ~tagged=Record({fields, fieldNames, unknownKeys: Strip}),
        ~parseActionFactories=struct.parseActionFactories,
        ~serializeActionFactories=struct.serializeActionFactories,
        ~metadataDict=?struct.maybeMetadataDict,
        (),
      )
    | _ => Error.UnknownKeysRequireRecord.panic()
    }
  }

  let strict = struct => {
    let tagged = struct->classify
    switch tagged {
    | Record({fields, fieldNames}) =>
      make(
        ~name=struct.name,
        ~tagged=Record({fields, fieldNames, unknownKeys: Strict}),
        ~parseActionFactories=struct.parseActionFactories,
        ~serializeActionFactories=struct.serializeActionFactories,
        ~metadataDict=?struct.maybeMetadataDict,
        (),
      )
    | _ => Error.UnknownKeysRequireRecord.panic()
    }
  }
}

module Never = {
  let factory = () => {
    let actionFactories = [
      Action.factory((~struct) => Sync(
        input => {
          raiseUnexpectedTypeError(~input, ~struct)
        },
      )),
    ]

    make(
      ~name=`Never`,
      ~tagged=Never,
      ~parseActionFactories=actionFactories,
      ~serializeActionFactories=actionFactories,
      (),
    )
  }
}

module Unknown = {
  let factory = () => {
    make(
      ~name=`Unknown`,
      ~tagged=Unknown,
      ~parseActionFactories=Action.emptyArray,
      ~serializeActionFactories=Action.emptyArray,
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
      ~name=`String`,
      ~tagged=String,
      ~parseActionFactories=[
        Action.factory((~struct) => Sync(
          input => {
            if input->Js.typeof === "string" {
              input
            } else {
              raiseUnexpectedTypeError(~input, ~struct)
            }
          },
        )),
      ],
      ~serializeActionFactories=Action.emptyArray,
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      if value->Js.String2.length < length {
        Error.raise(
          maybeMessage->Belt.Option.getWithDefault(
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
          maybeMessage->Belt.Option.getWithDefault(
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
          maybeMessage->Belt.Option.getWithDefault(
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
      if !(value->Lib.Url.test) {
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

module Bool = {
  let factory = () => {
    make(
      ~name=`Bool`,
      ~tagged=Bool,
      ~parseActionFactories=[
        Action.factory((~struct) => Sync(
          input => {
            if input->Js.typeof === "boolean" {
              input
            } else {
              raiseUnexpectedTypeError(~input, ~struct)
            }
          },
        )),
      ],
      ~serializeActionFactories=Action.emptyArray,
      (),
    )
  }
}

module Int = {
  let factory = () => {
    make(
      ~name=`Int`,
      ~tagged=Int,
      ~parseActionFactories=[
        Action.factory((~struct) => Sync(
          input => {
            if Lib.Int.test(input) {
              input
            } else {
              raiseUnexpectedTypeError(~input, ~struct)
            }
          },
        )),
      ],
      ~serializeActionFactories=Action.emptyArray,
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, thanValue) => {
    let refiner = value => {
      if value < thanValue {
        Error.raise(
          maybeMessage->Belt.Option.getWithDefault(
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
          maybeMessage->Belt.Option.getWithDefault(
            `Number must be lower than or equal to ${thanValue->Js.Int.toString}`,
          ),
        )
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }
}

module Float = {
  let factory = () => {
    make(
      ~name=`Float`,
      ~tagged=Float,
      ~parseActionFactories=[
        Action.factory((~struct) => Sync(
          input => {
            switch input->Js.typeof === "number" {
            | true =>
              if Js.Float.isNaN(input) {
                raiseUnexpectedTypeError(~input, ~struct)
              } else {
                input
              }
            | false => raiseUnexpectedTypeError(~input, ~struct)
            }
          },
        )),
      ],
      ~serializeActionFactories=Action.emptyArray,
      (),
    )
  }

  let min = Int.min->Obj.magic
  let max = Int.max->Obj.magic
}

module Date = {
  let factory = () => {
    make(
      ~name="Date",
      ~tagged=Date,
      ~parseActionFactories=[
        Action.factory((~struct) => Sync(
          input => {
            if %raw(`input instanceof Date`) && input->Js.Date.getTime->Js.Float.isNaN->not {
              input
            } else {
              raiseUnexpectedTypeError(~input, ~struct)
            }
          },
        )),
      ],
      ~serializeActionFactories=Action.emptyArray,
      (),
    )
  }
}

module Null = {
  let factory = innerStruct => {
    make(
      ~name=`Null`,
      ~tagged=Null(innerStruct->Obj.magic),
      ~parseActionFactories={
        let makeSyncParseAction = fn => {
          Action.make(
            Sync(
              input => {
                switch input->Js.Null.toOption {
                | Some(innerData) => Some(fn(. innerData))
                | None => None
                }
              },
            ),
          )
        }

        switch innerStruct.parse {
        | NoopOperation => [
            Action.make(
              Sync(
                input => {
                  input->Js.Null.toOption
                },
              ),
            ),
          ]
        | SyncOperation(fn) => [makeSyncParseAction(fn)]
        | AsyncOperation(fn) => [
            makeSyncParseAction(fn),
            Action.make(
              Async(
                input => {
                  switch input {
                  | Some(asyncFn) => asyncFn(.)->Lib.Promise.thenResolve(value => Some(value))
                  | None => None->Lib.Promise.resolve
                  }
                },
              ),
            ),
          ]
        }
      },
      ~serializeActionFactories=[
        Action.factory((~struct as _) => Sync(
          input => {
            switch input {
            | Some(value) => serializeInner(~struct=innerStruct, ~value)
            | None => Js.Null.empty->castAnyToUnknown
            }
          },
        )),
      ],
      (),
    )
  }
}

module Option = {
  let factory = innerStruct => {
    make(
      ~name=`Option`,
      ~tagged=Option(innerStruct->Obj.magic),
      ~parseActionFactories={
        let makeSyncParseAction = fn => {
          Action.make(
            Sync(
              input => {
                switch input {
                | Some(innerData) => Some(fn(. innerData))
                | None => None
                }
              },
            ),
          )
        }

        switch innerStruct.parse {
        | NoopOperation => Action.emptyArray
        | SyncOperation(fn) => [makeSyncParseAction(fn)]
        | AsyncOperation(fn) => [
            makeSyncParseAction(fn),
            Action.make(
              Async(
                input => {
                  switch input {
                  | Some(asyncFn) => asyncFn(.)->Lib.Promise.thenResolve(value => Some(value))
                  | None => None->Lib.Promise.resolve
                  }
                },
              ),
            ),
          ]
        }
      },
      ~serializeActionFactories=[
        Action.factory((~struct as _) => Sync(
          input => {
            switch input {
            | Some(value) => serializeInner(~struct=innerStruct, ~value)
            | None => Js.Undefined.empty->castAnyToUnknown
            }
          },
        )),
      ],
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
    make(
      ~name=`Array`,
      ~tagged=Array(innerStruct->Obj.magic),
      ~parseActionFactories={
        let makeSyncParseAction = fn => {
          Action.make(
            Sync(
              input => {
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
              },
            ),
          )
        }

        let parseActionFactories = [
          Action.factory((~struct) => Sync(
            input => {
              if Js.Array2.isArray(input) === false {
                raiseUnexpectedTypeError(~input, ~struct)
              } else {
                input
              }
            },
          )),
        ]

        switch innerStruct.parse {
        | NoopOperation => ()
        | SyncOperation(fn) => parseActionFactories->Js.Array2.push(makeSyncParseAction(fn))->ignore
        | AsyncOperation(fn) =>
          parseActionFactories->Js.Array2.push(makeSyncParseAction(fn))->ignore
          parseActionFactories
          ->Js.Array2.push(
            Action.make(
              Async(
                input => {
                  input
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

        parseActionFactories
      },
      ~serializeActionFactories={
        switch innerStruct.serialize {
        | NoopOperation => Action.emptyArray
        | SyncOperation(fn) => [
            Action.make(
              Sync(
                input => {
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
                },
              ),
            ),
          ]
        | AsyncOperation(_) => Error.Unreachable.panic()
        }
      },
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value => {
      if value->Js.Array2.length < length {
        Error.raise(
          maybeMessage->Belt.Option.getWithDefault(
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
          maybeMessage->Belt.Option.getWithDefault(
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
          maybeMessage->Belt.Option.getWithDefault(
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
    make(
      ~name=`Dict`,
      ~tagged=Dict(innerStruct->Obj.magic),
      ~parseActionFactories={
        let makeSyncParseAction = fn => {
          Action.make(
            Sync(
              input => {
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
                    raise(
                      Error.Internal.Exception(internalError->Error.Internal.prependLocation(key)),
                    )
                  }
                }
                newDict
              },
            ),
          )
        }

        let parseActionFactories = [
          Action.factory((~struct) => Sync(
            input => {
              if input->Lib.Object.test === false {
                raiseUnexpectedTypeError(~input, ~struct)
              } else {
                input
              }
            },
          )),
        ]

        switch innerStruct.parse {
        | NoopOperation => ()
        | SyncOperation(fn) => parseActionFactories->Js.Array2.push(makeSyncParseAction(fn))->ignore
        | AsyncOperation(fn) =>
          parseActionFactories->Js.Array2.push(makeSyncParseAction(fn))->ignore
          parseActionFactories
          ->Js.Array2.push(
            Action.make(
              Async(
                input => {
                  let keys = input->Js.Dict.keys
                  keys
                  ->Js.Array2.map(key => {
                    let asyncFn = input->Js.Dict.unsafeGet(key)
                    try {
                      asyncFn(.)->Lib.Promise.catch(exn => {
                        switch exn {
                        | Error.Internal.Exception(internalError) =>
                          Error.Internal.Exception(
                            internalError->Error.Internal.prependLocation(key),
                          )
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
                    tempDict
                  })
                },
              ),
            ),
          )
          ->ignore
        }

        parseActionFactories
      },
      ~serializeActionFactories={
        switch innerStruct.serialize {
        | NoopOperation => Action.emptyArray
        | SyncOperation(fn) => [
            Action.make(
              Sync(
                input => {
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
                      raise(
                        Error.Internal.Exception(
                          internalError->Error.Internal.prependLocation(key),
                        ),
                      )
                    }
                  }
                  newDict
                },
              ),
            ),
          ]
        | AsyncOperation(_) => Error.Unreachable.panic()
        }
      },
      (),
    )
  }
}

module Defaulted = {
  type tagged = WithDefaultValue(unknown)

  let metadataId = Metadata.Id.make(~namespace="rescript-struct", ~name="Defaulted")

  let factory = (innerStruct, defaultValue) => {
    make(
      ~name=innerStruct.name,
      ~tagged=innerStruct.tagged,
      ~parseActionFactories=[
        Action.factory((~struct as _) => {
          switch innerStruct.parse {
          | NoopOperation =>
            Sync(
              input => {
                switch input->castUnknownToAny {
                | Some(output) => output
                | None => defaultValue
                }
              },
            )
          | SyncOperation(fn) =>
            Sync(
              input => {
                switch fn(. input)->castUnknownToAny {
                | Some(output) => output
                | None => defaultValue
                }
              },
            )
          | AsyncOperation(fn) =>
            Async(
              input => {
                fn(. input)(.)->Lib.Promise.thenResolve(value => {
                  switch value->castUnknownToAny {
                  | Some(output) => output
                  | None => defaultValue
                  }
                })
              },
            )
          }
        }),
      ],
      ~serializeActionFactories=[
        Action.make(
          Sync(
            input => {
              serializeInner(~struct=innerStruct, ~value=Some(input))
            },
          ),
        ),
      ],
      (),
    )->Metadata.set(~id=metadataId, ~metadata=WithDefaultValue(defaultValue->castAnyToUnknown))
  }

  let classify = struct => struct->Metadata.get(~id=metadataId)
}

module Tuple = {
  let factory = (
    () => {
      let structs = Lib.Fn.getArguments()
      let numberOfStructs = structs->Js.Array2.length

      make(
        ~name="Tuple",
        ~tagged=Tuple(structs),
        ~parseActionFactories={
          let noopOps = []
          let syncOps = []
          let asyncOps = []
          for idx in 0 to structs->Js.Array2.length - 1 {
            let innerStruct = structs->Js.Array2.unsafe_get(idx)
            switch innerStruct.parse {
            | NoopOperation => noopOps->Js.Array2.push(idx)->ignore
            | SyncOperation(fn) => syncOps->Js.Array2.push((idx, fn))->ignore
            | AsyncOperation(fn) => {
                syncOps->Js.Array2.push((idx, fn->Obj.magic))->ignore
                asyncOps->Js.Array2.push(idx)->ignore
              }
            }
          }
          let withAsyncOps = asyncOps->Js.Array2.length > 0

          let parseActionFactories = [
            Action.factory((~struct) => Sync(
              input => {
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
                  let innerData = input->Js.Array2.unsafe_get(originalIdx)
                  newArray->Lib.Array.set(originalIdx, innerData)
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
              },
            )),
          ]

          if withAsyncOps {
            parseActionFactories
            ->Js.Array2.push(
              Action.make(
                Async(
                  tempArray => {
                    asyncOps
                    ->Js.Array2.map(originalIdx => {
                      (
                        tempArray->castUnknownToAny->Js.Array2.unsafe_get(originalIdx)->Obj.magic
                      )(.)->Lib.Promise.catch(exn => {
                        switch exn {
                        | Error.Internal.Exception(internalError) =>
                          Error.Internal.Exception(
                            internalError->Error.Internal.prependLocation(
                              originalIdx->Js.Int.toString,
                            ),
                          )
                        | _ => exn
                        }->Lib.Exn.throw
                      })
                    })
                    ->Lib.Promise.all
                    ->Lib.Promise.thenResolve(values => {
                      values->Js.Array2.forEachi((value, idx) => {
                        let originalIdx = asyncOps->Js.Array2.unsafe_get(idx)
                        tempArray->castUnknownToAny->Lib.Array.set(originalIdx, value)
                      })
                      tempArray->castUnknownToAny->Lib.Array.toTuple
                    })
                  },
                ),
              ),
            )
            ->ignore
          }

          parseActionFactories
        },
        ~serializeActionFactories=[
          Action.factory((~struct as _) => Sync(
            input => {
              let inputArray = numberOfStructs === 1 ? [input] : input->Obj.magic

              let newArray = []
              for idx in 0 to numberOfStructs - 1 {
                let innerData = inputArray->Js.Array2.unsafe_get(idx)
                let innerStruct = structs->Js.Array.unsafe_get(idx)
                switch innerStruct.serialize {
                | NoopOperation => newArray->Js.Array2.push(innerData)->ignore
                | SyncOperation(fn) =>
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
                | AsyncOperation(_) => Error.Unreachable.panic()
                }
              }
              newArray
            },
          )),
        ],
        (),
      )
    }
  )->Obj.magic
}

module Union = {
  exception HackyValidValue(unknown)

  let factory = structs => {
    if structs->Js.Array2.length < 2 {
      Error.UnionLackingStructs.panic()
    }

    let serializeActionFactories = [
      Action.factory((~struct as _) => Sync(
        input => {
          let idxRef = ref(0)
          let maybeLastErrorRef = ref(None)
          let maybeNewValueRef = ref(None)
          while idxRef.contents < structs->Js.Array2.length && maybeNewValueRef.contents === None {
            let idx = idxRef.contents
            let innerStruct = structs->Js.Array2.unsafe_get(idx)->Obj.magic
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

    let parseActionFactories = {
      let noopOps = []
      let syncOps = []
      let asyncOps = []
      for idx in 0 to structs->Js.Array2.length - 1 {
        let innerStruct = structs->Js.Array2.unsafe_get(idx)
        switch innerStruct.parse {
        | NoopOperation => noopOps->Js.Array2.push()->ignore
        | SyncOperation(fn) => syncOps->Js.Array2.push((idx, fn))->ignore
        | AsyncOperation(fn) => asyncOps->Js.Array2.push((idx, fn))->ignore
        }
      }
      let withAsyncOps = asyncOps->Js.Array2.length > 0

      if noopOps->Js.Array2.length > 0 {
        Action.emptyArray
      } else {
        let parseActionFactories = [
          Action.make(
            Sync(
              input => {
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
                  }->castAnyToUnknown
                }
              },
            ),
          ),
        ]

        if withAsyncOps {
          parseActionFactories
          ->Js.Array2.push(
            Action.make(
              Async(
                input => {
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

        parseActionFactories
      }
    }

    make(
      ~name=`Union`,
      ~tagged=Union(structs->Obj.magic),
      ~parseActionFactories,
      ~serializeActionFactories,
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
    result->Lib.Result.mapError(Error.toString)
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
let defaulted = Defaulted.factory
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
  string()
  ->transform(~parser=jsonString => {
    try jsonString->Js.Json.parseExn catch {
    | Js.Exn.Error(obj) =>
      Error.raise(obj->Js.Exn.message->Belt.Option.getWithDefault("Failed to parse JSON"))
    }
  }, ~serializer=Js.Json.stringify, ())
  ->advancedTransform(
    ~parser=(~struct as _) => {
      switch innerStruct->isAsyncParse {
      | true =>
        Async(
          parsedJson => {
            parsedJson
            ->parseAsyncWith(innerStruct)
            ->Lib.Promise.thenResolve(result => {
              switch result {
              | Ok(value) => value
              | Error(error) => Error.raiseCustom(error)
              }
            })
          },
        )
      | false =>
        Sync(
          parsedJson => {
            switch parsedJson->parseWith(innerStruct) {
            | Ok(value) => value
            | Error(error) => Error.raiseCustom(error)
            }
          },
        )
      }
    },
    ~serializer=(~struct as _) => {
      Sync(
        value => {
          switch value->serializeWith(innerStruct) {
          | Ok(unknown) => unknown->castUnknownToAny
          | Error(error) => Error.raiseCustom(error)
          }
        },
      )
    },
    (),
  )
}
