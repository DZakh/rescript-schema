type t

module MissingRecordConstructorAndDestructor: {
  let raise: unit => 'a
}

module MissingTransformConstructorAndDestructor: {
  let raise: unit => 'a
}

module MissingConstructorAndDestructorRefine: {
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

module ParsingOperationFailed: {
  let make: string => t
}

module SerializingOperationFailed: {
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

  module ExcessField: {
    let make: (~fieldName: string) => t
  }
}

let prependField: (t, string) => t
let prependIndex: (t, int) => t

let toString: t => string
