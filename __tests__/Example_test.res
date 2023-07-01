open Ava

@dead
type rating =
  | @as("G") GeneralAudiences
  | @as("PG") ParentalGuidanceSuggested
  | @as("PG13") ParentalStronglyCautioned
  | @as("R") Restricted

@dead
type film = {
  id: float,
  title: string,
  tags: array<string>,
  rating: rating,
  deprecatedAgeRestriction: option<int>,
}

test("Example", t => {
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

  t->Assert.deepEqual(
    %raw(`{"Id": 1, "Title": "My first film", "Rating": "R", "Age": 17}`)->S.parseWith(filmStruct),
    Ok({
      id: 1.,
      title: "My first film",
      tags: [],
      rating: Restricted,
      deprecatedAgeRestriction: Some(17),
    }),
    (),
  )
  t->Assert.deepEqual(
    {
      id: 2.,
      tags: ["Loved"],
      title: "Sad & sed",
      rating: ParentalStronglyCautioned,
      deprecatedAgeRestriction: None,
    }->S.serializeWith(filmStruct),
    Ok(
      %raw(`{
        "Id": 2,
        "Title": "Sad & sed",
        "Rating": "PG13",
        "Tags": ["Loved"],
        "Age": undefined,
      }`),
    ),
    (),
  )
})
