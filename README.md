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

### Real-world use cases

- [API requests with **rescript-struct**](https://github.com/Nicolas1st/net-cli-rock-paper-scissors/blob/main/apps/client/src/Api.res)
- [Env variables with **rescript-struct**](https://github.com/Nicolas1st/net-cli-rock-paper-scissors/blob/main/apps/client/src/Env.res)

## API Reference

### Core

#### **`S.parseWith`**

`('any, ~mode: mode=?, t<'value>) => result<'value, S.Error.t>`

```rescript
data->S.parseWith(userStruct)
```

Parses data using the transformation logic that is built-in to the struct.
Has multiple modes:
- `S.Safe` (default) - In this mode **rescript-struct** will check that provided data is valid.
- `S.Unsafe` - In this mode all checks and refinements are ignored and only transformation logic is applied. It's ~1.4 times faster than `Safe` mode.

#### **`S.serializeWith`**

`('value, ~mode: mode=?, S.t<'value>) => result<S.unknown, S.Error.t>`

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

`string` struct represents a data that is a string. It can be further constrainted with the following utility methods.

**rescript-struct** includes a handful of string-specific refinements and transforms:

```rescript
S.string()->S.String.max(5) // String must be 5 or more characters long
S.string()->S.String.min(5) // String must be 5 or fewer characters long
S.string()->S.String.length(5) // String must be exactly 5 characters long
S.string()->S.String.email() // Invalid email address
S.string()->S.String.url() // Invalid url
S.string()->S.String.uuid() // Invalid UUID
S.string()->S.String.cuid() // Invalid CUID
S.string()->S.String.pattern(%re(`/[0-9]/`)) // Invalid

S.string()->S.String.trimmed() // trim whitespaces
```

When using built-in refinements, you can provide a custom error message.

```rescript
S.string()->S.String.min(~message="String can't be empty", 1)
S.string()->S.String.length(~message="SMS code should be 5 digits long", 5)
```

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

**rescript-struct** includes some of int-specific refinements:

```rescript
S.int()->S.Int.max(5) // Number must be lower than or equal to 5
S.int()->S.Int.min(5) // Number must be greater than or equal to 5
```

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

**rescript-struct** includes some of float-specific refinements:

```rescript
S.float()->S.Float.max(5) // Number must be lower than or equal to 5
S.float()->S.Float.min(5) // Number must be greater than or equal to 5
```

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

**rescript-struct** includes some of array-specific refinements:

```rescript
S.array()->S.Array.max(5) // Array must be 5 or more items long
S.array()->S.Array.min(5) // Array must be 5 or fewer items long
S.array()->S.Array.length(5) // Array must be exactly 5 items long
```

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

#### **`S.date`**

`() => S.t<Js.Date.t>`

```rescript
let struct = S.date()

%raw(`new Date(1656245105821.)`)->S.parseWith(struct)
```

```rescript
Ok(Js.Date.fromFloat(1656245105821.))
```

`date` struct represents JavaScript Date instances.

> 🧠 To avoid unexpected runtime errors, `date` struct does **not** accept invalid `Date` objects, even though they are technically an instance of a `Date`. This meshes with the 99% use case where invalid dates create inconsistencies.

#### **`S.unknown`**

`() => S.t<S.unknown>`

```rescript
let struct = S.unknown()

"Hello World!"->S.parseWith(struct)
```

`unknown` struct represents any data.

#### **`S.literal`**

`S.literal<'value> => S.t<'value>`

```rescript
let tunaStruct = S.literal(String("Tuna"))
let twelveStruct = S.literal(Int(12))
let importantTimestampStruct = S.literal(Float(1652628345865.))
let truStruct = S.literal(Bool(true))
let nullStruct = S.literal(EmptyNull)
let undefinedStruct = S.literal(EmptyOption)
let nanStruct = S.literal(NaN)
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
Error({
  code: ExcessField("unknownKey"),
  operation: Parsing,
  path: [],
})
```

You can use the `S.Record.strict` function to reset a record struct to the default behavior (disallowing unrecognized keys).

#### **`S.never`**

`() => S.t<S.never>`

```rescript
let struct = S.never()

%raw(`undefined`)->S.parseWith(struct)
```

```rescript
Error({
  code: UnexpectedType({expected: "Never", received: "Option"}),
  operation: Parsing,
  path: [],
})
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
    ("kind", S.literal(String("circle"))),
    ("radius", S.float()),
  )->S.transform(~parser=((_, radius)) => Circle({radius: radius})->Ok, ())
  let squareStruct = S.record2(.
    ("kind", S.literal(String("square"))),
    ("x", S.float()),
  )->S.transform(~parser=((_, x)) => Square({x: x})->Ok, ())
  let triangleStruct = S.record3(.
    ("kind", S.literal(String("triangle"))),
    ("x", S.float()),
    ("y", S.float()),
  )->S.transform(~parser=((_, x, y)) => Triangle({x: x, y: y})->Ok, ())
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

#### **`S.custom`**

`(~parser: (. ~unknown: S.unknown, ~mode: S.mode) => result<'value, S.Error.t>=?, ~serializer: (. ~value: 'value, ~mode: S.mode) => result<'any, S.Error.t>=?, unit) => S.t<'value>`

You can also define your own custom struct factories that are specific to your application's requirements, like so:

```rescript
let nullableStruct = innerStruct =>
  S.custom(
    ~parser=(. ~unknown, ~mode) => {
      switch unknown->Obj.magic->Js.Nullable.toOption {
      | Some(innerValue) =>
        innerValue->S.parseWith(~mode, innerStruct)->Belt.Result.map(value => Some(value))
      | None => Ok(None)
      }
    },
    ~serializer=(. ~value, ~mode) => {
      switch value {
      | Some(innerValue) => innerValue->S.serializeWith(~mode, innerStruct)
      | None => Js.Null.empty->Obj.magic->Ok
      }
    },
    (),
  )

"Hello world!"->S.parseWith(struct)
%raw("null")->S.parseWith(struct)
%raw("undefined")->S.parseWith(struct)
123->S.parseWith(struct)
```

```rescript
Ok(Some("Hello World!"))
Ok(None)
Ok(None)
Error({
  code: UnexpectedType({expected: "String", received: "Float"}),
  operation: Parsing,
  path: [],
})
```

### Transforms

**rescript-struct** allows structs to be augmented with transformation logic, letting you transform data during parsing and serializing. This is most commonly used to apply default values to an input, but it can be used for more complex cases like trimming strings, or mapping input to a convenient ReScript data structure.

#### **`S.transform`**

`(S.t<'value>, ~parser: 'value => result<'transformed, string>=?, ~serializer: 'transformed => result<'value, string>=?, unit) => S.t<'transformed>`

```rescript
let intToString = S.transform(
  _,
  ~parser=int => int->Js.Int.toString->Ok,
  ~serializer=string =>
    switch string->Belt.Int.fromString {
    | Some(int) => Ok(int)
    | None => Error("Can't convert string to int")
    },
  (),
)
```

#### **`S.superTransform`**

`(S.t<'value>, ~parser: (. ~value: 'value, ~struct: S.t<'value>, ~mode: S.mode) => result<'transformed, S.Error.t>=?, ~serializer: (. ~transformed: 'transformed, ~struct: S.t<'value>, ~mode: S.mode) => result<'value, S.Error.t>=?, unit) => S.t<'transformed>`

```rescript
let trimmedInSafeMode = S.superTransform(
  _,
  ~parser=(. ~value, ~struct as _, ~mode) =>
    switch mode {
    | Safe => value->Js.String2.trim
    | Unsafe => value
    }->Ok,
  ~serializer=(. ~transformed, ~struct as _, ~mode) =>
    switch mode {
    | Safe => transformed->Js.String2.trim
    | Unsafe => transformed
    }->Ok,
  (),
)
```

The `.transform` and `.custom` functions are actually syntactic sugar atop a more versatile (and verbose) function called `superTransform`.

### Error handling

**rescript-struct** returns a result type with error `S.Error.t` containing detailed information about the validation problems.

```rescript
let struct = S.literal(Bool(false))
true->S.parseWith(struct)
```

```rescript
Error({
  code: UnexpectedValue({expected: "false", received: "true"}),
  operation: Parsing,
  path: [],
})
```

#### **`S.Error.toString`**

`S.Error.t => string`

```rescript
{
  code: UnexpectedValue({expected: "false", received: "true"}),
  operation: Parsing,
  path: [],
}->S.Error.toString
```

```rescript
"[ReScript Struct] Failed parsing at root. Reason: Expected false, received true"
```

#### **`S.Error.make`**

`string => S.Error.t`

A function to create a custom **rescript-struct** error for usage with `superTransform`.

#### **`S.Error.prependLocation`**

`(S.Error.t, string) => S.Error.t`

A function to add location to the path field for usage with `superTransform`.

### Result helpers

#### **`S.Result.getExn`**

`result<'a, S.Error.t> => 'a`

```rescript
let struct = S.literal(Bool(false))

false->S.parseWith(struct)->S.Result.getExn
true->S.parseWith(struct)->S.Result.getExn
```

```rescript
false
// throw new RescriptStructError("[ReScript Struct] Failed parsing at root. Reason: Expected false, received true")
```

> 🧠 It's not intended to be caught. Useful to panic with a readable error message.

#### **`S.Result.mapErrorToString`**

`result<'a, S.Error.t> => result<'a, string>`

```rescript
let struct = S.literal(Bool(false))

true->S.parseWith(struct)->S.Result.mapErrorToString
```

```rescript
Error("[ReScript Struct] Failed parsing at root. Reason: Expected false, received true")
```

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
- [x] Add Tuple struct factory
- [x] Add Never struct factory
- [ ] Add Instance struct factory
- [ ] Add Function struct factory
- [ ] Add Regexp struct factory
- [x] Add Date struct factory
- [x] Add Json struct factory
- [x] Design and add Literal struct factory
- [ ] Design and add Lazy struct factory
- [x] Design and add Union struct factory
  - [ ] Add discriminant optimization for record structs
- [ ] Design and add tagged refinements
- [x] Properly handle NaN
- [ ] Design and add async transforms
- [x] Add super transforms
- [ ] Add preprocessors