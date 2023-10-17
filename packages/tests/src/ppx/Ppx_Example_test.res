open Ava
open U

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
  tags: @struct(S.array(S.string)->S.option->S.Option.getOr([])) array<string>,
  @as("Rating")
  rating: rating,
  @as("Age")
  deprecatedAgeRestriction: @struct(S.int->S.option->S.deprecate("Use rating instead")) option<int>,
}

test("Example", t => {
  t->assertEqualStructs(
    filmStruct,
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
