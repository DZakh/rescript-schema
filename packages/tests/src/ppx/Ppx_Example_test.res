open Ava
open U

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
  tags: @s.default([]) array<string>,
  @as("Rating")
  rating: rating,
  @as("Age")
  deprecatedAgeRestriction: @s.deprecate("Use rating instead") option<int>,
}

test("Main example", t => {
  t->assertEqualSchemas(
    filmSchema,
    S.object(s => {
      id: s.field("Id", S.float),
      title: s.field("Title", S.string),
      tags: s.fieldOr("Tags", S.array(S.string), []),
      rating: s.field(
        "Rating",
        S.union([
          S.literal(GeneralAudiences),
          S.literal(ParentalGuidanceSuggested),
          S.literal(ParentalStronglyCautioned),
          S.literal(Restricted),
        ]),
      ),
      deprecatedAgeRestriction: s.field("Age", S.option(S.int)->S.deprecate("Use rating instead")),
    }),
  )
})

@schema
type matches = @s.matches(S.string->S.url) string
test("@s.matches", t => {
  t->assertEqualSchemas(matchesSchema, S.string->S.url)
})

@schema
type default = @s.default("Unknown") string
test("@s.default", t => {
  t->assertEqualSchemas(defaultSchema, S.option(S.string)->S.Option.getOr("Unknown"))
})

@schema
type defaultWith = @s.defaultWith(() => []) array<string>
test("@s.defaultWith", t => {
  t->assertEqualSchemas(
    defaultWithSchema,
    S.option(S.array(S.string))->S.Option.getOrWith(() => []),
  )
})

@schema
type null = @s.null option<string>
test("@s.null", t => {
  t->assertEqualSchemas(nullSchema, S.null(S.string))
})

@schema
type nullWithDefault = @s.null @s.default("Unknown") string
test("@s.null with @s.default", t => {
  t->assertEqualSchemas(nullWithDefaultSchema, S.null(S.string)->S.Option.getOr("Unknown"))
})

@schema
type nullable = @s.nullable option<string>
test("@s.nullable", t => {
  t->assertEqualSchemas(nullableSchema, S.nullable(S.string))
})

@schema
type nullableWithDefault = @s.nullable @s.default("Unknown") string
test("@s.nullable with @s.default", t => {
  t->assertEqualSchemas(nullableWithDefaultSchema, S.nullable(S.string)->S.Option.getOr("Unknown"))
})

@schema
type deprecate = @s.deprecate("Will be removed in APIv2") string
test("@s.deprecate", t => {
  t->assertEqualSchemas(deprecateSchema, S.string->S.deprecate("Will be removed in APIv2"))
})

@schema
type describe = @s.describe("A useful bit of text, if you know what to do with it.") string
test("@s.describe", t => {
  t->assertEqualSchemas(
    describeSchema,
    S.string->S.describe("A useful bit of text, if you know what to do with it."),
  )
})
