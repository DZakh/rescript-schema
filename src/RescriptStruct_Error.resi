type t

module MissingRecordConstructorAndDestructor: {
  let raise: unit => 'a
}

module MissingTransformConstructorAndDestructor: {
  let raise: unit => 'a
}

module UnknownKeysRequireRecord: {
  let raise: unit => 'a
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

module ParsingFailed: {
  let make: string => t

  module UnexpectedType: {
    let make: (~expected: string, ~got: string) => t
  }

  module UnexpectedValue: {
    let make: (~expectedValue: 'value, ~gotValue: 'value) => t
  }

  module DisallowedUnknownKeys: {
    let make: (~unknownKeys: array<string>) => t
  }
}

let prependField: (t, string) => t
let prependIndex: (t, int) => t

let toString: t => string
