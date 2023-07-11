# Changelog for the next release (WIP)

## API changes

- Library works in `uncurried` mode
- Changed primitive structs from functions to values. For example, `S.string()` -> `S.string`
- `S.jsonable()` -> `S.json`
- `S.json(struct)` -> `S.jsonString(struct)`
- `S.parseJsonWith` -> `S.parseJsonStringWith`
- `S.serializeToJsonWith` -> `S.serializeToJsonStringWith`
- Removed `S.asyncRecursive`. Now you can use `S.recursive` for both sync and async structs
- Added `S.toUnknown` helper to cast the struct type from `S.t<'any>` to `S.t<unknown>`
- `S.object` enhancements:
  - It became easier to define a field (`o->S.field` -> `o.field`)
  - Added helper for discriminant fields (`ignore(o.field("key", S.literal("value")))` -> `o.tag("key", "value")`)
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
- `S.deprecate` doesn't make a struct optional anymore (it used to use `S.option` internally)
- `S.default` now uses `S.option` internally, so you don't need to call it yourself
- Updated `S.name` logic and added `S.setName` to be able customize it. Name is used for errors, codegen and external tools
- `S.inline` is temporary broken
- Updated API for `S.Tuple.factory`. There are plans to change it once more before the actual release

## TS API changes

- Changed primitive structs from functions to values. For example, `S.string()` -> `S.string`
- Added support for `Symbol` and `BigInt` literals
- Renamed `S.json(struct)` to `S.jsonString(struct)`
- Added `Json` type and the `S.json` struct for it
- `S.literal(null)` now returns `S.Struct<null>` instead of `S.Struct<undefined>`

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
  id: float,
  title: string,
  tags: @struct(S.array(S.string)->S.default(() => [])) array<string>,
  rating: rating,
  deprecatedAgeRestriction: @struct(S.int->S.option->S.deprecate("Use rating instead")) option<int>,
}
```

This will automatically create `filmStruct` of type `S.t<film>`:

```rescript
let filmStruct = S.object(o => {
  id: o.field("Id", S.float),
  title: o.field("Title", S.string),
  tags: o.field("Tags", S.array(S.string)->S.default(() => [])),
  rating: o.field(
    "Rating",
    S.union([
      S.literal(GeneralAudiences),
      S.literal(ParentalGuidanceSuggested),
      S.literal(ParentalStronglyCautioned),
      S.literal(Restricted),
    ]),
  ),
  deprecatedAgeRestriction: o.field("Age", S.int->S.option->S.deprecate("Use rating instead")),
})
```
