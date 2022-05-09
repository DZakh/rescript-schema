open Ava

test("Constructs unknown dict of primitives", t => {
  let value = Js.Dict.fromArray([("foo", "bar"), ("baz", "qux")])
  let any = %raw(`{foo:"bar", baz:"qux"}`)

  let struct = S.dict(S.string())

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
})

test("Using default value when constructing optional unknown primitive", t => {
  let value = 123.
  let any = %raw(`undefined`)

  let struct = S.option(S.float())->S.default(value)

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
})

module Example = {
  type author = {id: float, tags: array<string>, isAproved: bool, deprecatedAge: option<int>}

  test("Example", t => {
    let authorStruct: S.t<author> = S.record4(
      ~fields=(
        ("Id", S.float()),
        ("Tags", S.option(S.array(S.string()))->S.default([])),
        ("IsApproved", S.int()->S.coerce(~constructor=int =>
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
      %raw(`{"Id": 1, "IsApproved": 1, "Age": 12}`)->S.constructWith(authorStruct),
      Ok({
        id: 1.,
        tags: [],
        isAproved: true,
        deprecatedAge: Some(12),
      }),
      (),
    )
    t->Assert.deepEqual(
      %raw(`{"Id": 1, "IsApproved": 0, "Tags": ["Loved"]}`)->S.constructWith(authorStruct),
      Ok({
        id: 1.,
        tags: ["Loved"],
        isAproved: false,
        deprecatedAge: None,
      }),
      (),
    )
  })
}
