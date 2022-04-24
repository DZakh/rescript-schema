type locationComponent = Field(string) | Index(int)

type t

module MissingConstructor: {
  let make: unit => t
}

module MissingDestructor: {
  let make: unit => t
}

module ConstructingFailed: {
  let make: string => t
}

module DestructingFailed: {
  let make: string => t
}

let prependLocation: (t, locationComponent) => t

let toString: t => string
