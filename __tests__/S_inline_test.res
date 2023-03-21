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

test("Supports Int", t => {
  let struct = S.int()
  t->Assert.deepEqual(struct->S.inline, `S.int()`, ())
})

test("Supports Float", t => {
  let struct = S.float()
  t->Assert.deepEqual(struct->S.inline, `S.float()`, ())
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
    ~parser=(. ~unknown as _) => {
      S.Error.raise("User error")
    },
    (),
  )
  t->Assert.deepEqual(struct->S.inline, `S.unknown()`, ())
})

test("Supports Never", t => {
  let struct = S.never()
  t->Assert.deepEqual(struct->S.inline, `S.never()`, ())
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

test("Supports Null", t => {
  let struct = S.null(S.string())
  t->Assert.deepEqual(struct->S.inline, `S.null(S.string())`, ())
})

test("Supports Array", t => {
  let struct = S.array(S.string())
  t->Assert.deepEqual(struct->S.inline, `S.array(S.string())`, ())
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

test("Uses S.transform for primitive structs inside of union", t => {
  let struct = S.union([
    S.string()->S.transform(~parser=d => #String(d), ()),
    S.bool()->S.transform(~parser=d => #Bool(d), ()),
    S.float()->S.transform(~parser=d => #Float(d), ()),
    S.int()->S.transform(~parser=d => #Int(d), ()),
    S.unknown()->S.transform(~parser=d => #Unknown(d), ()),
    S.never()->S.transform(~parser=d => #Never(d), ()),
  ])
  let structInlineResult = S.union([
    S.string()->S.transform(
      ~parser=d => #String(d),
      ~serializer=v =>
        switch v {
        | #String(d) => d
        | _ => S.Error.raise(`Value is not the #"String" variant.`)
        },
      (),
    ),
    S.bool()->S.transform(
      ~parser=d => #Bool(d),
      ~serializer=v =>
        switch v {
        | #Bool(d) => d
        | _ => S.Error.raise(`Value is not the #"Bool" variant.`)
        },
      (),
    ),
    S.float()->S.transform(
      ~parser=d => #Float(d),
      ~serializer=v =>
        switch v {
        | #Float(d) => d
        | _ => S.Error.raise(`Value is not the #"Float" variant.`)
        },
      (),
    ),
    S.int()->S.transform(
      ~parser=d => #Int(d),
      ~serializer=v =>
        switch v {
        | #Int(d) => d
        | _ => S.Error.raise(`Value is not the #"Int" variant.`)
        },
      (),
    ),
    S.unknown()->S.transform(
      ~parser=d => #Unknown(d),
      ~serializer=v =>
        switch v {
        | #Unknown(d) => d
        | _ => S.Error.raise(`Value is not the #"Unknown" variant.`)
        },
      (),
    ),
    S.never()->S.transform(
      ~parser=d => #Never(d),
      ~serializer=v =>
        switch v {
        | #Never(d) => d
        | _ => S.Error.raise(`Value is not the #"Never" variant.`)
        },
      (),
    ),
  ])

  structInlineResult->(
    Obj.magic: S.t<
      [
        | #String(string)
        | #Bool(bool)
        | #Float(float)
        | #Int(int)
        | #Unknown(unknown)
        | #Never(S.never)
      ],
    > => unit
  )

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.string()->S.transform(
  ~parser=d => #"String"(d),
  ~serializer=v => switch v {
| #"String"(d) => d
| _ => S.Error.raise(\`Value is not the #"String" variant.\`)
}, ()), S.bool()->S.transform(
  ~parser=d => #"Bool"(d),
  ~serializer=v => switch v {
| #"Bool"(d) => d
| _ => S.Error.raise(\`Value is not the #"Bool" variant.\`)
}, ()), S.float()->S.transform(
  ~parser=d => #"Float"(d),
  ~serializer=v => switch v {
| #"Float"(d) => d
| _ => S.Error.raise(\`Value is not the #"Float" variant.\`)
}, ()), S.int()->S.transform(
  ~parser=d => #"Int"(d),
  ~serializer=v => switch v {
| #"Int"(d) => d
| _ => S.Error.raise(\`Value is not the #"Int" variant.\`)
}, ()), S.unknown()->S.transform(
  ~parser=d => #"Unknown"(d),
  ~serializer=v => switch v {
| #"Unknown"(d) => d
| _ => S.Error.raise(\`Value is not the #"Unknown" variant.\`)
}, ()), S.never()->S.transform(
  ~parser=d => #"Never"(d),
  ~serializer=v => switch v {
| #"Never"(d) => d
| _ => S.Error.raise(\`Value is not the #"Never" variant.\`)
}, ())])`,
    (),
  )
})

test("Adds index for the same structs inside of the union", t => {
  let struct = S.union([S.string(), S.string()])
  let structInlineResult = S.union([
    S.string()->S.transform(
      ~parser=d => #String(d),
      ~serializer=v =>
        switch v {
        | #String(d) => d
        | _ => S.Error.raise(`Value is not the #"String" variant.`)
        },
      (),
    ),
    S.string()->S.transform(
      ~parser=d => #String2(d),
      ~serializer=v =>
        switch v {
        | #String2(d) => d
        | _ => S.Error.raise(`Value is not the #"String2" variant.`)
        },
      (),
    ),
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
    `S.union([S.string()->S.transform(
  ~parser=d => #"String"(d),
  ~serializer=v => switch v {
| #"String"(d) => d
| _ => S.Error.raise(\`Value is not the #"String" variant.\`)
}, ()), S.string()->S.transform(
  ~parser=d => #"String2"(d),
  ~serializer=v => switch v {
| #"String2"(d) => d
| _ => S.Error.raise(\`Value is not the #"String2" variant.\`)
}, ())])`,
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

test("Supports empty Object (ignores transformations)", t => {
  let struct = S.object(_ => 123)
  let structInlineResult = S.object(_ => ())

  t->assertEqualStructs(struct, structInlineResult->(Obj.magic: S.t<unit> => S.t<int>), ())
  t->Assert.deepEqual(struct->S.inline, `S.object(_ => ())`, ())
})

test("Supports empty Object in union", t => {
  let struct = S.union([S.object(_ => ()), S.object(_ => ())])
  let structInlineResult = S.union([
    S.object(_ => ())->S.transform(
      ~parser=d => #EmptyObject(d),
      ~serializer=v =>
        switch v {
        | #EmptyObject(d) => d
        | _ => S.Error.raise(`Value is not the #"EmptyObject" variant.`)
        },
      (),
    ),
    S.object(_ => ())->S.transform(
      ~parser=d => #EmptyObject2(d),
      ~serializer=v =>
        switch v {
        | #EmptyObject2(d) => d
        | _ => S.Error.raise(`Value is not the #"EmptyObject2" variant.`)
        },
      (),
    ),
  ])

  structInlineResult->(Obj.magic: S.t<[#EmptyObject(unit) | #EmptyObject2(unit)]> => unit)

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.object(_ => ())->S.transform(
  ~parser=d => #"EmptyObject"(d),
  ~serializer=v => switch v {
| #"EmptyObject"(d) => d
| _ => S.Error.raise(\`Value is not the #"EmptyObject" variant.\`)
}, ()), S.object(_ => ())->S.transform(
  ~parser=d => #"EmptyObject2"(d),
  ~serializer=v => switch v {
| #"EmptyObject2"(d) => d
| _ => S.Error.raise(\`Value is not the #"EmptyObject2" variant.\`)
}, ())])`,
    (),
  )
})

test("Supports empty Tuple in union", t => {
  let struct = S.union([S.tuple0(.), S.tuple0(.)])
  let structInlineResult = S.union([
    S.tuple0(.)->S.transform(
      ~parser=d => #EmptyTuple(d),
      ~serializer=v =>
        switch v {
        | #EmptyTuple(d) => d
        | _ => S.Error.raise(`Value is not the #"EmptyTuple" variant.`)
        },
      (),
    ),
    S.tuple0(.)->S.transform(
      ~parser=d => #EmptyTuple2(d),
      ~serializer=v =>
        switch v {
        | #EmptyTuple2(d) => d
        | _ => S.Error.raise(`Value is not the #"EmptyTuple2" variant.`)
        },
      (),
    ),
  ])

  structInlineResult->(Obj.magic: S.t<[#EmptyTuple(unit) | #EmptyTuple2(unit)]> => unit)

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.tuple0(.)->S.transform(
  ~parser=d => #"EmptyTuple"(d),
  ~serializer=v => switch v {
| #"EmptyTuple"(d) => d
| _ => S.Error.raise(\`Value is not the #"EmptyTuple" variant.\`)
}, ()), S.tuple0(.)->S.transform(
  ~parser=d => #"EmptyTuple2"(d),
  ~serializer=v => switch v {
| #"EmptyTuple2"(d) => d
| _ => S.Error.raise(\`Value is not the #"EmptyTuple2" variant.\`)
}, ())])`,
    (),
  )
})

test("Supports Option structs in union", t => {
  let struct = S.union([S.option(S.literalVariant(String("123"), 123.)), S.option(S.float())])
  let structInlineResult = S.union([
    S.option(S.literal(String("123")))->S.transform(
      ~parser=d => #OptionOf123(d),
      ~serializer=v =>
        switch v {
        | #OptionOf123(d) => d
        | _ => S.Error.raise(`Value is not the #"OptionOf123" variant.`)
        },
      (),
    ),
    S.option(S.float())->S.transform(
      ~parser=d => #OptionOfFloat(d),
      ~serializer=v =>
        switch v {
        | #OptionOfFloat(d) => d
        | _ => S.Error.raise(`Value is not the #"OptionOfFloat" variant.`)
        },
      (),
    ),
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
    `S.union([S.option(S.literal(String("123")))->S.transform(
  ~parser=d => #"OptionOf123"(d),
  ~serializer=v => switch v {
| #"OptionOf123"(d) => d
| _ => S.Error.raise(\`Value is not the #"OptionOf123" variant.\`)
}, ()), S.option(S.float())->S.transform(
  ~parser=d => #"OptionOfFloat"(d),
  ~serializer=v => switch v {
| #"OptionOfFloat"(d) => d
| _ => S.Error.raise(\`Value is not the #"OptionOfFloat" variant.\`)
}, ())])`,
    (),
  )
})

test("Supports Null structs in union", t => {
  let struct = S.union([S.null(S.literalVariant(String("123"), 123.)), S.null(S.float())])
  let structInlineResult = S.union([
    S.null(S.literal(String("123")))->S.transform(
      ~parser=d => #NullOf123(d),
      ~serializer=v =>
        switch v {
        | #NullOf123(d) => d
        | _ => S.Error.raise(`Value is not the #"NullOf123" variant.`)
        },
      (),
    ),
    S.null(S.float())->S.transform(
      ~parser=d => #NullOfFloat(d),
      ~serializer=v =>
        switch v {
        | #NullOfFloat(d) => d
        | _ => S.Error.raise(`Value is not the #"NullOfFloat" variant.`)
        },
      (),
    ),
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
    `S.union([S.null(S.literal(String("123")))->S.transform(
  ~parser=d => #"NullOf123"(d),
  ~serializer=v => switch v {
| #"NullOf123"(d) => d
| _ => S.Error.raise(\`Value is not the #"NullOf123" variant.\`)
}, ()), S.null(S.float())->S.transform(
  ~parser=d => #"NullOfFloat"(d),
  ~serializer=v => switch v {
| #"NullOfFloat"(d) => d
| _ => S.Error.raise(\`Value is not the #"NullOfFloat" variant.\`)
}, ())])`,
    (),
  )
})

test("Supports Array structs in union", t => {
  let struct = S.union([S.array(S.literalVariant(String("123"), 123.)), S.array(S.float())])
  let structInlineResult = S.union([
    S.array(S.literal(String("123")))->S.transform(
      ~parser=d => #ArrayOf123(d),
      ~serializer=v =>
        switch v {
        | #ArrayOf123(d) => d
        | _ => S.Error.raise(`Value is not the #"ArrayOf123" variant.`)
        },
      (),
    ),
    S.array(S.float())->S.transform(
      ~parser=d => #ArrayOfFloat(d),
      ~serializer=v =>
        switch v {
        | #ArrayOfFloat(d) => d
        | _ => S.Error.raise(`Value is not the #"ArrayOfFloat" variant.`)
        },
      (),
    ),
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
    `S.union([S.array(S.literal(String("123")))->S.transform(
  ~parser=d => #"ArrayOf123"(d),
  ~serializer=v => switch v {
| #"ArrayOf123"(d) => d
| _ => S.Error.raise(\`Value is not the #"ArrayOf123" variant.\`)
}, ()), S.array(S.float())->S.transform(
  ~parser=d => #"ArrayOfFloat"(d),
  ~serializer=v => switch v {
| #"ArrayOfFloat"(d) => d
| _ => S.Error.raise(\`Value is not the #"ArrayOfFloat" variant.\`)
}, ())])`,
    (),
  )
})

test("Supports Dict structs in union", t => {
  let struct = S.union([S.dict(S.literalVariant(String("123"), 123.)), S.dict(S.float())])
  let structInlineResult = S.union([
    S.dict(S.literal(String("123")))->S.transform(
      ~parser=d => #DictOf123(d),
      ~serializer=v =>
        switch v {
        | #DictOf123(d) => d
        | _ => S.Error.raise(`Value is not the #"DictOf123" variant.`)
        },
      (),
    ),
    S.dict(S.float())->S.transform(
      ~parser=d => #DictOfFloat(d),
      ~serializer=v =>
        switch v {
        | #DictOfFloat(d) => d
        | _ => S.Error.raise(`Value is not the #"DictOfFloat" variant.`)
        },
      (),
    ),
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
    `S.union([S.dict(S.literal(String("123")))->S.transform(
  ~parser=d => #"DictOf123"(d),
  ~serializer=v => switch v {
| #"DictOf123"(d) => d
| _ => S.Error.raise(\`Value is not the #"DictOf123" variant.\`)
}, ()), S.dict(S.float())->S.transform(
  ~parser=d => #"DictOfFloat"(d),
  ~serializer=v => switch v {
| #"DictOfFloat"(d) => d
| _ => S.Error.raise(\`Value is not the #"DictOfFloat" variant.\`)
}, ())])`,
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
    )->S.transform(
      ~parser=d => #Object(d),
      ~serializer=v =>
        switch v {
        | #Object(d) => d
        | _ => S.Error.raise(`Value is not the #"Object" variant.`)
        },
      (),
    ),
    S.object(o =>
      {
        "field": o->S.field("field", S.float()),
      }
    )->S.transform(
      ~parser=d => #Object2(d),
      ~serializer=v =>
        switch v {
        | #Object2(d) => d
        | _ => S.Error.raise(`Value is not the #"Object2" variant.`)
        },
      (),
    ),
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
)->S.transform(
  ~parser=d => #"Object"(d),
  ~serializer=v => switch v {
| #"Object"(d) => d
| _ => S.Error.raise(\`Value is not the #"Object" variant.\`)
}, ()), S.object(o =>
  {
    "field": o->S.field("field", S.float()),
  }
)->S.transform(
  ~parser=d => #"Object2"(d),
  ~serializer=v => switch v {
| #"Object2"(d) => d
| _ => S.Error.raise(\`Value is not the #"Object2" variant.\`)
}, ())])`,
    (),
  )
})

test("Supports Tuple structs in union", t => {
  let struct = S.union([S.tuple1(. S.literalVariant(String("123"), 123.)), S.tuple1(. S.float())])
  let structInlineResult = S.union([
    S.tuple1(. S.literal(String("123")))->S.transform(
      ~parser=d => #Tuple(d),
      ~serializer=v =>
        switch v {
        | #Tuple(d) => d
        | _ => S.Error.raise(`Value is not the #"Tuple" variant.`)
        },
      (),
    ),
    S.tuple1(. S.float())->S.transform(
      ~parser=d => #Tuple2(d),
      ~serializer=v =>
        switch v {
        | #Tuple2(d) => d
        | _ => S.Error.raise(`Value is not the #"Tuple2" variant.`)
        },
      (),
    ),
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
    `S.union([S.tuple1(. S.literal(String("123")))->S.transform(
  ~parser=d => #"Tuple"(d),
  ~serializer=v => switch v {
| #"Tuple"(d) => d
| _ => S.Error.raise(\`Value is not the #"Tuple" variant.\`)
}, ()), S.tuple1(. S.float())->S.transform(
  ~parser=d => #"Tuple2"(d),
  ~serializer=v => switch v {
| #"Tuple2"(d) => d
| _ => S.Error.raise(\`Value is not the #"Tuple2" variant.\`)
}, ())])`,
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
    ])->S.transform(
      ~parser=d => #Union(d),
      ~serializer=v =>
        switch v {
        | #Union(d) => d
        | _ => S.Error.raise(`Value is not the #"Union" variant.`)
        },
      (),
    ),
    S.union([S.literalVariant(Int(0), #0), S.literalVariant(Int(1), #1)])->S.transform(
      ~parser=d => #Union2(d),
      ~serializer=v =>
        switch v {
        | #Union2(d) => d
        | _ => S.Error.raise(`Value is not the #"Union2" variant.`)
        },
      (),
    ),
  ])

  structInlineResult->(Obj.magic: S.t<[#Union([#red | #blue]) | #Union2([#0 | #1])]> => unit)

  t->Assert.deepEqual(
    struct->S.inline,
    `S.union([S.union([S.literalVariant(String("red"), #"red"), S.literalVariant(String("blue"), #"blue")])->S.transform(
  ~parser=d => #"Union"(d),
  ~serializer=v => switch v {
| #"Union"(d) => d
| _ => S.Error.raise(\`Value is not the #"Union" variant.\`)
}, ()), S.union([S.literalVariant(Int(0), #"0"), S.literalVariant(Int(1), #"1")])->S.transform(
  ~parser=d => #"Union2"(d),
  ~serializer=v => switch v {
| #"Union2"(d) => d
| _ => S.Error.raise(\`Value is not the #"Union2" variant.\`)
}, ())])`,
    (),
  )
})
