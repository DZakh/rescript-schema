"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
exports.__esModule = true;
var ava_1 = require("ava");
var ts_expect_1 = require("ts-expect");
var S = require("../src/S_JsApi.js");
(0, ava_1["default"])("Successfully parses string", function (t) {
    var struct = S.string();
    var value = struct.parseOrThrow("123");
    t.deepEqual(value, "123");
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses int", function (t) {
    var struct = S.integer();
    var value = struct.parseOrThrow(123);
    t.deepEqual(value, 123);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses float", function (t) {
    var struct = S.number();
    var value = struct.parseOrThrow(123.4);
    t.deepEqual(value, 123.4);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses bool", function (t) {
    var struct = S.boolean();
    var value = struct.parseOrThrow(true);
    t.deepEqual(value, true);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses unknown", function (t) {
    var struct = S.unknown();
    var value = struct.parseOrThrow(true);
    t.deepEqual(value, true);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Fails to parse never", function (t) {
    var struct = S.never();
    t.throws(function () {
        var value = struct.parseOrThrow(true);
        (0, ts_expect_1.expectType)(true);
        (0, ts_expect_1.expectType)(true);
    }, {
        name: "RescriptStructError",
        message: "Failed parsing at root. Reason: Expected Never, received Bool"
    });
});
(0, ava_1["default"])("Successfully parses array", function (t) {
    var struct = S.array(S.string());
    var value = struct.parseOrThrow(["foo"]);
    t.deepEqual(value, ["foo"]);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses record", function (t) {
    var struct = S.record(S.string());
    var value = struct.parseOrThrow({ foo: "bar" });
    t.deepEqual(value, { foo: "bar" });
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses json", function (t) {
    var struct = S.json(S.string());
    var value = struct.parseOrThrow("\"foo\"");
    t.deepEqual(value, "foo");
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses optional string when optional applied as a function", function (t) {
    var struct = S.optional(S.string());
    var value1 = struct.parseOrThrow("foo");
    var value2 = struct.parseOrThrow(undefined);
    t.deepEqual(value1, "foo");
    t.deepEqual(value2, undefined);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses optional string when optional applied as a method", function (t) {
    var struct = S.string().optional();
    var value1 = struct.parseOrThrow("foo");
    var value2 = struct.parseOrThrow(undefined);
    t.deepEqual(value1, "foo");
    t.deepEqual(value2, undefined);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses struct wrapped in optional multiple times", function (t) {
    var struct = S.string().optional().optional().optional();
    var value1 = struct.parseOrThrow("foo");
    var value2 = struct.parseOrThrow(undefined);
    t.deepEqual(value1, "foo");
    t.deepEqual(value2, undefined);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses nullable string when nullable applied as a function", function (t) {
    var struct = S.nullable(S.string());
    var value1 = struct.parseOrThrow("foo");
    var value2 = struct.parseOrThrow(null);
    t.deepEqual(value1, "foo");
    t.deepEqual(value2, undefined);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses nullable string when nullable applied as a method", function (t) {
    var struct = S.string().nullable();
    var value1 = struct.parseOrThrow("foo");
    var value2 = struct.parseOrThrow(null);
    t.deepEqual(value1, "foo");
    t.deepEqual(value2, undefined);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses struct wrapped in nullable multiple times", function (t) {
    var struct = S.string().nullable().nullable().nullable();
    var value1 = struct.parseOrThrow("foo");
    var value2 = struct.parseOrThrow(null);
    t.deepEqual(value1, "foo");
    t.deepEqual(value2, undefined);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Fails to parse with invalid data", function (t) {
    var struct = S.string();
    t.throws(function () {
        struct.parseOrThrow(123);
    }, {
        name: "RescriptStructError",
        message: "Failed parsing at root. Reason: Expected String, received Float"
    });
});
(0, ava_1["default"])("Successfully serializes with valid value", function (t) {
    var struct = S.string();
    var result = struct.serializeOrThrow("123");
    t.deepEqual(result, "123");
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Fails to serialize never", function (t) {
    var struct = S.never();
    t.throws(function () {
        // @ts-ignore
        struct.serializeOrThrow("123");
    }, {
        name: "RescriptStructError",
        message: "Failed serializing at root. Reason: Expected Never, received String"
    });
});
(0, ava_1["default"])("Successfully parses with transform to another type", function (t) {
    var struct = S.string().transform(function (string) { return Number(string); });
    var value = struct.parseOrThrow("123");
    t.deepEqual(value, 123);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully serializes with transform to another type", function (t) {
    var struct = S.string().transform(function (string) { return Number(string); }, function (number) {
        (0, ts_expect_1.expectType)(true);
        return number.toString();
    });
    var result = struct.serializeOrThrow(123);
    t.deepEqual(result, "123");
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses with refine", function (t) {
    var struct = S.string().refine(function (string) {
        (0, ts_expect_1.expectType)(true);
    });
    var value = struct.parseOrThrow("123");
    t.deepEqual(value, "123");
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully serializes with refine", function (t) {
    var struct = S.string().refine(undefined, function (string) {
        (0, ts_expect_1.expectType)(true);
    });
    var result = struct.serializeOrThrow("123");
    t.deepEqual(result, "123");
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Fails to parses with refine raising an error", function (t) {
    var struct = S.string().refine(function (_) {
        S.fail("User error");
    });
    t.throws(function () {
        struct.parseOrThrow("123");
    }, {
        name: "RescriptStructError",
        message: "Failed parsing at root. Reason: User error"
    });
});
(0, ava_1["default"])("Successfully parses async struct", function (t) { return __awaiter(void 0, void 0, void 0, function () {
    var struct, value;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0:
                struct = S.string().asyncRefine(function (string) { return __awaiter(void 0, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        (0, ts_expect_1.expectType)(true);
                        return [2 /*return*/];
                    });
                }); });
                return [4 /*yield*/, struct.parseAsync("123")];
            case 1:
                value = _a.sent();
                t.deepEqual(value, { success: true, value: "123" });
                (0, ts_expect_1.expectType)(true);
                return [2 /*return*/];
        }
    });
}); });
(0, ava_1["default"])("Fails to parses async struct", function (t) { return __awaiter(void 0, void 0, void 0, function () {
    var struct, result;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0:
                struct = S.string().asyncRefine(function (_) { return __awaiter(void 0, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        return [2 /*return*/, Promise.resolve().then(function () {
                                S.fail("User error");
                            })];
                    });
                }); });
                return [4 /*yield*/, struct.parseAsync("123")];
            case 1:
                result = _a.sent();
                t.deepEqual(result, {
                    success: false,
                    error: new S.StructError("Failed parsing at root. Reason: User error")
                });
                return [2 /*return*/];
        }
    });
}); });
(0, ava_1["default"])("Custom string struct", function (t) {
    var struct = S.custom("Postcode", function (unknown) {
        if (typeof unknown !== "string") {
            throw S.fail("Postcode should be a string");
        }
        if (unknown.length !== 5) {
            throw S.fail("Postcode should be 5 characters");
        }
        return unknown;
    }, function (value) {
        (0, ts_expect_1.expectType)(true);
        return value;
    });
    t.deepEqual(struct.parseOrThrow("12345"), "12345");
    t.deepEqual(struct.serializeOrThrow("12345"), "12345");
    t.throws(function () {
        struct.parseOrThrow(123);
    }, {
        name: "RescriptStructError",
        message: "Failed parsing at root. Reason: Postcode should be a string"
    });
    t.throws(function () {
        struct.parseOrThrow("123");
    }, {
        name: "RescriptStructError",
        message: "Failed parsing at root. Reason: Postcode should be 5 characters"
    });
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses object by provided shape", function (t) {
    var struct = S.object({
        foo: S.string(),
        bar: S.boolean()
    });
    var value = struct.parseOrThrow({
        foo: "bar",
        bar: true
    });
    t.deepEqual(value, {
        foo: "bar",
        bar: true
    });
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Fails to parse strict object with exccess fields", function (t) {
    var struct = S.object({
        foo: S.string()
    }).strict();
    t.throws(function () {
        var value = struct.parseOrThrow({
            foo: "bar",
            bar: true
        });
        (0, ts_expect_1.expectType)(true);
        (0, ts_expect_1.expectType)(true);
    }, {
        name: "RescriptStructError",
        message: "Failed parsing at root. Reason: Encountered disallowed excess key \"bar\" on an object. Use Deprecated to ignore a specific field, or S.Object.strip to ignore excess keys completely"
    });
});
(0, ava_1["default"])("Resets object strict mode with strip method", function (t) {
    var struct = S.object({
        foo: S.string()
    })
        .strict()
        .strip();
    var value = struct.parseOrThrow({
        foo: "bar",
        bar: true
    });
    t.deepEqual(value, { foo: "bar" });
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Successfully parses and returns result", function (t) {
    var struct = S.string();
    var value = struct.parse("123");
    t.deepEqual(value, { success: true, value: "123" });
    (0, ts_expect_1.expectType)(true);
    if (value.success) {
        (0, ts_expect_1.expectType)(true);
    }
    else {
        (0, ts_expect_1.expectType)(true);
    }
});
(0, ava_1["default"])("Successfully serializes and returns result", function (t) {
    var struct = S.string();
    var value = struct.serialize("123");
    t.deepEqual(value, { success: true, value: "123" });
    if (value.success) {
        (0, ts_expect_1.expectType)(true);
    }
    else {
        (0, ts_expect_1.expectType)(true);
    }
});
(0, ava_1["default"])("Successfully parses union", function (t) {
    var struct = S.union([S.string(), S.number()]);
    var value = struct.parse("123");
    t.deepEqual(value, { success: true, value: "123" });
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("String literal", function (t) {
    var struct = S.literal("tuna");
    t.deepEqual(struct.parseOrThrow("tuna"), "tuna");
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Boolean literal", function (t) {
    var struct = S.literal(true);
    t.deepEqual(struct.parseOrThrow(true), true);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Number literal", function (t) {
    var struct = S.literal(123);
    t.deepEqual(struct.parseOrThrow(123), 123);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Undefined literal", function (t) {
    var struct = S.literal(undefined);
    t.deepEqual(struct.parseOrThrow(undefined), undefined);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Null literal", function (t) {
    var struct = S.literal(null);
    t.deepEqual(struct.parseOrThrow(null), undefined);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("NaN struct", function (t) {
    var struct = S.nan();
    t.deepEqual(struct.parseOrThrow(NaN), undefined);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Fails to create NaN literal. Use S.nan instead", function (t) {
    t.throws(function () {
        S.literal(NaN);
    }, {
        name: "Error",
        message: "[rescript-struct] Failed to create a NaN literal struct. Use S.nan instead."
    });
});
(0, ava_1["default"])("Fails to create Symbol literal. It's not supported", function (t) {
    t.throws(function () {
        var terrificSymbol = Symbol("terrific");
        S.literal(terrificSymbol);
    }, {
        name: "Error",
        message: "[rescript-struct] The value provided to literal struct factory is not supported."
    });
});
(0, ava_1["default"])("Correctly infers type", function (t) {
    var struct = S.string();
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
    t.pass();
});
(0, ava_1["default"])("Successfully parses undefined using the default value", function (t) {
    var struct = S.string()
        .optional()["default"](function () { return "foo"; });
    var value = struct.parseOrThrow(undefined);
    t.deepEqual(value, "foo");
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Creates struct with description", function (t) {
    var undocumentedStringStruct = S.string();
    (0, ts_expect_1.expectType)(true);
    var documentedStringStruct = undocumentedStringStruct.describe("A useful bit of text, if you know what to do with it.");
    (0, ts_expect_1.expectType)(true);
    var descriptionResult = documentedStringStruct.description();
    (0, ts_expect_1.expectType)(true);
    t.deepEqual(undocumentedStringStruct.description(), undefined);
    t.deepEqual(documentedStringStruct.description(), "A useful bit of text, if you know what to do with it.");
});
(0, ava_1["default"])("Empty tuple", function (t) {
    var struct = S.tuple([]);
    t.deepEqual(struct.parseOrThrow([]), undefined);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Tuple with single element", function (t) {
    var struct = S.tuple([S.string()]);
    t.deepEqual(struct.parseOrThrow(["foo"]), "foo");
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Tuple with multiple elements", function (t) {
    var struct = S.tuple([S.string(), S.number()]);
    t.deepEqual(struct.parseOrThrow(["foo", 123]), ["foo", 123]);
    (0, ts_expect_1.expectType)(true);
});
(0, ava_1["default"])("Example", function (t) {
    var User = S.object({
        username: S.string()
    });
    t.deepEqual(User.parseOrThrow({ username: "Ludwig" }), {
        username: "Ludwig"
    });
    (0, ts_expect_1.expectType)(true);
    (0, ts_expect_1.expectType)(true);
});
