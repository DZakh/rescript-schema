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
  | DecodingFailed(string)

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

module DecodingFailed = {
  let make = reason => {
    {kind: DecodingFailed(reason), location: []}
  }

  module UnexpectedType = {
    let make = (~expected, ~got) => {
      make(`Expected ${expected}, got ${got}`)
    }
  }

  module ExtraProperties = {
    let make = (~properties) => {
      make(
        `Encountered extra properties ${switch properties->Js.Json.stringifyAny {
          | Some(s) => s
          | None => ""
          }} on an object. If you want to be less strict and ignore any extra properties, use Shape instead (not implemented), to ignore a specific extra property, use Deprecated`,
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
  | DecodingFailed(reason) =>
    `[ReScript Struct] Failed decoding at ${locationText}. Reason: ${reason}`
  }
}
