[⬅ Back to highlights](/README.md)

# ReScript Schema for ReScript users

## Table of contents

- [Table of contents](#table-of-contents)
- [Install](#install)
- [Basic usage](#basic-usage)
- [Real-world examples](#real-world-examples)
- [API reference](#api-reference)
  - [`string`](#string)
    - [ISO datetimes](#iso-datetimes)
  - [`bool`](#bool)
  - [`int`](#int)
  - [`float`](#float)
  - [`option`](#option)
  - [`Option.getOr`](#optiongetor)
  - [`Option.getOrWith`](#optiongetorwith)
  - [`null`](#null)
  - [`unit`](#unit)
  - [`literal`](#literal)
  - [`object`](#object)
    - [Transform object field names](#transform-object-field-names)
    - [Transform to a structurally typed object](#transform-to-a-structurally-typed-object)
    - [Transform to a tuple](#transform-to-a-tuple)
    - [Transform to a variant](#transform-to-a-variant)
  - [`Object.strict`](#objectstrict)
  - [`Object.strip`](#objectstrip)
  - [`schema`](#schema)
  - [`variant`](#variant)
  - [`union`](#union)
    - [Enums](#enums)
  - [`array`](#array)
  - [`list`](#list)
  - [`tuple`](#tuple)
  - [`tuple1` - `tuple3`](#tuple1---tuple3)
  - [`dict`](#dict)
  - [`unknown`](#unknown)
  - [`never`](#never)
  - [`json`](#json)
  - [`jsonString`](#jsonString)
  - [`describe`](#describe)
  - [`deprecate`](#deprecate)
  - [`catch`](#catch)
  - [`custom`](#custom)
  - [`recursive`](#recursive)
- [Refinements](#refinements)
- [Transforms](#transforms)
- [Preprocess](#preprocess-advanced)
- [Functions on schema](#functions-on-schema)
  - [`parseWith`](#parsewith)
  - [`parseAnyWith`](#parseanywith)
  - [`parseJsonStringWith`](#parsejsonstringwith)
  - [`parseOrRaiseWith`](#parseorraisewith)
  - [`parseAnyOrRaiseWith`](#parseanyorraisewith)
  - [`parseAsyncWith`](#parseasyncwith)
  - [`parseAsyncInStepsWith`](#parseasyncinstepswith-advanced)
  - [`serializeWith`](#serializewith)
  - [`serializeToUnknownWith`](#serializetounknownwith)
  - [`serializeToJsonStringWith`](#serializetojsonstringwith)
  - [`serializeOrRaiseWith`](#serializeorraisewith)
  - [`serializeToUnknownOrRaiseWith`](#serializetounknownorraisewith)
  - [`classify`](#classify)
  - [`name`](#name)
  - [`setName`](#setname)
- [Error handling](#error-handling)
  - [`Error.make`](#errormake)
  - [`Error.raise`](#errorraise)
  - [`Error.message`](#errormessage)

## Install

```sh
npm install rescript-schema
```

Then add `rescript-schema` to `bs-dependencies` in your `rescript.json`:

```diff
{
  ...
+ "bs-dependencies": ["rescript-schema"],
+ "bsc-flags": ["-open RescriptSchema"],
}
```

> 🧠 Starting from V5 **rescript-schema** requires **rescript@11**. At the same time it works in both curried and uncurried mode.

## Basic usage

```rescript
// 1. Define a type
type rating =
  | @as("G") GeneralAudiences
  | @as("PG") ParentalGuidanceSuggested
  | @as("PG13") ParentalStronglyCautioned
  | @as("R") Restricted
type film = {
  id: float,
  title: string,
  tags: array<string>,
  rating: rating,
  deprecatedAgeRestriction: option<int>,
}

// 2. Create a schema
let filmSchema = S.object(s => {
  id: s.field("Id", S.float),
  title: s.field("Title", S.string),
  tags: s.fieldOr("Tags", S.array(S.string), []),
  rating: s.field(
    "Rating",
    S.union([
      S.literal(GeneralAudiences),
      S.literal(ParentalGuidanceSuggested),
      S.literal(ParentalStronglyCautioned),
      S.literal(Restricted),
    ]),
  ),
  deprecatedAgeRestriction: s.field("Age", S.option(S.int)->S.deprecate("Use rating instead")),
})

// 3. Parse data using the schema
// The data is validated and transformed to a convenient format
%raw(`{
  "Id": 1,
  "Title": "My first film",
  "Rating": "R",
  "Age": 17
}`)->S.parseWith(filmSchema)
// Ok({
//   id: 1.,
//   title: "My first film",
//   tags: [],
//   rating: Restricted,
//   deprecatedAgeRestriction: Some(17),
// })

// 4. Transform data back using the same schema
{
  id: 2.,
  tags: ["Loved"],
  title: "Sad & sed",
  rating: ParentalStronglyCautioned,
  deprecatedAgeRestriction: None,
}->S.serializeWith(filmSchema)
// Ok(%raw(`{
//   "Id": 2,
//   "Title": "Sad & sed",
//   "Rating": "PG13",
//   "Tags": ["Loved"],
//   "Age": undefined,
// }`))

// 5. Use schema as a building block for other tools
// For example, create a JSON-schema with rescript-json-schema and use it for OpenAPI generation
let filmJSONSchema = JSONSchema.make(filmSchema)
```

## Real-world examples

- [Reliable API layer](https://github.com/Nicolas1st/net-cli-rock-paper-scissors/blob/main/apps/client/src/Api.res)
- [Creating CLI utility](https://github.com/DZakh/rescript-stdlib-cli/blob/main/src/interactors/RunCli.res)
- [Safely accessing environment variables](https://github.com/Nicolas1st/net-cli-rock-paper-scissors/blob/main/apps/client/src/Env.res)

## API reference

### **`string`**

`S.t<string>`

```rescript
let schema = S.string

%raw(`"Hello World!"`)->S.parseWith(schema)
// Ok("Hello World!")
```

The `string` schema represents a data that is a string. It can be further constrainted with the following utility methods.

**rescript-schema** includes a handful of string-specific refinements and transforms:

```rescript
S.string->S.String.max(5) // String must be 5 or fewer characters long
S.string->S.String.min(5) // String must be 5 or more characters long
S.string->S.String.length(5) // String must be exactly 5 characters long
S.string->S.String.email // Invalid email address
S.string->S.String.url // Invalid url
S.string->S.String.uuid // Invalid UUID
S.string->S.String.cuid // Invalid CUID
S.string->S.String.pattern(%re(`/[0-9]/`)) // Invalid
S.string->S.String.datetime // Invalid datetime string! Must be UTC

S.string->S.String.trim // trim whitespaces
```

When using built-in refinements, you can provide a custom error message.

```rescript
S.string->S.String.min(1, ~message="String can't be empty")
S.string->S.String.length(5, ~message="SMS code should be 5 digits long")
```

#### ISO datetimes

The `S.string->S.String.datetime` function has following UTC validation: no timezone offsets with arbitrary sub-second decimal precision.

```rescript
let datetimeSchema = S.string->S.String.datetime
// The datetimeSchema has the type S.t<Date.t>
// String is transformed to the Date.t instance

%raw(`"2020-01-01T00:00:00Z"`)->S.parseWith(datetimeSchema) // pass
%raw(`"2020-01-01T00:00:00.123Z"`)->S.parseWith(datetimeSchema) // pass
%raw(`"2020-01-01T00:00:00.123456Z"`)->S.parseWith(datetimeSchema) // pass (arbitrary precision)
%raw(`"2020-01-01T00:00:00+02:00"`)->S.parseWith(datetimeSchema) // fail (no offsets allowed)
```

### **`bool`**

`S.t<bool>`

```rescript
let schema = S.bool

%raw(`false`)->S.parseWith(schema)
// Ok(false)
```

The `bool` schema represents a data that is a boolean.

### **`int`**

`S.t<int>`

```rescript
let schema = S.int

%raw(`123`)->S.parseWith(schema)
// Ok(123)
```

The `int` schema represents a data that is an integer.

**rescript-schema** includes some of int-specific refinements:

```rescript
S.int->S.Int.max(5) // Number must be lower than or equal to 5
S.int->S.Int.min(5) // Number must be greater than or equal to 5
S.int->S.Int.port // Invalid port
```

### **`float`**

`S.t<float>`

```rescript
let schema = S.float

%raw(`123`)->S.parseWith(schema)
// Ok(123.)
```

The `float` schema represents a data that is a number.

**rescript-schema** includes some of float-specific refinements:

```rescript
S.float->S.Float.max(5) // Number must be lower than or equal to 5
S.float->S.Float.min(5) // Number must be greater than or equal to 5
```

### **`option`**

`S.t<'value> => S.t<option<'value>>`

```rescript
let schema = S.option(S.string)

%raw(`"Hello World!"`)->S.parseWith(schema)
// Ok(Some("Hello World!"))
%raw(`undefined`)->S.parseWith(schema)
// Ok(None)
```

The `option` schema represents a data of a specific type that might be undefined.

### **`Option.getOr`**

`(S.t<option<'value>>, 'value) => S.t<'value>`

```rescript
let schema = S.option(S.string)->S.Option.getOr("Hello World!")

%raw(`undefined`)->S.parseWith(schema)
// Ok("Hello World!")
%raw(`"Goodbye World!"`)->S.parseWith(schema)
// Ok("Goodbye World!")
```

The `Option.getOr` augments a schema to add transformation logic for default values, which are applied when the input is undefined.

> 🧠 If you want to set a default value for an object field, there's a more convenient `fieldOr` method on `Object.ctx` type.

### **`Option.getOrWith`**

`(S.t<option<'value>>, () => 'value) => S.t<'value>`

```rescript
let schema = S.option(S.array(S.string))->S.Option.getOrWith(() => ["Hello World!"])

%raw(`undefined`)->S.parseWith(schema)
// Ok(["Hello World!"])
%raw(`["Goodbye World!"]`)->S.parseWith(schema)
// Ok(["Goodbye World!"])
```

Also you can use `Option.getOrWith` for lazy evaluation of the default value.

### **`null`**

`S.t<'value> => S.t<option<'value>>`

```rescript
let schema = S.null(S.string)

%raw(`"Hello World!"`)->S.parseWith(schema)
// Ok(Some("Hello World!"))
%raw(`null`)->S.parseWith(schema)
// Ok(None)
```

The `null` schema represents a data of a specific type that might be null.

> 🧠 Since `null` transforms value into `option` type, you can use `Option.getOr`/`Option.getOrWith` for it as well.

### **`unit`**

`S.t<unit>`

```rescript
let schema = S.unit

%raw(`undefined`)->S.parseWith(schema)
// Ok()
```

The `unit` schema factory is an alias for `S.literal()`.

### **`literal`**

`'value => S.t<'value>`

```rescript
let tunaSchema = S.literal("Tuna")
let twelveSchema = S.literal(12)
let importantTimestampSchema = S.literal(1652628345865.)
let truSchema = S.literal(true)
let nullSchema = S.literal(Null.null)
let undefinedSchema = S.literal() // Building block for S.unit

// Uses Number.isNaN to match NaN literals
let nanSchema = S.literal(Float.Constants.nan)->S.variant(_ => ()) // For NaN literals I recomment adding S.variant to transform it to unit. It's better than having it as a float

// Supports symbols and BigInt
let symbolSchema = S.literal(Symbol.asyncIterator)
let twobigSchema = S.literal(BigInt.fromInt(2))

// Supports variants and polymorphic variants
let appleSchema = S.literal(#apple)
let noneSchema = S.literal(None)

// Does a deep check for plain objects and arrays
let cliArgsSchema = S.literal(("help", "lint"))

// Supports functions and literally any Js values matching them with the === operator
let fn = () => "foo"
let fnSchema = S.literal(fn)
let weakMap = WeakMap.make()
let weakMapSchema = S.literal(weakMap)
```

The `literal` schema enforces that a data matches an exact value during parsing and serializing.

### **`object`**

`(S.Object.ctx => 'value) => S.t<'value>`

```rescript
type point = {
  x: int,
  y: int,
}

// The pointSchema will have the S.t<point> type
let pointSchema = S.object(s => {
  x: s.field("x", S.int),
  y: s.field("y", S.int),
})

// It can be used both for parsing and serializing
%raw(`{ "x": 1,"y": -4 }`)->S.parseWith(pointSchema)
{ x: 1, y: -4 }->S.serializeWith(pointSchema)
```

The `object` schema represents an object value, that can be transformed into any ReScript value. Here are some examples:

#### Transform object field names

```rescript
type user = {
  id: int,
  name: string,
}
// It will have the S.t<user> type
let schema = S.object(s => {
  id: s.field("USER_ID", S.int),
  name: s.field("USER_NAME", S.string),
})

%raw(`{"USER_ID":1,"USER_NAME":"John"}`)->S.parseWith(schema)
// Ok({ id: 1, name: "John" })
```

#### Transform to a structurally typed object

```rescript
// It will have the S.t<{"key1":string,"key2":string}> type
let schema = S.object(s => {
  "key1": s.field("key1", S.string),
  "key2": s.field("key2", S.string),
})
```

#### Transform to a tuple

```rescript
// It will have the S.t<(int, string)> type
let schema = S.object(s => (s.field("USER_ID", S.int), s.field("USER_NAME", S.string)))

%raw(`{"USER_ID":1,"USER_NAME":"John"}`)->S.parseWith(schema)
// Ok((1, "John"))
```

The same schema also works for serializing:

```rescript
(1, "John")->S.serializeWith(schema)
// Ok(%raw(`{"USER_ID":1,"USER_NAME":"John"}`))
```

#### Transform to a variant

```rescript
type shape = Circle({radius: float}) | Square({x: float}) | Triangle({x: float, y: float})

// It will have the S.t<shape> type
let schema = S.object(s => {
  s.tag("kind", "circle")
  Circle({
    radius: s.field("radius", S.float),
  })
})

%raw(`{
  "kind": "circle",
  "radius": 1,
}`)->S.parseWith(schema)
// Ok(Circle({radius: 1}))
```

For values whose runtime representation matches your schema, you can use the less verbose `S.schema`. Under the hood, it'll create the same `S.object` schema from the example above.

```rescript
@tag("kind")
type shape =
  | @as("circle") Circle({radius: float})
  | @as("square") Square({x: float})
  | @as("triangle") Triangle({x: float, y: float})

let schema = S.schema(s => Circle({
  radius: s.matches(S.float),
}))
```

You can use the schema for parsing as well as serializing:

```rescript
Circle({radius: 1})->S.serializeWith(schema)
// Ok(%raw(`{
//   "kind": "circle",
//   "radius": 1,
// }`))
```

### **`Object.strict`**

`S.t<'value> => S.t<'value>`

```rescript
// Represents an object without fields
let schema = S.object(_ => ())->S.Object.strict

%raw(`{
  "someField": "value",
}`)->S.parseWith(schema)
// Error({
//   code: ExcessField("someField"),
//   operation: Parsing,
//   path: S.Path.empty,
// })
```

By default **rescript-schema** silently strips unrecognized keys when parsing objects. You can change the behaviour to disallow unrecognized keys with the `S.Object.strict` function.

### **`Object.strip`**

`S.t<'value> => S.t<'value>`

```rescript
// Represents an object with any fields
let schema = S.object(_ => ())->S.Object.strip

%raw(`{
  "someField": "value",
}`)->S.parseWith(schema)
// Ok()
```

You can use the `S.Object.strip` function to reset a object schema to the default behavior (stripping unrecognized keys).

### **`schema`**

`(schemaCtx => 'value) => S.t<'value>`

It's a helper built on `S.literal`, `S.object`, and `S.tuple` to create schemas for runtime representation of ReScript types conveniently.

```rescript
@unboxed
type answer =
  | Text(string)
  | MultiSelect(array<string>)
  | Other({value: string, @as("description") maybeDescription: option<string>})

let textSchema = S.schema(s => Text(s.matches(S.string)))
// It'll create the following schema:
// S.string->S.variant(string => Text(string))

let multySelectSchema = S.schema(s => MultiSelect(s.matches(S.array(S.string))))
// The same as:
// S.array(S.string)->S.variant(array => MultiSelect(array))

let otherSchema = S.schema(s => Other({
  value: s.matches(S.string),
  maybeDescription: s.matches(S.option(S.string)),
}))
// Creates the schema under the hood:
// S.object(s => Other({
//   value: s.field("value", S.string),
//   maybeDescription: s.field("description", S.option(S.string)),
// }))
//       Notice how the field name /|\ is taken from the type's @as attribute

let tupleExampleSchema = S.schema(s => (#id, s.matches(S.string)))
// The same as:
// S.tuple(s => (s.item(0, S.literal(#id)), s.item(1, S.string)))
```

> 🧠 Note that `S.schema` relies on the runtime representation of your type, while `S.object`/`S.tuple` are more flexible and require you to describe the schema explicitly.

### **`variant`**

`(S.t<'value>, 'value => 'variant) => S.t<'variant>`

```rescript
type shape = Circle({radius: float}) | Square({x: float}) | Triangle({x: float, y: float})

// It will have the S.t<shape> type
let schema = S.float->S.variant(radius => Circle({radius: radius}))

%raw(`1`)->S.parseWith(schema)
// Ok(Circle({radius: 1.}))
```

The same schema also works for serializing:

```rescript
Circle({radius: 1})->S.serializeWith(schema)
// Ok(%raw(`1`))
```

### **`union`**

`array<S.t<'value>> => S.t<'value>`

```rescript
// TypeScript type for reference:
// type Shape =
// | { kind: "circle"; radius: number }
// | { kind: "square"; x: number }
// | { kind: "triangle"; x: number; y: number };
type shape = Circle({radius: float}) | Square({x: float}) | Triangle({x: float, y: float})

let shapeSchema = S.union([
  S.object(s => {
    s.tag("kind", "circle")
    Circle({
      radius: s.field("radius", S.float),
    })
  }),
  S.object(s => {
    s.tag("kind", "square")
    Square({
      x: s.field("x", S.float),
    })
  }),
  S.object(s => {
    s.tag("kind", "triangle")
    Triangle({
      x: s.field("x", S.float),
      y: s.field("y", S.float),
    })
  }),
])
```

```rescript
%raw(`{
  "kind": "circle",
  "radius": 1,
}`)->S.parseWith(shapeSchema)
// Ok(Circle({radius: 1.}))
```

```rescript
Square({x: 2.})->S.serializeWith(shapeSchema)
// Ok({
//   "kind": "square",
//   "x": 2,
// })
```

The `union` will test the input against each of the schemas in order and return the first value that validates successfully.

#### Enums

Also, you can describe enums using `S.union` together with `S.literal`.

```rescript
type outcome = | @as("win") Win | @as("draw") Draw | @as("loss") Loss

let schema = S.union([
  S.literal(Win),
  S.literal(Draw),
  S.literal(Loss),
])

%raw(`"draw"`)->S.parseWith(schema)
// Ok(Draw)
```

### **`array`**

`S.t<'value> => S.t<array<'value>>`

```rescript
let schema = S.array(S.string)

%raw(`["Hello", "World"]`)->S.parseWith(schema)
// Ok(["Hello", "World"])
```

The `array` schema represents an array of data of a specific type.

**rescript-schema** includes some of array-specific refinements:

```rescript
S.array(itemSchema)->S.Array.max(5) // Array must be 5 or fewer items long
S.array(itemSchema)->S.Array.min(5) // Array must be 5 or more items long
S.array(itemSchema)->S.Array.length(5) // Array must be exactly 5 items long
```

### **`list`**

`S.t<'value> => S.t<list<'value>>`

```rescript
let schema = S.list(S.string)

%raw(`["Hello", "World"]`)->S.parseWith(schema)
// Ok(list{"Hello", "World"})
```

The `list` schema represents an array of data of a specific type which is transformed to ReScript's list data-structure.

### **`tuple`**

`(S.Tuple.ctx => 'value) => S.t<'value>`

```rescript
type point = {
  x: int,
  y: int,
}

// The pointSchema will have the S.t<point> type
let pointSchema = S.tuple(s => {
  s.tag(0, "point")
  {
    x: s.item(1, S.int),
    y: s.item(2, S.int),
  }
})

// It can be used both for parsing and serializing
%raw(`["point", 1, -4]`)->S.parseWith(pointSchema)
{ x: 1, y: -4 }->S.serializeWith(pointSchema)
```

The `tuple` schema represents that a data is an array of a specific length with values each of a specific type.

For short tuples without the need for transformation, there are wrappers over `S.tuple`:

### **`tuple1` - `tuple3`**

`(S.t<'v0>, S.t<'v1>, S.t<'v2>) => S.t<('v0, 'v1, 'v2)>`

```rescript
let schema = S.tuple3(S.string, S.int, S.bool)

%raw(`["a", 1, true]`)->S.parseWith(schema)
// Ok("a", 1, true)
```

### **`dict`**

`S.t<'value> => S.t<Dict.t<'value>>`

```rescript
let schema = S.dict(S.string)

%raw(`{
  "foo": "bar",
  "baz": "qux",
}`)->S.parseWith(schema)
// Ok(Dict.fromArray([("foo", "bar"), ("baz", "qux")]))
```

The `dict` schema represents a dictionary of data of a specific type.

### **`unknown`**

`S.t<unknown>`

```rescript
let schema = S.unknown

%raw(`"Hello World!"`)->S.parseWith(schema)
```

The `unknown` schema represents any data.

### **`never`**

`S.t<S.never>`

```rescript
let schema = S.never

%raw(`undefined`)->S.parseWith(schema)
// Error({
//   code: InvalidType({expected: S.never, received: undefined}),
//   operation: Parsing,
//   path: S.Path.empty,
// })
```

The `never` schema will fail parsing for every value.

### **`json`**

`S.t<JSON.t>`

```rescript
let schema = S.json

%raw(`"123"`)->S.parseWith(schema)
// Ok(String("123"))
```

The `json` schema represents a data that is compatible with JSON.

### **`jsonString`**

`(S.t<'value>, ~space: int=?) => S.t<'value>`

```rescript
let schema = S.jsonString(S.int)

%raw(`"123"`)->S.parseWith(schema)
// Ok(123)
```

The `jsonString` schema represents JSON string containing value of a specific type.

### **`describe`**

`(S.t<'value>, string) => S.t<'value>`

Use `S.describe` to add a `description` property to the resulting schema.

```rescript
let documentedStringSchema = S.string
  ->S.describe("A useful bit of text, if you know what to do with it.")

documentedStringSchema->S.description // A useful bit of text…
```

This can be useful for documenting a field, for example in a JSON Schema using a library like [`rescript-json-schema`](https://github.com/DZakh/rescript-json-schema).

### **`deprecate`**

`(S.t<'value>, string) => S.t<'value>`

Use `S.deprecate` to add a `deprecation` message property to the resulting schema.

```rescript
let deprecatedString = S.string
  ->S.deprecate("Will be removed in APIv2")

deprecatedString->S.deprecation // Will be removed in APIv2…
```

This can be useful for documenting a field, for example in a JSON Schema using a library like [`rescript-json-schema`](https://github.com/DZakh/rescript-json-schema).

### **`catch`**

`(S.t<'value>, S.catchCtx<'value> => 'value) => S.t<'value>`

Use `S.catch` to provide a "catch value" to be returned instead of a parsing error.

```rescript
let schema = S.float->S.catch(_ => 42.)

%raw(`5`)->S.parseWith(schema)
// Ok(5.)
%raw(`"tuna"`)->S.parseWith(schema)
// Ok(42.)
```

Also, the callback `S.catch` receives a catch context as a first argument. It contains the caught error and the initial data provided to the parse function.

```rescript
let schema = S.float->S.catch(s => {
  Console.log(s.error) // The caught error
  Console.log(s.input) // The data provided to the parse function
  42.
})
```

Conceptually, this is how **rescript-schema** processes "catch values":

1. The data is parsed using the base schema
2. If the parsing fails, the "catch value" is returned

### **`custom`**

`(string, effectCtx<'output> => customDefinition<'input, 'output>) => t<'output>`

You can also define your own custom schema factories that are specific to your application's requirements:

```rescript
let nullableSchema = innerSchema => {
  S.custom("Nullable", s => {
    parser: unknown => {
      if unknown === %raw(`undefined`) || unknown === %raw(`null`) {
        None
      } else {
        switch unknown->S.parseAnyWith(innerSchema) {
        | Ok(value) => Some(value)
        | Error(error) => s.failWithError(error)
        }
      }
    },
    serializer: value => {
      switch value {
      | Some(innerValue) =>
        switch innerValue->S.serializeToUnknownWith(innerSchema) {
        | Ok(value) => value
        | Error(error) => s.failWithError(error)
        }
      | None => %raw(`null`)
      }
    },
  })
}

%raw(`"Hello world!"`)->S.parseWith(schema)
// Ok(Some("Hello World!"))
%raw(`null`)->S.parseWith(schema)
// Ok(None)
%raw(`undefined`)->S.parseWith(schema)
// Ok(None)
%raw(`123`)->S.parseWith(schema)
// Error({
//   code: InvalidType({expected: S.string, received: 123}),
//   operation: Parsing,
//   path: S.Path.empty,
// })
```

### **`recursive`**

`(t<'value> => t<'value>) => t<'value>`

You can define a recursive schema in **rescript-schema**.

```rescript
type rec node = {
  id: string,
  children: array<node>,
}

let nodeSchema = S.recursive(nodeSchema => {
  S.object(s => {
    id: s.field("Id", S.string),
    children: s.field("Children", S.array(nodeSchema)),
  })
})
```

```rescript
%raw(`{
  "Id": "1",
  "Children": [
    {"Id": "2", "Children": []},
    {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
  ],
}`)->S.parseWith(nodeSchema)
// Ok({
//   id: "1",
//   children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
// })
```

The same schema works for serializing:

```rescript
{
  id: "1",
  children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
}->S.serializeWith(nodeSchema)
// Ok(%raw(`{
//   "Id": "1",
//   "Children": [
//     {"Id": "2", "Children": []},
//     {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
//   ],
// }`))
```

You can also use asynchronous parser:

```rescript
let nodeSchema = S.recursive(nodeSchema => {
  S.object(s => {
    params: s.field("Id", S.string)->S.transform(_ => {asyncParser: id => () => loadParams(id)}),
    children: s.field("Children", S.array(nodeSchema)),
  })
})
```

One great aspect of the example above is that it uses parallelism to make four requests to check for the existence of nodes.

> 🧠 Despite supporting recursive schema, passing cyclical data into rescript-schema will cause an infinite loop.

## Refinements

**rescript-schema** lets you provide custom validation logic via refinements. It's useful to add checks that's not possible to cover with type system. For instance: checking that a number is an integer or that a string is a valid email address.

### **`refine`**

`(S.t<'value>, effectCtx<'value> => 'value => unit) => S.t<'value>`

```rescript
let shortStringSchema = S.string->S.refine(s => value =>
  if value->String.length > 255 {
    s.fail("String can't be more than 255 characters")
  }
)
```

The refine function is applied for both parser and serializer.

## Transforms

**rescript-schema** allows to augment schema with transformation logic, letting you transform value during parsing and serializing. This is most commonly used for mapping value to more convenient data-structures.

### **`transform`**

`(S.t<'input>, S.effectCtx<'output> => S.transformDefinition<'input, 'output>) => S.t<'output>`

```rescript
let intToString = schema =>
  schema->S.transform(s => {
    parser: Int.toString,
    serializer: string =>
      switch string->Int.fromString {
      | Some(int) => int
      | None => s.fail("Can't convert string to int")
      },
  })
```

Also, you can have an asynchronous transform:

```rescript
type user = {
  id: string,
  name: string,
}

let userSchema =
  S.string
  ->S.String.uuid
  ->S.transform(s => {
    asyncParser: userId => () => loadUser(~userId),
    serializer: user => user.id,
  })

await %raw(`"1"`)->S.parseAsyncWith(userSchema)
// Ok({
//   id: "1",
//   name: "John",
// })

{
  id: "1",
  name: "John",
}->S.serializeWith(userSchema)
// Ok("1")
```

## Preprocess _Advanced_

Typically **rescript-schema** operates under a "parse then transform" paradigm. **rescript-schema** validates the input first, then passes it through a chain of transformation functions.

But sometimes you want to apply some transform to the input before parsing happens. Mostly needed when you build sometimes on top of **rescript-schema**. A simplified example from [rescript-envsafe](https://github.com/DZakh/rescript-envsafe):

```rescript
let prepareEnvSchema = S.preprocess(_, s => {
    switch s.schema->S.classify {
    | Literal(Boolean(_))
    | Bool => {
        parser: unknown => {
          switch unknown->Obj.magic {
          | "true"
          | "t"
          | "1" => true
          | "false"
          | "f"
          | "0" => false
          | _ => unknown->Obj.magic
          }->Obj.magic
        },
      }
    | Int
    | Float
    | Literal(Number(_)) => {
        parser: unknown => {
          if unknown->Js.typeof === "string" {
            %raw(`+unknown`)
          } else {
            unknown
          }
        },
      }
    | _ => {}
    }
  })
```

> 🧠 When using preprocess on Union it will be applied to nested schemas separately.

## Functions on schema

### **`parseWith`**

`(JSON.t, S.t<'value>) => result<'value, S.error>`

```rescript
data->S.parseWith(userSchema)
```

Given any schema, you can call `parseWith` to check `data` is valid. It returns a result with valid data transformed to expected type or a **rescript-schema** error.

### **`parseAnyWith`**

`('any, S.t<'value>) => result<'value, S.error>`

```rescript
data->S.parseAnyWith(userSchema)
```

The same as `parseWith`, but the `data` is loosened to the abstract type.

### **`parseJsonStringWith`**

`(string, S.t<'value>) => result<'value, S.error>`

```rescript
json->S.parseJsonStringWith(userSchema)
```

The same as `parseWith`, but applies `JSON.parse` before parsing.

### **`parseOrRaiseWith`**

`(JSON.t, S.t<'value>) => 'value`

```rescript
try {
  data->S.parseOrRaiseWith(userSchema)
} catch {
| S.Raised(error) => Exn.raise(error->S.Error.message)
}
```

The exception-based version of `parseWith`.

### **`parseAnyOrRaiseWith`**

`('any', S.t<'value>) => 'value`

```rescript
try {
  data->S.parseAnyOrRaiseWith(userSchema)
} catch {
| S.Raised(error) => Exn.raise(error->S.Error.message)
}
```

The exception-based version of `parseAnyWith`.

### **`parseAsyncWith`**

`(JSON.t, S.t<'value>) => promise<result<'value, S.error>>`

```rescript
data->S.parseAsyncWith(userSchema)
```

If you use asynchronous refinements or transforms, you'll need to use `parseAsyncWith`. It will parse all synchronous branches first and then continue with asynchronous refinements and transforms in parallel.

### **`parseAsyncInStepsWith`** _Advanced_

`(JSON.t, S.t<'value>) => result<(. unit) => promise<result<'value, S.error>>, S.error>`

```rescript
data->S.parseAsyncInStepsWith(userSchema)
```

After parsing synchronous branches will return a function to run asynchronous refinements and transforms.

### **`serializeWith`**

`('value, S.t<'value>) => result<JSON.t, S.error>`

```rescript
user->S.serializeWith(userSchema)
```

Serializes value using the transformation logic that is built-in to the schema. It returns a result with a transformed data or a **rescript-schema** error.

> 🧠 It'll fail with JSON incompatible schema. Use S.serializeToUnknownWith if you have schema which doesn't serialize to JSON.

### **`serializeToUnknownWith`**

`('value, S.t<'value>) => result<unknown, S.error>`

```rescript
user->S.serializeToUnknownWith(userSchema)
```

Similar to the `serializeWith` but returns `unknown` instead of `JSON.t`. Also, it doesn't check the schema on JSON compatibility.

### **`serializeToJsonStringWith`**

`('value, ~space: int=?, S.t<'value>) => result<string, S.error>`

```rescript
user->S.serializeToJsonStringWith(userSchema)
```

The same as `serializeToUnknownWith`, but applies `JSON.serialize` at the end.

### **`serializeOrRaiseWith`**

`('value, S.t<'value>) => JSON.t`

```rescript
try {
  user->S.serializeOrRaiseWith(userSchema)
} catch {
| S.Raised(error) => Exn.raise(error->S.Error.message)
}
```

The exception-based version of `serializeWith`.

### **`serializeToUnknownOrRaiseWith`**

`('value, S.t<'value>) => JSON.t`

```rescript
try {
  user->S.serializeToUnknownOrRaiseWith(userSchema)
} catch {
| S.Raised(error) => Exn.raise(error->S.Error.message)
}
```

The exception-based version of `serializeToUnknownWith`.

### **`classify`**

`(S.t<'value>) => S.tagged`

```rescript
S.string->S.tagged
// String
```

This can be useful for building other tools like [`rescript-json-schema`](https://github.com/DZakh/rescript-json-schema).

### **`name`**

`(S.t<'value>) => string`

```rescript
S.literal({"abc": 123})->S.name
// `Literal({"abc": 123})`
```

Used internally for readable error messages.

> 🧠 Subject to change

### **`setName`**

`(S.t<'value>, string) => string`

```rescript
let schema = S.literal({"abc": 123})->S.setName("Abc")

schema->S.name
// `Abc`
```

You can customise a schema name using `S.setName`.

## Error handling

**rescript-schema** returns a result type with error `S.error` containing detailed information about the validation problems.

```rescript
let schema = S.literal(false)

%raw(`true`)->S.parseWith(schema)
// Error({
//   code: InvalidLiteral({expected: Boolean(false), received: true}),
//   operation: Parsing,
//   path: S.Path.empty,
// })
```

Also you can use the exception-based operations like `parseOrRaiseWith`. In this case the instance of `RescriptSchemaError` will be thrown with a nice error message. Also, you can use the `S.Raised` exception to catch it in ReScript code.

### **`Error.make`**

`(~code: S.errorCode, ~operation: S.operation, ~path: S.Path.t) => S.error`

Creates an instance of `RescriptSchemaError` error. At the same time it's the `S.Raised` exception.

### **`Error.raise`**

`S.error => exn`

Throws error. Since internally it's both the `S.Raised` exception and instance of `RescriptSchemaError`, it'll have a nice error message and can be caught using `S.Raised`.

### **`Error.message`**

`S.error => string`

```rescript
{
  code: InvalidLiteral({expected: Boolean(false), received: true}),
  operation: Parsing,
  path: S.Path.empty,
}->S.Error.message
```

```rescript
"Failed parsing at root. Reason: Expected false, received true"
```

### **`Error.reason`**

`S.error => string`

```rescript
{
  code: InvalidLiteral({expected: Boolean(false), received: true}),
  operation: Parsing,
  path: S.Path.empty,
}->S.Error.reason
```

```rescript
"Expected false, received true"
```
