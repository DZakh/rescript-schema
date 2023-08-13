open Ava
open U

@struct
type poly = [#one | #two]
test("Polymorphic variant", t => {
  t->assertEqualStructs(polyStruct, S.union([S.literal(#one), S.literal(#two)]), ())
})

@struct
type polyWithSingleItem = [#single]
test("Polymorphic variant with single item becomes a literal struct of the item", t => {
  t->assertEqualStructs(polyWithSingleItemStruct, S.literal(#single), ())
})

@struct
type polyWithAlias = [@as(`하나`) #one | #two]
test("Polymorphic variant with partial @as usage", t => {
  t->assertEqualStructs(polyWithAliasStruct, S.union([S.literal(#one), S.literal(#two)]), ())
})

// TODO: Support
// type polyWithPayloads = [#one | #two(int) | #three(bool)]
// TODO: Support
// type basicBlueTone<'a> = [> #Blue | #DeepBlue | #LightBlue] as 'a
// TODO: Support
// type polyWithInheritance = [poly | #three]
// TODO: Support poly as record/object fields
