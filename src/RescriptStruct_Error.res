%%raw(`class RescriptStructError extends Error {
  parser(message) {
    super(message);
    this.name = "RescriptStructError";
  }
}`)
let raiseRescriptStructError = %raw(`function(message){
  throw new RescriptStructError(message);
}`)

type rec t = {operation: operation, reason: string, path: array<string>}
and operation =
  | Serializing
  | Parsing

module MissingParserAndSerializer = {
  let raise = location =>
    raiseRescriptStructError(`For a ${location} either a parser, or a serializer is required`)
}

module UnknownKeysRequireRecord = {
  let raise = () =>
    raiseRescriptStructError("Can't set up unknown keys strategy. The struct is not Record")
}

module UnionLackingStructs = {
  let raise = () => raiseRescriptStructError("A Union struct factory require at least two structs")
}

module ParsingFailed = {
  let make = reason => {
    {operation: Parsing, reason: reason, path: []}
  }
}

module SerializingFailed = {
  let make = reason => {
    {operation: Serializing, reason: reason, path: []}
  }
}

module MissingParser = {
  let make = () => {
    {operation: Parsing, reason: "Struct parser is missing", path: []}
  }
}

module MissingSerializer = {
  let make = () => {
    {operation: Serializing, reason: "Struct serializer is missing", path: []}
  }
}

module UnexpectedType = {
  let make = (~expected, ~got, ~operation) => {
    {operation: operation, reason: `Expected ${expected}, got ${got}`, path: []}
  }
}

module UnexpectedValue = {
  let make = (~expectedValue, ~gotValue, ~operation) => {
    let reason = if expectedValue->Js.typeof === "string" {
      j`Expected "$expectedValue", got "$gotValue"`
    } else {
      j`Expected $expectedValue, got $gotValue`
    }
    {operation: operation, reason: reason, path: []}
  }
}

module ExcessField = {
  let make = (~fieldName) => {
    {
      operation: Parsing,
      reason: `Encountered disallowed excess key "${fieldName}" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely`,
      path: [],
    }
  }
}

let formatPath = path => {
  if path->Js.Array2.length === 0 {
    "root"
  } else {
    path->Js.Array2.map(pathItem => `[${pathItem}]`)->Js.Array2.joinWith("")
  }
}

let prependField = (error, field) => {
  {
    operation: error.operation,
    reason: error.reason,
    path: [field]->Js.Array2.concat(error.path),
  }
}

let prependIndex = (error, index) => {
  error->prependField(index->Js.Int.toString)
}

let toString = error => {
  let prefix = `[ReScript Struct]`
  let operation = switch error.operation {
  | Serializing => "serializing"
  | Parsing => "parsing"
  }
  let pathText = error.path->formatPath
  `${prefix} Failed ${operation} at ${pathText}. Reason: ${error.reason}`
}
