# Changelog for the next release (WIP)

## API changes

- Library works in `uncurried` mode
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
    - `UnexpectedValue` renamed to `InvlidLiteral` and contains the expected literal and provided input instead of their names.
    - `MissingSerializer` and `MissingParser` renamed to single `MissingOperation({description: string})`
- `S.deprecate` doesn't make a struct optional anymore (it used to use `S.option` internally)
- `S.default` now uses `S.option` internally, so you don't need to call it yourself
- Updated `S.name` logic and added `S.setName` to be able customize it. Name is used for errors, codegen and external tools
- `S.refine` now accepts only one refining function which is applied both for parser and serializer. If you want to refine the parser and serializer separately as before, use `S.transform` instead. And to asynchronously refine a parser you should use the newly added `S.asyncParserRefine`
- `S.inline` is temporary broken
- Updated API for `S.Tuple.factory`. There are plans to change it once more before the actual release
- `S.variant` used to fail when using value multiple times. Now it allows to create a struct and fails only on serializing with `MissingOperation` code.

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
- The `default` method now uses `S.optional` internally, so you don't need to call it yourself
- The `refine` method now accepts only one refining function which is applied both for parser and serializer. If you want to refine the parser and serializer separately as before, use `S.transform` instead
- The `asyncRefine` is renamed to `asyncParserRefine`

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
rewrite="S.refine(:[x])"

[refine-parser-2]
match="S.refine( ~parser=:[x], (), )"
rewrite="S.refine(:[x])"

[refine-serializer]
match="S.refine( ~serializer=:[x], (), )"
rewrite="S.refine(:[x])"

[refine-serializer-2]
match="S.refine(~serializer=:[x], ())"
rewrite="S.refine(:[x])"

[refine-async-parser]
match="S.refine(~asyncParser=:[x], ())"
rewrite="S.asyncParserRefine(:[x])"

[refine-async-parser-2]
match="S.refine( ~asyncParser=:[x], (), )"
rewrite="S.asyncParserRefine(:[x])"
```

3. Run the script in your project root. Assumes `migration.toml` has been copied in place to your project root.

```sh
comby -config migration.toml -f .res -matcher .re -exclude-dir node_modules,__generated__ -i
```

The migration script is a set of instructions that Comby runs in sequence. You're encouraged to take migration.toml and tweak it so it fits your needs. [Comby](https://comby.dev/) is powerful. It can do interactive rewriting and numerous other useful stuff. Check it out, but please note it's not intended to cover all of the migration necessary. You'll still likely need to do a few manual fixes after running the migration scripts.
