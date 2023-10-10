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
const array = S__namespace.array;
const record = S__namespace.dict;
const jsonString = S__namespace.jsonString;
const union = S__namespace.union;
const object = S__namespace.js_object;
const Object$1 = S__namespace.$$Object;
const String = S__namespace.$$String;
const Number = S__namespace.Float;
const Array = S__namespace.$$Array;
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

exports.Array = Array;
exports.Error = Error;
exports.Number = Number;
exports.Object = Object$1;
exports.String = String;
exports.array = array;
exports.asyncParserRefine = asyncParserRefine;
exports.boolean = boolean;
exports.custom = custom;
exports.describe = describe;
exports.description = description;
exports.integer = integer;
exports.json = json;
exports.jsonString = jsonString;
exports.literal = literal;
exports.never = never;
exports.nullable = nullable;
exports.number = number;
exports.object = object;
exports.optional = optional;
exports.parse = parse;
exports.parseAsync = parseAsync;
exports.parseOrThrow = parseOrThrow;
exports.record = record;
exports.refine = refine;
exports.serialize = serialize;
exports.serializeOrThrow = serializeOrThrow;
exports.string = string;
exports.transform = transform;
exports.tuple = tuple;
exports.undefined = undefined$1;
exports.union = union;
exports.unknown = unknown;
