# ReScript Struct

A simple and composable way to describe relationship between JavaScript and ReScript structures.

It's a great tool to parse and serialize any unknown data with type safety.

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

let authorStruct =
  S.record4(.
    ("Id", S.float()),
    ("Tags", S.option(S.array(S.string()))->S.default([])),
    (
      "IsApproved",
      S.union([
        S.literalVariant(String("Yes"), true),
        S.literalVariant(String("No"), false),
      ]),
    ),
    ("Age", S.deprecated(~message="A useful explanation", S.int())),
  )->S.transform(
    ~parser=((id, tags, isAproved, deprecatedAge)) =>
      {id: id, tags: tags, isAproved: isAproved, deprecatedAge: deprecatedAge}->Ok,
    (),
  )

{
  "Id": 1,
  "IsApproved": "Yes",
  "Age": 12,
}->S.parseWith(authorStruct)
{
  "Id": 2,
  "IsApproved": "No",
  "Tags": ["Loved"],
}->S.parseWith(authorStruct)
```

```rescript
Ok({
  id: 1.,
  tags: [],
  isAproved: true,
  deprecatedAge: Some(12),
})
Ok({
  id: 2.,
  tags: ["Loved"],
  isAproved: false,
  deprecatedAge: None,
})
```

## API Reference

### Core

#### **`S.parseWith`**

`('any, ~mode: mode=?, t<'value>) => result<'value, string>`

```rescript
data->S.parseWith(userStruct)
```

Parses data using the transformation logic that is built-in to the struct.
Has multiple modes:
- `S.Safe` (default) - In this mode **rescript-struct** will check that provided data is valid.
- `S.Unsafe` - In this mode all checks and refinements are ignored and only transformation logic is applied.

#### **`S.serializeWith`**

`('value, ~mode: mode=?, S.t<'value>) => result<S.unknown, string>`

```rescript
user->S.serializeWith(userStruct)
```

Serializes value using the transformation logic that is built-in to the struct. It returns the result with a transformed data or an error message.
Has multiple modes:
- `S.Safe` (default) - In this mode **rescript-struct** will check that provided value is valid.
- `S.Unsafe` - In this mode all checks and refinements are ignored and only transformation logic is applied.

### Types

**rescript-struct** exposes factory functions for a variety of common JavaScript types. You can also define your own custom struct factories.

#### **`S.string`**

`unit => S.t<string>`

```rescript
let struct = S.string()

"Hello World!"->S.parseWith(struct)
```

```rescript
Ok("Hello World!")
```

`string` struct represents a data that is a string.

#### **`S.bool`**

`unit => S.t<bool>`

```rescript
let struct = S.bool()

false->S.parseWith(struct)
```

```rescript
Ok(false)
```

`bool` struct represents a data that is a boolean.

#### **`S.int`**

`unit => S.t<int>`

```rescript
let struct = S.int()

123->S.parseWith(struct)
```

```rescript
Ok(123)
```

`int` struct represents a data that is an integer.

#### **`S.float`**

`unit => S.t<float>`

```rescript
let struct = S.float()

123->S.parseWith(struct)
```

```rescript
Ok(123.)
```

`float` struct represents a data that is a number.

#### **`S.array`**

`S.t<'value> => S.t<array<'value>>`

```rescript
let struct = S.array(S.string())

["Hello", "World"]->S.parseWith(struct)
```

```rescript
Ok(["Hello", "World"])
```

`array` struct represents an array of data of a specific type.

#### **`S.tuple0` - `S.tuple10`**

`(. S.t<'v1>, S.t<'v2>, S.t<'v3>) => S.t<('v1, 'v2, 'v3)>`

```rescript
let struct = S.tuple3(. S.string(), S.int(), S.bool())

%raw(`['a', 1, true]`)->S.parseWith(struct)
```

```rescript
Ok(("a", 1, true))
```

`tuple` struct represents that a data is an array of a specific length with values each of a specific type.

The tuple struct factories are available up to 10 fields. If you have an array with more values, you can create a tuple struct factory for any number of fields using `S.Tuple.factory`.

#### **`S.Tuple.factory`**

```rescript
let tuple3: (. S.t<'v1>, S.t<'v2>, S.t<'v3>) => S.t<('v1, 'v2, 'v3)> = S.Tuple.factory
```

> 🧠 The `S.Tuple.factory` internal code isn't typesafe, so you should properly annotate the struct factory interface.

#### **`S.dict`**

`S.t<'value> => S.t<Js.Dict.t<'value>>`

```rescript
let struct = S.dict(S.string())

{
  "foo": "bar",
  "baz": "qux",
}->S.parseWith(struct)
```

```rescript
Ok(Js.Dict.fromArray([("foo", "bar"), ("baz", "qux")]))
```

`dict` struct represents a dictionary of data of a specific type.

#### **`S.option`**

`S.t<'value> => S.t<option<'value>>`

```rescript
let struct = S.option(S.string())

"Hello World!"->S.parseWith(struct)
%raw(`undefined`)->S.parseWith(struct)
```

```rescript
Ok(Some("Hello World!"))
Ok(None)
```

`option` struct represents a data of a specific type that might be undefined.

#### **`S.null`**

`S.t<'value> => S.t<option<'value>>`

```rescript
let struct = S.null(S.string())

"Hello World!"->S.parseWith(struct)
%raw(`null`)->S.parseWith(struct)
```

```rescript
Ok(Some("Hello World!"))
Ok(None)
```

`null` struct represents a data of a specific type that might be null.

#### **`S.unknown`**

`() => S.t<S.unknown>`

```rescript
let struct = S.unknown()

"Hello World!"->S.parseWith(struct)
```

`unknown` struct represents any data. Can be used together with `S.transformUnknown` to create a custom struct factory.

#### **`S.literal`**

`S.literal<'value> => S.t<'value>`

```rescript
let tunaStruct = S.literal(String("Tuna"))
let twelveStruct = S.literal(Int(12))
let importantTimestampStruct = S.literal(Float(1652628345865.))
let truStruct = S.literal(Bool(true))
let nullStruct = S.literal(EmptyNull)
let undefinedStruct = S.literal(EmptyOption)
```

`literal` struct enforces that a data matches an exact value using the === operator.

#### **`S.literalVariant`**

`(S.literal<'value>, 'variant) => S.t<'variant>`

```rescript
type fruit = Apple | Orange
let appleStruct = S.literalVariant(String("apple"), Apple)

"apple"->S.parseWith(appleStruct)
```

```rescript
Ok(Apple)
```

The same as `literal` struct factory, but with a convenient way to transform data to ReScript value.

#### **`S.literalUnit`**

`(S.literal<'value>) => S.t<unit>`

```rescript
let struct = S.literalUnit(EmptyOption)

%raw(`undefined`)->S.parseWith(struct)
```

```rescript
Ok()
```

The same as `literal` struct factory, but with a convenient way to transform data to ReScript unit. It's useful for parsing function return data.

#### **`S.record0` - `S.record10`**

`(. S.field<'v1>, S.field<'v2>, S.field<'v3>) => S.t<('v1, 'v2, 'v3)>`

```rescript
type author = {id: string}
let struct = S.record1(. ("ID", S.string()))->S.transform(~parser=id => {id: id}->Ok, ())

{"ID": "abc"}->S.parseWith(struct)
```

```rescript
Ok({
  id: "abc",
})
```

`record` struct represents an object and that each of its properties represent a specific type as well.

The record struct factories are available up to 10 fields. If you have an object with more fields, you can create a record struct factory for any number of fields using `S.Record.factory`.

#### **`S.Record.factory`**

```rescript
let record3: (
  . S.field<'v1>,
  S.field<'v2>,
  S.field<'v3>,
) => S.t<('v1, 'v2, 'v3)> = S.Record.factory
```

> 🧠 The `S.Record.factory` internal code isn't typesafe, so you should properly annotate the struct factory interface.

#### **`S.Record.strip`**

`S.t<'value> => S.t<'value>`

```rescript
let struct = S.record1(. ("key", S.string()))->S.Record.strip

{
  "key": "value",
  "unknownKey": "value2",
}->S.parseWith(struct)
```

```rescript
Ok("value")
```

By default **rescript-struct** disallow unrecognized keys during parsing objects. You can change the behaviour to stripping unrecognized keys with the `S.Record.strip` function.

#### **`S.Record.strict`**

`S.t<'value> => S.t<'value>`

```rescript
let struct = S.record1(. ("key", S.string()))->S.Record.strict

{
  "key": "value",
  "unknownKey": "value2",
}->S.parseWith(struct)
```

```rescript
Error(`[ReScript Struct] Failed parsing at root. Reason: Encountered disallowed excess key "unknownKey" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely`)
```

You can use the `S.Record.strict` function to reset a record struct to the default behavior (disallowing unrecognized keys).

#### **`S.never`**

`() => S.t<S.never>`

```rescript
let struct = S.never()

%raw(`undefined`)->S.parseWith(struct)
```

```rescript
Error("[ReScript Struct] Failed parsing at root. Reason: Expected Never, got Option")
```

`never` struct will fail parsing for every value.

#### **`S.json`**

`S.t<'value> => S.t<'value>`

```rescript
let struct = S.json(S.int())

"123"->S.parseWith(struct)
```

```rescript
Ok(123)
```

`json` struct represents a data that is a JSON string containing a value of a specific type.

> 🧠 If you came from Jzon and looking for `decodeStringWith`/`encodeStringWith` alternative, you can use `S.json` struct factory. Example: `data->S.parseWith(S.json(struct))`

#### **`S.default`**

`(S.t<option<'value>>, 'value) => S.t<'value>`

```rescript
let struct = S.option(S.string())->S.default("Hello World!")

%raw(`undefined`)->S.parseWith(struct)
"Goodbye World!"->S.parseWith(struct)
```

```rescript
Ok("Hello World!")
Ok("Goodbye World!")
```

`default` augments a struct to add transformation logic for default values, which are applied when the input is undefined.

#### **`S.deprecated`**

`(~message: string=?, S.t<'value>) => S.t<option<'value>>`

```rescript
let struct = S.deprecated(~message="The struct is deprecated", S.string())

"Hello World!"->S.parseWith(struct)
%raw(`undefined`)->S.parseWith(struct)
```

```rescript
Ok(Some("Hello World!"))
Ok(None)
```

`deprecated` struct represents a data of a specific type and makes it optional. The message may be used by an integration library.

#### **`S.union`**

`array<S.t<'value>> => S.t<'value>`

```rescript
type shape = Circle({radius: float}) | Square({x: float}) | Triangle({x: float, y: float})

let shapeStruct = {
  let circleStruct = S.record2(.
    ("kind", S.literalUnit(String("circle"))),
    ("radius", S.float()),
  )->S.transform(~parser=(((), radius)) => Circle({radius: radius})->Ok, ())
  let squareStruct = S.record2(.
    ("kind", S.literalUnit(String("square"))),
    ("x", S.float()),
  )->S.transform(~parser=(((), x)) => Square({x: x})->Ok, ())
  let triangleStruct = S.record3(.
    ("kind", S.literalUnit(String("triangle"))),
    ("x", S.float()),
    ("y", S.float()),
  )->S.transform(~parser=(((), x, y)) => Triangle({x: x, y: y})->Ok, ())
  S.union([circleStruct, squareStruct, triangleStruct])
}

{
  "kind": "circle",
  "radius": 1,
}->S.parseWith(shapeStruct)
{
  "kind": "square",
  "x": 2,
}->S.parseWith(shapeStruct)
```

```rescript
Ok(Circle({radius: 1.}))
Ok(Square({x: 2.}))
```

`union` will test the input against each of the structs in order and return the first value that validates successfully.

> 🧠 Automatically changes parsing/serializing mode for union structs from Unsafe to Safe

##### Enums

Also, you can describe enums using `S.union` together with `S.union`.

```rescript
type outcome = Win | Draw | Loss

let struct = S.union([
  S.literalVariant(String("win"), Win),
  S.literalVariant(String("draw"), Draw),
  S.literalVariant(String("loss"), Loss),
])

"draw"->S.parseWith(struct)
```

```rescript
Ok(Draw)
```

### Transformations

**rescript-struct** allows structs to be augmented with transformation logic, letting you transform data during parsing and serializing. This is most commonly used to apply default values to an input, but it can be used for more complex cases like trimming strings, or mapping input to a convenient ReScript data structure.

#### **`S.transform`**

`(S.t<'value>, ~parser: 'value => result<'transformedValue, string>=?, ~serializer: 'transformedValue => result<'value, string>=?, unit) => S.t<'transformedValue>`

```rescript
let trimmed = S.transform(_, ~parser=s => s->Js.String2.trim->Ok, ~serializer=s => s->Ok, ())
```
```rescript
let nonEmptyString = () => {
  S.string()->S.transform(
    ~parser=s =>
      switch s {
      | "" => None
      | s' => Some(s')
      }->Ok,
    ~serializer=nonEmptyString =>
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
let date = () => {
  S.float()->S.transform(~serializer=date => date->Js.Date.getTime->Ok, ())
}
```

> 🧠 For transformation either a parser, or a serializer is required.

#### **`S.transformUnknown`**

`(S.t<unknown>, ~parser: unknown => result<'transformedValue, string>=?, ~serializer: 'transformedValue => result<'any, string>=?, unit) => S.t<'transformedValue>`

The same as `S.transform` but has more convinient interface to work with `S.unknown` struct factory that can be used to create custom struct factories.

### Integration

If you're a library maintainer, you can use **rescript-struct** as a way to describe a structure and use it in your own way. The most common use case is building type-safe schemas e.g for REST APIs, databases, and forms.

The detailed API documentation is a work in progress, for now, you can use `S.resi` file as a reference and [rescript-json-schema](https://github.com/DZakh/rescript-json-schema) source code.

## Roadmap

- [x] Add custom transformations
- [x] Add JSON module for parsing and serializing
- [x] Make parse and serialize work with any JS values and not only with Js.Json.t
- [x] Add Unknown struct factory and remove Custom
- [x] Add different unknown keys strategies
- [x] Add Null struct factory
- [ ] Add Instance struct factory
- [x] Add Tuple struct factory
- [x] Add Never struct factory
- [ ] Add Function struct factory
- [ ] Add Regexp struct factory
- [ ] Add Date struct factory
- [x] Add Json struct factory
- [x] Design and add Literal struct factory
- [ ] Design and add Lazy struct factory
- [x] Design and add Union struct factory
  - [ ] Add discriminant optimization for record structs
  - [ ] Better error message
- [ ] Design and add Refinements
- [ ] Properly handle NaN
- [ ] Design and add async transforms
