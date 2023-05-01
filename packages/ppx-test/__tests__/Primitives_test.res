open Ava
open TestUtils

@struct
type myString = string
test("String struct", t => {
  t->assertEqualStructs(myStringStruct, S.string(), ())
})

@struct
type myInt = int
test("Int struct", t => {
  t->assertEqualStructs(myIntStruct, S.int(), ())
})

@struct
type myFloat = float
test("Float struct", t => {
  t->assertEqualStructs(myFloatStruct, S.float(), ())
})

@struct
type myBool = bool
test("Bool struct", t => {
  t->assertEqualStructs(myBoolStruct, S.bool(), ())
})

@struct
type myUnit = unit
test("Unit struct", t => {
  t->assertEqualStructs(myUnitStruct, S.unit(), ())
})

@struct
type myUnknown = unknown
test("Unknown struct", t => {
  t->assertEqualStructs(myUnknownStruct, S.unknown(), ())
})

@struct
type myNever = S.never
test("Never struct", t => {
  t->assertEqualStructs(myNeverStruct, S.never(), ())
})

@struct
type myOptionOfString = option<string>
test("Option of string struct", t => {
  t->assertEqualStructs(myOptionOfStringStruct, S.option(S.string()), ())
})

@struct
type myArrayOfString = array<string>
test("Array of string struct", t => {
  t->assertEqualStructs(myArrayOfStringStruct, S.array(S.string()), ())
})

@struct
type myListOfString = list<string>
test("List of string struct", t => {
  t->assertEqualStructs(myListOfStringStruct, S.list(S.string()), ())
})

@struct
type myDictOfString = Js.Dict.t<string>
test("Dict of string struct", t => {
  t->assertEqualStructs(myDictOfStringStruct, S.dict(S.string()), ())
})

@struct
type myDictOfStringFromCore = Dict.t<string>
test("Dict of string struct from Core", t => {
  t->assertEqualStructs(myDictOfStringFromCoreStruct, S.dict(S.string()), ())
})

@struct
type myJson = Js.Json.t
test("Json struct", t => {
  t->assertEqualStructs(myJsonStruct, S.jsonable(), ())
})

@struct
type myJsonFromCore = JSON.t
test("Json struct from Core", t => {
  t->assertEqualStructs(myJsonFromCoreStruct, S.jsonable(), ())
})

@struct
type myTuple = (string, int)
test("Tuple struct", t => {
  t->assertEqualStructs(myTupleStruct, S.tuple2(S.string(), S.int()), ())
})

@struct
type myBigTuple = (string, string, string, int, int, int, float, float, float, bool, bool, bool)
test("Big tuple struct", t => {
  t->assertEqualStructs(
    myBigTupleStruct,
    {
      S.Tuple.factory([
        S.string()->S.toUnknown,
        S.string()->S.toUnknown,
        S.string()->S.toUnknown,
        S.int()->S.toUnknown,
        S.int()->S.toUnknown,
        S.int()->S.toUnknown,
        S.float()->S.toUnknown,
        S.float()->S.toUnknown,
        S.float()->S.toUnknown,
        S.bool()->S.toUnknown,
        S.bool()->S.toUnknown,
        S.bool()->S.toUnknown,
      ])->(
        magic: S.t<array<unknown>> => S.t<(
          string,
          string,
          string,
          int,
          int,
          int,
          float,
          float,
          float,
          bool,
          bool,
          bool,
        )>
      )
    },
    (),
  )
})

@struct
type myCustomString = @struct(S.string()->S.String.email()) string
test("Custom string struct", t => {
  t->assertEqualStructs(myCustomStringStruct, S.string()->S.String.email(), ())
})

@struct
type myCustomLiteralString = @struct(S.literal(String("123"))->S.String.email()) string
test("Custom litaral string struct", t => {
  t->assertEqualStructs(myCustomLiteralStringStruct, S.literal(String("123"))->S.String.email(), ())
})

// @struct
// type myNullOfString = null<string>
// This will result with error:
// The incompatible parts: option<string> vs myNullOfString (defined as Js.null<string>)
// So use the code below instead
@struct
type myNullOfString = @struct(S.null(S.string())) option<string>
test("Null of string struct", t => {
  t->assertEqualStructs(myNullOfStringStruct, S.null(S.string()), ())
})
