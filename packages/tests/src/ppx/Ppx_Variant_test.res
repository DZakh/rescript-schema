open Ava
open U

@schema
type variant = One | Two
test("Variant", t => {
  t->assertEqualSchemas(variantSchema, S.union([S.literal(One), S.literal(Two)]))
})

@schema
type variantWithSingleItem = Single
test("Variant with single item becomes a literal schema of the item", t => {
  t->assertEqualSchemas(variantWithSingleItemSchema, S.literal(Single))
})

@schema
type variantWithAlias = | @as(`하나`) One | Two
test("Variant with partial @as usage", t => {
  t->assertEqualSchemas(variantWithAliasSchema, S.union([S.literal(One), S.literal(Two)]))
})

// TODO: Support
// @schema
// type variantWithPayloads = Constant | SinglePayload(int)
// test("Variant with tuple payloads", t => {
//   t->assertEqualSchemas(
//     variantWithPayloadsSchema,
//     S.union([S.literal(Constant), S.unknown->Obj.magic]),
//   )
// })

// TODO: Support @unboxed
// TODO: Support @tag
