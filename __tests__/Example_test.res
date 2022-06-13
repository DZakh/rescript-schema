open Ava

type author = {id: float, tags: array<string>, isAproved: bool, deprecatedAge: option<int>}

test("Example", t => {
  let authorStruct: S.t<author> = S.record4(
    ~fields=(
      ("Id", S.float()),
      ("Tags", S.option(S.array(S.string()))->S.default([])),
      ("IsApproved", S.int()->S.transform(~constructor=int =>
          switch int {
          | 1 => true
          | _ => false
          }->Ok
        , ())),
      ("Age", S.deprecated(~message="A useful explanation", S.int())),
    ),
    ~constructor=((id, tags, isAproved, deprecatedAge)) =>
      {id: id, tags: tags, isAproved: isAproved, deprecatedAge: deprecatedAge}->Ok,
    (),
  )

  t->Assert.deepEqual(
    {"Id": 1, "IsApproved": 1, "Age": 12}->S.parseWith(authorStruct),
    Ok({
      id: 1.,
      tags: [],
      isAproved: true,
      deprecatedAge: Some(12),
    }),
    (),
  )
  t->Assert.deepEqual(
    {"Id": 1, "IsApproved": 0, "Tags": ["Loved"]}->S.parseWith(authorStruct),
    Ok({
      id: 1.,
      tags: ["Loved"],
      isAproved: false,
      deprecatedAge: None,
    }),
    (),
  )
})
