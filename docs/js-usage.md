[⬅ Back to highlights](../README.md)

# ReScript Struct for JS/TS users

## Table of contents

- [Table of contents](#table-of-contents)
- [Install](#install)
- [Basic usage](#basic-usage)
- [Primitives](#primitives)
- [Literals](#literals)
- [Strings](#strings)
  - [ISO datetimes](#iso-datetimes)
- [Numbers](#numbers)
- [NaNs](#nans)
- [Optionals](#optionals)
- [Nullables](#nullables)
- [Objects](#objects)
  - [Advanced object struct](#advanced-object-struct)
  - [`Object.strict`](#objectstrict)
  - [`Object.strip`](#objectstrip)
  - [`merge`](#merge)
- [Arrays](#arrays)
- [Tuples](#tuples)
  - [Advanced tuple struct](#advanced-tuple-struct)
- [Unions](#unions)
- [Records](#records)
- [JSON](#json)
- [JSON string](#json-string)
- [Describe](#describe)
- [Custom structs](#custom-structs)
- [Refinements](#refinements)
- [Transforms](#transforms)
- [Functions on struct](#functions-on-struct)
  - [`parse`](#parse)
  - [`parseOrThrow`](#parseorthrow)
  - [`parseAsync`](#parseasync)
  - [`serialize`](#serialize)
  - [`serializeOrThrow`](#serializeorthrow)
  - [`name`](#name)
  - [`setName`](#setname)
- [Error handling](#error-handling)
- [Comparison](#comparison)

## Install

```sh
npm install rescript-struct rescript@11
```

> 🧠 Even though `rescript` is a peer dependency, you don't need to use the compiler. It's only needed for a few lightweight runtime helpers.

## Basic usage

```ts
import * as S from "rescript-struct";

// Create login struct with email and password
const loginStruct = S.object({
  email: S.String.email(S.string),
  password: S.String.min(S.string, 8),
});

// Infer output TypeScript type of login struct
type LoginData = S.Output<typeof loginStruct>; // { email: string; password: string }

// Throws the S.Error(`Failed parsing at ["email"]. Reason: Invalid email address`)
S.parseOrThrow(loginStruct, { email: "", password: "" });

// Returns data as { email: string; password: string }
S.parseOrThrow(loginStruct, {
  email: "jane@example.com",
  password: "12345678",
});
```

## Primitives

```ts
import * as S from "rescript-struct";

// primitive values
S.string;
S.number;
S.integer; // ReScript's S.int
S.boolean;
S.json;

// empty type
S.undefined;

// catch-all types
// allows any value
S.unknown;

// never type
// allows no values
S.never;
```

## Literals

Literal schemas represent a [literal type](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#literal-types), like `"hello world"` or `5`.

```ts
const tuna = S.literal("tuna");
const twelve = S.literal(12);
const twobig = S.literal(2n); // bigint literal
const tru = S.literal(true);

const terrificSymbol = Symbol("terrific");
const terrific = S.literal(terrificSymbol);
```

Compared to other libraries, `S.literal` in **rescript-struct** supports literally any value. They are validated using strict equal checks. With the exception of plain objects and arrays, they are validated using deep equal checks. So the struct like this will work correctly:

```ts
const cliArgsStruct = S.literal(["help", "lint"] as const);
```

## Strings

**rescript-struct** includes a handful of string-specific refinements and transforms:

```ts
S.String.max(S.string, 5); // String must be 5 or fewer characters long
S.String.min(S.string, 5); // String must be 5 or more characters long
S.String.length(S.string, 5); // String must be exactly 5 characters long
S.String.email(S.string); // Invalid email address
S.String.url(S.string); // Invalid url
S.String.uuid(S.string); // Invalid UUID
S.String.cuid(S.string); // Invalid CUID
S.String.pattern(S.string, %re(`/[0-9]/`)); // Invalid
S.String.datetime(S.string); // Invalid datetime string! Must be UTC

S.String.trim(S.string); // trim whitespaces
```

When using built-in refinements, you can provide a custom error message.

```ts
S.String.min(S.string, 1, "String can't be empty");
S.String.length(S.string, 5, "SMS code should be 5 digits long");
```

### ISO datetimes

The `S.String.datetime(S.string)` function has following UTC validation: no timezone offsets with arbitrary sub-second decimal precision.

```ts
const datetimeStruct = S.String.datetime(S.string);
// The datetimeStruct has the type S.Struct<Date, string>
// String is transformed to the Date instance

S.parseOrThrow(datetimeStruct, "2020-01-01T00:00:00Z"); // pass
S.parseOrThrow(datetimeStruct, "2020-01-01T00:00:00.123Z"); // pass
S.parseOrThrow(datetimeStruct, "2020-01-01T00:00:00.123456Z"); // pass (arbitrary precision)
S.parseOrThrow(datetimeStruct, "2020-01-01T00:00:00+02:00"); // fail (no offsets allowed)
```

## Numbers

**rescript-struct** includes some of number-specific refinements:

```ts
S.Number.max(S.number, 5); // Number must be lower than or equal to 5
S.Number.min(S.number 5); // Number must be greater than or equal to 5
```

Optionally, you can pass in a second argument to provide a custom error message.

```ts
S.Number.max(S.number, 5, "this👏is👏too👏big");
```

## NaNs

There's no specific struct for NaN, but you can use `S.literal` for this.

```ts
const nanStruct = S.literal(NaN);
```

It's going to use `Number.isNaN` check under the hood.

## Optionals

You can make any struct optional with `S.optional`.

```ts
const struct = S.optional(S.string);

S.parseOrThrow(struct, undefined); // => returns undefined
type A = S.Output<typeof struct>; // string | undefined
```

You can pass a default value to the second argument of `S.optional`.

```ts
const stringWithDefaultStruct = S.optional(S.string, "tuna");

S.parseOrThrow(stringWithDefaultStruct, undefined); // => returns "tuna"
type A = S.Output<typeof stringWithDefaultStruct>; // string
```

Optionally, you can pass a function as a default value that will be re-executed whenever a default value needs to be generated:

```ts
const numberWithRandomDefault = S.optional(S.number, Math.random);

S.parseOrThrow(numberWithRandomDefault, undefined); // => 0.4413456736055323
S.parseOrThrow(numberWithRandomDefault, undefined); // => 0.1871840107401901
S.parseOrThrow(numberWithRandomDefault, undefined); // => 0.7223408162401552
```

Conceptually, this is how **rescript-struct** processes default values:

1. If the input is `undefined`, the default value is returned
2. Otherwise, the data is parsed using the base schema

## Nullables

Similarly, you can create nullable types with `S.nullable`.

```ts
const nullableStringStruct = S.nullable(S.string);
S.parseOrThrow(nullableStringStruct, "asdf"); // => "asdf"
S.parseOrThrow(nullableStringStruct, null); // => null
```

## Objects

```ts
// all properties are required by default
const dogStruct = S.object({
  name: S.string,
  age: S.number,
});

// extract the inferred type like this
type Dog = S.Output<typeof dogStruct>;

// equivalent to:
type Dog = {
  name: string;
  age: number;
};
```

### Advanced object struct

Sometimes you want to transform the data coming to your system. You can easily do it by passing a function to the `S.object` struct.

```ts
const userStruct = S.object((s) => ({
  id: s.field("USER_ID", S.number),
  name: s.field("USER_NAME", S.string),
}));

S.parseOrThrow(userStruct, {
  USER_ID: 1,
  USER_NAME: "John",
});
// => returns { id: 1, name: "John" }

// Infer output TypeScript type of the userStruct
type User = S.Output<typeof userStruct>; // { id: number; name: string }
```

Compared to using `S.transform`, the approach has 0 performance overhead. Also, you can use the same struct to transform the parsed data back to the initial format:

```ts
S.serializeOrThrow(userStruct, {
  id: 1,
  name: "John",
});
// => returns { USER_ID: 1, USER_NAME: "John" }
```

### `Object.strict`

By default **rescript-struct** object struct strip out unrecognized keys during parsing. You can disallow unknown keys with `S.Object.strict` function. If there are any unknown keys in the input, **rescript-struct** will fail with an error.

```ts
const personStruct = S.Object.strict(
  S.object({
    name: S.string,
  })
);

S.parseOrThrow(personStruct, {
  name: "bob dylan",
  extraKey: 61,
});
// => throws S.Error
```

### `Object.strip`

You can use the `S.Object.strip` function to reset an object struct to the default behavior (stripping unrecognized keys).

### `merge`

You can add additional fields to an object schema with the `merge` function.

```ts
const baseTeacherStruct = S.object({ students: S.array(S.string) });
const hasIDStruct = S.object({ id: S.string });

const teacherStruct = S.merge(baseTeacherStruct, hasIDStruct);
type Teacher = S.Output<typeof teacherStruct>; // => { students: string[], id: string }
```

> 🧠 The function will throw if the structs share keys. The returned schema also inherits the "unknownKeys" policy (strip/strict) of B.

## Arrays

```ts
const stringArrayStruct = S.array(S.string);
```

**rescript-struct** includes some of array-specific refinements:

```ts
S.Array.max(S.array(S.string), 5); // Array must be 5 or fewer items long
S.Array.min(S.array(S.string) 5); // Array must be 5 or more items long
S.Array.length(S.array(S.string) 5); // Array must be exactly 5 items long
```

## Tuples

Unlike arrays, tuples have a fixed number of elements and each element can have a different type.

```ts
const athleteStruct = S.tuple([
  S.string, // name
  S.number, // jersey number
  S.object({
    pointsScored: S.number,
  }), // statistics
]);

type Athlete = S.Output<typeof athleteStruct>;
// type Athlete = [string, number, { pointsScored: number }]
```

### Advanced tuple struct

Sometimes you want to transform incoming tuples to a more convenient data-structure. To do this you can pass a function to the `S.tuple` struct.

```ts
const athleteStruct = S.tuple((s) => ({
  name: s.item(0, S.string),
  jerseyNumber: s.item(1, S.number),
  statistics: s.item(
    2,
    S.object({
      pointsScored: S.number,
    })
  ),
}));

type Athlete = S.Output<typeof athleteStruct>;
// type Athlete = {
//   name: string;
//   jerseyNumber: number;
//   statistics: {
//     pointsScored: number;
//   };
// }
```

That looks much better than before. And the same as for advanced objects, you can use the same struct for transforming the parsed data back to the initial format. Also, it has 0 performance overhead and is as fast as parsing tuples without the transformation.

## Unions

**rescript-struct** includes a built-in S.union struct for composing "OR" types.

```ts
const stringOrNumberStruct = S.union([S.string, S.number]);

S.parseOrThrow(stringOrNumberStruct, "foo"); // passes
S.parseOrThrow(stringOrNumberStruct, 14); // passes
```

It will test the input against each of the "options" in order and return the first value that parses successfully.

## Records

Record structs are used to validate types such as `{ [k: string]: number }`.

If you want to validate the values of an object against some struct but don't care about the keys, use `S.record(valueStruct)`:

```ts
const numberCacheStruct = S.record(S.number);

type NumberCache = S.Output<typeof numberCacheStruct>;
// => { [k: string]: number }
```

## JSON

The `S.json` struct makes sure that the value is compatible with JSON.

```ts
S.parseOrThrow(S.json, "foo"); // passes
```

## JSON string

```ts
const struct = S.jsonString(S.int);

S.parseOrThrow("123", struct);
// => 123
```

The `S.jsonString` struct represents JSON string containing value of a specific type.

## Describe

Use `S.describe` to add a `description` property to the resulting struct.

```ts
const documentedStringStruct = S.describe(
  S.string,
  "A useful bit of text, if you know what to do with it."
);

S.description(documentedStringStruct); // A useful bit of text…
```

This can be useful for documenting a field, for example in a JSON Schema using a library like [`rescript-json-schema`](https://github.com/DZakh/rescript-json-schema).

## Custom structs

You can create a struct for any TypeScript type by using `S.custom`. This is useful for creating structs for types that are not supported by **rescript-struct** out of the box.

```ts
const mySetStruct = S.custom("MySet", (input, s) => {
  if (input instanceof Set) {
    return input;
  }
  throw s.fail("Provided data is not an instance of Set.");
});

type MySet = S.Output<typeof mySetStruct>; // Set<any>
```

## Refinements

**rescript-struct** lets you provide custom validation logic via refinements. It's useful to add checks that's not possible to cover with type system. For instance: checking that a number is an integer or that a string is a valid email address.

```ts
const shortStringStruct = S.refine(S.string, (value, s) =>
  if (value.length > 255) {
    throw s.fail("String can't be more than 255 characters")
  }
)
```

The refine function is applied for both parser and serializer.

Also, you can have an asynchronous refinement (for parser only):

```ts
const userStruct = S.object({
  id: S.asyncParserRefine(S.String.uuid(S.string), async (id, s) => {
    const isActiveUser = await checkIsActiveUser(id);
    if (!isActiveUser) {
      s.fail(`The user ${id} is inactive.`);
    }
  }),
  name: S.string,
});

type User = S.Output<typeof userStruct>; // { id: string, name: string }

// Need to use parseAsync which will return a promise with S.Result
await S.parseAsync(userStruct, {
  id: "1",
  name: "John",
});
```

## Transforms

**rescript-struct** allows structs to be augmented with transformation logic, letting you transform value during parsing and serializing. This is most commonly used for mapping value to more convenient data structures.

```ts
const intToString = (struct) =>
  S.transform(
    struct,
    (int) => int.toString(),
    (string, s) => {
      const int = parseInt(string, 10);
      if (isNaN(int)) {
        throw s.fail("Can't convert string to int");
      }
      return int;
    }
  );
```

## Functions on struct

### **`parse`**

```ts
S.parse(struct, data); // => S.Result<Output>
```

Given any struct, you can call `S.parse` to check `data` is valid. It returns `S.Result` with valid data transformed to expected type or a **rescript-struct** error.

### **`parseOrThrow`**

```ts
S.parseOrThrow(struct, data); // => Output
// Or throws S.Error
```

The exception-based version of `S.parse`.

### **`parseAsync`**

```ts
await S.parseAsync(struct, data); // => S.Result<Output>
```

If you use asynchronous refinements or transforms, you'll need to use `parseAsync`. It will parse all synchronous branches first and then continue with asynchronous refinements and transforms in parallel.

### **`serialize`**

```ts
S.serialize(userStruct, user); // => S.Result<Input>
```

Serializes value using the transformation logic that is built-in to the struct. It returns a result with a transformed data or a **rescript-struct** error.

### **`serializeOrThrow`**

```ts
S.serializeOrThrow(userStruct, user); // => Input
// Or throws S.Error
```

The exception-based version of `S.serialize`.

### **`name`**

```ts
S.name(S.literal({ abc: 123 }));
// `Literal({"abc": 123})`
```

Used internally for readable error messages.

> 🧠 Subject to change

### **`setName`**

```ts
const struct = S.setName(S.literal({ abc: 123 }, "Abc"));

S.name(struct);
// `Abc`
```

You can customise a struct name using `S.setName`.

## Error handling

**rescript-struct** provides a subclass of Error called `S.Error`. It contains detailed information about the validation problem.

```ts
S.parseOrThrow(S.literal(false), true);
// => Throws S.Error with the following message: "Failed parsing at root. Reason: Expected false, received true".
```

## Comparison

Instead of relying on a few large functions with many methods, **rescript-struct** follows [Valibot](https://github.com/fabian-hiller/valibot)'s approach, where API design and source code is based on many small and independent functions, each with just a single task. This modular design has several advantages.

For example, this allows a bundler to use the import statements to remove code that is not needed. This way, only the code that is actually used gets into your production build. This can reduce the bundle size by up to 2 times compared to [Zod](https://github.com/colinhacks/zod).

Besides the individual bundle size, the overall size of the library is also significantly smaller.

At the same time **rescript-struct** is the fastest composable validation library in the entire JavaScript ecosystem. This is achieved because of the JIT approach when an ultra optimized validator is created using `eval`.

|                                                  | rescript-struct@5.1.0 | Zod@3.22.2      | Valibot@0.18.0 |
| ------------------------------------------------ | --------------------- | --------------- | -------------- |
| **Total size** (minified + gzipped)              | 9.67 kB               | 13.4 kB         | 6.73 kB        |
| **Example size** (minified + gzipped)            | 5.53 kB               | 12.8 kB         | 965 B          |
| **Nested object parsing**                        | 153,787 ops/ms        | 1,177 ops/ms    | 3,562 ops/ms   |
| **Create struct/schema + Nested object parsing** | 54 ops/ms             | 110 ops/ms      | 1,937 ops/ms   |
| **Eval-free**                                    | ❌                    | ✅              | ✅             |
| **Codegen-free** (Doesn't need compiler)         | ✅                    | ✅              | ✅             |
| **Ecosystem**                                    | ⭐️                   | ⭐️⭐️⭐️⭐️⭐️ | ⭐️⭐️         |
