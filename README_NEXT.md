[![CI](https://github.com/DZakh/rescript-struct/actions/workflows/ci.yml/badge.svg)](https://github.com/DZakh/rescript-struct/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DZakh/rescript-struct/branch/main/graph/badge.svg?token=40G6YKKD6J)](https://codecov.io/gh/DZakh/rescript-struct)
[![npm](https://img.shields.io/npm/dm/rescript-struct)](https://www.npmjs.com/package/rescript-struct)

# ReScript Struct

Safely parse and serialize with transformation to convenient ReScript data structures.

Highlights:

- Parses any data, not only `JSON.t`
- Uses the same struct for parsing and serializing
- Asynchronous refinements and transforms
- Support for both result and exception based API
- Easy to create _recursive_ structs
- Ability to disallow excessive object fields
- Built-in `union`, `literal` and many other structs
- Js API with TypeScript support for mixed codebases ([.d.ts](./src/S_JsApi.d.ts))
- The **fastest** parsing library in the entire JavaScript ecosystem ([benchmark](https://dzakh.github.io/rescript-runtime-type-benchmarks/))
- Small and tree-shakable: [7.1kB minified + zipped](https://bundlephobia.com/package/rescript-struct)

Also, it has declarative API allowing you to use **rescript-struct** as a building block for other tools, such as:

- [rescript-envsafe](https://github.com/DZakh/rescript-envsafe) - Makes sure you don't accidentally deploy apps with missing or invalid environment variables
- [rescript-json-schema](https://github.com/DZakh/rescript-json-schema) - Typesafe JSON schema for ReScript
- Internal form library at [Carla](https://www.carla.se/)

## How to use

Works the same in the browser and in node. See the [examples](#examples) section for more examples.

> 🧠 Note that **rescript-struct** uses the `Function` constructor, which may cause issues when included as a third-party script on a site with a [script-src](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/script-src) header. But it is completely safe to use as part of your application bundle.

## Install

```sh
npm install rescript-struct
```

Then add `rescript-struct` to `bs-dependencies` in your `bsconfig.json`:

```diff
{
  ...
+ "bs-dependencies": ["rescript-struct"]
+ "bsc-flags": ["-open RescriptStruct"],
}
```

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

// 2. Create a struct
let filmStruct = S.object(s => {
  id: s.field("Id", S.float),
  title: s.field("Title", S.string),
  tags: s.field("Tags", S.array(S.string)->S.default(() => [])),
  rating: s.field(
    "Rating",
    S.union([
      S.literal(GeneralAudiences),
      S.literal(ParentalGuidanceSuggested),
      S.literal(ParentalStronglyCautioned),
      S.literal(Restricted),
    ]),
  ),
  deprecatedAgeRestriction: s.field("Age", S.int->S.option->S.deprecate("Use rating instead")),
})

// 3. Parse data using the struct
// The data is validated and transformed to a convenient format
%raw(`{
  "Id": 1,
  "Title": "My first film",
  "Rating": "R",
  "Age": 17
}`)->S.parseWith(filmStruct)
// Ok({
//   id: 1.,
//   title: "My first film",
//   tags: [],
//   rating: Restricted,
//   deprecatedAgeRestriction: Some(17),
// })

// 4. Transform data back using the same struct
{
  id: 2.,
  tags: ["Loved"],
  title: "Sad & sed",
  rating: ParentalStronglyCautioned,
  deprecatedAgeRestriction: None,
}->S.serializeWith(filmStruct)
// Ok(%raw(`{
//   "Id": 2,
//   "Title": "Sad & sed",
//   "Rating": "PG13",
//   "Tags": ["Loved"],
//   "Age": undefined,
// }`))

// 5. Use struct as a building block for other tools
// For example, create a JSON-schema with rescript-json-schema and use it for OpenAPI generation
let filmJsonSchema = JSONSchema.make(filmStruct)
```

## Examples

- [Reliable API layer](https://github.com/Nicolas1st/net-cli-rock-paper-scissors/blob/main/apps/client/src/Api.res)
- [Creating CLI utility](https://github.com/DZakh/rescript-stdlib-cli/blob/main/src/interactors/RunCli.res)
- [Safely accessing environment variables variables](https://github.com/Nicolas1st/net-cli-rock-paper-scissors/blob/main/apps/client/src/Env.res)

## Struct factories

**rescript-struct** exposes factory functions for a variety of common JavaScript types. You can also define your own custom struct factories.

### **`string`**

`S.t<string>`

```rescript
let struct = S.string

%raw(`"Hello World!"`)->S.parseWith(struct)
// Ok("Hello World!")
```

The `string` struct represents a data that is a string. It can be further constrainted with the following utility methods.

**rescript-struct** includes a handful of string-specific refinements and transforms:

```rescript
S.string->S.String.max(5) // String must be 5 or fewer characters long
S.string->S.String.min(5) // String must be 5 or more characters long
S.string->S.String.length(5) // String must be exactly 5 characters long
S.string->S.String.email() // Invalid email address
S.string->S.String.url() // Invalid url
S.string->S.String.uuid() // Invalid UUID
S.string->S.String.cuid() // Invalid CUID
S.string->S.String.pattern(%re(`/[0-9]/`)) // Invalid
S.string->S.String.datetime() // Invalid datetime string! Must be UTC

S.string->S.String.trim() // trim whitespaces
```

When using built-in refinements, you can provide a custom error message.

```rescript
S.string->S.String.min(~message="String can't be empty", 1)
S.string->S.String.length(~message="SMS code should be 5 digits long", 5)
```

#### ISO datetimes

The `S.string->S.String.datetime()` function has following UTC validation: no timezone offsets with arbitrary sub-second decimal precision.

```rescript
let datetimeStruct = S.string->S.String.datetime()
// The datetimeStruct has the type S.t<Date.t>
// String is transformed to the Date.t instance

%raw(`"2020-01-01T00:00:00Z"`)->S.parseWith(datetimeStruct) // pass
%raw(`"2020-01-01T00:00:00.123Z"`)->S.parseWith(datetimeStruct) // pass
%raw(`"2020-01-01T00:00:00.123456Z"`)->S.parseWith(datetimeStruct) // pass (arbitrary precision)
%raw(`"2020-01-01T00:00:00+02:00"`)->S.parseWith(datetimeStruct) // fail (no offsets allowed)
```

### **`bool`**

`S.t<bool>`

```rescript
let struct = S.bool

%raw(`false`)->S.parseWith(struct)
// Ok(false)
```

The `bool` struct represents a data that is a boolean.

### **`int`**

`S.t<int>`

```rescript
let struct = S.int

%raw(`123`)->S.parseWith(struct)
// Ok(123)
```

The `int` struct represents a data that is an integer.

**rescript-struct** includes some of int-specific refinements:

```rescript
S.int->S.Int.max(5) // Number must be lower than or equal to 5
S.int->S.Int.min(5) // Number must be greater than or equal to 5
S.int->S.Int.port() // Invalid port
```

### **`float`**

`S.t<float>`

```rescript
let struct = S.float

%raw(`123`)->S.parseWith(struct)
// Ok(123.)
```

The `float` struct represents a data that is a number.

**rescript-struct** includes some of float-specific refinements:

```rescript
S.float->S.Float.max(5) // Number must be lower than or equal to 5
S.float->S.Float.min(5) // Number must be greater than or equal to 5
```

### **`option`**

`S.t<'value> => S.t<option<'value>>`

```rescript
let struct = S.option(S.string)

%raw(`"Hello World!"`)->S.parseWith(struct)
// Ok(Some("Hello World!"))
%raw(`undefined`)->S.parseWith(struct)
// Ok(None)
```

The `option` struct represents a data of a specific type that might be undefined.

### **`null`**

`S.t<'value> => S.t<option<'value>>`

```rescript
let struct = S.null(S.string)

%raw(`"Hello World!"`)->S.parseWith(struct)
// Ok(Some("Hello World!"))
%raw(`null`)->S.parseWith(struct)
// Ok(None)
```

The `null` struct represents a data of a specific type that might be null.

### **`unit`**

`S.t<unit>`

```rescript
let struct = S.unit

%raw(`undefined`)->S.parseWith(struct)
// Ok()
```

The `unit` struct factory is an alias for `S.literal()`.

### **`literal`**

`'value => S.t<'value>`

```rescript
let tunaStruct = S.literal("Tuna")
let twelveStruct = S.literal(12)
let importantTimestampStruct = S.literal(1652628345865.)
let truStruct = S.literal(true)
let nullStruct = S.literal(Null.null)
let undefinedStruct = S.literal() // Building block for S.unit

// Uses Number.isNaN to match NaN literals
let nanStruct = S.literal(Float.Constants.nan)->S.variant(_ => ()) // For NaN literals I recomment adding S.variant to transform it to unit. It's better than having it as a float

// Supports symbols and BigInt
let symbolStruct = S.literal(Symbol.asyncIterator)
let twobigStruct = S.literal(BigInt.fromInt(2))

// Supports variants and polymorphic variants
let appleStruct = S.literal(#apple)
let noneStruct = S.literal(None)

// Does a deep check for objects and arrays
let cliArgsStruct = S.literal(("help", "lint"))

// Supports functions and literally any Js values matching them with the === operator
let fn = () => "foo"
let fnStruct = S.literal(fn)
let weakMap = WeakMap.make()
let weakMapStruct = S.literal(weakMap)
```

The `literal` struct enforces that a data matches an exact value during parsing and serializing.

### **`object`**

`(S.Object.definerCtx => 'value) => S.t<'value>`

```rescript
type point = {
  x: int,
  y: int,
}

// The pointStruct will have the S.t<point> type
let pointStruct = S.object(s => {
  x: s.field("x", S.int),
  y: s.field("y", S.int),
})

// It can be used both for parsing and serializing
%raw(`{ "x": 1,"y": -4 }`)->S.parseWith(pointStruct)
{ x: 1, y: -4 }->S.serializeWith(pointStruct)
```

The `object` struct represents an object value, that can be transformed into any ReScript value. Here are some examples:

#### Transform object field names

```rescript
type user = {
  id: int,
  name: string,
}
// It will have the S.t<user> type
let struct = S.object(s => {
  id: s.field("USER_ID", S.int),
  name: s.field("USER_NAME", S.string),
})

%raw(`{"USER_ID":1,"USER_NAME":"John"}`)->S.parseWith(struct)
// Ok({ id: 1, name: "John" })
```

#### Transform to a structurally typed object

```rescript
// It will have the S.t<{"key1":string,"key2":string}> type
let struct = S.object(s => {
  "key1": s.field("key1", S.string),
  "key2": s.field("key2", S.string),
})
```

#### Transform to a tuple

```rescript
// It will have the S.t<(int, string)> type
let struct = S.object(s => (s.field("USER_ID", S.int), s.field("USER_NAME", S.string)))

%raw(`{"USER_ID":1,"USER_NAME":"John"}`)->S.parseWith(struct)
// Ok((1, "John"))
```

The same struct also works for serializing:

```rescript
(1, "John")->S.serializeWith(struct)
// Ok(%raw(`{"USER_ID":1,"USER_NAME":"John"}`))
```

#### Transform to a variant

```rescript
type shape = Circle({radius: float}) | Square({x: float}) | Triangle({x: float, y: float})

// It will have the S.t<shape> type
let struct = S.object(s => {
  s.tag("kind", "circle")
  Circle({
    radius: s.field("radius", S.float),
  })
})

%raw(`{
  "kind": "circle",
  "radius": 1,
}`)->S.parseWith(struct)
// Ok(Circle({radius: 1}))
```

The same struct also works for serializing:

```rescript
Circle({radius: 1})->S.serializeWith(struct)
// Ok(%raw(`{
//   "kind": "circle",
//   "radius": 1,
// }`))
```

### **`Object.strict`**

`S.t<'value> => S.t<'value>`

```rescript
// Represents an object without fields
let struct = S.object(_ => ())->S.Object.strict

%raw(`{
  "someField": "value",
}`)->S.parseWith(struct)
// Error({
//   code: ExcessField("someField"),
//   operation: Parsing,
//   path: S.Path.empty,
// })
```

By default **rescript-struct** silently strips unrecognized keys when parsing objects. You can change the behaviour to disallow unrecognized keys with the `S.Object.strict` function.

### **`Object.strip`**

`S.t<'value> => S.t<'value>`

```rescript
// Represents an object with any fields
let struct = S.object(_ => ())->S.Object.strip

%raw(`{
  "someField": "value",
}`)->S.parseWith(struct)
// Ok()
```

You can use the `S.Object.strip` function to reset a object struct to the default behavior (stripping unrecognized keys).

### **`variant`**

`(S.t<'value>, 'value => 'variant) => S.t<'variant>`

```rescript
type shape = Circle({radius: float}) | Square({x: float}) | Triangle({x: float, y: float})

// It will have the S.t<shape> type
let struct = S.float->S.variant(radius => Circle({radius: radius}))

%raw(`1`)->S.parseWith(struct)
// Ok(Circle({radius: 1.}))
```

The same struct also works for serializing:

```rescript
Circle({radius: 1})->S.serializeWith(struct)
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

let shapeStruct = S.union([
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
}`)->S.parseWith(shapeStruct)
// Ok(Circle({radius: 1.}))
```

```rescript
Square({x: 2.})->S.serializeWith(shapeStruct)
// Ok({
//   "kind": "square",
//   "x": 2,
// })
```

The `union` will test the input against each of the structs in order and return the first value that validates successfully.

#### Enums

Also, you can describe enums using `S.union` together with `S.literal`.

```rescript
type outcome = | @as("win") Win | @as("draw") Draw | @as("loss") Loss

let struct = S.union([
  S.literal(Win),
  S.literal(Draw),
  S.literal(Loss),
])

%raw(`"draw"`)->S.parseWith(struct)
// Ok(Draw)
```

### **`array`**

`S.t<'value> => S.t<array<'value>>`

```rescript
let struct = S.array(S.string)

%raw(`["Hello", "World"]`)->S.parseWith(struct)
// Ok(["Hello", "World"])
```

The `array` struct represents an array of data of a specific type.

**rescript-struct** includes some of array-specific refinements:

```rescript
S.array()->S.Array.max(5) // Array must be 5 or fewer items long
S.array()->S.Array.min(5) // Array must be 5 or more items long
S.array()->S.Array.length(5) // Array must be exactly 5 items long
```

### **`list`**

`S.t<'value> => S.t<list<'value>>`

```rescript
let struct = S.list(S.string)

%raw(`["Hello", "World"]`)->S.parseWith(struct)
// Ok(list{"Hello", "World"})
```

The `list` struct represents an array of data of a specific type which is transformed to ReScript's list data structure.

### **`tuple0` - `S.tuple10`**

`(. S.t<'v1>, S.t<'v2>, S.t<'v3>) => S.t<('v1, 'v2, 'v3)>`

```rescript
let struct = S.tuple3(. S.string, S.int, S.bool)

%raw(`["a", 1, true]`)->S.parseWith(struct)
// Ok(("a", 1, true))
```

The `tuple` struct represents that a data is an array of a specific length with values each of a specific type.

The tuple struct factories are available up to 10 fields. If you have an array with more values, you can create a tuple struct factory for any number of fields using `S.Tuple.factory`.

```rescript
let bigTupleStruct = S.Tuple.factory([
  S.string->S.toUnknown,
  S.string->S.toUnknown,
  S.string->S.toUnknown,
  S.int->S.toUnknown,
  S.int->S.toUnknown,
  S.int->S.toUnknown,
  S.float->S.toUnknown,
  S.float->S.toUnknown,
  S.float->S.toUnknown,
  S.bool->S.toUnknown,
  S.bool->S.toUnknown,
  S.bool->S.toUnknown,
])->(Obj.magic: S.t<array<unknown>> => S.t<(string, string, string, int, int, int, float, float, float, bool, bool, bool)>)
```

> 🧠 You need to cast the `S.Tuple.factory` return value to desired type by yourself.

### **`dict`**

`S.t<'value> => S.t<Dict.t<'value>>`

```rescript
let struct = S.dict(S.string)

%raw(`{
  "foo": "bar",
  "baz": "qux",
}`)->S.parseWith(struct)
// Ok(Dict.fromArray([("foo", "bar"), ("baz", "qux")]))
```

The `dict` struct represents a dictionary of data of a specific type.

### **`unknown`**

`S.t<unknown>`

```rescript
let struct = S.unknown

%raw(`"Hello World!"`)->S.parseWith(struct)
```

The `unknown` struct represents any data.

### **`never`**

`S.t<S.never>`

```rescript
let struct = S.never

%raw(`undefined`)->S.parseWith(struct)
// Error({
//   code: InvalidType({expected: S.never, received: undefined}),
//   operation: Parsing,
//   path: S.Path.empty,
// })
```

The `never` struct will fail parsing for every value.

### **`json`**

`S.t<JSON.t>`

```rescript
let struct = S.json

%raw(`"123"`)->S.parseWith(struct)
// Ok(String("123"))
```

The `json` struct represents a data that is compatible with JSON.

### **`jsonString`**

`S.t<'value> => S.t<'value>`

```rescript
let struct = S.jsonString(S.int)

%raw(`"123"`)->S.parseWith(struct)
// Ok(123)
```

The `jsonString` struct represents a data that is a JSON string containing a value of a specific type.

### **`default`**

`(S.t<'value>, unit => 'value) => S.t<'value>`

```rescript
let struct = S.string->S.default(() => "Hello World!")

%raw(`undefined`)->S.parseWith(struct)
// Ok("Hello World!")
%raw(`"Goodbye World!"`)->S.parseWith(struct)
// Ok("Goodbye World!")
```

The `default` augments a struct to add transformation logic for default values, which are applied when the input is undefined.

### **`describe`**

`(S.t<'value>, string) => S.t<'value>`

Use `S.describe` to add a `description` property to the resulting struct.

```rescript
let documentedString = S.string
  ->S.describe("A useful bit of text, if you know what to do with it.")

documentedString->S.description // A useful bit of text…
```

This can be useful for documenting a field, for example in a JSON Schema using a library like [`rescript-json-schema`](https://github.com/DZakh/rescript-json-schema).

### **`deprecate`**

`(S.t<'value>, string) => S.t<'value>`

Use `S.deprecate` to add a `deprecation` message property to the resulting struct.

```rescript
let deprecatedString = S.string
  ->S.deprecate("Will be removed in APIv2")

deprecatedString->S.deprecation // Will be removed in APIv2…
```

This can be useful for documenting a field, for example in a JSON Schema using a library like [`rescript-json-schema`](https://github.com/DZakh/rescript-json-schema).

### **`catch`**

`(S.t<'value>, S.catchCtx => 'value) => S.t<'value>`

Use `S.catch` to provide a "catch value" to be returned instead of a parsing error.

```rescript
let struct = S.float->S.catch(_ => 42.)

%raw(`5`)->S.parseWith(struct)
// Ok(5.)
%raw(`"tuna"`)->S.parseWith(struct)
// Ok(42.)
```

Also, the callback `S.catch` receives a catch context as a first argument. It contains the caught error and the initial data provided to the parse function.

```rescript
let struct = S.float->S.catch(ctx => {
  Console.log(ctx.error) // The caught error
  Console.log(ctx.input) // The data provided to the parse function
  42.
})
```

Conceptually, this is how **rescript-struct** processes "catch values":

1. The data is parsed using the base struct
2. If the parsing fails, the "catch value" is returned

### **`custom`**

`(string, effectCtx<'output> => customDefinition<'input, 'output>) => t<'output>`

You can also define your own custom struct factories that are specific to your application's requirements:

```rescript
let nullableStruct = innerStruct => {
  S.custom("Nullable", s => {
    parser: unknown => {
      if unknown === %raw(`undefined`) || unknown === %raw(`null`) {
        None
      } else {
        switch unknown->S.parseAnyWith(innerStruct) {
        | Ok(value) => Some(value)
        | Error(error) => s.failWithError(error)
        }
      }
    },
    serializer: value => {
      switch value {
      | Some(innerValue) =>
        switch innerValue->S.serializeToUnknownWith(innerStruct) {
        | Ok(value) => value
        | Error(error) => s.failWithError(error)
        }
      | None => %raw(`null`)
      }
    },
  })
}

%raw(`"Hello world!"`)->S.parseWith(struct)
// Ok(Some("Hello World!"))
%raw(`null`)->S.parseWith(struct)
// Ok(None)
%raw(`undefined`)->S.parseWith(struct)
// Ok(None)
%raw(`123`)->S.parseWith(struct)
// Error({
//   code: InvalidType({expected: S.string, received: 123}),
//   operation: Parsing,
//   path: S.Path.empty,
// })
```

### **`recursive`**

`(t<'value> => t<'value>) => t<'value>`

You can define a recursive struct in **rescript-struct**.

```rescript
type rec node = {
  id: string,
  children: array<node>,
}

let nodeStruct = S.recursive(nodeStruct => {
  S.object(s => {
    id: s.field("Id", S.string),
    children: s.field("Children", S.array(nodeStruct)),
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
}`)->S.parseWith(nodeStruct)
// Ok({
//   id: "1",
//   children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
// })
```

The same struct works for serializing:

```rescript
{
  id: "1",
  children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
}->S.serializeWith(nodeStruct)
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
let nodeStruct = S.recursive(nodeStruct => {
  S.object(s => {
    id: s.field("Id", S.string)->S.asyncParserRefine(checkIsExistingNode),
    children: s.field("Children", S.array(nodeStruct)),
  })
})
```

One great aspect of the example above is that it uses parallelism to make four requests to check for the existence of nodes.

> 🧠 Despite supporting recursive structs, passing cyclical data into rescript-struct will cause an infinite loop.

## Refinements

**rescript-struct** lets you provide custom validation logic via refinements.

There are many so-called "refinement types" you may wish to check for that can't be represented in ReScript's type system. For instance: checking that a number is an integer or that a string is a valid email address.

### **`refine`**

`(S.t<'value>, effectCtx<'value> => 'value => unit) => S.t<'value>`

```rescript
let shortStringStruct = S.string->S.refine(s => value =>
  if value->String.length > 255 {
    s.fail("String can't be more than 255 characters")
  }
)
```

The refine function is applied for both parser and serializer.

### **`asyncParserRefine`**

`(S.t<'value>, effectCtx<'value> => 'value => promise<unit>) => S.t<'value>`

Also, you can have an asynchronous refinement. It's applied only for parsing. Serializing is not affected.

```rescript
let userIdStruct = S.string->S.asyncParserRefine(s => userId =>
  verfiyUserExistsInDb(~userId)->Promise.thenResolve(isExistingUser =>
    if !isExistingUser {
      s.fail("User doesn't exist")
    }
  )
)
```

> 🧠 If you use async refinements, you must use the `parseAsyncWith` to parse data! Otherwise **rescript-struct** will return an `UnexpectedAsync` error.

## Transforms

**rescript-struct** allows structs to be augmented with transformation logic, letting you transform value during parsing and serializing. This is most commonly used for mapping value to a more convenient ReScript data structure.

### **`transform`**

`(S.t<'input>, S.effectCtx<'output> => S.transformDefinition<'input, 'output>) => S.t<'output>`

```rescript
let intToString = struct =>
  struct->S.transform(s => {
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

let userStruct =
  S.string
  ->S.String.uuid
  ->S.transform(s => {
    asyncParser: userId => () => loadUser(~userId),
    serializer: user => user.id,
  })

await %raw(`"1"`)->S.parseAsyncWith(userStruct)
// Ok({
//   id: "1",
//   name: "John",
// })

{
  id: "1",
  name: "John",
}->S.serializeWith(userStruct)
// Ok("1")
```

## Preprocess _Advanced_

Typically **rescript-struct** operates under a "parse then transform" paradigm. **rescript-struct** validates the input first, then passes it through a chain of transformation functions.

But sometimes you want to apply some transform to the input before parsing happens. Mostly needed when you build sometimes on top of **rescript-struct**. A simplified example from [rescript-envsafe](https://github.com/DZakh/rescript-envsafe):

```rescript
let prepareEnvStruct = S.preprocess(_, s => {
    switch s.struct->S.classify {
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

> 🧠 When using preprocess on Union it will be applied to nested structs separately instead.

## Functions on struct

### **`parseWith`**

`(JSON.t, S.t<'value>) => result<'value, S.Error.t>`

```rescript
data->S.parseWith(userStruct)
```

Given any struct, you can call `parseWith` to check `data` is valid. It returns a result with valid data transformed to expected type or a **rescript-struct** error.

### **`parseAnyWith`**

`('any, S.t<'value>) => result<'value, S.Error.t>`

```rescript
data->S.parseAnyWith(userStruct)
```

The same as `parseWith`, but the `data` is loosened to the abstract type.

### **`parseJsonStringWith`**

`(string, S.t<'value>) => result<'value, S.Error.t>`

```rescript
json->S.parseJsonStringWith(userStruct)
```

The same as `parseWith`, but applies `JSON.parse` before parsing.

### **`parseOrRaiseWith`**

`(JSON.t, S.t<'value>) => 'value`

```rescript
try {
  data->S.parseOrRaiseWith(userStruct)
} catch {
| S.Raised(error) => Exn.raise(error->S.Error.toString)
}
```

The exception-based version of `parseWith`.

### **`parseAnyOrRaiseWith`**

`('any', S.t<'value>) => 'value`

```rescript
try {
  data->S.parseAnyOrRaiseWith(userStruct)
} catch {
| S.Raised(error) => Exn.raise(error->S.Error.toString)
}
```

The exception-based version of `parseAnyWith`.

### **`parseAsyncWith`**

`(JSON.t, S.t<'value>) => promise<result<'value, S.Error.t>>`

```rescript
data->S.parseAsyncWith(userStruct)
```

If you use asynchronous refinements or transforms (more on those later), you'll need to use `parseAsyncWith`. It will parse all synchronous branches first and then continue with asynchronous refinements and transforms in parallel.

### **`parseAsyncInStepsWith`** _Advanced_

`(JSON.t, S.t<'value>) => result<(. unit) => promise<result<'value, S.Error.t>>, S.Error.t>`

```rescript
data->S.parseAsyncInStepsWith(userStruct)
```

After parsing synchronous branches will return a function to run asynchronous refinements and transforms.

### **`serializeWith`**

`('value, S.t<'value>) => result<JSON.t, S.Error.t>`

```rescript
user->S.serializeWith(userStruct)
```

Serializes value using the transformation logic that is built-in to the struct. It returns a result with a transformed data or a **rescript-struct** error.

> 🧠 It fails with JSON incompatible structs. Use S.serializeToUnknownWith if you use structs that don't serialize to JSON.

### **`serializeToUnknownWith`**

`('value, S.t<'value>) => result<unknown, S.Error.t>`

```rescript
user->S.serializeToUnknownWith(userStruct)
```

Similar to the `serializeWith` but returns `unknown` instead of `JSON.t`. Also, it doesn't check the struct on JSON compatibility.

### **`serializeToJsonStringWith`**

`('value, ~space: int=?, S.t<'value>) => result<string, S.Error.t>`

```rescript
user->S.serializeToJsonStringWith(userStruct)
```

The same as `serializeToUnknownWith`, but applies `JSON.serialize` at the end.

### **`serializeOrRaiseWith`**

`('value, S.t<'value>) => JSON.t`

```rescript
try {
  user->S.serializeOrRaiseWith(userStruct)
} catch {
| S.Raised(error) => Exn.raise(error->S.Error.toString)
}
```

The exception-based version of `serializeWith`.

### **`serializeToUnknownOrRaiseWith`**

`('value, S.t<'value>) => JSON.t`

```rescript
try {
  user->S.serializeToUnknownOrRaiseWith(userStruct)
} catch {
| S.Raised(error) => Exn.raise(error->S.Error.toString)
}
```

The exception-based version of `serializeToUnknownWith`.

## Error handling

**rescript-struct** returns a result type with error `S.Error.t` containing detailed information about the validation problems.

```rescript
let struct = S.literal(false)

%raw(`true`)->S.parseWith(struct)
// Error({
//   code: InvalidLiteral({expected: Boolean(false), received: true}),
//   operation: Parsing,
//   path: S.Path.empty,
// })
```

### **`Error.toString`**

`S.Error.t => string`

```rescript
{
  code: InvalidLiteral({expected: Boolean(false), received: true}),
  operation: Parsing,
  path: S.Path.empty,
}->S.Error.toString
```

```rescript
"Failed parsing at root. Reason: Expected false, received true"
```

## Result helpers

### **`Result.getExn`**

`result<'a, S.Error.t> => 'a`

```rescript
let struct = S.literal(false)

%raw(`false`)->S.parseWith(struct)->S.Result.getExn
// false
%raw(`true`)->S.parseWith(struct)->S.Result.getExn
// throw new Error("[rescript-struct] Failed parsing at root. Reason: Expected false, received true")
```

> 🧠 It's not intended to be caught. Useful to panic with a readable error message.

### **`Result.mapErrorToString`**

`result<'a, S.Error.t> => result<'a, string>`

```rescript
let struct = S.literal(false)

%raw(`true`)->S.parseWith(struct)->S.Result.mapErrorToString
// Error("Failed parsing at root. Reason: Expected false, received true")
```

## Integration

If you're a library maintainer, you can use **rescript-struct** to get information about described structures. The most common use case is building type-safe schemas e.g for REST APIs, databases, and forms.

Documentation for this feature is work in progress, for now, you can use `S.resi` file as a reference and [rescript-json-schema](https://github.com/DZakh/rescript-json-schema) source code.
