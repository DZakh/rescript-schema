open Ava
open TestUtils

@struct
type variant = One | Two
test("Variant", t => {
  t->assertEqualStructs(
    variantStruct,
    S.union([S.literalVariant(String("One"), One), S.literalVariant(String("Two"), Two)]),
    (),
  )
})

@struct
type variantWithSingleItem = Single
test("Variant with single item becomes a literal struct of the item", t => {
  t->assertEqualStructs(variantWithSingleItemStruct, S.literalVariant(String("Single"), Single), ())
})

@struct
type variantWithAlias = | @struct.as(`하나`) One | Two
test("Variant with partial @as usage", t => {
  t->assertEqualStructs(
    variantWithAliasStruct,
    S.union([S.literalVariant(String("하나"), One), S.literalVariant(String("Two"), Two)]),
    (),
  )
})

// TODO: Support
// type variantWithPayloads = One | Two(int) | Three(bool)
// TODO: Support @unboxed
// TODO: Support @tag
