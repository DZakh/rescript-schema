open Ava
open TestUtils

@struct
type poly = [#one | #two]
test("Polymorphic variant", t => {
  t->assertEqualStructs(
    polyStruct,
    S.union([S.literalVariant(String("one"), #one), S.literalVariant(String("two"), #two)]),
    (),
  )
})

@struct
type polyWithSingleItem = [#single]
test("Polymorphic variant with single item becomes a literal struct of the item", t => {
  t->assertEqualStructs(polyWithSingleItemStruct, S.literalVariant(String("single"), #single), ())
})

@struct
type polyWithAlias = [@struct.as(`하나`) #one | #two]
test("Polymorphic variant with partial @as usage", t => {
  t->assertEqualStructs(
    polyWithAliasStruct,
    S.union([S.literalVariant(String("하나"), #one), S.literalVariant(String("two"), #two)]),
    (),
  )
})

// TODO: Support
// type polyWithPayloads = [#one | #two(int) | #three(bool)]
// TODO: Support
// type basicBlueTone<'a> = [> #Blue | #DeepBlue | #LightBlue] as 'a
// TODO: Support
// type polyWithInheritance = [poly | #three]
// TODO: Support poly as record/object fields
