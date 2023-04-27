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

test("Supports String", t => {
  let struct = S.string()
  t->Assert.deepEqual(struct->S.inline, `S.string()`, ())
})

test("Doesn't support transforms and refinements", t => {
  let struct = S.string()->S.transform(~parser=ignore, ())->S.refine(~parser=ignore, ())
  t->Assert.deepEqual(struct->S.inline, `S.string()`, ())
})

test("Supports built-in String.email refinement", t => {
  let struct = S.string()->S.String.email()
  let structInlineResult = S.string()->S.String.email(~message="Invalid email address", ())

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.string()->S.String.email(~message="Invalid email address", ())`,
    (),
  )
})

test("Supports built-in String.datetime refinement", t => {
  let struct = S.string()->S.String.datetime()
  let structInlineResult =
    S.string()->S.String.datetime(~message="Invalid datetime string! Must be UTC", ())

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.string()->S.String.datetime(~message="Invalid datetime string! Must be UTC", ())`,
    (),
  )
})

test("Supports built-in String.url refinement", t => {
  let struct = S.string()->S.String.url()
  let structInlineResult = S.string()->S.String.url(~message="Invalid url", ())

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(struct->S.inline, `S.string()->S.String.url(~message="Invalid url", ())`, ())
})

test("Supports built-in String.uuid refinement", t => {
  let struct = S.string()->S.String.uuid()
  let structInlineResult = S.string()->S.String.uuid(~message="Invalid UUID", ())

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.string()->S.String.uuid(~message="Invalid UUID", ())`,
    (),
  )
})

test("Supports built-in String.cuid refinement", t => {
  let struct = S.string()->S.String.cuid()
  let structInlineResult = S.string()->S.String.cuid(~message="Invalid CUID", ())

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.string()->S.String.cuid(~message="Invalid CUID", ())`,
    (),
  )
})

test("Supports built-in String.min refinement", t => {
  let struct = S.string()->S.String.min(5)
  let structInlineResult =
    S.string()->S.String.min(~message="String must be 5 or more characters long", 5)

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.string()->S.String.min(~message="String must be 5 or more characters long", 5)`,
    (),
  )
})

test("Supports built-in String.max refinement", t => {
  let struct = S.string()->S.String.max(5)
  let structInlineResult =
    S.string()->S.String.max(~message="String must be 5 or fewer characters long", 5)

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.string()->S.String.max(~message="String must be 5 or fewer characters long", 5)`,
    (),
  )
})

test("Supports built-in String.length refinement", t => {
  let struct = S.string()->S.String.length(5)
  let structInlineResult =
    S.string()->S.String.length(~message="String must be exactly 5 characters long", 5)

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.string()->S.String.length(~message="String must be exactly 5 characters long", 5)`,
    (),
  )
})

test("Supports built-in String.pattern refinement", t => {
  let struct = S.string()->S.String.pattern(%re("/0-9/"))
  let structInlineResult = S.string()->S.String.pattern(~message="Invalid", %re("/0-9/"))

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.string()->S.String.pattern(~message="Invalid", %re("/0-9/"))`,
    (),
  )
})

test("Supports Int", t => {
  let struct = S.int()
  t->Assert.deepEqual(struct->S.inline, `S.int()`, ())
})

test("Supports built-in Int.max refinement", t => {
  let struct = S.int()->S.Int.max(4)
  let structInlineResult = S.int()->S.Int.max(~message="Number must be lower than or equal to 4", 4)

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.int()->S.Int.max(~message="Number must be lower than or equal to 4", 4)`,
    (),
  )
})

test("Supports built-in Int.min refinement", t => {
  let struct = S.int()->S.Int.min(4)
  let structInlineResult =
    S.int()->S.Int.min(~message="Number must be greater than or equal to 4", 4)

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.int()->S.Int.min(~message="Number must be greater than or equal to 4", 4)`,
    (),
  )
})

test("Supports built-in Int.port refinement", t => {
  let struct = S.int()->S.Int.port()
  let structInlineResult = S.int()->S.Int.port(~message="Invalid port", ())

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(struct->S.inline, `S.int()->S.Int.port(~message="Invalid port", ())`, ())
})

test("Supports Float", t => {
  let struct = S.float()
  t->Assert.deepEqual(struct->S.inline, `S.float()`, ())
})

test("Supports built-in Float.max refinement", t => {
  let struct = S.float()->S.Float.max(4.)
  let structInlineResult =
    S.float()->S.Float.max(~message="Number must be lower than or equal to 4", 4.)

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.float()->S.Float.max(~message="Number must be lower than or equal to 4", 4.)`,
    (),
  )
})

test("Supports built-in Float.max refinement with digits after decimal point", t => {
  let struct = S.float()->S.Float.max(4.4)
  let structInlineResult =
    S.float()->S.Float.max(~message="Number must be lower than or equal to 4.4", 4.4)

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.float()->S.Float.max(~message="Number must be lower than or equal to 4.4", 4.4)`,
    (),
  )
})

test("Supports built-in Float.min refinement", t => {
  let struct = S.float()->S.Float.min(4.)
  let structInlineResult =
    S.float()->S.Float.min(~message="Number must be greater than or equal to 4", 4.)

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.float()->S.Float.min(~message="Number must be greater than or equal to 4", 4.)`,
    (),
  )
})

test("Supports built-in Float.min refinement with digits after decimal point", t => {
  let struct = S.float()->S.Float.min(4.4)
  let structInlineResult =
    S.float()->S.Float.min(~message="Number must be greater than or equal to 4.4", 4.4)

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.float()->S.Float.min(~message="Number must be greater than or equal to 4.4", 4.4)`,
    (),
  )
})

test("Supports multiple built-in refinements", t => {
  let struct = S.string()->S.String.min(5)->S.String.max(10)
  let structInlineResult =
    S.string()
    ->S.String.min(~message="String must be 5 or more characters long", 5)
    ->S.String.max(~message="String must be 10 or fewer characters long", 10)

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.string()->S.String.min(~message="String must be 5 or more characters long", 5)->S.String.max(~message="String must be 10 or fewer characters long", 10)`,
    (),
  )
})

test("Supports Bool", t => {
  let struct = S.bool()
  t->Assert.deepEqual(struct->S.inline, `S.bool()`, ())
})

test("Supports Unknown", t => {
  let struct = S.unknown()
  t->Assert.deepEqual(struct->S.inline, `S.unknown()`, ())
})

test("Treats custom struct factory as Unknown", t => {
  let struct = S.custom(
    ~name="Test",
    ~parser=_ => {
      S.fail("User error")
    },
    (),
  )
  t->Assert.deepEqual(struct->S.inline, `S.unknown()`, ())
})

test("Supports Never", t => {
  let struct = S.never()
  t->Assert.deepEqual(struct->S.inline, `S.never()`, ())
})

test("Supports JSON", t => {
  let struct = S.jsonable()
  t->Assert.deepEqual(struct->S.inline, `S.jsonable()`, ())
})

test("Supports String Literal", t => {
  let struct = S.literal(String("foo"))
  t->Assert.deepEqual(struct->S.inline, `S.literal(String("foo"))`, ())
})

test("Escapes the String Literal value", t => {
  let struct = S.literal(String(`"foo"`))
  t->Assert.deepEqual(struct->S.inline, `S.literal(String("\\"foo\\""))`, ())
})

test("Supports Int Literal", t => {
  let struct = S.literal(Int(3))
  t->Assert.deepEqual(struct->S.inline, `S.literal(Int(3))`, ())
})

test("Supports Float Literal", t => {
  let struct = S.literal(Float(3.))
  t->Assert.deepEqual(struct->S.inline, `S.literal(Float(3.))`, ())
})

test("Supports decimal Float Literal", t => {
  let struct = S.literal(Float(3.3))
  t->Assert.deepEqual(struct->S.inline, `S.literal(Float(3.3))`, ())
})

test("Supports Bool Literal", t => {
  let struct = S.literal(Bool(true))
  t->Assert.deepEqual(struct->S.inline, `S.literal(Bool(true))`, ())
})

test("Supports EmptyOption Literal", t => {
  let struct = S.literal(EmptyOption)
  t->Assert.deepEqual(struct->S.inline, `S.literal(EmptyOption)`, ())
})

test("Supports EmptyNull Literal", t => {
  let struct = S.literal(EmptyNull)
  t->Assert.deepEqual(struct->S.inline, `S.literal(EmptyNull)`, ())
})

test("Supports NaN Literal", t => {
  let struct = S.literal(NaN)
  t->Assert.deepEqual(struct->S.inline, `S.literal(NaN)`, ())
})

test("Supports Option", t => {
  let struct = S.option(S.string())
  t->Assert.deepEqual(struct->S.inline, `S.option(S.string())`, ())
})

test("Supports Default", t => {
  let struct = S.option(S.float())->S.default(() => 4.)
  let _ = S.option(S.float())->S.default(() => %raw(`4`))

  t->Assert.deepEqual(struct->S.inline, `S.option(S.float())->S.default(() => %raw(\`4\`))`, ())
})

test("Supports undefined as Defaulted value", t => {
  let struct = S.option(S.option(S.float()))->S.default(() => None)
  let _ = S.option(S.option(S.float()))->S.default(() => %raw(`undefined`))

  t->Assert.deepEqual(
    struct->S.inline,
    `S.option(S.option(S.float()))->S.default(() => %raw(\`undefined\`))`,
    (),
  )
})

test("Supports Deprecated with message", t => {
  let struct = S.string()->S.deprecate("Will be removed in API v2.")
  t->Assert.deepEqual(struct->S.inline, `S.string()->S.deprecate("Will be removed in API v2.")`, ())
})

test("Supports Null", t => {
  let struct = S.null(S.string())
  t->Assert.deepEqual(struct->S.inline, `S.null(S.string())`, ())
})

test("Supports Array", t => {
  let struct = S.array(S.string())
  t->Assert.deepEqual(struct->S.inline, `S.array(S.string())`, ())
})

test("Supports built-in Array.max refinement", t => {
  let struct = S.array(S.string())->S.Array.max(4)
  let structInlineResult =
    S.array(S.string())->S.Array.max(~message="Array must be 4 or fewer items long", 4)

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.array(S.string())->S.Array.max(~message="Array must be 4 or fewer items long", 4)`,
    (),
  )
})

test("Supports built-in Array.min refinement", t => {
  let struct = S.array(S.string())->S.Array.min(4)
  let structInlineResult =
    S.array(S.string())->S.Array.min(~message="Array must be 4 or more items long", 4)

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.array(S.string())->S.Array.min(~message="Array must be 4 or more items long", 4)`,
    (),
  )
})

test("Supports built-in Array.length refinement", t => {
  let struct = S.array(S.string())->S.Array.length(4)
  let structInlineResult =
    S.array(S.string())->S.Array.length(~message="Array must be exactly 4 items long", 4)

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.array(S.string())->S.Array.length(~message="Array must be exactly 4 items long", 4)`,
    (),
  )
})

test("Supports Dict", t => {
  let struct = S.dict(S.string())
  t->Assert.deepEqual(struct->S.inline, `S.dict(S.string())`, ())
})

test("Supports empty Tuple", t => {
  let struct = S.tuple0(.)
  t->Assert.deepEqual(struct->S.inline, `S.tuple0(.)`, ())
})

test("Supports Tuple", t => {
  let struct = S.tuple3(. S.string(), S.int(), S.bool())
  let structInlineResult = S.tuple3(. S.string(), S.int(), S.bool())

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(struct->S.inline, `S.tuple3(. S.string(), S.int(), S.bool())`, ())
})

test("Supports Tuple with 10 items", t => {
  let struct = S.tuple10(.
    S.string(),
    S.int(),
    S.bool(),
    S.string(),
    S.int(),
    S.bool(),
    S.string(),
    S.int(),
    S.bool(),
    S.string(),
  )
  let structInlineResult = S.tuple10(.
    S.string(),
    S.int(),
    S.bool(),
    S.string(),
    S.int(),
    S.bool(),
    S.string(),
    S.int(),
    S.bool(),
    S.string(),
  )

  t->assertEqualStructs(struct, structInlineResult, ())
  t->Assert.deepEqual(
    struct->S.inline,
    `S.tuple10(. S.string(), S.int(), S.bool(), S.string(), S.int(), S.bool(), S.string(), S.int(), S.bool(), S.string())`,
    (),
  )
})

test("Fails to inline Tuple with 11 items", t => {
  let struct = S.Tuple.factory(.
    S.string(),
    S.int(),
    S.bool(),
    S.string(),
    S.int(),
    S.bool(),
    S.string(),
    S.int(),
    S.bool(),
    S.string(),
    S.string(),
  )

  t->Assert.throws(
    () => {
      struct->S.inline
    },
    ~expectations={
      message: "[rescript-struct] The S.inline doesn\'t support tuples with more than 10 items.",
    },
    (),
  )
})

test("Supports Union", t => {
  let struct = S.union([S.literal(String("yes")), S.literal(String("no"))])
  let structInlineResult = S.union([
    S.literalVariant(String("yes"), #yes),
    S.literalVariant(String("no"), #no),
  ])

  structInlineResult->(Obj.magic: S.t<[#yes | #no]> => unit)

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.literalVariant(String("yes"), #"yes"), S.literalVariant(String("no"), #"no")])`,
    (),
  )
})

test("Uses S.literalVariant for all literals inside of union", t => {
  let struct = S.union([
    S.literalVariant(String("yes"), ()),
    S.literalVariant(Bool(true), ()),
    S.literalVariant(Bool(false), ()),
    S.literalVariant(Int(123), ()),
    S.literalVariant(Float(123.), ()),
    S.literalVariant(Float(123.456), ()),
    S.literalVariant(EmptyNull, ()),
    S.literalVariant(EmptyOption, ()),
    S.literalVariant(NaN, ()),
  ])
  let structInlineResult = S.union([
    S.literalVariant(String("yes"), #yes),
    S.literalVariant(Bool(true), #True),
    S.literalVariant(Bool(false), #False),
    S.literalVariant(Int(123), #123),
    S.literalVariant(Float(123.), #1232),
    S.literalVariant(Float(123.456), #"123.456"),
    S.literalVariant(EmptyNull, #EmptyNull),
    S.literalVariant(EmptyOption, #EmptyOption),
    S.literalVariant(NaN, #NaN),
  ])

  structInlineResult->(
    Obj.magic: S.t<
      [
        | #yes
        | #True
        | #False
        | #123
        | #1232
        | #"123.456"
        | #EmptyNull
        | #EmptyOption
        | #NaN
      ],
    > => unit
  )

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.literalVariant(String("yes"), #"yes"), S.literalVariant(Bool(true), #"True"), S.literalVariant(Bool(false), #"False"), S.literalVariant(Int(123), #"123"), S.literalVariant(Float(123.), #"1232"), S.literalVariant(Float(123.456), #"123.456"), S.literalVariant(EmptyNull, #"EmptyNull"), S.literalVariant(EmptyOption, #"EmptyOption"), S.literalVariant(NaN, #"NaN")])`,
    (),
  )
})

test("Supports description", t => {
  let struct = S.string()->S.describe("It's a string")
  t->Assert.deepEqual(struct->S.inline, `S.string()->S.describe("It's a string")`, ())
})

test("Uses S.transform for primitive structs inside of union", t => {
  let struct = S.union([
    S.string()->S.variant(v => #String(v)),
    S.bool()->S.variant(v => #Bool(v)),
    S.float()->S.variant(v => #Float(v)),
    S.int()->S.variant(v => #Int(v)),
    S.unknown()->S.variant(v => #Unknown(v)),
    S.never()->S.variant(v => #Never(v)),
    S.jsonable()->S.variant(v => #JSON(v)),
  ])

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.string()->S.variant(v => #"String"(v)), S.bool()->S.variant(v => #"Bool"(v)), S.float()->S.variant(v => #"Float"(v)), S.int()->S.variant(v => #"Int"(v)), S.unknown()->S.variant(v => #"Unknown"(v)), S.never()->S.variant(v => #"Never"(v)), S.jsonable()->S.variant(v => #"JSON"(v))])`,
    (),
  )
})

test("Adds index for the same structs inside of the union", t => {
  let struct = S.union([S.string(), S.string()])
  let structInlineResult = S.union([
    S.string()->S.variant(v => #String(v)),
    S.string()->S.variant(v => #String2(v)),
  ])

  structInlineResult->(
    Obj.magic: S.t<
      [
        | #String(string)
        | #String2(string)
      ],
    > => unit
  )

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.string()->S.variant(v => #"String"(v)), S.string()->S.variant(v => #"String2"(v))])`,
    (),
  )
})

test("Supports Object (ignores transformations)", t => {
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

test("Supports Object.strip", t => {
  let struct = S.object(_ => ())->S.Object.strip
  t->Assert.deepEqual(struct->S.inline, `S.object(_ => ())`, ())
})

test("Supports Object.strict", t => {
  let struct = S.object(_ => ())->S.Object.strict
  t->Assert.deepEqual(struct->S.inline, `S.object(_ => ())->S.Object.strict`, ())
})

test("Supports empty Object (ignores transformations)", t => {
  let struct = S.object(_ => 123)
  let structInlineResult = S.object(_ => ())

  t->assertEqualStructs(struct, structInlineResult->(Obj.magic: S.t<unit> => S.t<int>), ())
  t->Assert.deepEqual(struct->S.inline, `S.object(_ => ())`, ())
})

test("Supports empty Object in union", t => {
  let struct = S.union([S.object(_ => ()), S.object(_ => ())])
  let structInlineResult = S.union([
    S.object(_ => ())->S.variant(v => #EmptyObject(v)),
    S.object(_ => ())->S.variant(v => #EmptyObject2(v)),
  ])

  structInlineResult->(Obj.magic: S.t<[#EmptyObject(unit) | #EmptyObject2(unit)]> => unit)

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.object(_ => ())->S.variant(v => #"EmptyObject"(v)), S.object(_ => ())->S.variant(v => #"EmptyObject2"(v))])`,
    (),
  )
})

test("Supports empty Tuple in union", t => {
  let struct = S.union([S.tuple0(.), S.tuple0(.)])
  let structInlineResult = S.union([
    S.tuple0(.)->S.variant(v => #EmptyTuple(v)),
    S.tuple0(.)->S.variant(v => #EmptyTuple2(v)),
  ])

  structInlineResult->(Obj.magic: S.t<[#EmptyTuple(unit) | #EmptyTuple2(unit)]> => unit)

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.tuple0(.)->S.variant(v => #"EmptyTuple"(v)), S.tuple0(.)->S.variant(v => #"EmptyTuple2"(v))])`,
    (),
  )
})

test("Supports Option structs in union", t => {
  let struct = S.union([S.option(S.literalVariant(String("123"), 123.)), S.option(S.float())])
  let structInlineResult = S.union([
    S.option(S.literal(String("123")))->S.variant(v => #OptionOf123(v)),
    S.option(S.float())->S.variant(v => #OptionOfFloat(v)),
  ])

  structInlineResult->(
    Obj.magic: S.t<
      [
        | #OptionOf123(option<string>)
        | #OptionOfFloat(option<float>)
      ],
    > => unit
  )

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.option(S.literal(String("123")))->S.variant(v => #"OptionOf123"(v)), S.option(S.float())->S.variant(v => #"OptionOfFloat"(v))])`,
    (),
  )
})

test("Supports Null structs in union", t => {
  let struct = S.union([S.null(S.literalVariant(String("123"), 123.)), S.null(S.float())])
  let structInlineResult = S.union([
    S.null(S.literal(String("123")))->S.variant(v => #NullOf123(v)),
    S.null(S.float())->S.variant(v => #NullOfFloat(v)),
  ])

  structInlineResult->(
    Obj.magic: S.t<
      [
        | #NullOf123(option<string>)
        | #NullOfFloat(option<float>)
      ],
    > => unit
  )

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.null(S.literal(String("123")))->S.variant(v => #"NullOf123"(v)), S.null(S.float())->S.variant(v => #"NullOfFloat"(v))])`,
    (),
  )
})

test("Supports Array structs in union", t => {
  let struct = S.union([S.array(S.literalVariant(String("123"), 123.)), S.array(S.float())])
  let structInlineResult = S.union([
    S.array(S.literal(String("123")))->S.variant(v => #ArrayOf123(v)),
    S.array(S.float())->S.variant(v => #ArrayOfFloat(v)),
  ])

  structInlineResult->(
    Obj.magic: S.t<
      [
        | #ArrayOf123(array<string>)
        | #ArrayOfFloat(array<float>)
      ],
    > => unit
  )

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.array(S.literal(String("123")))->S.variant(v => #"ArrayOf123"(v)), S.array(S.float())->S.variant(v => #"ArrayOfFloat"(v))])`,
    (),
  )
})

test("Supports Dict structs in union", t => {
  let struct = S.union([S.dict(S.literalVariant(String("123"), 123.)), S.dict(S.float())])
  let structInlineResult = S.union([
    S.dict(S.literal(String("123")))->S.variant(v => #DictOf123(v)),
    S.dict(S.float())->S.variant(v => #DictOfFloat(v)),
  ])

  structInlineResult->(
    Obj.magic: S.t<
      [
        | #DictOf123(Js.Dict.t<string>)
        | #DictOfFloat(Js.Dict.t<float>)
      ],
    > => unit
  )

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.dict(S.literal(String("123")))->S.variant(v => #"DictOf123"(v)), S.dict(S.float())->S.variant(v => #"DictOfFloat"(v))])`,
    (),
  )
})

test("Supports Object structs in union", t => {
  let struct = S.union([
    S.object(o => o->S.field("field", S.literalVariant(String("123"), 123.))),
    S.object(o => o->S.field("field", S.float())),
  ])
  let structInlineResult = S.union([
    S.object(o =>
      {
        "field": o->S.field("field", S.literal(String("123"))),
      }
    )->S.variant(v => #Object(v)),
    S.object(o =>
      {
        "field": o->S.field("field", S.float()),
      }
    )->S.variant(v => #Object2(v)),
  ])

  structInlineResult->(
    Obj.magic: S.t<
      [
        | #Object({"field": string})
        | #Object2({"field": float})
      ],
    > => unit
  )

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.object(o =>
  {
    "field": o->S.field("field", S.literal(String("123"))),
  }
)->S.variant(v => #"Object"(v)), S.object(o =>
  {
    "field": o->S.field("field", S.float()),
  }
)->S.variant(v => #"Object2"(v))])`,
    (),
  )
})

test("Supports Tuple structs in union", t => {
  let struct = S.union([S.tuple1(. S.literalVariant(String("123"), 123.)), S.tuple1(. S.float())])
  let structInlineResult = S.union([
    S.tuple1(. S.literal(String("123")))->S.variant(v => #Tuple(v)),
    S.tuple1(. S.float())->S.variant(v => #Tuple2(v)),
  ])

  structInlineResult->(
    Obj.magic: S.t<
      [
        | #Tuple(string)
        | #Tuple2(float)
      ],
    > => unit
  )

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.tuple1(. S.literal(String("123")))->S.variant(v => #"Tuple"(v)), S.tuple1(. S.float())->S.variant(v => #"Tuple2"(v))])`,
    (),
  )
})

test("Supports Union structs in union", t => {
  let struct = S.union([
    S.union([S.literal(String("red")), S.literal(String("blue"))]),
    S.union([S.literalVariant(Int(0), "black"), S.literalVariant(Int(1), "white")]),
  ])
  let structInlineResult = S.union([
    S.union([
      S.literalVariant(String("red"), #red),
      S.literalVariant(String("blue"), #blue),
    ])->S.variant(v => #Union(v)),
    S.union([S.literalVariant(Int(0), #0), S.literalVariant(Int(1), #1)])->S.variant(v =>
      #Union2(v)
    ),
  ])

  structInlineResult->(Obj.magic: S.t<[#Union([#red | #blue]) | #Union2([#0 | #1])]> => unit)

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.union([S.literalVariant(String("red"), #"red"), S.literalVariant(String("blue"), #"blue")])->S.variant(v => #"Union"(v)), S.union([S.literalVariant(Int(0), #"0"), S.literalVariant(Int(1), #"1")])->S.variant(v => #"Union2"(v))])`,
    (),
  )
})

// TODO: Add support for recursive struct.
// TODO: Add support for list.
