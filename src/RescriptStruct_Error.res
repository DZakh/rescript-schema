type locationComponent = Field(string) | Index(int)

type location = array<locationComponent>

%%raw(`class RescriptStructError extends Error {
  constructor(message) {
    super(message);
    this.name = "RescriptStructError";
  }
}`)
let raiseRescriptStructError = %raw(`function(message){
  throw new RescriptStructError(message);
}`)

type rec t = {kind: kind, mutable location: location}
and kind =
  | ConstructingFailed(string)
  | DestructingFailed(string)
  | ParsingFailed(string)

module MissingRecordConstructorAndDestructor = {
  let raise = () =>
    raiseRescriptStructError(
      "For a Record struct factory either a constructor, or a destructor is required",
    )
}

module MissingTransformConstructorAndDestructor = {
  let raise = () =>
    raiseRescriptStructError("For transformation either a constructor, or a destructor is required")
}

module UnknownKeysRequireRecord = {
  let raise = () =>
    raiseRescriptStructError("Can't set up unknown keys strategy. The struct is not Record")
}

module MissingConstructor = {
  let make = () => {
    {kind: ConstructingFailed("Struct constructor is missing"), location: []}
  }
}

module MissingDestructor = {
  let make = () => {
    {kind: DestructingFailed("Struct destructor is missing"), location: []}
  }
}

module ConstructingFailed = {
  let make = reason => {
    {kind: ConstructingFailed(reason), location: []}
  }
}

module DestructingFailed = {
  let make = reason => {
    {kind: DestructingFailed(reason), location: []}
  }
}

module ParsingFailed = {
  let make = reason => {
    {kind: ParsingFailed(reason), location: []}
  }

  module UnexpectedType = {
    let make = (~expected, ~got) => {
      make(`Expected ${expected}, got ${got}`)
    }
  }

  module UnexpectedValue = {
    let make = (~expectedValue, ~gotValue) => {
      if expectedValue->Js.typeof === "string" {
        make(j`Expected "$expectedValue", got "$gotValue"`)
      } else {
        make(j`Expected $expectedValue, got $gotValue`)
      }
    }
  }

  module DisallowedUnknownKeys = {
    external unsafeStringArrayToJson: array<string> => Js.Json.t = "%identity"
    let make = (~unknownKeys) => {
      make(
        `Encountered disallowed unknown keys ${unknownKeys
          ->unsafeStringArrayToJson
          ->Js.Json.stringify} on an object. You can use the S.Record.strip to ignore unknown keys during parsing, or use Deprecated to ignore a specific field`,
      )
    }
  }
}

let formatLocation = location => {
  if location->Js.Array2.length === 0 {
    "root"
  } else {
    location
    ->Js.Array2.map(s =>
      switch s {
      | Field(field) => `["` ++ field ++ `"]`
      | Index(index) => `[` ++ index->Js.Int.toString ++ `]`
      }
    )
    ->Js.Array2.joinWith("")
  }
}

let prependField = (error, field) => {
  error.location = [Field(field)]->Js.Array2.concat(error.location)
  error
}

let prependIndex = (error, index) => {
  error.location = [Index(index)]->Js.Array2.concat(error.location)
  error
}

let toString = error => {
  let locationText = error.location->formatLocation
  switch error.kind {
  | ConstructingFailed(reason) =>
    `[ReScript Struct] Failed constructing at ${locationText}. Reason: ${reason}`
  | DestructingFailed(reason) =>
    `[ReScript Struct] Failed destructing at ${locationText}. Reason: ${reason}`
  | ParsingFailed(reason) =>
    `[ReScript Struct] Failed parsing at ${locationText}. Reason: ${reason}`
  }
}
