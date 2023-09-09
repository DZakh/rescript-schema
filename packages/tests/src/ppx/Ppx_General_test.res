open Ava
open U

@struct
type t = string
test("Creates struct with the name struct from t type", t => {
  t->assertEqualStructs(struct, S.string)
})

@struct
type foo = int
test("Creates struct with the type name and struct at the for non t types", t => {
  t->assertEqualStructs(fooStruct, S.int)
})

type bar = bool

@struct
type reusedTypes = (t, foo, @struct(S.bool) bar, float)
test("Can reuse structs from other types", t => {
  t->assertEqualStructs(
    reusedTypesStruct,
    S.tuple(s => (s.item(0, struct), s.item(1, fooStruct), s.item(2, S.bool), s.item(3, S.float))),
  )
})

// TODO: Support recursive structs
