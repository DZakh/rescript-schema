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
  | SerializingFailed(string)
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

module MissingConstructorAndDestructorRefine = {
  let raise = () =>
    raiseRescriptStructError(
      "For refining either a constructor, or a destructor refinement is required",
    )
}

module UnknownKeysRequireRecord = {
  let raise = () =>
    raiseRescriptStructError("Can't set up unknown keys strategy. The struct is not Record")
}

module MissingConstructor = {
  let make = () => {
    {kind: ParsingFailed("Struct constructor is missing"), location: []}
  }
}

module MissingDestructor = {
  let make = () => {
    {kind: SerializingFailed("Struct destructor is missing"), location: []}
  }
}

module ParsingOperationFailed = {
  let make = reason => {
    {kind: ParsingFailed(reason), location: []}
  }
}

module SerializingOperationFailed = {
  let make = reason => {
    {kind: SerializingFailed(reason), location: []}
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

  module ExcessField = {
    let make = (~fieldName) => {
      make(
        `Encountered disallowed excess key "${fieldName}" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely`,
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
  | SerializingFailed(reason) =>
    `[ReScript Struct] Failed serializing at ${locationText}. Reason: ${reason}`
  | ParsingFailed(reason) =>
    `[ReScript Struct] Failed parsing at ${locationText}. Reason: ${reason}`
  }
}
