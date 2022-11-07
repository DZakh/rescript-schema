[![CI](https://github.com/DZakh/rescript-struct/actions/workflows/ci.yml/badge.svg)](https://github.com/DZakh/rescript-struct/actions/workflows/ci.yml) [![codecov](https://codecov.io/gh/DZakh/rescript-struct/branch/main/graph/badge.svg?token=40G6YKKD6J)](https://codecov.io/gh/DZakh/rescript-struct)

# ReScript Struct

Safely parse and serialize with transformation to convenient ReScript data structures.

Highlights:

- Parses any data, not only JSON
- Asynchronous refinements and transforms
- Support for both result and exception based API
- Ability to disallow excessive object fields
- Built-in `union`, `literal` and many other structs
- Fast: The **3rd** fastest parsing library in the whole JavaScript ecosystem ([benchmark](https://dzakh.github.io/rescript-runtime-type-benchmarks/))
- Tiny: [7kb minified + zipped](https://bundle.js.org/?q=github%3ADZakh%2Frescript-struct%2Fmain%2Fsrc%2FS.bs.js&treeshake=%5B*+as+S%5D&config=%7B%22esbuild%22%3A%7B%22external%22%3A%5B%22rescript%22%5D%7D%7D)

Also, it has declarative API allowing you to use **rescript-struct** as a building block for other tools, such as:

- [rescript-envsafe](https://github.com/DZakh/rescript-envsafe) - Makes sure you don't accidentally deploy apps with missing or invalid environment variables
- [rescript-json-schema](https://github.com/DZakh/rescript-json-schema) - Typesafe JSON schema for ReScript
- Internal form library at [Carla](https://www.carla.se/)

## How to use

Works the same in the browser and in node. See the [examples](#examples) section for more examples.

### Install

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

### Basic usage

```rescript
type author = {
  id: float,
  tags: array<string>,
  isAproved: bool,
  deprecatedAge: option<int>,
}

let authorStruct =
  S.object4(.
    ("Id", S.float()),
    ("Tags", S.option(S.array(S.string()))->S.defaulted([])),
    (
      "IsApproved",
      S.union([
        S.literalVariant(String("Yes"), true),
        S.literalVariant(String("No"), false),
      ]),
    ),
    ("Age", S.int()->S.deprecated(~message="Will be removed in APIv2", ())),
  )->S.transform(~parser=((id, tags, isAproved, deprecatedAge)) => {
    id,
    tags,
    isAproved,
    deprecatedAge,
  }, ())

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

### Examples

- [API layer with **rescript-struct**](https://github.com/Nicolas1st/net-cli-rock-paper-scissors/blob/main/apps/client/src/Api.res)
- [Env variables with **rescript-struct**](https://github.com/Nicolas1st/net-cli-rock-paper-scissors/blob/main/apps/client/src/Env.res)

## API Reference

### Core

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

#### **`S.parseAsyncWith`**

`('any, S.t<'value>) => Js.Promise.t<result<'value, S.Error.t>>`

```rescript
data->S.parseAsyncWith(userStruct)
```

If you use asynchronous refinements or transforms (more on those later), you'll need to use `parseAsyncWith`. It will parse all synchronous branches first and then continue with asynchronous refinements and transforms in parallel.

#### **`S.parseAsyncInStepsWith`** _Advanced_

`('any, S.t<'value>) => result<unit => Js.Promise.t<result<'value, S.Error.t>>, S.Error.t>`

```rescript
data->S.parseAsyncInStepsWith(userStruct)
```

After parsing synchronous branches will return a function to run asynchronous refinements and transforms.

#### **`S.serializeWith`**

`('value, S.t<'value>) => result<S.unknown, S.Error.t>`

```rescript
user->S.serializeWith(userStruct)
```

Serializes value using the transformation logic that is built-in to the struct. It returns a result with a transformed data or a **rescript-struct** error.

#### **`S.serializeOrRaiseWith`**

`('value, S.t<'value>) => S.unknown`

```rescript
try {
  user->S.serializeOrRaiseWith(userStruct)
} catch {
| S.Raised(error) => Js.Exn.raise(error->S.Error.toString)
}
```

The exception-based version of `serializeWith`.

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

#### **`S.object0` - `S.object10`**

`(. S.field<'v1>, S.field<'v2>, S.field<'v3>) => S.t<('v1, 'v2, 'v3)>`

```rescript
type author = {id: string}
let struct = S.object1(. ("ID", S.string()))->S.transform(~parser=id => {id: id}, ())

{"ID": "abc"}->S.parseWith(struct)
```

```rescript
Ok({
  id: "abc",
})
```

`object` struct represents an object and that each of its properties represent a specific type as well.

The object struct factories are available up to 10 fields. If you have an object with more fields, you can create a object struct factory for any number of fields using `S.Object.factory`.

#### **`S.Object.factory`**

```rescript
let object3: (
  . S.field<'v1>,
  S.field<'v2>,
  S.field<'v3>,
) => S.t<('v1, 'v2, 'v3)> = S.Object.factory
```

> 🧠 The `S.Object.factory` internal code isn't typesafe, so you should properly annotate the struct factory interface.

#### **`S.Object.strict`**

`S.t<'value> => S.t<'value>`

```rescript
let struct = S.object1(. ("key", S.string()))->S.Object.strict

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

By default **rescript-struct** silently strips unrecognized keys when parsing objects. You can change the behaviour to disallow unrecognized keys with the `S.Object.strict` function.

#### **`S.Object.strip`**

`S.t<'value> => S.t<'value>`

```rescript
let struct = S.object1(. ("key", S.string()))->S.Object.strip

{
  "key": "value",
  "unknownKey": "value2",
}->S.parseWith(struct)
```

```rescript
Ok("value")
```

You can use the `S.Object.strip` function to reset a object struct to the default behavior (stripping unrecognized keys).

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

#### **`S.union`**

`array<S.t<'value>> => S.t<'value>`

```rescript
type shape = Circle({radius: float}) | Square({x: float}) | Triangle({x: float, y: float})

let shapeStruct = {
  let circleStruct = S.object2(.
    ("kind", S.literal(String("circle"))),
    ("radius", S.float()),
  )->S.transform(~parser=((_, radius)) => Circle({radius: radius}), ())
  let squareStruct = S.object2(.
    ("kind", S.literal(String("square"))),
    ("x", S.float()),
  )->S.transform(~parser=((_, x)) => Square({x: x}), ())
  let triangleStruct = S.object3(.
    ("kind", S.literal(String("triangle"))),
    ("x", S.float()),
    ("y", S.float()),
  )->S.transform(~parser=((_, x, y)) => Triangle({x, y}), ())
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

#### **`S.custom`**

`(~name: string, ~parser: (. ~unknown: S.unknown) => 'value=?, ~serializer: (. ~value: 'value) => 'any=?, unit) => S.t<'value>`

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

`defaulted` augments a struct to add transformation logic for default values, which are applied when the input is undefined.

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

`(S.t<'value>, ~parser: 'value => Js.Promise.t<unit>, unit) => S.t<'value>`

```rescript
let userIdStruct = S.string()->S.asyncRefine(~parser=string =>
  verfiyUserExistsInDb(~userId=string)->Promise.thenResolve(isExistingUser =>
    if not(isExistingUser) {
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

`type transformation<'input, 'output> = Sync('input => 'output) | Async('input => Js.Promise.t<'output>)`

`(S.t<'value>, ~parser: (~struct: S.t<'value>) => S.transformation<'value, 'transformed>=?, ~serializer: (~struct: S.t<'value>) => S.transformation<'transformed, 'value>=?, unit) => S.t<'transformed>`

The `transform`, `refine`, `asyncRefine`, and `custom` functions are actually syntactic sugar atop a more versatile (and verbose) function called `advancedTransform`.

```rescript
let json = innerStruct => {
  S.string()
  ->S.transform(~parser=jsonString => {
    try jsonString->Js.Json.parseExn catch {
    | Js.Exn.Error(obj) =>
      S.Error.raise(obj->Js.Exn.message->Belt.Option.getWithDefault("Failed to parse JSON"))
    }
  }, ~serializer=Js.Json.stringify, ())
  ->S.advancedTransform(
    ~parser=(~struct as _) => {
      switch innerStruct->S.isAsyncParse {
      | true =>
        Async(
          parsedJson => {
            switch parsedJson->S.parseAsyncWith(innerStruct) {
            | Ok(promise) =>
              promise->Promise.thenResolve(result => {
                switch result {
                | Ok(value) => value
                | Error(error) => S.Error.raiseCustom(error)
                }
              })
            | Error(error) => S.Error.raiseCustom(error)
            }
          },
        )
      | false =>
        Sync(
          parsedJson => {
            switch parsedJson->S.parseWith(innerStruct) {
            | Ok(value) => value
            | Error(error) => S.Error.raiseCustom(error)
            }
          },
        )
      }
    },
    ~serializer=(~struct as _) => {
      Sync(
        value => {
          switch value->S.serializeWith(innerStruct) {
          | Ok(unknown) => unknown->Obj.magic
          | Error(error) => S.Error.raiseCustom(error)
          }
        },
      )
    },
    (),
  )
}
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

## Roadmap

- [x] Add tag system for flexible integration system
- [ ] Add custom configuration
- [x] Add name property to the custom struct factory for better error messages
- [ ] Add discriminant optimization for object unions
- [ ] Add async serializing support
- [ ] Documentation improvements
- [ ] Test coverage improvements
- [ ] Add JS/TS API
