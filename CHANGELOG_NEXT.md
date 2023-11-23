## v5.2

## Opt-in ppx support

### How to install

In progress

### How to use

Add `@schema` in front of a type defenition.

```rescript
@schema
type rating =
  | @as("G") GeneralAudiences
  | @as("PG") ParentalGuidanceSuggested
  | @as("PG13") ParentalStronglyCautioned
  | @as("R") Restricted
@schema
type film = {
  @as("Id")
  id: float,
  @as("Title")
  title: string,
  @as("Tags")
  tags: @schema(S.array(S.string)->S.default(() => [])) array<string>,
  @as("Rating")
  rating: rating,
  @as("Age")
  deprecatedAgeRestriction: @schema(S.int->S.option->S.deprecate("Use rating instead")) option<int>,
}
```

This will automatically create `filmSchema` of type `S.t<film>`:

```rescript
let ratingSchema = S.union([
  S.literal(GeneralAudiences),
  S.literal(ParentalGuidanceSuggested),
  S.literal(ParentalStronglyCautioned),
  S.literal(Restricted),
])
let filmSchema = S.object(s => {
  id: s.field("Id", S.float),
  title: s.field("Title", S.string),
  tags: s.field("Tags", S.array(S.string)->S.default(() => [])),
  rating: s.field("Rating", ratingSchema),
  deprecatedAgeRestriction: s.field("Age", S.int->S.option->S.deprecate("Use rating instead")),
})
```
