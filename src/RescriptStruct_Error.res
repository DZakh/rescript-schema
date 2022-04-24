type locationComponent = Field(string) | Index(int)

type location = array<locationComponent>

type rec t = {kind: kind, mutable location: location}
and kind =
  | MissingConstructor
  | MissingDestructor
  | ConstructingFailed(string)
  | DestructingFailed(string)

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

let formatLocation = location =>
  "." ++
  location
  ->Js.Array2.map(s =>
    switch s {
    | Field(field) => `"` ++ field ++ `"`
    | Index(index) => `[` ++ index->Js.Int.toString ++ `]`
    }
  )
  ->Js.Array2.joinWith(".")

let prependLocation = (error, location) => {
  error.location = [location]->Js.Array2.concat(error.location)
  error
}

let toString = error => {
  let withLocationInfo = error.location->Js.Array2.length !== 0
  switch (error.kind, withLocationInfo) {
  | (MissingConstructor, true) => `Struct missing constructor at ${error.location->formatLocation}`
  | (MissingConstructor, false) => `Struct missing constructor at root`
  | (MissingDestructor, true) => `Struct missing destructor at ${error.location->formatLocation}`
  | (MissingDestructor, false) => `Struct missing destructor at root`
  | (ConstructingFailed(reason), true) =>
    `Struct construction failed at ${error.location->formatLocation}. Reason: ${reason}`
  | (ConstructingFailed(reason), false) => `Struct construction failed at root. Reason: ${reason}`
  | (DestructingFailed(reason), true) =>
    `Struct destruction failed at ${error.location->formatLocation}. Reason: ${reason}`
  | (DestructingFailed(reason), false) => `Struct destruction failed at root. Reason: ${reason}`
  }
}
