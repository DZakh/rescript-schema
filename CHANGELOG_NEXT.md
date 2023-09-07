# Changelog for the next release (WIP)

## API changes

- Library works in `uncurried` mode
- ReScript V11: serializer improvement to support unboxed variants with transformation.
- Changed primitive structs from functions to values. For example, `S.string()` -> `S.string`
- `S.jsonable()` -> `S.json`
- `S.json(struct)` -> `S.jsonString(struct)`
- `S.jsonString` throws an error if you pass non-JSONable struct. It used to silently serialize to `undefined` instead of the expected `string` type
- `S.parseJsonWith` -> `S.parseJsonStringWith`
- `S.serializeToJsonWith` -> `S.serializeToJsonStringWith`
- Removed `S.asyncRecursive`. Now you can use `S.recursive` for both sync and async structs
- Added `S.toUnknown` helper to cast the struct type from `S.t<'any>` to `S.t<unknown>`
- `S.object` enhancements:
  - It became easier to define a field (`o->S.field` -> `s.field`)
  - Added helper for discriminant fields (`ignore(s.field("key", S.literal("value")))` -> `s.tag("key", "value")`)
  - Added helper for setting default value for fields (`s.field("key", S.option(S.string)->S.default(() => "foo"))` -> `s.fieldOr("key", S.string, "foo")`)
- Exciting literals rework:
  - It became much easier to define a literal (`S.literal(String("foo"))` -> `S.literal("foo")`)
  - Literal structs now support any Js values, not only the primitive ones as before
  - The literal structs infers the value type and can be used even with nested variants `S.literal(Student({name: "Vasil", kind: Graduated}))`
  - `S.literal` type moved to `S.Literal.t` and now supports all Js values
  - `S.Literal` module exposes a lot of useful helpers to work with literals
  - `S.literalVariant` removed in favor of `S.literal` and `S.variant`
- **rescript-struct** error updates:
  - Moved error types from `S.Error` module to the `S` module:
    - `S.Error.t` -> `S.error`
    - `S.Error.code` -> `S.errorCode`
    - `S.Error.operation` -> `S.operation`
  - Updated error codes:
    - `InvalidJsonStruct`'s payload now contains the invalid struct itself instead of the name
    - `TupleSize` renamed to `InvalidTupleSize`
    - `UnexpectedType` renamed to `InvalidType` and contains the failed struct and provided input instead of their names. Also, it's not returned for literals anymore, literal structs always fail with `InvlidLiteral` error code now.
    - Fixed `InvalidType` expected type in error message for nullable and optional structs.
    - `UnexpectedValue` renamed to `InvlidLiteral` and contains the expected literal and provided input instead of their names.
    - `MissingSerializer` and `MissingParser` renamed to single `InvalidOperation({description: string})`
  - Added `S.Path.dynamic` and fixed `S.error.path` for errors happening during operation compilation phase
- `S.deprecate` doesn't make a struct optional anymore (it used to use `S.option` internally)
- `S.default` is renamed to `S.Option.getOrWith`. Also, now you can use `S.Option.getOr`.
- Updated `S.name` logic and added `S.setName` to be able customize it. Name is used for errors, codegen and external tools
- `S.refine` now accepts only one refining function which is applied both for parser and serializer. If you want to refine the parser and serializer separately as before, or use asynchronous parser, use `S.transform` instead
- `S.transform` now accepts only one argument which is a function that gets `effectCtx` and returns a record with parser and serializer.
- `S.custom` now accepts only one argument which is a function that gets `effectCtx` and returns a record with parser and serializer.
- `S.advancedTransform` is deprecated in favor of `S.transform`
- `S.advancedPreprocess` is renamed to `S.preprocess`. It now accepts only one argument which is a function that gets `effectCtx` and returns a record with parser and serializer. Operation stoped failing with `InvalidOperation` error when a parser or serializer is not passed.
- Removed `S.fail` and `S.advancedFail` in favor of having `effectCtx` with `.fail` and `.failWithError` methods
- `S.inline` is temporary broken
- Removed `S.Tuple.factory`, `S.tuple0`, `S.tuple4`-`S.tuple10` in favor of the new `S.tuple` which has similar API to `S.object`.
- `S.variant` used to fail when using value multiple times. Now it allows to create a struct and fails only on serializing with `InvalidOperation` code
- Added `fail` and `failWithError` methods to the `catchCtx`
- `Object.UnknownKeys` moved from metadata to `tagged` type
- `S.object` type check started using `input.constructor===Object` instead of `typeof input === "object"`. Use `S.custom` if it doesn't work for you
- Removed the need to pass `()` as an ending argument to built-in refinement functions
- Moved all function optional arguments to the end

## TS API changes

- Updated `S.Struct` type to include both input and output types
- You can get the struct input type by using `S.Input(struct)` and output type by using `S.Output(struct)` (previouse `S.Infer`)
- The `serialize` and `serializeOrThrow` started returning the struct `Input` type instead of `unknown`
- Changed primitive structs from functions to values. For example, `S.string()` -> `S.string`
- Added support for `Symbol` and `BigInt` literals
- Renamed `S.json(struct)` to `S.jsonString(struct)`
- `S.jsonString` throws an error if you pass non-JSONable struct. It used to silently serialize to `undefined` instead of the expected `string` type
- Added `Json` type and the `S.json` struct for it
- `S.literal(null)` now returns `S.Struct<null, null>` instead of `S.Struct<undefined>`
- Removed `S.nan`. Use `S.literal(NaN)` instead
- Removed `default` methods is removed. You can pass the default value to the second argument of the `S.optional` function
- The `refine` method now accepts only one refining function which is applied both for parser and serializer. If you want to refine the parser and serializer separately as before, use `S.transform` instead
- Removed `S.fail` in favor of having a `ctx` with `.fail` method
- The `asyncRefine` is renamed to `asyncParserRefine`
- `S.object` type check started using `input.constructor===Object` instead of `typeof input === "object"`. Use `S.custom` if it doesn't work for you
- Empty `S.tuple` now returns empty array during parsing instead of `undefined`
- `S.tuple` with single item doesn't unwrap it from array during parsing
- Turned all the struct methods to functions, to enable tree-shaking, remove runtime overhead, make API similar to the ReScript one.
- Remove `ObjectStruct` type.
- Use the same `Struct` type as `genType`
- Add built-in refinements and transforms

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

## Semi-automated migration

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
