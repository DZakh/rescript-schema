type t
type operation =
  | Serializing
  | Parsing

module MissingParserAndSerializer: {
  let raise: string => 'a
}

module UnknownKeysRequireRecord: {
  let raise: unit => 'a
}

module UnionLackingStructs: {
  let raise: unit => 'a
}

module MissingParser: {
  let make: unit => t
}

module MissingSerializer: {
  let make: unit => t
}

module ParsingFailed: {
  let make: string => t
}

module SerializingFailed: {
  let make: string => t
}

module UnexpectedType: {
  let make: (~expected: string, ~got: string, ~operation: operation) => t
}

module UnexpectedValue: {
  let make: (~expectedValue: 'value, ~gotValue: 'value, ~operation: operation) => t
}

module ExcessField: {
  let make: (~fieldName: string) => t
}

let prependField: (t, string) => t
let prependIndex: (t, int) => t

let toString: t => string
