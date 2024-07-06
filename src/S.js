import * as S from "./S_Core.bs.mjs";

export const Error = S.$$Error.$$class;
export const string = S.string;
export const boolean = S.bool;
export const integer = S.$$int;
export const number = S.$$float;
export const json = S.json;
export const never = S.never;
export const unknown = S.unknown;
export const undefined = S.unit;
export const optional = S.js_optional;
export const nullable = S.$$null;
export const nullish = S.nullable;
export const array = S.array;
export const record = S.dict;
export const jsonString = S.jsonString;
export const union = S.union;
export const object = S.js_object;
export const schema = S.schema;
export const merge = S.js_merge;
export const Object = S.$$Object;
export const custom = S.js_custom;
export const literal = S.literal;
export const tuple = S.js_tuple;
export const asyncParserRefine = S.js_asyncParserRefine;
export const refine = S.js_refine;
export const transform = S.js_transform;
export const description = S.description;
export const describe = S.describe;
export const name = S.js_name;
export const setName = S.setName;

export const integerMin = S.intMin;
export const integerMax = S.intMax;
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
