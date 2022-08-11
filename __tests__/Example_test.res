open Ava

type author = {id: float, tags: array<string>, isAproved: bool, deprecatedAge: option<int>}

test("Example", t => {
  let authorStruct =
    S.record4(.
      ("Id", S.float()),
      ("Tags", S.option(S.array(S.string()))->S.default([])),
      (
        "IsApproved",
        S.union([S.literalVariant(String("Yes"), true), S.literalVariant(String("No"), false)]),
      ),
      ("Age", S.deprecated(~message="A useful explanation", S.int())),
    )->S.transform(~parser=((id, tags, isAproved, deprecatedAge)) => {
      id: id,
      tags: tags,
      isAproved: isAproved,
      deprecatedAge: deprecatedAge,
    }, ())

  t->Assert.deepEqual(
    {"Id": 1, "IsApproved": "Yes", "Age": 12}->S.parseWith(authorStruct),
    Ok({
      id: 1.,
      tags: [],
      isAproved: true,
      deprecatedAge: Some(12),
    }),
    (),
  )
  t->Assert.deepEqual(
    {"Id": 1, "IsApproved": "No", "Tags": ["Loved"]}->S.parseWith(authorStruct),
    Ok({
      id: 1.,
      tags: ["Loved"],
      isAproved: false,
      deprecatedAge: None,
    }),
    (),
  )
})

let intToString = struct =>
  struct->S.transform(
    ~parser=int => int->Js.Int.toString,
    ~serializer=string =>
      switch string->Belt.Int.fromString {
      | Some(int) => int
      | None => S.Error.raise("Can't convert string to int")
      },
    (),
  )
