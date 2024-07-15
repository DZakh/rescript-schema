import * as S from './../src/S_Core.bs.mjs';

const Error = S.$$Error.$$class;
const string = S.string;
const boolean = S.bool;
const integer = S.$$int;
const number = S.$$float;
const json = S.json;
const never = S.never;
const unknown = S.unknown;
const undefined$1 = S.unit;
const optional = S.js_optional;
const nullable = S.$$null;
const nullish = S.nullable;
const array = S.array;
const record = S.dict;
const jsonString = S.jsonString;
const union = S.union;
const object = S.js_object;
const schema = S.schema;
const merge = S.js_merge;
const Object$1 = S.$$Object;
const custom = S.js_custom;
const literal = S.literal;
const tuple = S.js_tuple;
const asyncParserRefine = S.js_asyncParserRefine;
const refine = S.js_refine;
const transform = S.js_transform;
const description = S.description;
const describe = S.describe;
const name = S.js_name;
const setName = S.setName;

const integerMin = S.intMin;
const integerMax = S.intMax;
const port = S.port;

const numberMin = S.floatMin;
const numberMax = S.floatMax;

const arrayMinLength = S.arrayMinLength;
const arrayMaxLength = S.arrayMaxLength;
const arrayLength = S.arrayLength;

const stringMinLength = S.stringMinLength;
const stringMaxLength = S.stringMaxLength;
const stringLength = S.stringLength;
const email = S.email;
const uuid = S.uuid;
const cuid = S.cuid;
const url = S.url;
const pattern = S.pattern;
const datetime = S.datetime;
const trim = S.trim;

const setGlobalConfig = S.setGlobalConfig;

export { Error, Object$1 as Object, array, arrayLength, arrayMaxLength, arrayMinLength, asyncParserRefine, boolean, cuid, custom, datetime, describe, description, email, integer, integerMax, integerMin, json, jsonString, literal, merge, name, never, nullable, nullish, number, numberMax, numberMin, object, optional, pattern, port, record, refine, schema, setGlobalConfig, setName, string, stringLength, stringMaxLength, stringMinLength, transform, trim, tuple, undefined$1 as undefined, union, unknown, url, uuid };
