[⬅ Back to highlights](/README.md)

# ReScript Schema PPX

ReScript PPX to generate **rescript-schema** from type.

> 🧠 It's 100% opt-in. You can use **rescript-schema** without ppx.

## Table of contents

- [Table of contents](#table-of-contents)
- [Install](#install)
- [Basic usage](#basic-usage)
- [API reference](#api-reference)

## Install

```sh
npm install rescript-schema rescript-schema-ppx
```

Then update your `rescript.json` config:

```diff
{
  ...
+ "bs-dependencies": ["rescript-schema"],
+ "bsc-flags": ["-open RescriptSchema"],
+ "ppx-flags": ["rescript-schema-ppx/bin"],
}
```

## Basic usage

```rescript
// 1. Define a type and add @schema attribute
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
  tags: @s.matches(S.option(S.array(S.string))->S.Option.getOr([])) array<string>,
  @as("Rating")
  rating: rating,
  @as("Age")
  deprecatedAgeRestriction: @s.matches(S.option(S.int)->S.deprecate("Use rating instead")) option<int>,
}

// 2. ppx will generate the code below
let ratingSchema = S.union([
  S.literal(GeneralAudiences),
  S.literal(ParentalGuidanceSuggested),
  S.literal(ParentalStronglyCautioned),
  S.literal(Restricted),
])
let filmSchema = S.object(s => {
  id: s.field("Id", S.float),
  title: s.field("Title", S.string),
  tags: s.fieldOr("Tags", S.array(S.string), []),
  rating: s.field("Rating", ratingSchema),
  deprecatedAgeRestriction: s.field("Age", S.option(S.int)->S.deprecate("Use rating instead")),
})

// 3. Parse data using the schema
// The data is validated and transformed to a convenient format
%raw(`{
  "Id": 1,
  "Title": "My first film",
  "Rating": "R",
  "Age": 17
}`)->S.parseWith(filmSchema)
// Ok({
//   id: 1.,
//   title: "My first film",
//   tags: [],
//   rating: Restricted,
//   deprecatedAgeRestriction: Some(17),
// })

// 4. Transform data back using the same schema
{
  id: 2.,
  tags: ["Loved"],
  title: "Sad & sed",
  rating: ParentalStronglyCautioned,
  deprecatedAgeRestriction: None,
}->S.serializeWith(filmSchema)
// Ok(%raw(`{
//   "Id": 2,
//   "Title": "Sad & sed",
//   "Rating": "PG13",
//   "Tags": ["Loved"],
//   "Age": undefined,
// }`))

// 5. Use schema as a building block for other tools
// For example, create a JSON-schema with rescript-json-schema and use it for OpenAPI generation
let filmJSONSchema = JSONSchema.make(filmSchema)
```

> 🧠 Read more about schema usage in the _[ReScript Schema for ReScript users](/docs/rescript-usage.md)_ documentation.

## API reference

### `@schema`

**Applies to**: type declarations, type signatures

Indicates that a schema should be generated for the given type.

### `@s.matches(S.t<'value>)`

**Applies to**: type expressions

Specifies custom schema for the type.
