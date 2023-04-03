open Ava

@live
type author = {id: float, tags: array<string>, isAproved: bool, deprecatedAge: option<int>}

test("Example", t => {
  let authorStruct = S.object(o => {
    id: o->S.field("Id", S.float()),
    tags: o->S.field("Tags", S.option(S.array(S.string()))->S.default(() => [])),
    isAproved: o->S.field(
      "IsApproved",
      S.union([S.literalVariant(String("Yes"), true), S.literalVariant(String("No"), false)]),
    ),
    deprecatedAge: o->S.field(
      "Age",
      S.int()->S.deprecated(~message="Will be removed in APIv2", ()),
    ),
  })

  t->Assert.deepEqual(
    %raw(`{"Id": 1, "IsApproved": "Yes", "Age": 22}`)->S.parseWith(authorStruct),
    Ok({
      id: 1.,
      tags: [],
      isAproved: true,
      deprecatedAge: Some(22),
    }),
    (),
  )
  t->Assert.deepEqual(
    {
      id: 2.,
      tags: ["Loved"],
      isAproved: false,
      deprecatedAge: None,
    }->S.serializeWith(authorStruct),
    Ok(
      %raw(`{
        "Id": 2,
        "IsApproved": "No",
        "Tags": ["Loved"],
        "Age": undefined,
      }`),
    ),
    (),
  )
})
