# v5.0.0

## Highlights

- 50% faster 🚀
- X times lighter 🙌
- X times more convenient 🧑‍💻

## API changes

> 🚨 Breaking changes alert. There are a lot of them, so I've prepared a semi-automated migration guide.

### Trailing unit removal

Also, the primitive structs are not functions anymore 🙌
The structs became much more ergonomic to write:

```diff
// Primitive structs
- S.string()
+ S.string

// Built-in refinements
- S.string()->S.String.email()
+ S.string->S.String.email
```

### Exciting literal rework

Creating a literal struct became much easier:

```diff
- S.literal(String("foo"))
+ S.literal("foo")
```

You can pass literally any value to `S.literal` and it'll work. Even a tagged variant. That's because now they support any Js value, not only primitives as before:

```rescript
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

#### Other literal changes

- Added `S.Literal` module, which provides useful helpers to work with literals
- `S.literal` type moved to `S.Literal.t` and now supports all Js values
- `S.literalVariant` removed in favor of `S.literal` and `S.variant`

### Object enhancements

Updated `Object` parser type check. Now it uses `input && input.constructor === Object` check instead of `input && typeof input === "object" && !Array.isArray(input)`. You can use `S.custom` to deal with class instances. Let me know if it causes problems.

The `S.field` function is removed and became a method on the object factory ctx. More reliable and less letters to type.

```diff
- let pointStruct = S.object(o => {
-   x: o->S.field("x", S.int()),
-   y: o->S.field("y", S.int()),
- })
+ let pointStruct = S.object(s => {
+   x: s.field("x", S.int),
+   y: s.field("y", S.int),
+ })
```

> 🧠 You can notice that the `o` arg is now called `s`. The same changes are in the docs as well. That's a new suggested convention to call _rescript-struct_ ctx objects with the `s` letter. It's not required to follow, but I think it's nice to follow the same style.

To make the life easier I've rethought the previously removed `S.discriminant` function, redesigned and returned it back as the `tag` method:

```diff
- let struct = S.object(o => {
-   ignore(o->S.field("key", S.literal(String("value"))))
-   Circle({
-     radius: o->S.field("radius", S.float()),
-   })
- })
+ let struct = S.object(s => {
+   s.tag("kind", "circle")
+   Circle({
+     radius: s.field("radius", S.float),
+   })
+ })
```

Also, there's another lil helper for setting default values for fields:

```diff
- let struct = S.object(o => {
-   name: o->S.field("name", S.option(S.string)->S.default(() => "Unknown")),
- })
+ let struct = S.object(s => {
+   name: s.fieldOr("name", S.string, "Unknown"),
+ })
```

And yeah, it became `50%` faster 🚀

### Tuple keeps up with trends

Say goodbuy to the `tuple0-tuple10` and untyped `Tuple.factory`. Now you can create tuples in the same nice way as object: type-safe, without limitation on size and with built-in transformation.

```diff
- let pointStruct =
-   S.tuple3(S.literalVariant(String("point"), ()), S.int(), S.int())->S.transform(
-     ~parser=((), x, y) => {x, y},
-     ~serializer=({x, y}) => ((), x, y),
-     (),
-   )
+ let pointStruct = S.tuple(s => {
+   // The same `tag` method as in S.object
+   s.tag(0, "point")
+   {
+     x: s.item(1, S.int),
+     y: s.item(2, S.int),
+   }
+ })
```

> 🧠 The `S.tuple1-S.tuple3` are still available for convenience.

### Big error clean up

I've turned the error into an instance of `Error`. So now when it's raised and not caught, it's going to be logged nice with a readable error message.

At the same time it's still compatible with ReScript `exn` type and can be caught using `S.Raised`.

#### The whole list of error-related changes

- Added `S.Error.make`, `S.Error.raise`, `S.Error.code`. `S.Raised` became private, use `S.Error.raise` instead
- Moved error types from `S.Error` module to the `S` module:
  - `S.Error.t` -> `S.error`
  - `S.Error.code` -> `S.errorCode`
  - `S.Error.operation` -> `S.operation`
- Renamed `S.Error.toString` -> `S.Error.message`
- Improved the type name foramat in the error message
- Removed `S.Result.getExn`. Use `...OrRaiseWith` operations. They now throw beatiful errors, so the `S.Result.getExn` is not needed
- Removed `S.Result.mapErrorToString`
- Updated error codes:
  - `InvalidJsonStruct`'s payload now contains the invalid struct itself instead of the name
  - Renamed `TupleSize` -> `InvalidTupleSize`
  - Renamed `UnexpectedType` -> `InvalidType`, which now contains the failed struct and provided input instead of their names. Also, it's not returned for literals anymore, literal structs always fail with `InvlidLiteral` error code
  - Fixed `InvalidType` expected type in error message for nullable and optional structs
  - `UnexpectedValue` renamed to `InvlidLiteral` and contains the expected literal and provided input instead of their names
  - `MissingSerializer` and `MissingParser` turned into the single `InvalidOperation({description: string})`

### Effects redesign

Before to fail inside of an effect struct (`refine`/`transform`/`preprocess`) there was the `S.fail` function, available globabally. To solve this one and other problems the effect structs now provide a `ctx` object with the `fail` method in it:

```diff
- let intToString = struct =>
-   struct->S.transform(
-     ~parser=int => int->Int.toString,
-     ~serializer=string =>
-       switch string->Int.fromString {
-       | Some(int) => int
-       | None => S.fail("Can't convert string to int")
-       },
-     (),
-   )
+ let intToString = struct =>
+   struct->S.transform(s => {
+     parser: Int.toString,
+     serializer: string =>
+       switch string->Int.fromString {
+       | Some(int) => int
+       | None => s.fail("Can't convert string to int")
+       },
+   })
```

You can also access the final `struct` state with all metadata applied and the `failWithError` which previosly was the `S.advancedFail` function:

```rescript
type effectCtx<'value> = {
  struct: t<'value>,
  fail: 'a. (string, ~path: Path.t=?) => 'a,
  failWithError: 'a. error => 'a,
}
```

Because of the change `S.advancedTransform` and `S.advancedPreprocess` became not needed and removed. You can do the same with `S.transform` and `S.preprocess`.

Another noteble change happend with `S.refine`. Now it accepts only one function which is applied both for parser and serializer. If you need to refine only one opperation, use `S.transform` instead.

```diff
- let shortStringStruct = S.string()->S.refine(~parser=value =>
-   if value->String.length > 255 {
-     S.fail("String can't be more than 255 characters")
-   }
- , ())
+ let shortStringStruct = S.string->S.refine(s => value =>
+   if value->String.length > 255 {
+     s.fail("String can't be more than 255 characters")
+   }
+ )
```

## TS API empowerment

In the release the TS API got some love and was completely redesigned to shine like never before.

It moved from `zod`-like API where all methods belong to one object to tree-shakable `valibot`-like API. So methods became functions, which allowed to make the code tree-shakable, faster, smaller and simpler.

```diff
import * as S from "rescript-struct";

- const userStruct = S.object({
-   username: S.string(),
- });
- userStruct.parse({ username: "Ludwig" });
+ const userStruct = S.object({
+   username: S.string,
+ });
+ S.parse(userStruct, { username: "Ludwig" });
```

Also, the change brought improved interop with GenType. Since `S.Struct` type now extends the struct type created by GenType and the interop layer for methods is removed, you can freely mix **rescript-struct**'s TS API with code generated by GenType.

Take a look at the whole changelog at [Other TS API changes](#other-ts-api-changes).

## Other changes

- V5 requires `rescript@11`
- Improved usage example
- All library modules are uncurried, but it still can be used with `uncurried: false`
- Added experimental support for serializing untagged variants. Please report if you come accross any issue.
- `S.jsonable()` -> `S.json`
- `S.json(struct)` -> `S.jsonString(struct)`
- `S.parseJsonWith` -> `S.parseJsonStringWith`
- `S.serializeToJsonWith` -> `S.serializeToJsonStringWith`
- `S.asyncRecursive` -> `S.recursive`. The `S.recursive` now works for both sync and async structs
- Added `S.toUnknown` helper to cast the struct type from `S.t<'any>` to `S.t<unknown>`
- Bug fix: `S.jsonString` throws an error if you pass non-JSONable struct. It used to silently serialize to `undefined` instead of the expected `string` type
- Bug fix: Errors happening during the operation compilation phase now has a correct path
- Added `S.Path.dynamic`
- `S.deprecate` doesn't make a struct optional anymore. You need to manually wrap it with `S.option`
- `S.default` is renamed to `S.Option.getOrWith`. Also, now you can use `S.Option.getOr`
- Improved `S.name` logic to print more beatiful names for built-in structs. Name is used for errors, codegen and external tools
- Added `S.setName` to be able to customize struct name
- The same as effect structs the `S.custom` now accepts only one argument which is a function that gets `effectCtx` and returns a record with parser and serializer. Also, the name argument is not labeled anymore
- The `S.preprocess` stoped failing with the `InvalidOperation` error when parser or serializer missing
- Removed `S.fail` and `S.advancedFail` in favor of having `effectCtx` with `fail` and `failWithError` methods
- `S.variant` used to fail when using value multiple times. Now it allows to create a struct and fails only on serializing with `InvalidOperation` code
- Added `fail` and `failWithError` methods to the `catchCtx`
- `Object.UnknownKeys` moved from metadata to `tagged` type
- Removed the need to pass `()` as an ending argument to built-in refinement functions
- Moved all function optional arguments to the end

## Other TS API changes

- Updated `S.Struct` type to include both input and output types
- You can get the struct input type by using `S.Input<struct>` and output type by using `S.Output<struct>` (previouse `S.Infer`)
- The `serialize` and `serializeOrThrow` started returning the struct `Input` type instead of `unknown`
- Changed primitive structs from functions to values. For example, `S.string()` -> `S.string`
- Added support for `Symbol` and `BigInt` literals
- Renamed `S.json(struct)` to `S.jsonString(struct)`
- Added `Json` type and the `S.json` struct for it
- `S.literal(null)` now returns `S.Struct<null>` instead of `S.Struct<undefined>`
- Removed `S.nan`. Use `S.literal(NaN)` instead
- Removed `default` method. You can pass the default value to the second argument of the `S.optional` function
- The `refine` method now accepts only one refining function which is applied both for parser and serializer. If you want to refine the parser and serializer separately as before, use `S.transform` instead
- Removed `S.fail` in favor of having a `ctx` with `fail` method
- The `asyncRefine` is renamed to `asyncParserRefine`
- `S.object` type check started using `input.constructor===Object` instead of `typeof input === "object"`. Use `S.custom` if it doesn't work for you
- Empty `S.tuple` now returns empty array during parsing instead of `undefined`
- `S.tuple` with single item doesn't unwrap it from array during parsing
- Removed `ObjectStruct` type
- Added built-in refinements and transforms
- `StructError` renamed to `Error` which now contains the `message` getter and other fields.

## Semi-automated migration

> 🧠 The migration file is WIP. I'll update it while migrating projects to V5.

The release contains a lot of clean up with API breaking change, so I've prepared a script you can run with [comby.dev](https://comby.dev/) that will do parts of the migration for you automatically.

1. Create `migration.toml` in your project root

2. Copy the following content to the `migration.toml`:

```toml
[refine-parser]
match="S.refine(~parser=:[x], ())"
rewrite="S.refine(s => :[x])"

[refine-parser-2]
match="S.refine( ~parser=:[x], (), )"
rewrite="S.refine(s => :[x])"

[refine-serializer]
match="S.refine( ~serializer=:[x], (), )"
rewrite="S.refine(s => :[x])"

[refine-serializer-2]
match="S.refine(~serializer=:[x], ())"
rewrite="S.refine(s => :[x])"

[transform-1-parser]
match="S.transform(~parser, ())"
rewrite="S.transform(s => {parser: parser})"

[transform-1-serializer]
match="S.transform(~serializer, ())"
rewrite="S.transform(s => {serializer: serializer})"

[transform-1-parser-serializer]
match="S.transform(~parser, ~serializer, ())"
rewrite="S.transform(s => {parser, serializer})"

[transform-1-serializer-parser]
match="S.transform(~serializer, ~parser, ())"
rewrite="S.transform(s => {parser, serializer})"

[transform-2]
match="S.transform(~parser=:[parser], ~asyncParser=:[asyncParserArg] => :[asyncParserBody], ())"
rewrite="S.transform(s => {parser: :[parser], asyncParser: :[asyncParserArg] => () => :[asyncParserBody]})"

[transform-3]
match="S.transform(~parser=:[parser], ~serializer=:[serializer], ())"
rewrite="S.transform(s => {parser: :[parser], serializer: :[serializer]})"

[transform-3-multiline]
match="S.transform( ~parser=:[parser], ~serializer=:[serializer], (), )"
rewrite="S.transform(s => {parser: :[parser], serializer: :[serializer]})"

[transform-4-parser-only]
match="S.transform(~parser=:[parser], ())"
rewrite="S.transform(s => {parser: :[parser]})"

[transform-4-serializer-only]
match="S.transform(~serializer=:[serializer], ())"
rewrite="S.transform(s => {serializer: :[serializer]})"

[transform-4-async-parser-only]
match="S.transform(~asyncParser=:[asyncParserArg] => :[asyncParserBody], ())"
rewrite="S.transform(s => {asyncParser: :[asyncParserArg] => () => :[asyncParserBody]})"

[transform-4-async-parser-only-multiline]
match="S.transform( ~asyncParser=:[asyncParserArg] => :[asyncParserBody], (), )"
rewrite="S.transform(s => {asyncParser: :[asyncParserArg] => () => :[asyncParserBody]})"
```

3. Run the script in your project root. Assumes `migration.toml` has been copied in place to your project root.

```sh
comby -config migration.toml -f .res -matcher .re -exclude-dir node_modules,__generated__ -i
```

The migration script is a set of instructions that Comby runs in sequence. You're encouraged to take migration.toml and tweak it so it fits your needs. [Comby](https://comby.dev/) is powerful. It can do interactive rewriting and numerous other useful stuff. Check it out, but please note it's not intended to cover all of the migration necessary. You'll still likely need to do a few manual fixes after running the migration scripts.

## Opt-in ppx support

### How to install

In progress

### How to use

Add `@struct` in front of a type defenition.

```rescript
@struct
type rating =
  | @as("G") GeneralAudiences
  | @as("PG") ParentalGuidanceSuggested
  | @as("PG13") ParentalStronglyCautioned
  | @as("R") Restricted
@struct
type film = {
  @as("Id")
  id: float,
  @as("Title")
  title: string,
  @as("Tags")
  tags: @struct(S.array(S.string)->S.default(() => [])) array<string>,
  @as("Rating")
  rating: rating,
  @as("Age")
  deprecatedAgeRestriction: @struct(S.int->S.option->S.deprecate("Use rating instead")) option<int>,
}
```

This will automatically create `filmStruct` of type `S.t<film>`:

```rescript
let ratingStruct = S.union([
  S.literal(GeneralAudiences),
  S.literal(ParentalGuidanceSuggested),
  S.literal(ParentalStronglyCautioned),
  S.literal(Restricted),
])
let filmStruct = S.object(s => {
  id: s.field("Id", S.float),
  title: s.field("Title", S.string),
  tags: s.field("Tags", S.array(S.string)->S.default(() => [])),
  rating: s.field("Rating", ratingStruct),
  deprecatedAgeRestriction: s.field("Age", S.int->S.option->S.deprecate("Use rating instead")),
})
```
