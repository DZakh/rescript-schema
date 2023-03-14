[![CI](https://github.com/DZakh/rescript-struct/actions/workflows/ci.yml/badge.svg)](https://github.com/DZakh/rescript-struct/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DZakh/rescript-struct/branch/main/graph/badge.svg?token=40G6YKKD6J)](https://codecov.io/gh/DZakh/rescript-struct)
[![npm](https://img.shields.io/npm/dm/rescript-struct)](https://www.npmjs.com/package/rescript-struct)

# ReScript Struct

Safely parse and serialize with transformation to convenient ReScript data structures.

Highlights:

- Parses any data, not only JSON
- Uses the same struct for parsing and serializing
- Asynchronous refinements and transforms
- Support for both result and exception based API
- Easy to create _recursive_ structs
- Ability to disallow excessive object fields
- Built-in `union`, `literal` and many other structs
- Js API with TypeScript support for mixed codebases ([.d.ts](./src/S_JsApi.d.ts))
- The **fastest** parsing library in the entire JavaScript ecosystem ([benchmark](https://dzakh.github.io/rescript-runtime-type-benchmarks/))
- Tiny: [8.5kB minified + zipped](https://bundlephobia.com/package/rescript-struct)

Also, it has declarative API allowing you to use **rescript-struct** as a building block for other tools, such as:

- [rescript-envsafe](https://github.com/DZakh/rescript-envsafe) - Makes sure you don't accidentally deploy apps with missing or invalid environment variables
- [rescript-json-schema](https://github.com/DZakh/rescript-json-schema) - Typesafe JSON schema for ReScript
- Internal form library at [Carla](https://www.carla.se/)

## How to use

Works the same in the browser and in node. See the [examples](#examples) section for more examples.

> 🧠 Note that **rescript-struct** uses the `Function` constructor, which may cause issues when included as a third-party script on a site with a [script-src](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/script-src) header. But it is completely safe to use as part of your application bundle.

### Install

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

### Basic usage

```rescript
type author = {
  id: float,
  tags: array<string>,
  isAproved: bool,
  deprecatedAge: option<int>,
}

let authorStruct = S.object(o => {
  id: o->S.field("Id", S.float()),
  tags: o->S.field("Tags", S.option(S.array(S.string()))->S.defaulted([])),
  isAproved: o->S.field(
    "IsApproved",
    S.union([S.literalVariant(String("Yes"), true), S.literalVariant(String("No"), false)]),
  ),
  deprecatedAge: o->S.field(
    "Age",
    S.int()->S.deprecated(~message="Will be removed in APIv2", ()),
  ),
})
```

After creating a struct you can use it for parsing data:

```rescript
%raw(`{
  "Id": 1,
  "IsApproved": "Yes",
  "Age": 22,
}`)->S.parseWith(authorStruct)

Ok({
  id: 1.,
  tags: [],
  isAproved: true,
  deprecatedAge: Some(22),
})
```

The same struct also works for serializing:

```rescript
{
  id: 2.,
  tags: ["Loved"],
  isAproved: false,
  deprecatedAge: None,
}->S.serializeWith(authorStruct)

Ok(%raw(`{
  "Id": 2,
  "IsApproved": "No",
  "Tags": ["Loved"],
  "Age": undefined,
}`))
```

### Examples

- [Reliable API layer](https://github.com/Nicolas1st/net-cli-rock-paper-scissors/blob/main/apps/client/src/Api.res)
- [Creating CLI utility](https://github.com/DZakh/rescript-stdlib-cli/blob/main/src/interactors/RunCli.res)
- [Safely accessing environment variables variables](https://github.com/Nicolas1st/net-cli-rock-paper-scissors/blob/main/apps/client/src/Env.res)

## API Reference

### Struct factories

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

The `string` struct represents a data that is a string. It can be further constrainted with the following utility methods.

**rescript-struct** includes a handful of string-specific refinements and transforms:

```rescript
S.string()->S.String.max(5) // String must be 5 or fewer characters long
S.string()->S.String.min(5) // String must be 5 or more characters long
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

The `bool` struct represents a data that is a boolean.

#### **`S.int`**

`unit => S.t<int>`

```rescript
let struct = S.int()

123->S.parseWith(struct)
```

```rescript
Ok(123)
```

The `int` struct represents a data that is an integer.

**rescript-struct** includes some of int-specific refinements:

```rescript
S.int()->S.Int.max(5) // Number must be lower than or equal to 5
S.int()->S.Int.min(5) // Number must be greater than or equal to 5
S.int()->S.Int.port() // Invalid port
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

The `float` struct represents a data that is a number.

**rescript-struct** includes some of float-specific refinements:

```rescript
S.float()->S.Float.max(5) // Number must be lower than or equal to 5
S.float()->S.Float.min(5) // Number must be greater than or equal to 5
```

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

The `option` struct represents a data of a specific type that might be undefined.

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

The `null` struct represents a data of a specific type that might be null.

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

The `literal` struct enforces that a data matches an exact value using the === operator.

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

#### **`S.object`**

`(S.Object.definerCtx => 'value) => S.t<'value>`

```rescript
type point = {
  x: int,
  y: int,
}

// The pointStruct will have the S.t<point> type
let pointStruct = S.object(o => {
  x: o->S.field("x", S.int()),
  y: o->S.field("y", S.int()),
})

// It can be used both for parsing and serializing
{ "x": 1, "y": -4 }->S.parseWith(pointStruct)
{ x: 1, y: -4 }->S.serializeWith(pointStruct)
```

The `object` struct represents an object value, that can be transformed into any ReScript value. Here are some examples:

##### Transform object field names

```rescript
type user = {
  id: int,
  name: string,
}
// It will have the S.t<user> type
let struct = S.object(o => {
  id: o->S.field("USER_ID", S.int())
  name: o->S.field("USER_NAME", S.string())
})

%raw(`{"USER_ID":1,"USER_NAME":"John"}`)->S.parseWith(struct)

Ok({ id: 1, name: "John" })
```

##### Transform to a structurally typed object

```rescript
// It will have the S.t<{"key1":string,"key2":string}> type
let struct = S.object(o => {
  "key1": o->S.field("key1", S.string())
  "key2": o->S.field("key2", S.string())
})
```

##### Transform to a tuple

```rescript
// It will have the S.t<(int, string)> type
let struct = S.object(o => (o->S.field("USER_ID", S.int()), o->S.field("USER_NAME", S.string())))

%raw(`{"USER_ID":1,"USER_NAME":"John"}`)->S.parseWith(struct)

Ok((1, "John"))
```

The same struct also works for serializing:

```rescript
(1, "John")->S.serializeWith(struct)

Ok(%raw(`{"USER_ID":1,"USER_NAME":"John"}`))
```

##### Transform to a variant

```rescript
type shape = Circle({radius: float}) | Square({x: float}) | Triangle({x: float, y: float})

// It will have the S.t<shape> type
let struct = S.object(o => {
  ignore(o->S.field("kind", S.literal(String("circle"))))
  Circle({
    radius: o->S.field("radius", S.float()),
  })
})

%raw(`{
  "kind": "circle",
  "radius": 1,
}`)->S.parseWith(struct)

Ok(Circle({radius: 1}))
```

The same struct also works for serializing:

```rescript
Circle({radius: 1})->S.serializeWith(struct)

Ok(%raw(`{
  "kind": "circle",
  "radius": 1,
}`))
```

#### **`S.Object.strict`**

`S.t<'value> => S.t<'value>`

```rescript
// Represents an object without fields
let struct = S.object(_ => ())->S.Object.strict

{
  "someField": "value",
}->S.parseWith(struct)
```

```rescript
Error({
  code: ExcessField("someField"),
  operation: Parsing,
  path: [],
})
```

By default **rescript-struct** silently strips unrecognized keys when parsing objects. You can change the behaviour to disallow unrecognized keys with the `S.Object.strict` function.

#### **`S.Object.strip`**

`S.t<'value> => S.t<'value>`

```rescript
// Represents an object with any fields
let struct = S.object(_ => ())->S.Object.strip

{
  "someField": "value",
}->S.parseWith(struct)
```

```rescript
Ok()
```

You can use the `S.Object.strip` function to reset a object struct to the default behavior (stripping unrecognized keys).

#### **`S.union`**

`array<S.t<'value>> => S.t<'value>`

```rescript
// TypeScript type for reference:
// type Shape =
// | { kind: "circle"; radius: number }
// | { kind: "square"; x: number }
// | { kind: "triangle"; x: number; y: number };
type shape = Circle({radius: float}) | Square({x: float}) | Triangle({x: float, y: float})

let shapeStruct = S.union([
  S.object(o => {
    ignore(o->S.field("kind", S.literal(String("circle"))))
    Circle({
      radius: o->S.field("radius", S.float()),
    })
  }),
  S.object(o => {
    ignore(o->S.field("kind", S.literal(String("square"))))
    Square({
      x: o->S.field("x", S.float()),
    })
  }),
  S.object(o => {
    ignore(o->S.field("kind", S.literal(String("triangle"))))
    Triangle({
      x: o->S.field("x", S.float()),
      y: o->S.field("y", S.float()),
    })
  }),
])
```

```rescript
{
  "kind": "circle",
  "radius": 1,
}->S.parseWith(shapeStruct)

Ok(Circle({radius: 1.}))
```

```rescript
Square({x: 2.})->S.serializeWith(shapeStruct)

Ok({
  "kind": "square",
  "x": 2,
})
```

The `union` will test the input against each of the structs in order and return the first value that validates successfully.

##### Enums

Also, you can describe enums using `S.union` together with `S.literalVariant`.

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

#### **`S.array`**

`S.t<'value> => S.t<array<'value>>`

```rescript
let struct = S.array(S.string())

["Hello", "World"]->S.parseWith(struct)
```

```rescript
Ok(["Hello", "World"])
```

The `array` struct represents an array of data of a specific type.

**rescript-struct** includes some of array-specific refinements:

```rescript
S.array()->S.Array.max(5) // Array must be 5 or fewer items long
S.array()->S.Array.min(5) // Array must be 5 or more items long
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

The `tuple` struct represents that a data is an array of a specific length with values each of a specific type.

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

The `dict` struct represents a dictionary of data of a specific type.

#### **`S.unknown`**

`() => S.t<unknown>`

```rescript
let struct = S.unknown()

"Hello World!"->S.parseWith(struct)
```

The `unknown` struct represents any data.

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

The `never` struct will fail parsing for every value.

#### **`S.json`**

`S.t<'value> => S.t<'value>`

```rescript
let struct = S.json(S.int())

"123"->S.parseWith(struct)
```

```rescript
Ok(123)
```

The `json` struct represents a data that is a JSON string containing a value of a specific type.

#### **`S.custom`**

`(~name: string, ~parser: (. ~unknown: unknown) => 'value=?, ~serializer: (. ~value: 'value) => 'any=?, unit) => S.t<'value>`

You can also define your own custom struct factories that are specific to your application's requirements:

```rescript
let nullableStruct = innerStruct =>
  S.custom(
    ~name="Nullable",
    ~parser=(. ~unknown) => {
      unknown
      ->Obj.magic
      ->Js.Nullable.toOption
      ->Belt.Option.map(innerValue =>
        switch innerValue->S.parseWith(innerStruct) {
        | Ok(value) => value
        | Error(error) => S.Error.raiseCustom(error)
        }
      )
    },
    ~serializer=(. ~value) => {
      switch value {
      | Some(innerValue) =>
        switch innerValue->S.serializeWith(innerStruct) {
        | Ok(value) => value
        | Error(error) => S.Error.raiseCustom(error)
        }
      | None => %raw("null")
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

#### **`S.defaulted`**

`(S.t<option<'value>>, 'value) => S.t<'value>`

```rescript
let struct = S.option(S.string())->S.defaulted("Hello World!")

%raw(`undefined`)->S.parseWith(struct)
"Goodbye World!"->S.parseWith(struct)
```

```rescript
Ok("Hello World!")
Ok("Goodbye World!")
```

The `defaulted` augments a struct to add transformation logic for default values, which are applied when the input is undefined.

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

The `deprecated` struct represents a data of a specific type and makes it optional. The message may be used by an integration library.

#### **`S.recursive`**

`(t<'value> => t<'value>) => t<'value>`

You can define a recursive struct in **rescript-struct**.

```rescript
type rec node = {
  id: string,
  children: array<node>,
}

let nodeStruct = S.recursive(nodeStruct => {
  S.object(
    o => {
      id: o->S.field("Id", S.string()),
      children: o->S.field("Children", S.array(nodeStruct)),
    },
  )
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

Ok({
  id: "1",
  children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
})
```

The same struct also works for serializing:

```rescript
{
  id: "1",
  children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
}->S.serializeWith(nodeStruct)

Ok(%raw(`{
  "Id": "1",
  "Children": [
    {"Id": "2", "Children": []},
    {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
  ],
}`))
```

> 🧠 Despite supporting recursive structs, passing cyclical data into rescript-struct will cause an infinite loop.

#### **`S.asyncRecursive`**

`(t<'value> => t<'value>) => t<'value>`

If the recursive struct has an asynchronous parser, you must use `S.asyncRecursive` instead of `S.recursive`.

```rescript
type rec node = {
  id: string,
  children: array<node>,
}

let nodeStruct = S.asyncRecursive(nodeStruct => {
  S.object(
    o => {
      id: o->S.field("Id", S.string())->S.asyncRefine(~parser=checkIsExistingNode, ()),
      children: o->S.field("Children", S.array(nodeStruct)),
    },
  )
})
```

```rescript
await %raw(`{
  "Id": "1",
  "Children": [
    {"Id": "2", "Children": []},
    {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
  ],
}`)->S.parseAsyncWith(nodeStruct)

Ok({
  id: "1",
  children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
})
```

One great aspect of the example above is that it uses parallelism to make four requests to check for the existence of nodes.

### Refinements

**rescript-struct** lets you provide custom validation logic via refinements.

There are many so-called "refinement types" you may wish to check for that can't be represented in ReScript's type system. For instance: checking that a number is an integer or that a string is a valid email address.

#### **`S.refine`**

`(S.t<'value>, ~parser: 'value => unit=?, ~serializer: 'value => unit=?, unit) => S.t<'value>`

```rescript
let shortStringStruct = S.string()->S.refine(~parser=value =>
  if value->Js.String2.length > 255 {
    S.Error.raise("String can't be more than 255 characters")
  }
, ())
```

> 🧠 Refinement functions should not throw. Use `S.Error.raise` or `S.Error.raiseCustom` to exit with failure.

#### **`S.asyncRefine`**

`(S.t<'value>, ~parser: 'value => promise<unit>, unit) => S.t<'value>`

```rescript
let userIdStruct = S.string()->S.asyncRefine(~parser=userId =>
  verfiyUserExistsInDb(~userId)->Promise.thenResolve(isExistingUser =>
    if !isExistingUser {
      S.Error.raise("User doesn't exist")
    }
  )
, ())
```

> 🧠 If you use async refinements, you must use the `parseAsyncWith` to parse data! Otherwise **rescript-struct** will return an `UnexpectedAsync` error.

### Transforms

**rescript-struct** allows structs to be augmented with transformation logic, letting you transform value during parsing and serializing. This is most commonly used for mapping value to a more convenient ReScript data structure.

#### **`S.transform`**

`(S.t<'value>, ~parser: 'value => 'transformed=?, ~serializer: 'transformed => 'value=?, unit) => S.t<'transformed>`

```rescript
let intToString = struct =>
  struct->S.transform(
    ~parser=int => int->Js.Int.toString,
    ~serializer=string =>
      switch string->Belt.Int.fromString {
      | Some(int) => int
      | None => S.Error.raise("Can't convert string to int")
      },
    (),
  )
```

> 🧠 Transform functions should not throw. Use `S.Error.raise` or `S.Error.raiseCustom` to exit with failure.

#### **`S.advancedTransform`** _Advanced_

`type transformation<'input, 'output> = Sync('input => 'output) | Async('input => promise<'output>)`

`(S.t<'value>, ~parser: (~struct: S.t<'value>) => S.transformation<'value, 'transformed>=?, ~serializer: (~struct: S.t<'value>) => S.transformation<'transformed, 'value>=?, unit) => S.t<'transformed>`

The `transform`, `refine`, `asyncRefine`, and `custom` functions are actually syntactic sugar atop a more versatile (and verbose) function called `advancedTransform`.

```rescript
type user = {
  id: string,
  name: string,
}

let userStruct =
  userIdStruct->S.advancedTransform(
    ~parser=(~struct as _) => Async(userId => loadUser(~userId)),
    ~serializer=user => user.id,
    (),
  )
```

```rescript
await "1"->S.parseAsyncWith(userStruct)

Ok({
  id: "1",
  name: "John",
})
```

```rescript
{
  id: "1",
  name: "John",
}->S.serializeWith(userStruct)

Ok("1")
```

### Preprocess _Advanced_

Typically **rescript-struct** operates under a "parse then transform" paradigm. **rescript-struct** validates the input first, then passes it through a chain of transformation functions.

But sometimes you want to apply some transform to the input before parsing happens. Mostly needed when you build sometimes on top of **rescript-struct**. A simplified example from [rescript-envsafe](https://github.com/DZakh/rescript-envsafe):

```rescript
let prepareEnvStruct = S.advancedPreprocess(
  _,
  ~parser=(~struct) => {
    switch struct->S.classify {
    | Bool =>
      Sync(
        unknown => {
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
      )
    | Int =>
      Sync(
        unknown => {
          if unknown->Js.typeof === "string" {
            %raw(`+unknown`)
          } else {
            unknown
          }
        },
      )
    | _ => Sync(Obj.magic)
    }
  },
  (),
)
```

> 🧠 When using preprocess on Union it will be applied to nested structs separately instead.

### Functions on struct

#### **`S.parseWith`**

`('any, S.t<'value>) => result<'value, S.Error.t>`

```rescript
data->S.parseWith(userStruct)
```

Given any struct, you can call `parseWith` to check data is valid. It returns a result with valid data transformed to expected type or a **rescript-struct** error.

#### **`S.parseOrRaiseWith`**

`('any, S.t<'value>) => 'value`

```rescript
try {
  data->S.parseOrRaiseWith(userStruct)
} catch {
| S.Raised(error) => Js.Exn.raise(error->S.Error.toString)
}
```

The exception-based version of `parseWith`.

#### **`S.parseJsonWith`**

`(Js.Json.t, S.t<'value>) => result<'value, S.Error.t>`

```rescript
json->S.parseJsonWith(userStruct)
```

The same as `parseWith` but the data is narrowed to the `Js.Json.t` type.

#### **`S.parseJsonStringWith`**

`(string, S.t<'value>) => result<'value, S.Error.t>`

```rescript
jsonString->S.parseJsonWith(userStruct)
```

The same as `parseWith` but applies `JSON.parse` before parsing.

#### **`S.parseAsyncWith`**

`('any, S.t<'value>) => promise<result<'value, S.Error.t>>`

```rescript
data->S.parseAsyncWith(userStruct)
```

If you use asynchronous refinements or transforms (more on those later), you'll need to use `parseAsyncWith`. It will parse all synchronous branches first and then continue with asynchronous refinements and transforms in parallel.

#### **`S.parseAsyncInStepsWith`** _Advanced_

`('any, S.t<'value>) => result<(. unit) => promise<result<'value, S.Error.t>>, S.Error.t>`

```rescript
data->S.parseAsyncInStepsWith(userStruct)
```

After parsing synchronous branches will return a function to run asynchronous refinements and transforms.

#### **`S.serializeWith`**

`('value, S.t<'value>) => result<unknown, S.Error.t>`

```rescript
user->S.serializeWith(userStruct)
```

Serializes value using the transformation logic that is built-in to the struct. It returns a result with a transformed data or a **rescript-struct** error.

#### **`S.serializeOrRaiseWith`**

`('value, S.t<'value>) => unknown`

```rescript
try {
  user->S.serializeOrRaiseWith(userStruct)
} catch {
| S.Raised(error) => Js.Exn.raise(error->S.Error.toString)
}
```

The exception-based version of `serializeWith`.

#### **`S.serializeToJsonWith`**

`('value, S.t<'value>) => result<Js.Json.t, S.Error.t>`

```rescript
user->S.serializeToJsonWith(userStruct)
```

Similar to the `serializeWith` but returns `Js.Json.t` instead of `unknown`. Fails with JSON incompatible struct.

#### **`S.serializeToJsonStringWith`**

`('value, ~space: int=?, S.t<'value>) => result<string, S.Error.t>`

```rescript
user->S.serializeToJsonStringWith(userStruct)
```

The same as `serializeToJsonWith` but applies `JSON.serialize` after serializing.

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
"Failed parsing at root. Reason: Expected false, received true"
```

#### **`S.Error.raise`**

`string => 'a`

A function to exit with failure during refinements and transforms.

#### **`S.Error.raiseCustom`** _Advanced_

`S.Error.t => 'a`

A function to exit with failure during refinements and transforms.

#### **`S.Error.prependLocation`** _Advanced_

`(S.Error.t, string) => S.Error.t`

A function to add location to the error path field.

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
// throw new Error("[rescript-struct] Failed parsing at root. Reason: Expected false, received true")
```

> 🧠 It's not intended to be caught. Useful to panic with a readable error message.

#### **`S.Result.mapErrorToString`**

`result<'a, S.Error.t> => result<'a, string>`

```rescript
let struct = S.literal(Bool(false))

true->S.parseWith(struct)->S.Result.mapErrorToString
```

```rescript
Error("Failed parsing at root. Reason: Expected false, received true")
```

### Integration

If you're a library maintainer, you can use **rescript-struct** to get information about described structures. The most common use case is building type-safe schemas e.g for REST APIs, databases, and forms.

Documentation for this feature is work in progress, for now, you can use `S.resi` file as a reference and [rescript-json-schema](https://github.com/DZakh/rescript-json-schema) source code.
