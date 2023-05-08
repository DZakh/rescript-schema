open Ava
open TestUtils

@struct
type simpleRecord = {
  label: string,
  value: int,
}
test("Simple record struct", t => {
  t->assertEqualStructs(
    simpleRecordStruct,
    S.object(o => {
      label: o.field("label", S.string),
      value: o.field("value", S.int),
    }),
    (),
  )
  t->Assert.deepEqual(
    %raw(`{label:"foo",value:1}`)->S.parseWith(simpleRecordStruct),
    Ok({label: "foo", value: 1}),
    (),
  )
})

@struct
type recordWithAlias = {
  @struct.field("aliased-label") label: string,
  value: int,
}
test("Record struct with alias for field name", t => {
  t->assertEqualStructs(
    recordWithAliasStruct,
    S.object(o => {
      label: o.field("aliased-label", S.string),
      value: o.field("value", S.int),
    }),
    (),
  )
  t->Assert.deepEqual(
    %raw(`{"aliased-label":"foo",value:1}`)->S.parseWith(recordWithAliasStruct),
    Ok({label: "foo", value: 1}),
    (),
  )
})

@struct
type recordWithOptional = {
  label: option<string>,
  value?: int,
}
test("Record struct with optional fields", t => {
  t->assertEqualStructs(
    recordWithOptionalStruct,
    S.object(o => {
      label: o.field("label", S.option(S.string)),
      value: ?o.field("value", S.option(S.int)),
    }),
    (),
  )
  t->Assert.deepEqual(
    %raw(`{"label":"foo",value:1}`)->S.parseWith(recordWithOptionalStruct),
    Ok({label: Some("foo"), value: 1}),
    (),
  )
  t->Assert.deepEqual(
    %raw(`{}`)->S.parseWith(recordWithOptionalStruct),
    Ok({label: %raw("undefined"), value: %raw("undefined")}),
    (),
  )
})

// TODO: Support object type
