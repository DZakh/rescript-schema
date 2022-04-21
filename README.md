# ReScript Struct

A simple and composable way to describe relationship between JavaScript and ReScript structures.

## Status

> **rescript-struct** is currently in beta. Its core API is useable right now, but you might need to pull request improvements for advanced use cases, or fixes for some bugs. Some of its APIs are not "finalized" and will have breaking changes over time as we discover better solutions.

## Installation

```sh
npm install rescript-struct
```

Then add `rescript-struct` to `bs-dependencies` in your `bsconfig.json`:

```diff
{
  ...
+ "bs-dependencies": ["rescript-struct"]
}
```

## Usage

ReScript Struct allows you to define the shape of data. You can use the shape to serialize, validate or do whatever you need with a neat integration system.

### Libraries using ReScript Struct

- [ReScript JSON Schema](https://github.com/DZakh/rescript-json-schema) - Typesafe JSON schema for ReScript

### Example

```rescript
type author = {
  id: float,
  tags: array<string>,
  isAproved: bool,
  deprecatedAge: option<int>,
}

let authorStruct: S.t<author> = S.record4(
  ~fields=(
    ("Id", S.float()),
    ("Tags", S.option(S.array(S.string()))->S.default([])),
    ("IsApproved", S.coercedInt(~constructor=int =>
        switch int {
        | 1 => true
        | _ => false
        }->Ok
      , ())),
    ("Age", S.deprecated(~message="A useful explanation", S.int())),
  ),
  ~constructor=((id, tags, isAproved, deprecatedAge)) =>
    {id: id, tags: tags, isAproved: isAproved, deprecatedAge: deprecatedAge}->Ok,
  (),
)

let constructResult1: result<author, string> = %raw(`{
  "Id": 1,
  "IsApproved": 1,
  "Age": 12,
}`)->S.constructWith(authorStruct)
// Equal to:
// Ok({
//   id: 1.,
//   tags: [],
//   isAproved: true,
//   deprecatedAge: Some(12),
// })

let constructResult2: result<author, string> = %raw(`{
  "Id": 1,
  "IsApproved": 0,
  "Tags": ["Loved"],
}`)->S.constructWith(authorStruct)
// Equal to:
// Ok({
//   id: 1.,
//   tags: ["Loved"],
//   isAproved: false,
//   deprecatedAge: None,
// })
```

## API Reference

### Core

#### `S.constructWith`

`(Js.Json.t, S.t<'value>) => result<'value, string>`

```rescript
let constructResult = data->S.constructWith(userStruct)
```

Construct a data using the coercion logic that is built-in to the struct, returning the result with a newly coerced value or an error message.

> 🧠 The function is responsible only for coercion and suitable for cases when the data is valid. If not, you'll get a runtime error or invalid state.

#### `S.destructWith`

`('value, S.t<'value>) => result<Js.Json.t, string>`

```rescript
let destructResult = user->S.destructWith(userStruct)
```

Destruct a value using the coercion logic that is built-in to the struct, returning the result with a newly coerced data or an error message.

### Types

**rescript-struct** exposes factory functions for a variety of common JavaScript types. You can also define your own custom struct factories.

#### `S.string`

`unit => S.t<string>`

```rescript
let struct: S.t<string> = S.string()

%raw(`a string of text`)->S.constructWith(struct)
```

```rescript
Ok("a string of text")
```

`string` structs represent a data that is a string.


#### `S.coercedString`

`(~constructor: string => result<'value, string>=?, ~destructor: 'value => result<string, string>=?, unit) => S.t<'value>`

```rescript
let struct: S.t<string> = S.coercedString(~constructor=value => value->Js.String2.trim->Ok, ())

%raw(`   a string of text  `)->S.constructWith(struct)
```

```rescript
Ok("a string of text")
```

`coercedString` structs represent a data that is a string.

#### `S.bool`

`unit => S.t<bool>`

```rescript
let struct: S.t<bool> = S.bool()

%raw(false)->S.constructWith(struct)
```

```rescript
Ok(false)
```

`bool` structs represent a data that is a boolean.

#### `S.coercedBool`

`(~constructor: bool => result<'value, string>=?, ~destructor: 'value => result<bool, string>=?, unit) => S.t<'value>`

```rescript
let struct: S.t<string> = S.coercedBool(~constructor=value =>
  switch value {
  | true => "Yes"
  | false => "No"
  }->Ok
, ())

%raw(false)->S.constructWith(struct)
```

```rescript
Ok("No")
```

`coercedBool` structs represent a data that is a boolean.

#### `S.int`

`unit => S.t<int>`

```rescript
let struct: S.t<int> = S.int()

%raw(123)->S.constructWith(struct)
```

```rescript
Ok(123)
```

`int` structs represent a data that is an integer.

#### `S.coercedInt`

`(~constructor: int => result<'value, string>=?, ~destructor: 'value => result<int, string>=?, unit) => S.t<'value>`

```rescript
let struct: S.t<bool> = S.coercedInt(~constructor=value =>
  switch value {
  | 1 => Ok(true)
  | 0 => Ok(false)
  | _ => Error("Invalid exit code")
  }
, ())

%raw(1)->S.constructWith(struct)
```

```rescript
Ok(true)
```

`coercedInt` structs represent a data that is an integer.

#### `S.float`

`unit => S.t<float>`

```rescript
let struct: S.t<float> = S.float()

%raw(123)->S.constructWith(struct)
```

```rescript
Ok(123.)
```

`float` structs represent a data that is a number.

#### `S.coercedFloat`

`(~constructor: float => result<'value, string>=?, ~destructor: 'value => result<float, string>=?, unit) => S.t<'value>`

```rescript
let struct: S.t<Js.Date.t> = S.coercedFloat(~destructor=date => date->Js.Date.getTime->Ok, ())

Js.Date.fromFloat(1643669467293.)->S.destructWith(struct)
```

```rescript
Ok(%raw(`new Date(1643669467293)`))
```

`coercedFloat` structs represent a data that is a number.
