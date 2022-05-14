type t

module MissingRecordConstructorAndDestructor: {
  let raise: unit => unit
}

module MissingTransformConstructorAndDestructor: {
  let raise: unit => unit
}

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

module DecodingFailed: {
  let make: string => t

  module UnexpectedType: {
    let make: (~expected: string, ~got: string) => t
  }

  module ExtraProperties: {
    let make: (~properties: array<string>) => t
  }
}

let prependField: (t, string) => t
let prependIndex: (t, int) => t

let toString: t => string
