type locationComponent = Field(string) | Index(int)

type location = array<locationComponent>

type rec t = {kind: kind, mutable location: location}
and kind =
  | MissingConstructor
  | MissingDestructor
  | ConstructingFailed(string)
  | DestructingFailed(string)
  | DecodingFailed(string)

module MissingConstructor = {
  let make = () => {
    {kind: MissingConstructor, location: []}
  }
}

module MissingDestructor = {
  let make = () => {
    {kind: MissingDestructor, location: []}
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
    "." ++
    location
    ->Js.Array2.map(s =>
      switch s {
      | Field(field) => `"` ++ field ++ `"`
      | Index(index) => `[` ++ index->Js.Int.toString ++ `]`
      }
    )
    ->Js.Array2.joinWith(".")
  }
}

let prependLocation = (error, location) => {
  error.location = [location]->Js.Array2.concat(error.location)
  error
}

let toString = error => {
  let locationText = error.location->formatLocation
  switch error.kind {
  | MissingConstructor => `Struct missing constructor at ${locationText}`
  | MissingDestructor => `Struct missing destructor at ${locationText}`
  | ConstructingFailed(reason) => `Struct construction failed at ${locationText}. Reason: ${reason}`
  | DestructingFailed(reason) => `Struct destruction failed at ${locationText}. Reason: ${reason}`
  | DecodingFailed(reason) => `Struct decoding failed at ${locationText}. Reason: ${reason}`
  }
}
