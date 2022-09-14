type never
type unknown

module Lib = {
  module Promise = {
    type t<+'a> = Js.Promise.t<'a>

    @send
    external thenResolve: (t<'a>, @uncurry ('a => 'b)) => t<'b> = "then"

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
  @inline
  let panic = message => Lib.Exn.raiseError(Lib.Exn.makeError(`[rescript-struct] ${message}`))

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
    let operation = switch error.operation {
    | Serializing => "serializing"
    | Parsing => "parsing"
    }
    let reason = error->toReason
    let pathText = error.path->formatPath
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
  parseMigrationFactory: internalMigrationFactory,
  @as("sf")
  serializeMigrationFactory: internalMigrationFactory,
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
  | Literal
  | Option(t<unknown>)
  | Null(t<unknown>)
  | Array(t<unknown>)
  | Object({fields: Js.Dict.t<t<unknown>>, fieldNames: array<string>})
  | Tuple(array<t<unknown>>)
  | Union(array<t<unknown>>)
  | Dict(t<unknown>)
  | Date
and field<'value> = (string, t<'value>)
and migration<'input, 'output> =
  | Sync('input => 'output)
  | Async('input => Js.Promise.t<'output>)
and internalMigrationFactoryCtx = {
  @as("m")
  migrations: array<unknown => unknown>,
  @as("i")
  mutable firstAsyncMigrationIdx: int,
}
and internalMigrationFactory = (. ~ctx: internalMigrationFactoryCtx, ~struct: t<unknown>) => unit

type payloadedVariant<'payload> = {_0: 'payload}
let unsafeGetVariantPayload = variant => (variant->Obj.magic)._0

external castAnyToUnknown: 'any => unknown = "%identity"
external castUnknownToAny: unknown => 'any = "%identity"
external castUnknownStructToAnyStruct: t<unknown> => t<'any> = "%identity"
external castAnyStructToUnknownStruct: t<'any> => t<unknown> = "%identity"
external castPublicMigrationFactoryToUncurried: (
  (~struct: t<'value>) => migration<'input, 'output>,
  . ~struct: t<unknown>,
) => migration<unknown, unknown> = "%identity"

module MigrationFactory = {
  module Ctx = {
    let make = () => {
      {
        migrations: [],
        firstAsyncMigrationIdx: -1,
      }
    }

    @inline
    let planSyncMigration = (ctx, migration: 'a => 'b) => {
      ctx.migrations->Js.Array2.push(migration->Obj.magic)->ignore
    }

    let planAsyncMigration = (ctx, migration: 'a => Js.Promise.t<'b>) => {
      if ctx.firstAsyncMigrationIdx === -1 {
        ctx.firstAsyncMigrationIdx = ctx.migrations->Js.Array2.length
      }
      ctx.migrations->Js.Array2.push(migration->Obj.magic)->ignore
    }

    let planMissingParserMigration = ctx => {
      ctx->planSyncMigration(_ => Error.Internal.raise(MissingParser))
    }

    let planMissingSerializerMigration = ctx => {
      ctx->planSyncMigration(_ => Error.Internal.raise(MissingSerializer))
    }
  }

  external make: (
    (. ~ctx: internalMigrationFactoryCtx, ~struct: t<'value>) => unit
  ) => internalMigrationFactory = "%identity"

  let empty = make((. ~ctx as _, ~struct as _) => ())

  let compile = (migrationFactory, ~struct) => {
    let ctx = Ctx.make()
    migrationFactory(. ~ctx, ~struct)
    let {migrations, firstAsyncMigrationIdx} = ctx
    switch migrations {
    | [] => NoopOperation
    | _ =>
      let lastMigrationIdx = migrations->Js.Array2.length - 1
      let lastSyncMigrationIdx =
        firstAsyncMigrationIdx === -1 ? lastMigrationIdx : firstAsyncMigrationIdx - 1
      let syncOperation = switch lastSyncMigrationIdx < 1 {
      // Shortcut to get a fn of the first Sync
      | true => migrations->Js.Array2.unsafe_get(0)->Obj.magic
      | false =>
        (. input) => {
          let tempOuputRef = ref(input->Obj.magic)
          for idx in 0 to lastSyncMigrationIdx {
            let migration = migrations->Js.Array2.unsafe_get(idx)
            // Shortcut to get Sync fn
            let newValue = (migration->Obj.magic)(. tempOuputRef.contents)
            tempOuputRef.contents = newValue
          }
          tempOuputRef.contents
        }
      }

      switch firstAsyncMigrationIdx === -1 {
      | true => SyncOperation(syncOperation)
      | false =>
        AsyncOperation(
          (. input) => {
            let syncOutput = switch firstAsyncMigrationIdx {
            | 0 => input
            | _ => syncOperation(. input)
            }
            (. ()) => {
              let tempOuputRef = ref(syncOutput->Lib.Promise.resolve)
              for idx in firstAsyncMigrationIdx to lastMigrationIdx {
                let migration = migrations->Js.Array2.unsafe_get(idx)
                tempOuputRef.contents =
                  tempOuputRef.contents->Lib.Promise.then(migration->Obj.magic)
              }
              tempOuputRef.contents
            }
          },
        )
      }
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

let make = (
  ~name,
  ~tagged,
  ~parseMigrationFactory,
  ~serializeMigrationFactory,
  ~metadataDict as maybeMetadataDict=?,
  (),
) => {
  let struct = {
    name,
    tagged,
    parseMigrationFactory,
    serializeMigrationFactory,
    serialize: %raw("undefined"),
    parse: %raw("undefined"),
    maybeMetadataDict,
  }
  {
    ...struct,
    serialize: struct.serializeMigrationFactory->MigrationFactory.compile(~struct),
    parse: struct.parseMigrationFactory->MigrationFactory.compile(~struct),
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
        | _ => raise(exn)
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
            | _ => raise(exn)
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
    struct.maybeMetadataDict->Lib.Option.flatMap(metadataDict => {
      metadataDict->Js.Dict.get(id->Id.toKey)->Obj.magic
    })
  }

  let set = (
    struct,
    ~id: Id.t<'metadata>,
    ~metadata: 'metadata,
    ~withParserUpdate,
    ~withSerializerUpdate,
  ) => {
    let structWithNewMetadata = {
      ...struct,
      maybeMetadataDict: Some(
        Lib.Dict.immutableShallowMerge(
          struct.maybeMetadataDict->Obj.magic,
          Change.make(~id, ~metadata),
        ),
      ),
    }
    switch (withParserUpdate, withSerializerUpdate) {
    | (false, false) => structWithNewMetadata
    | _ => {
        ...structWithNewMetadata,
        parse: withParserUpdate
          ? structWithNewMetadata.parseMigrationFactory->MigrationFactory.compile(
              ~struct=structWithNewMetadata,
            )
          : structWithNewMetadata.parse,
        serialize: withSerializerUpdate
          ? structWithNewMetadata.serializeMigrationFactory->MigrationFactory.compile(
              ~struct=structWithNewMetadata,
            )
          : structWithNewMetadata.serialize,
      }
    }
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

  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseMigrationFactory=switch maybeRefineParser {
    | Some(refineParser) =>
      MigrationFactory.make((. ~ctx, ~struct as compilingStruct) => {
        struct.parseMigrationFactory(. ~ctx, ~struct=compilingStruct)
        ctx->MigrationFactory.Ctx.planSyncMigration(input => {
          let () = refineParser->Lib.Fn.call1(input)
          input
        })
      })
    | None => struct.parseMigrationFactory
    },
    ~serializeMigrationFactory=switch maybeRefineSerializer {
    | Some(refineSerializer) =>
      MigrationFactory.make((. ~ctx, ~struct as compilingStruct) => {
        ctx->MigrationFactory.Ctx.planSyncMigration(input => {
          let () = refineSerializer->Lib.Fn.call1(input)
          input
        })
        struct.serializeMigrationFactory(. ~ctx, ~struct=compilingStruct)
      })
    | None => struct.serializeMigrationFactory
    },
    ~metadataDict=?struct.maybeMetadataDict,
    (),
  )
}

let asyncRefine = (struct, ~parser, ()) => {
  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as compilingStruct) => {
      struct.parseMigrationFactory(. ~ctx, ~struct=compilingStruct)
      ctx->MigrationFactory.Ctx.planAsyncMigration(input => {
        parser
        ->Lib.Fn.call1(input)
        ->Lib.Promise.thenResolve(
          () => {
            input
          },
        )
      })
    }),
    ~serializeMigrationFactory=struct.serializeMigrationFactory,
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
    ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as compilingStruct) => {
      struct.parseMigrationFactory(. ~ctx, ~struct=compilingStruct)
      switch maybeTransformParser {
      | Some(transformParser) => ctx->MigrationFactory.Ctx.planSyncMigration(transformParser)
      | None => ctx->MigrationFactory.Ctx.planMissingParserMigration
      }
    }),
    ~serializeMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as compilingStruct) => {
      switch maybeTransformSerializer {
      | Some(transformSerializer) =>
        ctx->MigrationFactory.Ctx.planSyncMigration(transformSerializer)
      | None => ctx->MigrationFactory.Ctx.planMissingSerializerMigration
      }
      struct.serializeMigrationFactory(. ~ctx, ~struct=compilingStruct)
    }),
    ~metadataDict=?struct.maybeMetadataDict,
    (),
  )
}

let advancedTransform: (
  t<'value>,
  ~parser: (~struct: t<'value>) => migration<'value, 'transformed>=?,
  ~serializer: (~struct: t<'value>) => migration<'transformed, 'value>=?,
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
    ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as compilingStruct) => {
      struct.parseMigrationFactory(. ~ctx, ~struct=compilingStruct)
      switch maybeTransformParser {
      | Some(transformParser) =>
        switch (transformParser->castPublicMigrationFactoryToUncurried)(.
          ~struct=compilingStruct->castUnknownStructToAnyStruct,
        ) {
        | Sync(syncMigration) => ctx->MigrationFactory.Ctx.planSyncMigration(syncMigration)
        | Async(asyncMigration) => ctx->MigrationFactory.Ctx.planAsyncMigration(asyncMigration)
        }
      | None => ctx->MigrationFactory.Ctx.planMissingParserMigration
      }
    }),
    ~serializeMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as compilingStruct) => {
      switch maybeTransformSerializer {
      | Some(transformSerializer) =>
        switch (transformSerializer->castPublicMigrationFactoryToUncurried)(.
          ~struct=compilingStruct->castUnknownStructToAnyStruct,
        ) {
        | Sync(syncMigration) => ctx->MigrationFactory.Ctx.planSyncMigration(syncMigration)
        | Async(asyncMigration) => ctx->MigrationFactory.Ctx.planAsyncMigration(asyncMigration)
        }
      | None => ctx->MigrationFactory.Ctx.planMissingSerializerMigration
      }
      struct.serializeMigrationFactory(. ~ctx, ~struct=compilingStruct)
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
      ~parseMigrationFactory=struct.parseMigrationFactory,
      ~serializeMigrationFactory=struct.serializeMigrationFactory,
      ~metadataDict=?struct.maybeMetadataDict,
      (),
    )
  | _ =>
    make(
      ~name=struct.name,
      ~tagged=struct.tagged,
      ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as compilingStruct) => {
        switch maybePreprocessParser {
        | Some(preprocessParser) =>
          switch (preprocessParser->castPublicMigrationFactoryToUncurried)(.
            ~struct=compilingStruct->castUnknownStructToAnyStruct,
          ) {
          | Sync(syncMigration) => ctx->MigrationFactory.Ctx.planSyncMigration(syncMigration)
          | Async(asyncMigration) => ctx->MigrationFactory.Ctx.planAsyncMigration(asyncMigration)
          }
        | None => ctx->MigrationFactory.Ctx.planMissingParserMigration
        }
        struct.parseMigrationFactory(. ~ctx, ~struct=compilingStruct)
      }),
      ~serializeMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as compilingStruct) => {
        struct.serializeMigrationFactory(. ~ctx, ~struct=compilingStruct)
        switch maybePreprocessSerializer {
        | Some(preprocessSerializer) =>
          switch (preprocessSerializer->castPublicMigrationFactoryToUncurried)(.
            ~struct=compilingStruct->castUnknownStructToAnyStruct,
          ) {
          | Sync(syncMigration) => ctx->MigrationFactory.Ctx.planSyncMigration(syncMigration)
          | Async(asyncMigration) => ctx->MigrationFactory.Ctx.planAsyncMigration(asyncMigration)
          }
        | None => ctx->MigrationFactory.Ctx.planMissingSerializerMigration
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
    ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as _) => {
      switch maybeCustomParser {
      | Some(customParser) => ctx->MigrationFactory.Ctx.planSyncMigration(customParser->Obj.magic)
      | None => ctx->MigrationFactory.Ctx.planMissingParserMigration
      }
    }),
    ~serializeMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as _) => {
      switch maybeCustomSerializer {
      | Some(customSerializer) =>
        ctx->MigrationFactory.Ctx.planSyncMigration(customSerializer->Obj.magic)
      | None => ctx->MigrationFactory.Ctx.planMissingSerializerMigration
      }
    }),
    (),
  )
}

module Literal = {
  type tagged =
    | String(string)
    | Int(int)
    | Float(float)
    | Bool(bool)
    | EmptyNull
    | EmptyOption
    | NaN

  external castLiteralToTagged: literal<'a> => tagged = "%identity"

  let metadataId: Metadata.Id.t<tagged> = Metadata.Id.make(
    ~namespace="rescript-struct",
    ~name="Literal",
  )

  let classify = struct => struct->Metadata.get(~id=metadataId)

  module Variant = {
    let factory:
      type literalValue variant. (literal<literalValue>, variant) => t<variant> =
      (innerLiteral, variant) => {
        let tagged = Literal

        let makeParseMigrationFactory = (~literalValue, ~test) => {
          MigrationFactory.make((. ~ctx, ~struct) =>
            ctx->MigrationFactory.Ctx.planSyncMigration(input => {
              if test->Lib.Fn.call1(input) {
                if literalValue->castAnyToUnknown === input {
                  variant
                } else {
                  Error.Internal.UnexpectedValue.raise(~expected=literalValue, ~received=input)
                }
              } else {
                raiseUnexpectedTypeError(~input, ~struct)
              }
            })
          )
        }

        let makeSerializeMigrationFactory = output => {
          MigrationFactory.make((. ~ctx, ~struct as _) =>
            ctx->MigrationFactory.Ctx.planSyncMigration(input => {
              if input === variant {
                output
              } else {
                Error.Internal.UnexpectedValue.raise(~expected=variant, ~received=input)
              }
            })
          )
        }

        switch innerLiteral {
        | EmptyNull =>
          make(
            ~name="EmptyNull Literal (null)",
            ~tagged,
            ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct) =>
              ctx->MigrationFactory.Ctx.planSyncMigration(input => {
                if input === Js.Null.empty {
                  variant
                } else {
                  raiseUnexpectedTypeError(~input, ~struct)
                }
              })
            ),
            ~serializeMigrationFactory=makeSerializeMigrationFactory(Js.Null.empty),
            (),
          )
        | EmptyOption =>
          make(
            ~name="EmptyOption Literal (undefined)",
            ~tagged,
            ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct) =>
              ctx->MigrationFactory.Ctx.planSyncMigration(input => {
                if input === Js.Undefined.empty {
                  variant
                } else {
                  raiseUnexpectedTypeError(~input, ~struct)
                }
              })
            ),
            ~serializeMigrationFactory=makeSerializeMigrationFactory(Js.Undefined.empty),
            (),
          )
        | NaN =>
          make(
            ~name="NaN Literal (NaN)",
            ~tagged,
            ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct) =>
              ctx->MigrationFactory.Ctx.planSyncMigration(input => {
                if Js.Float.isNaN(input) {
                  variant
                } else {
                  raiseUnexpectedTypeError(~input, ~struct)
                }
              })
            ),
            ~serializeMigrationFactory=makeSerializeMigrationFactory(Js.Float._NaN),
            (),
          )
        | Bool(bool) =>
          make(
            ~name=j`Bool Literal ($bool)`,
            ~tagged,
            ~parseMigrationFactory=makeParseMigrationFactory(~literalValue=bool, ~test=input =>
              input->Js.typeof === "boolean"
            ),
            ~serializeMigrationFactory=makeSerializeMigrationFactory(bool),
            (),
          )
        | String(string) =>
          make(
            ~name=`String Literal ("${string}")`,
            ~tagged,
            ~parseMigrationFactory=makeParseMigrationFactory(~literalValue=string, ~test=input =>
              input->Js.typeof === "string"
            ),
            ~serializeMigrationFactory=makeSerializeMigrationFactory(string),
            (),
          )
        | Float(float) =>
          make(
            ~name=`Float Literal (${float->Js.Float.toString})`,
            ~tagged,
            ~parseMigrationFactory=makeParseMigrationFactory(~literalValue=float, ~test=input =>
              input->Js.typeof === "number"
            ),
            ~serializeMigrationFactory=makeSerializeMigrationFactory(float),
            (),
          )
        | Int(int) =>
          make(
            ~name=`Int Literal (${int->Js.Int.toString})`,
            ~tagged,
            ~parseMigrationFactory=makeParseMigrationFactory(~literalValue=int, ~test=input =>
              input->Lib.Int.test
            ),
            ~serializeMigrationFactory=makeSerializeMigrationFactory(int),
            (),
          )
        }->Metadata.set(
          ~id=metadataId,
          ~metadata=innerLiteral->castLiteralToTagged,
          ~withParserUpdate=false,
          ~withSerializerUpdate=false,
        )
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

    let classify = struct => struct->Metadata.get(~id=metadataId)->Lib.Option.getWithDefault(Strip)
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
        ~name="Object",
        ~tagged=Object({fields, fieldNames}),
        ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct) => {
          let unknownKeys = struct->UnknownKeys.classify

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

          ctx->MigrationFactory.Ctx.planSyncMigration(input => {
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

            if unknownKeys === UnknownKeys.Strict {
              switch getMaybeExcessKey(. input->castAnyToUnknown, fields) {
              | Some(excessKey) => Error.Internal.raise(ExcessField(excessKey))
              | None => ()
              }
            }

            withAsyncOps ? newArray->castAnyToUnknown : newArray->Lib.Array.toTuple
          })

          if withAsyncOps {
            ctx->MigrationFactory.Ctx.planAsyncMigration(tempArray => {
              asyncOps
              ->Js.Array2.map(
                ((originalIdx, fieldName)) => {
                  (
                    tempArray->castUnknownToAny->Js.Array2.unsafe_get(originalIdx)->Obj.magic
                  )(.)->Lib.Promise.catch(
                    exn => {
                      switch exn {
                      | Error.Internal.Exception(internalError) =>
                        Error.Internal.Exception(
                          internalError->Error.Internal.prependLocation(fieldName),
                        )
                      | _ => exn
                      }->raise
                    },
                  )
                },
              )
              ->Lib.Promise.all
              ->Lib.Promise.thenResolve(
                asyncFieldValues => {
                  asyncFieldValues->Js.Array2.forEachi(
                    (fieldValue, idx) => {
                      let (originalIdx, _) = asyncOps->Js.Array2.unsafe_get(idx)
                      tempArray->castUnknownToAny->Lib.Array.set(originalIdx, fieldValue)
                    },
                  )
                  tempArray
                },
              )
            })
          }
        }),
        ~serializeMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as _) =>
          ctx->MigrationFactory.Ctx.planSyncMigration(input => {
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
          })
        ),
        (),
      )
    }
  )->Obj.magic

  let strip = struct => {
    struct->Metadata.set(
      ~id=UnknownKeys.metadataId,
      ~metadata=UnknownKeys.Strip,
      ~withParserUpdate=true,
      ~withSerializerUpdate=false,
    )
  }

  let strict = struct => {
    struct->Metadata.set(
      ~id=UnknownKeys.metadataId,
      ~metadata=UnknownKeys.Strict,
      ~withParserUpdate=true,
      ~withSerializerUpdate=false,
    )
  }
}

module Never = {
  let factory = () => {
    let migrationFactory = MigrationFactory.make((. ~ctx, ~struct) =>
      ctx->MigrationFactory.Ctx.planSyncMigration(input => {
        raiseUnexpectedTypeError(~input, ~struct)
      })
    )

    make(
      ~name=`Never`,
      ~tagged=Never,
      ~parseMigrationFactory=migrationFactory,
      ~serializeMigrationFactory=migrationFactory,
      (),
    )
  }
}

module Unknown = {
  let factory = () => {
    make(
      ~name=`Unknown`,
      ~tagged=Unknown,
      ~parseMigrationFactory=MigrationFactory.empty,
      ~serializeMigrationFactory=MigrationFactory.empty,
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
      ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct) =>
        ctx->MigrationFactory.Ctx.planSyncMigration(input => {
          if input->Js.typeof === "string" {
            input
          } else {
            raiseUnexpectedTypeError(~input, ~struct)
          }
        })
      ),
      ~serializeMigrationFactory=MigrationFactory.empty,
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      if value->Js.String2.length < length {
        Error.raise(
          maybeMessage->Lib.Option.getWithDefault(
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
          maybeMessage->Lib.Option.getWithDefault(
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
          maybeMessage->Lib.Option.getWithDefault(
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
      ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct) =>
        ctx->MigrationFactory.Ctx.planSyncMigration(input => {
          if input->Js.typeof === "boolean" {
            input
          } else {
            raiseUnexpectedTypeError(~input, ~struct)
          }
        })
      ),
      ~serializeMigrationFactory=MigrationFactory.empty,
      (),
    )
  }
}

module Int = {
  let factory = () => {
    make(
      ~name=`Int`,
      ~tagged=Int,
      ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct) =>
        ctx->MigrationFactory.Ctx.planSyncMigration(input => {
          if Lib.Int.test(input) {
            input
          } else {
            raiseUnexpectedTypeError(~input, ~struct)
          }
        })
      ),
      ~serializeMigrationFactory=MigrationFactory.empty,
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, thanValue) => {
    let refiner = value => {
      if value < thanValue {
        Error.raise(
          maybeMessage->Lib.Option.getWithDefault(
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
          maybeMessage->Lib.Option.getWithDefault(
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
      ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct) =>
        ctx->MigrationFactory.Ctx.planSyncMigration(input => {
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
      ~serializeMigrationFactory=MigrationFactory.empty,
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
      ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct) =>
        ctx->MigrationFactory.Ctx.planSyncMigration(input => {
          if %raw(`input instanceof Date`) && input->Js.Date.getTime->Js.Float.isNaN->not {
            input
          } else {
            raiseUnexpectedTypeError(~input, ~struct)
          }
        })
      ),
      ~serializeMigrationFactory=MigrationFactory.empty,
      (),
    )
  }
}

module Null = {
  let factory = innerStruct => {
    make(
      ~name=`Null`,
      ~tagged=Null(innerStruct->Obj.magic),
      ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as _) => {
        let planSyncMigration = fn => {
          ctx->MigrationFactory.Ctx.planSyncMigration(input => {
            switch input->Js.Null.toOption {
            | Some(innerData) => Some(fn(. innerData))
            | None => None
            }
          })
        }
        switch innerStruct.parse {
        | NoopOperation => ctx->MigrationFactory.Ctx.planSyncMigration(Js.Null.toOption)
        | SyncOperation(fn) => planSyncMigration(fn)
        | AsyncOperation(fn) => {
            planSyncMigration(fn)
            ctx->MigrationFactory.Ctx.planAsyncMigration(input => {
              switch input {
              | Some(asyncFn) => asyncFn(.)->Lib.Promise.thenResolve(value => Some(value))
              | None => None->Lib.Promise.resolve
              }
            })
          }
        }
      }),
      ~serializeMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as _) =>
        ctx->MigrationFactory.Ctx.planSyncMigration(input => {
          switch input {
          | Some(value) => serializeInner(~struct=innerStruct, ~value)
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
    make(
      ~name=`Option`,
      ~tagged=Option(innerStruct->Obj.magic),
      ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as _) => {
        let planSyncMigration = fn => {
          ctx->MigrationFactory.Ctx.planSyncMigration(input => {
            switch input {
            | Some(innerData) => Some(fn(. innerData))
            | None => None
            }
          })
        }
        switch innerStruct.parse {
        | NoopOperation => ()
        | SyncOperation(fn) => planSyncMigration(fn)
        | AsyncOperation(fn) => {
            planSyncMigration(fn)
            ctx->MigrationFactory.Ctx.planAsyncMigration(input => {
              switch input {
              | Some(asyncFn) => asyncFn(.)->Lib.Promise.thenResolve(value => Some(value))
              | None => None->Lib.Promise.resolve
              }
            })
          }
        }
      }),
      ~serializeMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as _) =>
        ctx->MigrationFactory.Ctx.planSyncMigration(input => {
          switch input {
          | Some(value) => serializeInner(~struct=innerStruct, ~value)
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
      ~withParserUpdate=false,
      ~withSerializerUpdate=false,
    )
  }

  let classify = struct => struct->Metadata.get(~id=metadataId)
}

module Array = {
  let factory = innerStruct => {
    make(
      ~name=`Array`,
      ~tagged=Array(innerStruct->Obj.magic),
      ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct) => {
        ctx->MigrationFactory.Ctx.planSyncMigration(input => {
          if Js.Array2.isArray(input) === false {
            raiseUnexpectedTypeError(~input, ~struct)
          } else {
            input
          }
        })

        let planSyncMigration = fn => {
          ctx->MigrationFactory.Ctx.planSyncMigration(input => {
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

        switch innerStruct.parse {
        | NoopOperation => ()
        | SyncOperation(fn) => planSyncMigration(fn)
        | AsyncOperation(fn) =>
          planSyncMigration(fn)
          ctx->MigrationFactory.Ctx.planAsyncMigration(input => {
            input
            ->Js.Array2.mapi(
              (asyncFn, idx) => {
                asyncFn(.)->Lib.Promise.catch(
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
            ->Lib.Promise.all
            ->Obj.magic
          })
        }
      }),
      ~serializeMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as _) => {
        switch innerStruct.serialize {
        | NoopOperation => ()
        | SyncOperation(fn) =>
          ctx->MigrationFactory.Ctx.planSyncMigration(input => {
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
        | AsyncOperation(_) => Error.Unreachable.panic()
        }
      }),
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value => {
      if value->Js.Array2.length < length {
        Error.raise(
          maybeMessage->Lib.Option.getWithDefault(
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
          maybeMessage->Lib.Option.getWithDefault(
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
          maybeMessage->Lib.Option.getWithDefault(
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
      ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct) => {
        let planSyncMigration = fn => {
          ctx->MigrationFactory.Ctx.planSyncMigration(input => {
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

        ctx->MigrationFactory.Ctx.planSyncMigration(input => {
          if input->Lib.Object.test === false {
            raiseUnexpectedTypeError(~input, ~struct)
          } else {
            input
          }
        })

        switch innerStruct.parse {
        | NoopOperation => ()
        | SyncOperation(fn) => planSyncMigration(fn)
        | AsyncOperation(fn) =>
          planSyncMigration(fn)
          ctx->MigrationFactory.Ctx.planAsyncMigration(input => {
            let keys = input->Js.Dict.keys
            keys
            ->Js.Array2.map(
              key => {
                let asyncFn = input->Js.Dict.unsafeGet(key)
                try {
                  asyncFn(.)->Lib.Promise.catch(
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
            ->Lib.Promise.all
            ->Lib.Promise.thenResolve(
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
      ~serializeMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as _) => {
        switch innerStruct.serialize {
        | NoopOperation => ()
        | SyncOperation(fn) =>
          ctx->MigrationFactory.Ctx.planSyncMigration(input => {
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
        | AsyncOperation(_) => Error.Unreachable.panic()
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
    make(
      ~name=innerStruct.name,
      ~tagged=innerStruct.tagged,
      ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as _) => {
        switch innerStruct.parse {
        | NoopOperation =>
          ctx->MigrationFactory.Ctx.planSyncMigration(input => {
            input->castUnknownToAny->Lib.Option.getWithDefault(defaultValue)
          })
        | SyncOperation(fn) =>
          ctx->MigrationFactory.Ctx.planSyncMigration(input => {
            fn(. input)->castUnknownToAny->Lib.Option.getWithDefault(defaultValue)
          })
        | AsyncOperation(fn) =>
          ctx->MigrationFactory.Ctx.planAsyncMigration(input => {
            fn(. input)(.)->Lib.Promise.thenResolve(
              value => {
                value->castUnknownToAny->Lib.Option.getWithDefault(defaultValue)
              },
            )
          })
        }
      }),
      ~serializeMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as _) => {
        ctx->MigrationFactory.Ctx.planSyncMigration(input => {
          serializeInner(~struct=innerStruct, ~value=Some(input))
        })
      }),
      (),
    )->Metadata.set(
      ~id=metadataId,
      ~metadata=WithDefaultValue(defaultValue->castAnyToUnknown),
      ~withParserUpdate=false,
      ~withSerializerUpdate=false,
    )
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
        ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct) => {
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

          ctx->MigrationFactory.Ctx.planSyncMigration(input => {
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
          })

          if withAsyncOps {
            ctx->MigrationFactory.Ctx.planAsyncMigration(tempArray => {
              asyncOps
              ->Js.Array2.map(
                originalIdx => {
                  (
                    tempArray->castUnknownToAny->Js.Array2.unsafe_get(originalIdx)->Obj.magic
                  )(.)->Lib.Promise.catch(
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
              ->Lib.Promise.all
              ->Lib.Promise.thenResolve(
                values => {
                  values->Js.Array2.forEachi(
                    (value, idx) => {
                      let originalIdx = asyncOps->Js.Array2.unsafe_get(idx)
                      tempArray->castUnknownToAny->Lib.Array.set(originalIdx, value)
                    },
                  )
                  tempArray->castUnknownToAny->Lib.Array.toTuple
                },
              )
            })
          }
        }),
        ~serializeMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as _) =>
          ctx->MigrationFactory.Ctx.planSyncMigration(input => {
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
      Error.UnionLackingStructs.panic()
    }

    make(
      ~name=`Union`,
      ~tagged=Union(structs->Obj.magic),
      ~parseMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as compilingStruct) => {
        let structs = compilingStruct->classify->unsafeGetVariantPayload

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

        if noopOps->Js.Array2.length === 0 {
          ctx->MigrationFactory.Ctx.planSyncMigration(input => {
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
          })

          if withAsyncOps {
            ctx->MigrationFactory.Ctx.planAsyncMigration(input => {
              switch input["maybeSyncValue"] {
              | Some(syncValue) => syncValue->Lib.Promise.resolve
              | None =>
                asyncOps
                ->Js.Array2.map(
                  ((originalIdx, fn)) => {
                    try {
                      fn(. input["originalInput"])(.)->Lib.Promise.thenResolveWithCatch(
                        value => raise(HackyValidValue(value)),
                        exn =>
                          switch exn {
                          | Error.Internal.Exception(internalError) =>
                            input["tempErrors"]->Lib.Array.set(originalIdx, internalError)
                          | _ => raise(exn)
                          },
                      )
                    } catch {
                    | Error.Internal.Exception(internalError) =>
                      input["tempErrors"]
                      ->Lib.Array.set(originalIdx, internalError)
                      ->Lib.Promise.resolve
                    }
                  },
                )
                ->Lib.Promise.all
                ->Lib.Promise.thenResolveWithCatch(
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
      ~serializeMigrationFactory=MigrationFactory.make((. ~ctx, ~struct as _) =>
        ctx->MigrationFactory.Ctx.planSyncMigration(input => {
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
    result->Lib.Result.mapError(Error.toString)
  }
}

let object0 = Object.factory
let object1 = Object.factory
let object2 = Object.factory
let object3 = Object.factory
let object4 = Object.factory
let object5 = Object.factory
let object6 = Object.factory
let object7 = Object.factory
let object8 = Object.factory
let object9 = Object.factory
let object10 = Object.factory
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
      Error.raise(obj->Js.Exn.message->Lib.Option.getWithDefault("Failed to parse JSON"))
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
