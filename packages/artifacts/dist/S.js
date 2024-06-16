'use strict';

var S = require('./../src/S_Core.bs.js');

function _interopNamespaceDefault(e) {
	var n = Object.create(null);
	if (e) {
		Object.keys(e).forEach(function (k) {
			if (k !== 'default') {
				var d = Object.getOwnPropertyDescriptor(e, k);
				Object.defineProperty(n, k, d.get ? d : {
					enumerable: true,
					get: function () { return e[k]; }
				});
			}
		});
	}
	n.default = e;
	return Object.freeze(n);
}

var S__namespace = /*#__PURE__*/_interopNamespaceDefault(S);

const Error = S__namespace.$$Error.$$class;
const string = S__namespace.string;
const boolean = S__namespace.bool;
const integer = S__namespace.$$int;
const number = S__namespace.$$float;
const json = S__namespace.json;
const never = S__namespace.never;
const unknown = S__namespace.unknown;
const undefined$1 = S__namespace.unit;
const optional = S__namespace.js_optional;
const nullable = S__namespace.$$null;
const nullish = S__namespace.nullable;
const array = S__namespace.array;
const record = S__namespace.dict;
const jsonString = S__namespace.jsonString;
const union = S__namespace.union;
const object = S__namespace.js_object;
const schema = S__namespace.schema;
const merge = S__namespace.js_merge;
const Object$1 = S__namespace.$$Object;
const custom = S__namespace.js_custom;
const literal = S__namespace.literal;
const tuple = S__namespace.js_tuple;
const asyncParserRefine = S__namespace.js_asyncParserRefine;
const refine = S__namespace.js_refine;
const transform = S__namespace.js_transform;
const description = S__namespace.description;
const describe = S__namespace.describe;
const parse = S__namespace.js_parse;
const parseOrThrow = S__namespace.js_parseOrThrow;
const parseAsync = S__namespace.js_parseAsync;
const serialize = S__namespace.js_serialize;
const serializeOrThrow = S__namespace.js_serializeOrThrow;
const name = S__namespace.js_name;
const setName = S__namespace.setName;

const integerMin = S__namespace.intMin;
const integerMax = S__namespace.intMax;
const port = S__namespace.port;

const numberMin = S__namespace.floatMin;
const numberMax = S__namespace.floatMax;

const arrayMin = S__namespace.arrayMin;
const arrayMax = S__namespace.arrayMax;
const arrayLength = S__namespace.arrayLength;

const stringMin = S__namespace.stringMin;
const stringMax = S__namespace.stringMax;
const stringLength = S__namespace.stringLength;
const email = S__namespace.email;
const uuid = S__namespace.uuid;
const cuid = S__namespace.cuid;
const url = S__namespace.url;
const pattern = S__namespace.pattern;
const datetime = S__namespace.datetime;
const trim = S__namespace.trim;

exports.Error = Error;
exports.Object = Object$1;
exports.array = array;
exports.arrayLength = arrayLength;
exports.arrayMax = arrayMax;
exports.arrayMin = arrayMin;
exports.asyncParserRefine = asyncParserRefine;
exports.boolean = boolean;
exports.cuid = cuid;
exports.custom = custom;
exports.datetime = datetime;
exports.describe = describe;
exports.description = description;
exports.email = email;
exports.integer = integer;
exports.integerMax = integerMax;
exports.integerMin = integerMin;
exports.json = json;
exports.jsonString = jsonString;
exports.literal = literal;
exports.merge = merge;
exports.name = name;
exports.never = never;
exports.nullable = nullable;
exports.nullish = nullish;
exports.number = number;
exports.numberMax = numberMax;
exports.numberMin = numberMin;
exports.object = object;
exports.optional = optional;
exports.parse = parse;
exports.parseAsync = parseAsync;
exports.parseOrThrow = parseOrThrow;
exports.pattern = pattern;
exports.port = port;
exports.record = record;
exports.refine = refine;
exports.schema = schema;
exports.serialize = serialize;
exports.serializeOrThrow = serializeOrThrow;
exports.setName = setName;
exports.string = string;
exports.stringLength = stringLength;
exports.stringMax = stringMax;
exports.stringMin = stringMin;
exports.transform = transform;
exports.trim = trim;
exports.tuple = tuple;
exports.undefined = undefined$1;
exports.union = union;
exports.unknown = unknown;
exports.url = url;
exports.uuid = uuid;
