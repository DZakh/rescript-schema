[⬅ Back to highlights](/README.md)

# ReScript Schema for JS/TS users

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
- [Nullish](#nullish)
- [Objects](#objects)
  - [Literal shorthand](#literal-shorthand)
  - [Advanced object schema](#advanced-object-schema)
  - [`Object.strict`](#objectstrict)
  - [`Object.strip`](#objectstrip)
  - [`merge`](#merge)
- [Arrays](#arrays)
- [Tuples](#tuples)
  - [Advanced tuple schema](#advanced-tuple-schema)
- [Unions](#unions)
  - [Discriminated unions](#discriminated-unions)
- [Records](#records)
- [`schema`](#schema)
- [JSON](#json)
- [JSON string](#json-string)
- [Describe](#describe)
- [Custom schema](#custom-schema)
- [Recursive schemas](#recursive-schemas)
- [Refinements](#refinements)
- [Transforms](#transforms)
- [Functions on schema](#functions-on-schema)
  - [`parse`](#parse)
  - [`parseOrThrow`](#parseorthrow)
  - [`parseAsync`](#parseasync)
  - [`serialize`](#serialize)
  - [`serializeOrThrow`](#serializeorthrow)
  - [`serializeToJsonOrThrow`](#serializetojsonorthrow)
  - [`assert`](#assert)
  - [`name`](#name)
  - [`setName`](#setname)
- [Error handling](#error-handling)
- [Comparison](#comparison)
- [Global config](#global-config)
  - [`defaultUnknownKeys`](#defaultunknownkeys)
  - [`disableNanNumberCheck`](#disablenannumbercheck)

## Install

```sh
npm install rescript-schema rescript@11
```

> 🧠 Even though `rescript` is a peer dependency, you don't need to use the compiler. It's only needed for a few lightweight runtime helpers.

## Basic usage

```ts
import * as S from "rescript-schema";

// Create login schema with email and password
const loginSchema = S.object({
  email: S.email(S.string),
  password: S.stringMinLength(S.string, 8),
});

// Infer output TypeScript type of login schema
type LoginData = S.Output<typeof loginSchema>; // { email: string; password: string }

// Throws the S.Error(`Failed parsing at ["email"]. Reason: Invalid email address`)
loginSchema.parseOrThrow({ email: "", password: "" });

// Returns data as { email: string; password: string }
loginSchema.parseOrThrow({
  email: "jane@example.com",
  password: "12345678",
});
```

## Primitives

```ts
import * as S from "rescript-schema";

// primitive values
S.string;
S.number;
S.integer; // ReScript's S.int
S.boolean;

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

Compared to other libraries, `S.literal` in **rescript-schema** supports literally any value. They are validated using strict equal checks. With the exception of plain objects and arrays, they are validated using deep equal checks. So the schema like this will work correctly:

```ts
const cliArgsSchema = S.literal(["help", "lint"] as const);
```

## Strings

**rescript-schema** includes a handful of string-specific refinements and transforms:

```ts
S.stringMaxLength(S.string, 5); // String must be 5 or fewer characters long
S.stringMinLength(S.string, 5); // String must be 5 or more characters long
S.stringLength(S.string, 5); // String must be exactly 5 characters long
S.email(S.string); // Invalid email address
S.url(S.string); // Invalid url
S.uuid(S.string); // Invalid UUID
S.cuid(S.string); // Invalid CUID
S.pattern(S.string, %re(`/[0-9]/`)); // Invalid
S.datetime(S.string); // Invalid datetime string! Must be UTC

S.trim(S.string); // trim whitespaces
```

> ⚠️ Validating email addresses is nearly impossible with just code. Different clients and servers accept different things and many diverge from the various specs defining "valid" emails. The ONLY real way to validate an email address is to send a verification email to it and check that the user got it. With that in mind, rescript-schema picks a relatively simple regex that does not cover all cases.

When using built-in refinements, you can provide a custom error message.

```ts
S.stringMinLength(S.string, 1, "String can't be empty");
S.stringLength(S.string, 5, "SMS code should be 5 digits long");
```

### ISO datetimes

The `S.datetime(S.string)` function has following UTC validation: no timezone offsets with arbitrary sub-second decimal precision.

```ts
const datetimeSchema = S.datetime(S.string);
// The datetimeSchema has the type S.Schema<Date, string>
// String is transformed to the Date instance

datetimeSchema.parseOrThrow("2020-01-01T00:00:00Z"); // pass
datetimeSchema.parseOrThrow("2020-01-01T00:00:00.123Z"); // pass
datetimeSchema.parseOrThrow("2020-01-01T00:00:00.123456Z"); // pass (arbitrary precision)
datetimeSchema.parseOrThrow("2020-01-01T00:00:00+02:00"); // fail (no offsets allowed)
```

## Numbers

**rescript-schema** includes some of number-specific refinements:

```ts
S.numberMax(S.number, 5); // Number must be lower than or equal to 5
S.numberMin(S.number 5); // Number must be greater than or equal to 5
```

Optionally, you can pass in a second argument to provide a custom error message.

```ts
S.numberMax(S.number, 5, "this👏is👏too👏big");
```

## NaNs

There's no specific schema for NaN, but you can use `S.literal` for this.

```ts
const nanSchema = S.literal(NaN);
```

It's going to use `Number.isNaN` check under the hood.

## Optionals

You can make any schema optional with `S.optional`.

```ts
const schema = S.optional(S.string);

schema.parseOrThrow(undefined); // => returns undefined
type A = S.Output<typeof schema>; // string | undefined
```

You can pass a default value to the second argument of `S.optional`.

```ts
const stringWithDefaultSchema = S.optional(S.string, "tuna");

stringWithDefaultSchema.parseOrThrow(undefined); // => returns "tuna"
type A = S.Output<typeof stringWithDefaultSchema>; // string
```

Optionally, you can pass a function as a default value that will be re-executed whenever a default value needs to be generated:

```ts
const numberWithRandomDefault = S.optional(S.number, Math.random);

numberWithRandomDefault.parseOrThrow(undefined); // => 0.4413456736055323
numberWithRandomDefault.parseOrThrow(undefined); // => 0.1871840107401901
numberWithRandomDefault.parseOrThrow(undefined); // => 0.7223408162401552
```

Conceptually, this is how **rescript-schema** processes default values:

1. If the input is `undefined`, the default value is returned
2. Otherwise, the data is parsed using the base schema

## Nullables

Similarly, you can create nullable types with `S.nullable`.

```ts
const nullableStringSchema = S.nullable(S.string);
nullableStringSchema.parseOrThrow("asdf"); // => "asdf"
nullableStringSchema.parseOrThrow(null); // => undefined
```

## Nullish

A convenience method that returns a "nullish" version of a schema. Nullish schemas will accept both `undefined` and `null`. Read more about the concept of "nullish" [in the TypeScript 3.7 release notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-7.html#nullish-coalescing).

```ts
const nullishStringSchema = S.nullish(S.string);
nullishStringSchema.parseOrThrow("asdf"); // => "asdf"
nullishStringSchema.parseOrThrow(null); // => undefined
nullishStringSchema.parseOrThrow(undefined); // => undefined
```

## Objects

```ts
// all properties are required by default
const dogSchema = S.object({
  name: S.string,
  age: S.number,
});

// extract the inferred type like this
type Dog = S.Output<typeof dogSchema>;

// equivalent to:
type Dog = {
  name: string;
  age: number;
};
```

### Literal shorthand

Besides passing schemas for values in `S.object`, you can also pass **any** Js value.

```ts
const meSchema = S.object({
  id: S.number,
  name: "Dmitry Zakharov",
  age: 23,
  kind: "human" as const,
  metadata: {
    description: "What?? Even an object with NaN works! Yes 🔥",
    money: NaN,
  },
});
```

This is a shorthand for `S.literal` and useful for discriminated unions.

### Advanced object schema

Sometimes you want to transform the data coming to your system. You can easily do it by passing a function to the `S.object` schema.

```ts
const userSchema = S.object((s) => ({
  id: s.field("USER_ID", S.number),
  name: s.field("USER_NAME", S.string),
}));

userSchema.parseOrThrow({
  USER_ID: 1,
  USER_NAME: "John",
});
// => returns { id: 1, name: "John" }

// Infer output TypeScript type of the userSchema
type User = S.Output<typeof userSchema>; // { id: number; name: string }
```

Compared to using `S.transform`, the approach has 0 performance overhead. Also, you can use the same schema to transform the parsed data back to the initial format:

```ts
userSchema.serializeOrThrow({
  id: 1,
  name: "John",
});
// => returns { USER_ID: 1, USER_NAME: "John" }
```

### `Object.strict`

By default **rescript-schema** object schema strip out unrecognized keys during parsing. You can disallow unknown keys with `S.Object.strict` function. If there are any unknown keys in the input, **rescript-schema** will fail with an error.

```ts
const personSchema = S.Object.strict(
  S.object({
    name: S.string,
  })
);

personSchema.parseOrThrow({
  name: "bob dylan",
  extraKey: 61,
});
// => throws S.Error
```

### `Object.strip`

You can use the `S.Object.strip` function to reset an object schema to the default behavior (stripping unrecognized keys).

### `merge`

You can add additional fields to an object schema with the `merge` function.

```ts
const baseTeacherSchema = S.object({ students: S.array(S.string) });
const hasIDSchema = S.object({ id: S.string });

const teacherSchema = S.merge(baseTeacherSchema, hasIDSchema);
type Teacher = S.Output<typeof teacherSchema>; // => { students: string[], id: string }
```

> 🧠 The function will throw if the schemas share keys. The returned schema also inherits the "unknownKeys" policy (strip/strict) of B.

## Arrays

```ts
const stringArraySchema = S.array(S.string);
```

**rescript-schema** includes some of array-specific refinements:

```ts
S.arrayMaxLength(S.array(S.string), 5); // Array must be 5 or fewer items long
S.arrayMinLength(S.array(S.string) 5); // Array must be 5 or more items long
S.arrayLength(S.array(S.string) 5); // Array must be exactly 5 items long
```

## Tuples

Unlike arrays, tuples have a fixed number of elements and each element can have a different type.

```ts
const athleteSchema = S.tuple([
  S.string, // name
  S.number, // jersey number
  S.object({
    pointsScored: S.number,
  }), // statistics
]);

type Athlete = S.Output<typeof athleteSchema>;
// type Athlete = [string, number, { pointsScored: number }]
```

### Advanced tuple schema

Sometimes you want to transform incoming tuples to a more convenient data-structure. To do this you can pass a function to the `S.tuple` schema.

```ts
const athleteSchema = S.tuple((s) => ({
  name: s.item(0, S.string),
  jerseyNumber: s.item(1, S.number),
  statistics: s.item(
    2,
    S.object({
      pointsScored: S.number,
    })
  ),
}));

type Athlete = S.Output<typeof athleteSchema>;
// type Athlete = {
//   name: string;
//   jerseyNumber: number;
//   statistics: {
//     pointsScored: number;
//   };
// }
```

That looks much better than before. And the same as for advanced objects, you can use the same schema for transforming the parsed data back to the initial format. Also, it has 0 performance overhead and is as fast as parsing tuples without the transformation.

## Unions

An union represents a logical OR relationship. You can apply this concept to your schemas with `S.union`. The same api works for discriminated unions as well.

The schema function `union` creates an OR relationship between any number of schemas that you pass as the first argument in the form of an array. On validation, the schema returns the result of the first schema that was successfully validated.

> 🧠 Schemas are not guaranteed to be validated in the order they are passed to `S.union`. They are grouped by the input data type to optimise performance and improve error message. Schemas with unknown data typed validated the last.

```ts
// TypeScript type for reference:
// type Union = string | number;

const stringOrNumberSchema = S.union([S.string, S.number]);

stringOrNumberSchema.parseOrThrow("foo"); // passes
stringOrNumberSchema.parseOrThrow(14); // passes
```

### Discriminated unions

```typescript
// TypeScript type for reference:
// type Shape =
// | { kind: "circle"; radius: number }
// | { kind: "square"; x: number }
// | { kind: "triangle"; x: number; y: number };

const shapeSchema = S.union([
  S.object({
    kind: "circle" as const,
    radius: S.number,
  }),
  S.object({
    kind: "square" as const,
    x: S.number,
  }),
  S.object({
    kind: "triangle" as const,
    x: S.number,
    y: S.number,
  }),
]);
```

## Records

Record schema is used to validate types such as `{ [k: string]: number }`.

If you want to validate the values of an object against some schema but don't care about the keys, use `S.record(valueSchema)`:

```ts
const numberCacheSchema = S.record(S.number);

type NumberCache = S.Output<typeof numberCacheSchema>;
// => { [k: string]: number }
```

### `schema`

It's a helper built on `S.literal`, `S.object`, and `S.tuple` to create schemas more conveniently.

```typescript
type Shape = { kind: "circle"; radius: number } | { kind: "square"; x: number };

let circleSchema = S.schema(
  (s): Shape => ({
    kind: "circle",
    radius: s.matches(S.number),
  })
);
// The same as:
// S.object(s => ({
//   kind: s.field("kind", S.literal("circle")),
//   radius: s.field("radius", S.number),
// }))
```

## JSON

The `S.json` schema makes sure that the value is compatible with JSON.

It accepts a boolean as an argument. If it's true, then the value will be validated as valid JSON; otherwise, it unsafely casts it to the `S.Json` type.

```ts
S.json(true).parseOrThrow(`"foo"`); // passes
```

## JSON string

```ts
const schema = S.jsonString(S.int);

schema.parseOrThrow("123");
// => 123
```

The `S.jsonString` schema represents JSON string containing value of a specific type.

## Describe

Use `S.describe` to add a `description` property to the resulting schema.

```ts
const documentedStringSchema = S.describe(
  S.string,
  "A useful bit of text, if you know what to do with it."
);

S.description(documentedStringSchema); // A useful bit of text…
```

This can be useful for documenting a field, for example in a JSON Schema using a library like [`rescript-json-schema`](https://github.com/DZakh/rescript-json-schema).

## Custom schema

You can create a schema for any TypeScript type by using `S.custom`. This is useful for creating schema for types that are not supported by **rescript-schema** out of the box.

```ts
const mySetSchema = S.custom("MySet", (input, s) => {
  if (input instanceof Set) {
    return input;
  }
  throw s.fail("Provided data is not an instance of Set.");
});

type MySet = S.Output<typeof mySetSchema>; // Set<any>
```

## Recursive schemas

You can define a recursive schema in **rescript-schema**. Unfortunately, TypeScript derives the Schema type as `unknown` so you need to explicitly specify the type and it'll start correctly typechecking.

```ts
type Node = {
  id: string;
  children: Node[];
};

let nodeSchema = S.recursive<Node>((nodeSchema) =>
  S.object({
    id: S.string,
    children: S.array(nodeSchema),
  })
);
```

> 🧠 Despite supporting recursive schema, passing cyclical data into rescript-schema will cause an infinite loop.

## Refinements

**rescript-schema** lets you provide custom validation logic via refinements. It's useful to add checks that's not possible to cover with type system. For instance: checking that a number is an integer or that a string is a valid email address.

```ts
const shortStringSchema = S.refine(S.string, (value, s) =>
  if (value.length > 255) {
    s.fail("String can't be more than 255 characters")
  }
)
```

The refine function is applied for both parser and serializer.

Also, you can have an asynchronous refinement (for parser only):

```ts
const userSchema = S.object({
  id: S.asyncParserRefine(S.uuid(S.string), async (id, s) => {
    const isActiveUser = await checkIsActiveUser(id);
    if (!isActiveUser) {
      s.fail(`The user ${id} is inactive.`);
    }
  }),
  name: S.string,
});

type User = S.Output<typeof userSchema>; // { id: string, name: string }

// Need to use parseAsync which will return a promise with S.Result
await userSchema.parseAsync({
  id: "1",
  name: "John",
});
```

## Transforms

**rescript-schema** allows to augment schema with transformation logic, letting you transform value during parsing and serializing. This is most commonly used for mapping value to more convenient data-structures.

```ts
const intToString = (schema) =>
  S.transform(
    schema,
    (int) => int.toString(),
    (string, s) => {
      const int = parseInt(string, 10);
      if (isNaN(int)) {
        s.fail("Can't convert string to int");
      }
      return int;
    }
  );
```

## Functions on schema

### **`parse`**

```ts
schema.parse(data); // => S.Result<Output>
```

Given any schema, you can call `parse` to check `data` is valid. It returns `S.Result` with valid data transformed to expected type or a **rescript-schema** error.

### **`parseOrThrow`**

```ts
schema.parseOrThrow(data); // => Output
// Or throws S.Error
```

The exception-based version of `parse`.

### **`parseAsync`**

```ts
await schema.parseAsync(data); // => S.Result<Output>
```

If you use asynchronous refinements or transforms, you'll need to use `parseAsync`. It will parse all synchronous branches first and then continue with asynchronous refinements and transforms in parallel.

### **`serialize`**

```ts
userSchema.serialize(user); // => S.Result<Input>
```

Serializes value using the transformation logic that is built-in to the schema. It returns a result with a transformed data or a **rescript-schema** error.

### **`serializeOrThrow`**

```ts
userSchema.serializeOrThrow(user); // => Input
// Or throws S.Error
```

The exception-based version of `serialize`.

### **`serializeToJsonOrThrow`**

```ts
userSchema.serializeToJsonOrThrow(user); // => Json
// Or throws S.Error
```

The exception-based version of `serialize`, which guarantees to return a valid JSON.

### **`assert`**

```ts
userSchema.assert(data); // => asserts data is User
// Or throws S.Error
```

Given any schema, you can call `assert` to check `data` is valid. It returns `unit` and throws an exception if the data is invalid. Since the operation doesn't return a value, it's 2-3 times faster than `parseOrThrow` depending on the schema.

### **`name`**

```ts
S.name(S.literal({ abc: 123 }));
// `{"abc":123}`
```

Used internally for readable error messages.

> 🧠 Subject to change

### **`setName`**

```ts
const schema = S.setName(S.literal({ abc: 123 }, "Abc"));

S.name(schema);
// `Abc`
```

You can customise a schema name using `S.setName`.

## Error handling

**rescript-schema** provides a subclass of Error called `S.Error`. It contains detailed information about the validation problem.

```ts
S.literal(false).parseOrThrow(true);
// => Throws S.Error with the following message: "Failed parsing at root. Reason: Expected false, received true".
```

## Global config

**rescript-schema** has a global config that can be changed to customize the behavior of the library.

### `defaultUnknownKeys`

`defaultUnknownKeys` is an option that controls how unknown keys are handled when parsing objects. The default value is `Strip`, but you can globally change it to `Strict` to enforce strict object parsing.

```rescript
S.setGlobalConfig({
  defaultUnknownKeys: Strict,
})
```

### `disableNanNumberCheck`

`disableNanNumberCheck` is an option that controls whether the library should check for NaN values when parsing numbers. The default value is `false`, but you can globally change it to `true` to allow NaN values. If you parse many numbers which are guaranteed to be non-NaN, you can set it to `true` to improve performance ~10%, depending on the case.

```rescript
S.setGlobalConfig({
  disableNanNumberCheck: true,
})
```
