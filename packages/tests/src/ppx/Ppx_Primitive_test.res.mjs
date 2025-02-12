// Generated by ReScript, PLEASE EDIT WITH CARE

import * as U from "../utils/U.res.mjs";
import Ava from "ava";
import * as S$RescriptSchema from "rescript-schema/src/S.res.mjs";

Ava("String schema", (function (t) {
        U.assertEqualSchemas(t, S$RescriptSchema.string, S$RescriptSchema.string, undefined);
      }));

Ava("Int schema", (function (t) {
        U.assertEqualSchemas(t, S$RescriptSchema.$$int, S$RescriptSchema.$$int, undefined);
      }));

Ava("Float schema", (function (t) {
        U.assertEqualSchemas(t, S$RescriptSchema.$$float, S$RescriptSchema.$$float, undefined);
      }));

Ava("Bool schema", (function (t) {
        U.assertEqualSchemas(t, S$RescriptSchema.bool, S$RescriptSchema.bool, undefined);
      }));

Ava("Unit schema", (function (t) {
        U.assertEqualSchemas(t, S$RescriptSchema.unit, S$RescriptSchema.unit, undefined);
      }));

Ava("Unknown schema", (function (t) {
        U.assertEqualSchemas(t, S$RescriptSchema.unknown, S$RescriptSchema.unknown, undefined);
      }));

Ava("Never schema", (function (t) {
        U.assertEqualSchemas(t, S$RescriptSchema.never, S$RescriptSchema.never, undefined);
      }));

var myOptionOfStringSchema = S$RescriptSchema.option(S$RescriptSchema.string);

Ava("Option of string schema", (function (t) {
        U.assertEqualSchemas(t, myOptionOfStringSchema, S$RescriptSchema.option(S$RescriptSchema.string), undefined);
      }));

var myArrayOfStringSchema = S$RescriptSchema.array(S$RescriptSchema.string);

Ava("Array of string schema", (function (t) {
        U.assertEqualSchemas(t, myArrayOfStringSchema, S$RescriptSchema.array(S$RescriptSchema.string), undefined);
      }));

var myListOfStringSchema = S$RescriptSchema.list(S$RescriptSchema.string);

Ava("List of string schema", (function (t) {
        U.assertEqualSchemas(t, myListOfStringSchema, S$RescriptSchema.list(S$RescriptSchema.string), undefined);
      }));

var myDictOfStringSchema = S$RescriptSchema.dict(S$RescriptSchema.string);

Ava("Dict of string schema", (function (t) {
        U.assertEqualSchemas(t, myDictOfStringSchema, S$RescriptSchema.dict(S$RescriptSchema.string), undefined);
      }));

var myDictOfStringFromJsSchema = S$RescriptSchema.dict(S$RescriptSchema.string);

Ava("Dict of string schema from Js", (function (t) {
        U.assertEqualSchemas(t, myDictOfStringSchema, S$RescriptSchema.dict(S$RescriptSchema.string), undefined);
      }));

var myDictOfStringFromCoreSchema = S$RescriptSchema.dict(S$RescriptSchema.string);

Ava("Dict of string schema from Core", (function (t) {
        U.assertEqualSchemas(t, myDictOfStringFromCoreSchema, S$RescriptSchema.dict(S$RescriptSchema.string), undefined);
      }));

var myJsonSchema = S$RescriptSchema.json(true);

Ava("Json schema", (function (t) {
        U.assertEqualSchemas(t, myJsonSchema, S$RescriptSchema.json(true), undefined);
      }));

var myJsonFromCoreSchema = S$RescriptSchema.json(true);

Ava("Json schema from Core", (function (t) {
        U.assertEqualSchemas(t, myJsonFromCoreSchema, S$RescriptSchema.json(true), undefined);
      }));

var myTupleSchema = S$RescriptSchema.schema(function (s) {
      return [
              s.m(S$RescriptSchema.string),
              s.m(S$RescriptSchema.$$int)
            ];
    });

Ava("Tuple schema", (function (t) {
        U.assertEqualSchemas(t, myTupleSchema, S$RescriptSchema.tuple2(S$RescriptSchema.string, S$RescriptSchema.$$int), undefined);
      }));

var myBigTupleSchema = S$RescriptSchema.schema(function (s) {
      return [
              s.m(S$RescriptSchema.string),
              s.m(S$RescriptSchema.string),
              s.m(S$RescriptSchema.string),
              s.m(S$RescriptSchema.$$int),
              s.m(S$RescriptSchema.$$int),
              s.m(S$RescriptSchema.$$int),
              s.m(S$RescriptSchema.$$float),
              s.m(S$RescriptSchema.$$float),
              s.m(S$RescriptSchema.$$float),
              s.m(S$RescriptSchema.bool),
              s.m(S$RescriptSchema.bool),
              s.m(S$RescriptSchema.bool)
            ];
    });

Ava("Big tuple schema", (function (t) {
        U.assertEqualSchemas(t, myBigTupleSchema, S$RescriptSchema.tuple(function (s) {
                  return [
                          s.item(0, S$RescriptSchema.string),
                          s.item(1, S$RescriptSchema.string),
                          s.item(2, S$RescriptSchema.string),
                          s.item(3, S$RescriptSchema.$$int),
                          s.item(4, S$RescriptSchema.$$int),
                          s.item(5, S$RescriptSchema.$$int),
                          s.item(6, S$RescriptSchema.$$float),
                          s.item(7, S$RescriptSchema.$$float),
                          s.item(8, S$RescriptSchema.$$float),
                          s.item(9, S$RescriptSchema.bool),
                          s.item(10, S$RescriptSchema.bool),
                          s.item(11, S$RescriptSchema.bool)
                        ];
                }), undefined);
      }));

var myCustomStringSchema = S$RescriptSchema.email(S$RescriptSchema.string, undefined);

Ava("Custom string schema", (function (t) {
        U.assertEqualSchemas(t, myCustomStringSchema, S$RescriptSchema.email(S$RescriptSchema.string, undefined), undefined);
      }));

var myCustomLiteralStringSchema = S$RescriptSchema.email(S$RescriptSchema.literal("123"), undefined);

Ava("Custom litaral string schema", (function (t) {
        U.assertEqualSchemas(t, myCustomLiteralStringSchema, S$RescriptSchema.email(S$RescriptSchema.literal("123"), undefined), undefined);
      }));

var myCustomOptionalStringSchema = S$RescriptSchema.option(S$RescriptSchema.email(S$RescriptSchema.string, undefined));

Ava("Custom optional string schema", (function (t) {
        U.assertEqualSchemas(t, myCustomOptionalStringSchema, S$RescriptSchema.option(S$RescriptSchema.email(S$RescriptSchema.string, undefined)), undefined);
      }));

var myNullOfStringSchema = S$RescriptSchema.$$null(S$RescriptSchema.string);

Ava("Null of string schema", (function (t) {
        U.assertEqualSchemas(t, myNullOfStringSchema, S$RescriptSchema.$$null(S$RescriptSchema.string), undefined);
      }));

var myStringSchema = S$RescriptSchema.string;

var myIntSchema = S$RescriptSchema.$$int;

var myFloatSchema = S$RescriptSchema.$$float;

var myBoolSchema = S$RescriptSchema.bool;

var myUnitSchema = S$RescriptSchema.unit;

var myUnknownSchema = S$RescriptSchema.unknown;

var myNeverSchema = S$RescriptSchema.never;

export {
  myStringSchema ,
  myIntSchema ,
  myFloatSchema ,
  myBoolSchema ,
  myUnitSchema ,
  myUnknownSchema ,
  myNeverSchema ,
  myOptionOfStringSchema ,
  myArrayOfStringSchema ,
  myListOfStringSchema ,
  myDictOfStringSchema ,
  myDictOfStringFromJsSchema ,
  myDictOfStringFromCoreSchema ,
  myJsonSchema ,
  myJsonFromCoreSchema ,
  myTupleSchema ,
  myBigTupleSchema ,
  myCustomStringSchema ,
  myCustomLiteralStringSchema ,
  myCustomOptionalStringSchema ,
  myNullOfStringSchema ,
}
/*  Not a pure module */
