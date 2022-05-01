# ReScript Struct

A simple and composable way to describe relationship between JavaScript and ReScript structures.

It's a great tool to encode and decode JSON data with type safety.

Also, other libraries can use ReScript Struct as a building block with a neat integration system:

- [ReScript JSON Schema](https://github.com/DZakh/rescript-json-schema) - Typesafe JSON schema for ReScript

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


## Example

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
    ("IsApproved", S.int()->S.coerce(~constructor=int =>
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
}`)->S.Json.decodeWith(authorStruct)
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
}`)->S.Json.decodeWith(authorStruct)
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

Construct data using the coercion logic that is built-in to the struct, returning the result with a newly coerced value or an error message.

> 🧠 The function is responsible only for coercion and suitable for cases when the data is valid. If not, you'll get a runtime error or invalid state. Use `S.Json.decodeWith` to safely decode data.

#### `S.destructWith`

`('value, S.t<'value>) => result<Js.Json.t, string>`

```rescript
let destructResult = user->S.destructWith(userStruct)
```

Destruct value using the coercion logic that is built-in to the struct. It returns the result with a newly coerced data or an error message.

#### `S.Json.decodeWith`

`(Js.Json.t, t<'value>) => result<'value, string>`

```rescript
let decodeResult = data->S.Json.decodeWith(userStruct)
```

Decode data validating that JSON represents described struct and using the coercion logic. It returns the result with a decoded value or an error message.

#### `S.Json.decodeStringWith`

`(string, t<'value>) => result<'value, string>`

```rescript
let decodeResult = json->S.Json.decodeStringWith(userStruct)
```

Parse and decode data validating that JSON represents described struct and using the coercion logic. It returns the result with a decoded value or an error message.

#### `S.Json.encodeWith`

`('value, t<'value>) => result<Js.Json.t, string>`

```rescript
let encodeResult = user->S.Json.encodeWith(userStruct)
```

Decode value using the coercion logic. It returns the result with a decoded data or an error message.

#### `S.Json.encodeStringWith`

`('value, t<'value>) => result<string, string>`

```rescript
let encodeStringResult = user->S.Json.encodeStringWith(userStruct)
```

Decode value using the coercion logic and stringify it. It returns the result with a decoded stringified data or an error message.

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

`string` struct represents a data that is a string.

#### `S.bool`

`unit => S.t<bool>`

```rescript
let struct: S.t<bool> = S.bool()

%raw(`false`)->S.constructWith(struct)
```

```rescript
Ok(false)
```

`bool` struct represents a data that is a boolean.

#### `S.int`

`unit => S.t<int>`

```rescript
let struct: S.t<int> = S.int()

%raw(`123`)->S.constructWith(struct)
```

```rescript
Ok(123)
```

`int` struct represents a data that is an integer.

#### `S.float`

`unit => S.t<float>`

```rescript
let struct: S.t<float> = S.float()

%raw(`123`)->S.constructWith(struct)
```

```rescript
Ok(123.)
```

`float` struct represents a data that is a number.

#### `S.array`

`S.t<'value> => S.t<array<'value>>`

```rescript
let struct: S.t<array<string>> = S.array(S.string())

%raw(`["Hello", "World"]`)->S.constructWith(struct)
```

```rescript
Ok(["Hello", "World"])
```

`array` struct represents an array of data of a specific type.

#### `S.dict`

`S.t<'value> => S.t<Js.Dict.t<'value>>`

```rescript
let struct: S.t<Js.Dict.t<string>> = S.dict(S.string())

%raw(`{"foo":"bar","baz":"qux"}`)->S.constructWith(struct)
```

```rescript
Ok(Js.Dict.fromArray([("foo", "bar"), ("baz", "qux")]))
```

`dict` struct represents a dictionary of data of a specific type.

#### `S.option`

`S.t<'value> => S.t<option<'value>>`

```rescript
let struct: S.t<option<string>> = S.option(S.string())

%raw(`"a string of text"`)->S.constructWith(struct)
```

```rescript
Ok(Some("a string of text"))
```

`option` struct represents an optional data of a specific type.

#### `S.record1` - `S.record10`

`(~fields: (S.field<'v1>, S.field<'v2>), ~constructor: (('v1, 'v2)) => result<'value, string>=?, ~destructor: 'value => result<('v1, 'v2), string>=?, unit) => S.t<'value>`

```rescript
type author = {
  id: string,
}
let struct: S.t<author> = S.record1(~fields=("ID", S.string()), ~constructor=id => {id: id}->Ok, ())

%raw(`{"ID": "abc"}`)->S.constructWith(struct)
```

```rescript
Ok(Some({
  id: "abc",
}))
```

`record` struct represents an object and that each of its properties represent a specific type as well.

The record struct factories are available up to 10 fields. If you have an object with more fields, you can create a record struct factory for any number of fields using `S.Record.factory`.

#### `S.Record.factory`

```rescript
let record2: (
  ~fields: (S.field<'v1>, S.field<'v2>),
  ~constructor: (('v1, 'v2)) => result<'value, string>=?,
  ~destructor: 'value => result<('v1, 'v2), string>=?,
  unit,
) => S.t<'value> = S.Record.factory
```

> 🧠 The `S.Record.factory` internal code isn't typesafe, so you should properly annotate the struct factory interface.

#### `S.default`

`(S.t<option<'value>>, 'value) => S.t<'value>`

```rescript
let struct: S.t<string> = S.option(S.string())->S.default("a string of text")

%raw(`undefined`)->S.constructWith(struct)
```

```rescript
Ok(Some("a string of text"))
```

`default` augments a struct to add coercion logic for default values, which are applied when the input is undefined.

#### `S.deprecated`

`(~message: string=?, S.t<'value>) => S.t<option<'value>>`

```rescript
let struct: S.t<option<string>> = S.deprecated(~message="The struct is deprecated", S.string())

%raw(`"a string of text"`)->S.constructWith(struct)
```

```rescript
Ok(Some("a string of text"))
```

`deprecated` struct represents a data of a specific type and makes it optional. The message may be used by an integration library.

#### `S.custom`

`(~constructor: Js.Json.t => result<'value, string>=?, ~destructor: 'value => result<Js.Json.t, string>=?, unit) => S.t<'value>`

You can also define your own custom structs that are specific to your application's requirements.

> 🧠 It's mostly needed when you want to define a new data type, for other cases, it's better to use coercion.

### Coercions

**rescript-struct** allows structs to be augmented with coercion logic, letting you transform data during construction and destruction. This is most commonly used to apply default values to an input, but it can be used for more complex cases like pre-trimming strings, or mapping input to a convenient ReScript data structure.

#### `S.coerce`

`(S.t<'value>, ~constructor: 'value => result<'coercedValue, string>=?, ~destructor: 'coercedValue => result<'value, string>=?, unit) => S.t<'coercedValue>`

```rescript
let trimmed: S.t<string> => S.t<string> = S.coerce(_, ~constructor=s => s->Js.String2.trim->Ok, ~destructor=s => s->Ok, ())
```
```rescript
let nonEmptyString: unit => S.t<option<string>> = () => {
  S.string()->S.coerce(
    ~constructor=s =>
      switch s {
      | "" => None
      | s' => Some(s')
      }->Ok,
    ~destructor=nonEmptyString =>
      {
        switch nonEmptyString {
        | Some(s) => s
        | None => ""
        }
      }->Ok,
    (),
  )
}
```
```rescript
let date: unit => S.t<Js.Date.t> = () => {
  S.float()->S.coerce(~destructor=date => date->Js.Date.getTime->Ok, ())
}
```

> 🧠 For coercion either a constructor, or a destructor is required.

### Integration

If you're a library maintainer, you can use **rescript-struct** as a way to describe a structure and use it in your own way. The most common use case is building type-safe schemas e.g for REST APIs, databases, and forms.

The detailed API documentation is a work in progress, for now, you can use `S.resi` file as a reference and [rescript-json-schema](https://github.com/DZakh/rescript-json-schema) source code.

## Roadmap

- [x] Add custom Coercions
- [x] Add JSON module for decoding and encoding
- [ ] Add Shape struct factory
- [ ] Add Nullable struct factory
- [ ] Add Enum and Literal struct factories
- [ ] Add Dynamic struct factory
- [ ] Add Lazy struct factory
