open Ava
open U

@schema
type poly = [#one | #two]
test("Polymorphic variant", t => {
  t->assertEqualSchemas(polySchema, S.union([S.literal(#one), S.literal(#two)]))
})

@schema
type polyWithSingleItem = [#single]
test("Polymorphic variant with single item becomes a literal schema of the item", t => {
  t->assertEqualSchemas(polyWithSingleItemSchema, S.literal(#single))
})

@schema
type polyWithAlias = [@as(`하나`) #one | #two]
test("Polymorphic variant with partial @as usage", t => {
  t->assertEqualSchemas(polyWithAliasSchema, S.union([S.literal(#one), S.literal(#two)]))
})

// TODO: Support
// type polyWithPayloads = [#one | #two(int) | #three(bool)]
// TODO: Support
// type basicBlueTone<'a> = [> #Blue | #DeepBlue | #LightBlue] as 'a
// TODO: Support
// type polyWithInheritance = [poly | #three]
// TODO: Support poly as record/object fields
