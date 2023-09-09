open Ava
open U

@struct
type variant = One | Two
test("Variant", t => {
  t->assertEqualStructs(variantStruct, S.union([S.literal(One), S.literal(Two)]))
})

@struct
type variantWithSingleItem = Single
test("Variant with single item becomes a literal struct of the item", t => {
  t->assertEqualStructs(variantWithSingleItemStruct, S.literal(Single))
})

@struct
type variantWithAlias = | @as(`하나`) One | Two
test("Variant with partial @as usage", t => {
  t->assertEqualStructs(variantWithAliasStruct, S.union([S.literal(One), S.literal(Two)]))
})

// TODO: Support
// type variantWithPayloads = One | Two(int) | Three(bool)
// TODO: Support @unboxed
// TODO: Support @tag
