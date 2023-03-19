open Ava

module Stdlib = {
  module Dict = {
    @val
    external copy: (@as(json`{}`) _, Js.Dict.t<'a>) => Js.Dict.t<'a> = "Object.assign"

    let omit = (dict: Js.Dict.t<'a>, fields: array<string>): Js.Dict.t<'a> => {
      let dict = dict->copy
      fields->Js.Array2.forEach(field => {
        Js.Dict.unsafeDeleteKey(. dict, field)
      })
      dict
    }
  }
}

let assertEqualStructs = {
  let cleanUpTransformationFactories = (struct: S.t<'v>): S.t<'v> => {
    struct->Obj.magic->Stdlib.Dict.omit(["pf", "sf"])->Obj.magic
  }
  (t, s1, s2, ~message=?, ()) => {
    t->Assert.deepEqual(
      s1->cleanUpTransformationFactories,
      s2->cleanUpTransformationFactories,
      ~message?,
      (),
    )
  }
}

test("Works with String", t => {
  let struct = S.string()
  t->Assert.deepEqual(struct->S.inline, `S.string()`, ())
})

test("Doesn't support transforms and refinements", t => {
  let struct = S.string()->S.transform(~parser=ignore, ())->S.refine(~parser=ignore, ())
  t->Assert.deepEqual(struct->S.inline, `S.string()`, ())
})

// FIXME:
Failing.test("Support built-in refinements with String", t => {
  let struct = S.string()->S.String.email()
  let structInlineResult = {
    let s = S.string()
    let _ = %raw(`s.m = {"rescript-struct:String.refinements":[{"kind":0,"message":"Invalid email address"}]}`)
    s
  }
  t->Assert.deepEqual(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `{
  let s = S.string()
  let _ = %raw(\`s.m = {"rescript-struct:String.refinements":[{"kind":0,"message":"Invalid email address"}]}\`)
  s
}`,
    (),
  )
})

test("Works with Int", t => {
  let struct = S.int()
  t->Assert.deepEqual(struct->S.inline, `S.int()`, ())
})

test("Works with Float", t => {
  let struct = S.float()
  t->Assert.deepEqual(struct->S.inline, `S.float()`, ())
})

test("Works with Bool", t => {
  let struct = S.bool()
  t->Assert.deepEqual(struct->S.inline, `S.bool()`, ())
})

test("Works with Unknown", t => {
  let struct = S.unknown()
  t->Assert.deepEqual(struct->S.inline, `S.unknown()`, ())
})

test("Treats custom struct factory as Unknown", t => {
  let struct = S.custom(
    ~name="Test",
    ~parser=(. ~unknown as _) => {
      S.Error.raise("User error")
    },
    (),
  )
  t->Assert.deepEqual(struct->S.inline, `S.unknown()`, ())
})

test("Works with Never", t => {
  let struct = S.never()
  t->Assert.deepEqual(struct->S.inline, `S.never()`, ())
})

test("Works with String Literal", t => {
  let struct = S.literal(String("foo"))
  t->Assert.deepEqual(struct->S.inline, `S.literal(String("foo"))`, ())
})

test("Escapes the String Literal value", t => {
  let struct = S.literal(String(`"foo"`))
  t->Assert.deepEqual(struct->S.inline, `S.literal(String("\\"foo\\""))`, ())
})

test("Works with Int Literal", t => {
  let struct = S.literal(Int(3))
  t->Assert.deepEqual(struct->S.inline, `S.literal(Int(3))`, ())
})

test("Works with Float Literal", t => {
  let struct = S.literal(Float(3.))
  t->Assert.deepEqual(struct->S.inline, `S.literal(Float(3.))`, ())
})

test("Works with Bool Literal", t => {
  let struct = S.literal(Bool(true))
  t->Assert.deepEqual(struct->S.inline, `S.literal(Bool(true))`, ())
})

test("Works with EmptyOption Literal", t => {
  let struct = S.literal(EmptyOption)
  t->Assert.deepEqual(struct->S.inline, `S.literal(EmptyOption)`, ())
})

test("Works with EmptyNull Literal", t => {
  let struct = S.literal(EmptyNull)
  t->Assert.deepEqual(struct->S.inline, `S.literal(EmptyNull)`, ())
})

test("Works with NaN Literal", t => {
  let struct = S.literal(NaN)
  t->Assert.deepEqual(struct->S.inline, `S.literal(NaN)`, ())
})

test("Works with Option", t => {
  let struct = S.option(S.string())
  t->Assert.deepEqual(struct->S.inline, `S.option(S.string())`, ())
})

test("Works with Null", t => {
  let struct = S.null(S.string())
  t->Assert.deepEqual(struct->S.inline, `S.null(S.string())`, ())
})

test("Works with Array", t => {
  let struct = S.array(S.string())
  t->Assert.deepEqual(struct->S.inline, `S.array(S.string())`, ())
})

test("Works with Dict", t => {
  let struct = S.dict(S.string())
  t->Assert.deepEqual(struct->S.inline, `S.dict(S.string())`, ())
})

test("Works with empty Tuple", t => {
  let struct = S.tuple0(.)
  t->Assert.deepEqual(struct->S.inline, `S.tuple0(.)`, ())
})

test("Works with Tuple", t => {
  let struct = S.tuple3(. S.string(), S.int(), S.bool())
  let structInlineResult = (
    S.Tuple.factory: (. S.t<'v0>, S.t<'v1>, S.t<'v2>) => S.t<('v0, 'v1, 'v2)>
  )(. S.string(), S.int(), S.bool())

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `(S.Tuple.factory: (. S.t<'v0>, S.t<'v1>, S.t<'v2>) => S.t<('v0, 'v1, 'v2)>)(. S.string(), S.int(), S.bool())`,
    (),
  )
})

test("Works with Union", t => {
  let struct = S.union([S.literal(String("yes")), S.literal(String("no"))])
  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.literal(String("yes")), S.literal(String("no"))])`,
    (),
  )
})

test("Works with Object (ignores transformations)", t => {
  let struct = S.object(o =>
    {
      "name": o->S.field("Name", S.string()),
      "email": o->S.field("Email", S.string()),
      "age": o->S.field("Age", S.int()),
    }
  )
  t->Assert.deepEqual(
    struct->S.inline,
    `S.object(o =>
  {
    "Name": o->S.field("Name", S.string()),
    "Email": o->S.field("Email", S.string()),
    "Age": o->S.field("Age", S.int()),
  }
)`,
    (),
  )
})
