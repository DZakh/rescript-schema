# ReScript Struct

A simple and composable way to describe relationship between JavaScript and ReScript structures.

It's a great tool to decode and encode any unknown data with type safety.

And other libraries can use ReScript Struct as a building block with a neat integration system:

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
}`)->S.decodeWith(authorStruct)
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
}`)->S.decodeWith(authorStruct)
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

#### **`S.constructWith`**

`('any, S.t<'value>) => result<'value, string>`

```rescript
let constructResult = data->S.constructWith(userStruct)
```

Constructs value using the coercion logic that is built-in to the struct. It returns the result with a coerced value or an error message.

> 🧠 The function is responsible only for coercion and suitable for cases when the data is valid. If not, you'll get a runtime error or invalid state. Use `S.decodeWith` to safely decode data with structure tests.

#### **`S.destructWith`**

`('value, S.t<'value>) => result<S.unknown, string>`

```rescript
let destructResult = user->S.destructWith(userStruct)
```

Destructs value using the coercion logic that is built-in to the struct. It returns the result with a coerced unknown data or an error message.

#### **`S.decodeWith`**

`('any, t<'value>) => result<'value, string>`

```rescript
let decodeResult = data->S.decodeWith(userStruct)
```

Decodes value testing that it represents described struct. It returns the result with a decoded coerced value or an error message.

#### **`S.decodeJsonWith`**

`(string, t<'value>) => result<'value, string>`

```rescript
let decodeResult = json->S.decodeJsonWith(userStruct)
```

Parses and decodes JSON string testing that it represents described struct. It returns the result with a decoded coerced value or an error message.

#### **`S.encodeWith`**

`('value, t<'value>) => result<S.unknown, string>`

```rescript
let encodeResult = user->S.encodeWith(userStruct)
```

Encodes value using the coercion logic that is built-in to the struct. It returns the result with a coerced unknown data or an error message.

#### **`S.encodeJsonWith`**

`('value, t<'value>) => result<string, string>`

```rescript
let encodeStringResult = user->S.encodeJsonWith(userStruct)
```

Encodes value using the coercion logic and stringifies it to JSON. It returns the result with an encoded stringified unknown data or an error message.

### Types

**rescript-struct** exposes factory functions for a variety of common JavaScript types. You can also define your own custom struct factories.

#### **`S.string`**

`unit => S.t<string>`

```rescript
let struct: S.t<string> = S.string()

%raw(`a string of text`)->S.constructWith(struct)
```

```rescript
Ok("a string of text")
```

`string` struct represents a data that is a string.

#### **`S.bool`**

`unit => S.t<bool>`

```rescript
let struct: S.t<bool> = S.bool()

%raw(`false`)->S.constructWith(struct)
```

```rescript
Ok(false)
```

`bool` struct represents a data that is a boolean.

#### **`S.int`**

`unit => S.t<int>`

```rescript
let struct: S.t<int> = S.int()

%raw(`123`)->S.constructWith(struct)
```

```rescript
Ok(123)
```

`int` struct represents a data that is an integer.

#### **`S.float`**

`unit => S.t<float>`

```rescript
let struct: S.t<float> = S.float()

%raw(`123`)->S.constructWith(struct)
```

```rescript
Ok(123.)
```

`float` struct represents a data that is a number.

#### **`S.array`**

`S.t<'value> => S.t<array<'value>>`

```rescript
let struct: S.t<array<string>> = S.array(S.string())

%raw(`["Hello", "World"]`)->S.constructWith(struct)
```

```rescript
Ok(["Hello", "World"])
```

`array` struct represents an array of data of a specific type.

#### **`S.dict`**

`S.t<'value> => S.t<Js.Dict.t<'value>>`

```rescript
let struct: S.t<Js.Dict.t<string>> = S.dict(S.string())

%raw(`{"foo":"bar","baz":"qux"}`)->S.constructWith(struct)
```

```rescript
Ok(Js.Dict.fromArray([("foo", "bar"), ("baz", "qux")]))
```

`dict` struct represents a dictionary of data of a specific type.

#### **`S.option`**

`S.t<'value> => S.t<option<'value>>`

```rescript
let struct: S.t<option<string>> = S.option(S.string())

%raw(`"a string of text"`)->S.constructWith(struct)
```

```rescript
Ok(Some("a string of text"))
```

`option` struct represents a data of a specific type that might be undefined.

#### **`S.nullable`**

`S.t<'value> => S.t<option<'value>>`

```rescript
let struct: S.t<option<string>> = S.option(S.string())

%raw(`null`)->S.constructWith(struct)
```

```rescript
Ok(None)
```

`nullable` struct represents a data of a specific type that might be null.

#### **`S.record1` - `S.record10`**

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

#### **`S.Record.factory`**

```rescript
let record2: (
  ~fields: (S.field<'v1>, S.field<'v2>),
  ~constructor: (('v1, 'v2)) => result<'value, string>=?,
  ~destructor: 'value => result<('v1, 'v2), string>=?,
  unit,
) => S.t<'value> = S.Record.factory
```

> 🧠 The `S.Record.factory` internal code isn't typesafe, so you should properly annotate the struct factory interface.

#### **`S.default`**

`(S.t<option<'value>>, 'value) => S.t<'value>`

```rescript
let struct: S.t<string> = S.option(S.string())->S.default("a string of text")

%raw(`undefined`)->S.constructWith(struct)
```

```rescript
Ok(Some("a string of text"))
```

`default` augments a struct to add coercion logic for default values, which are applied when the input is undefined.

#### **`S.deprecated`**

`(~message: string=?, S.t<'value>) => S.t<option<'value>>`

```rescript
let struct: S.t<option<string>> = S.deprecated(~message="The struct is deprecated", S.string())

%raw(`"a string of text"`)->S.constructWith(struct)
```

```rescript
Ok(Some("a string of text"))
```

`deprecated` struct represents a data of a specific type and makes it optional. The message may be used by an integration library.

#### **`S.unknown`**

`() => S.t<S.unknown>`

```rescript
let struct: S.t<S.unknown> = S.unknown()

%raw(`"a string of text"`)->S.constructWith(struct)
```

`unknown` struct represents any data. Can be used together with coercion to create a custom struct factory.

### Coercions

**rescript-struct** allows structs to be augmented with coercion logic, letting you transform data during construction and destruction. This is most commonly used to apply default values to an input, but it can be used for more complex cases like pre-trimming strings, or mapping input to a convenient ReScript data structure.

#### **`S.coerce`**

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
- [x] Make encoder and decoder work with any JS values and not only with Js.Json.t
- [x] Add Unknown struct factory and remove Custom
- [ ] Add Shape struct factory
- [x] Add Nullable struct factory
- [ ] Add Instance struct factory
- [ ] Add Tuple struct factory
- [ ] Add Never struct factory
- [ ] Add Function struct factory
- [ ] Add Regexp struct factory
- [ ] Add Date struct factory
- [ ] Add Json struct factory
- [ ] Design and add Literal struct factory
- [ ] Design and add Enum struct factory
- [ ] Design and add Dynamic struct factory
- [ ] Design and add Lazy struct factory
- [ ] Design and add Union struct factory
- [ ] Design and add Refinements
