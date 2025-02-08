import * as S from "./S_Core.res.mjs";

export const Error = S.$$Error.$$class;
export const string = S.string;
export const boolean = S.bool;
export const int32 = S.$$int;
export const number = S.$$float;
export const bigint = S.bigint;
export const json = S.json;
export const never = S.never;
export const unknown = S.unknown;
export const undefined = S.unit;
export const optional = S.js_optional;
export const nullable = S.$$null;
export const nullish = S.nullable;
export const array = S.array;
export const unnest = S.unnest;
export const record = S.dict;
export const jsonString = S.jsonString;
export const union = S.js_union;
export const object = S.object;
export const schema = S.js_schema;
export const safe = S.js_safe;
export const safeAsync = S.js_safeAsync;
export const reverse = S.reverse;
export const convertOrThrow = S.convertOrThrow;
export const convertToJsonOrThrow = S.convertToJsonOrThrow;
export const convertToJsonStringOrThrow = S.convertToJsonStringOrThrow;
export const reverseConvertOrThrow = S.reverseConvertOrThrow;
export const reverseConvertToJsonOrThrow = S.reverseConvertToJsonOrThrow;
export const reverseConvertToJsonStringOrThrow =
  S.reverseConvertToJsonStringOrThrow;
export const parseOrThrow = S.parseOrThrow;
export const parseJsonOrThrow = S.parseJsonOrThrow;
export const parseJsonStringOrThrow = S.parseJsonStringOrThrow;
export const parseAsyncOrThrow = S.parseAsyncOrThrow;
export const assertOrThrow = S.assertOrThrow;
export const recursive = S.recursive;
export const merge = S.js_merge;
export const strict = S.strict;
export const deepStrict = S.deepStrict;
export const strip = S.strip;
export const deepStrip = S.deepStrip;
export const custom = S.js_custom;
export const standard = S.standard;
export const tuple = S.tuple;
export const asyncParserRefine = S.js_asyncParserRefine;
export const refine = S.js_refine;
export const transform = S.js_transform;
export const description = S.description;
export const describe = S.describe;
export const name = S.js_name;
export const setName = S.setName;
export const removeTypeValidation = S.removeTypeValidation;
export const compile = S.compile;

export const port = S.port;

export const numberMin = S.floatMin;
export const numberMax = S.floatMax;

export const arrayMinLength = S.arrayMinLength;
export const arrayMaxLength = S.arrayMaxLength;
export const arrayLength = S.arrayLength;

export const stringMinLength = S.stringMinLength;
export const stringMaxLength = S.stringMaxLength;
export const stringLength = S.stringLength;
export const email = S.email;
export const uuid = S.uuid;
export const cuid = S.cuid;
export const url = S.url;
export const pattern = S.pattern;
export const datetime = S.datetime;
export const trim = S.trim;

export const setGlobalConfig = S.setGlobalConfig;
