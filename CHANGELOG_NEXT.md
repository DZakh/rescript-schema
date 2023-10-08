## v5.1

- Fixed ts type for S.literal to work with litterally any value
- Added S.undefined to js api
- Added advanced object struct to js api
- Added advanced tuple struct to js api
- Added a proper documentation for JS/TS users
- Added table of contents and splitted documentation into multiple documents
- Improved tree-shaking

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
