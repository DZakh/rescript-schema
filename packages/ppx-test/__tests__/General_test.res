open Ava
open TestUtils

@struct
type t = string
test("Creates struct with the name struct from t type", t => {
  t->assertEqualStructs(struct, S.string, ())
})

@struct
type foo = int
test("Creates struct with the type name and struct at the for non t types", t => {
  t->assertEqualStructs(fooStruct, S.int, ())
})

type bar = bool

@struct
type reusedTypes = (t, foo, @struct(S.bool) bar, float)
test("Can reuse structs from other types", t => {
  t->assertEqualStructs(reusedTypesStruct, S.tuple4(struct, fooStruct, S.bool, S.float), ())
})

// TODO: Support recursive structs
