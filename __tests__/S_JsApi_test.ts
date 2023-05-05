import test from "ava";
import { expectType, TypeEqual } from "ts-expect";

import * as S from "../src/S_JsApi.js";

test("Successfully parses string", (t) => {
  const struct = S.string();
  const value = struct.parseOrThrow("123");

  t.deepEqual(value, "123");

  expectType<TypeEqual<typeof struct, S.Struct<string>>>(true);
  expectType<TypeEqual<typeof value, string>>(true);
});

test("Successfully parses int", (t) => {
  const struct = S.integer();
  const value = struct.parseOrThrow(123);

  t.deepEqual(value, 123);

  expectType<TypeEqual<typeof struct, S.Struct<number>>>(true);
  expectType<TypeEqual<typeof value, number>>(true);
});

test("Successfully parses float", (t) => {
  const struct = S.number();
  const value = struct.parseOrThrow(123.4);

  t.deepEqual(value, 123.4);

  expectType<TypeEqual<typeof struct, S.Struct<number>>>(true);
  expectType<TypeEqual<typeof value, number>>(true);
});

test("Successfully parses bool", (t) => {
  const struct = S.boolean();
  const value = struct.parseOrThrow(true);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof struct, S.Struct<boolean>>>(true);
  expectType<TypeEqual<typeof value, boolean>>(true);
});

test("Successfully parses unknown", (t) => {
  const struct = S.unknown();
  const value = struct.parseOrThrow(true);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof struct, S.Struct<unknown>>>(true);
  expectType<TypeEqual<typeof value, unknown>>(true);
});

test("Successfully parses json", (t) => {
  const struct = S.json();
  const value = struct.parseOrThrow(true);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof struct, S.Struct<S.Json>>>(true);
  expectType<TypeEqual<typeof value, S.Json>>(true);
});

test("Fails to parse never", (t) => {
  const struct = S.never();

  t.throws(
    () => {
      const value = struct.parseOrThrow(true);

      expectType<TypeEqual<typeof struct, S.Struct<never>>>(true);
      expectType<TypeEqual<typeof value, never>>(true);
    },
    {
      name: "RescriptStructError",
      message: "Failed parsing at root. Reason: Expected Never, received Bool",
    }
  );
});

test("Successfully parses array", (t) => {
  const struct = S.array(S.string());
  const value = struct.parseOrThrow(["foo"]);

  t.deepEqual(value, ["foo"]);

  expectType<TypeEqual<typeof struct, S.Struct<string[]>>>(true);
  expectType<TypeEqual<typeof value, string[]>>(true);
});

test("Successfully parses record", (t) => {
  const struct = S.record(S.string());
  const value = struct.parseOrThrow({ foo: "bar" });

  t.deepEqual(value, { foo: "bar" });

  expectType<TypeEqual<typeof struct, S.Struct<Record<string, string>>>>(true);
  expectType<TypeEqual<typeof value, Record<string, string>>>(true);
});

test("Successfully parses JSON string", (t) => {
  const struct = S.jsonString(S.string());
  const value = struct.parseOrThrow(`"foo"`);

  t.deepEqual(value, "foo");

  expectType<TypeEqual<typeof struct, S.Struct<string>>>(true);
  expectType<TypeEqual<typeof value, string>>(true);
});

test("Successfully parses optional string when optional applied as a function", (t) => {
  const struct = S.optional(S.string());
  const value1 = struct.parseOrThrow("foo");
  const value2 = struct.parseOrThrow(undefined);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<TypeEqual<S.Struct<string | undefined>, typeof struct>>(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses optional string when optional applied as a method", (t) => {
  const struct = S.string().optional();
  const value1 = struct.parseOrThrow("foo");
  const value2 = struct.parseOrThrow(undefined);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<TypeEqual<S.Struct<string | undefined>, typeof struct>>(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses struct wrapped in optional multiple times", (t) => {
  const struct = S.string().optional().optional().optional();
  const value1 = struct.parseOrThrow("foo");
  const value2 = struct.parseOrThrow(undefined);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<TypeEqual<S.Struct<string | undefined>, typeof struct>>(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses nullable string when nullable applied as a function", (t) => {
  const struct = S.nullable(S.string());
  const value1 = struct.parseOrThrow("foo");
  const value2 = struct.parseOrThrow(null);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<TypeEqual<S.Struct<string | undefined>, typeof struct>>(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses nullable string when nullable applied as a method", (t) => {
  const struct = S.string().nullable();
  const value1 = struct.parseOrThrow("foo");
  const value2 = struct.parseOrThrow(null);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<TypeEqual<S.Struct<string | undefined>, typeof struct>>(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses struct wrapped in nullable multiple times", (t) => {
  const struct = S.string().nullable().nullable().nullable();
  const value1 = struct.parseOrThrow("foo");
  const value2 = struct.parseOrThrow(null);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<TypeEqual<S.Struct<string | undefined>, typeof struct>>(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Fails to parse with invalid data", (t) => {
  const struct = S.string();

  t.throws(
    () => {
      struct.parseOrThrow(123);
    },
    {
      name: "RescriptStructError",
      message:
        "Failed parsing at root. Reason: Expected String, received Float",
    }
  );
});

test("Successfully serializes with valid value", (t) => {
  const struct = S.string();
  const result = struct.serializeOrThrow("123");

  t.deepEqual(result, "123");

  expectType<TypeEqual<typeof result, unknown>>(true);
});

test("Fails to serialize never", (t) => {
  const struct = S.never();

  t.throws(
    () => {
      // @ts-ignore
      struct.serializeOrThrow("123");
    },
    {
      name: "RescriptStructError",
      message:
        "Failed serializing at root. Reason: Expected Never, received String",
    }
  );
});

test("Successfully parses with transform to another type", (t) => {
  const struct = S.string().transform((string) => Number(string));
  const value = struct.parseOrThrow("123");

  t.deepEqual(value, 123);

  expectType<TypeEqual<typeof value, number>>(true);
});

test("Successfully serializes with transform to another type", (t) => {
  const struct = S.string().transform(
    (string) => Number(string),
    (number) => {
      expectType<TypeEqual<typeof number, number>>(true);
      return number.toString();
    }
  );
  const result = struct.serializeOrThrow(123);

  t.deepEqual(result, "123");

  expectType<TypeEqual<typeof result, unknown>>(true);
});

test("Successfully parses with refine", (t) => {
  const struct = S.string().refine((string) => {
    expectType<TypeEqual<typeof string, string>>(true);
  });
  const value = struct.parseOrThrow("123");

  t.deepEqual(value, "123");

  expectType<TypeEqual<typeof value, string>>(true);
});

test("Successfully serializes with refine", (t) => {
  const struct = S.string().refine(undefined, (string) => {
    expectType<TypeEqual<typeof string, string>>(true);
  });
  const result = struct.serializeOrThrow("123");

  t.deepEqual(result, "123");

  expectType<TypeEqual<typeof result, unknown>>(true);
});

test("Fails to parses with refine raising an error", (t) => {
  const struct = S.string().refine((_) => {
    S.fail("User error");
  });

  t.throws(
    () => {
      struct.parseOrThrow("123");
    },
    {
      name: "RescriptStructError",
      message: "Failed parsing at root. Reason: User error",
    }
  );
});

test("Successfully parses async struct", async (t) => {
  const struct = S.string().asyncRefine(async (string) => {
    expectType<TypeEqual<typeof string, string>>(true);
  });
  const value = await struct.parseAsync("123");

  t.deepEqual(value, { success: true, value: "123" });

  expectType<TypeEqual<typeof value, S.Result<string>>>(true);
});

test("Fails to parses async struct", async (t) => {
  const struct = S.string().asyncRefine(async (_) => {
    return Promise.resolve().then(() => {
      S.fail("User error");
    });
  });

  const result = await struct.parseAsync("123");

  t.deepEqual(result, {
    success: false,
    error: new S.StructError("Failed parsing at root. Reason: User error"),
  });
});

test("Custom string struct", (t) => {
  const struct = S.custom(
    "Postcode",
    (unknown) => {
      if (typeof unknown !== "string") {
        throw S.fail("Postcode should be a string");
      }
      if (unknown.length !== 5) {
        throw S.fail("Postcode should be 5 characters");
      }
      return unknown;
    },
    (value) => {
      expectType<TypeEqual<typeof value, string>>(true);
      return value;
    }
  );

  t.deepEqual(struct.parseOrThrow("12345"), "12345");
  t.deepEqual(struct.serializeOrThrow("12345"), "12345");
  t.throws(
    () => {
      struct.parseOrThrow(123);
    },
    {
      name: "RescriptStructError",
      message: "Failed parsing at root. Reason: Postcode should be a string",
    }
  );
  t.throws(
    () => {
      struct.parseOrThrow("123");
    },
    {
      name: "RescriptStructError",
      message:
        "Failed parsing at root. Reason: Postcode should be 5 characters",
    }
  );

  expectType<TypeEqual<typeof struct, S.Struct<string>>>(true);
});

test("Successfully parses object by provided shape", (t) => {
  const struct = S.object({
    foo: S.string(),
    bar: S.boolean(),
  });
  const value = struct.parseOrThrow({
    foo: "bar",
    bar: true,
  });

  t.deepEqual(value, {
    foo: "bar",
    bar: true,
  });

  expectType<
    TypeEqual<
      typeof struct,
      S.ObjectStruct<{
        foo: string;
        bar: boolean;
      }>
    >
  >(true);
  expectType<
    TypeEqual<
      typeof value,
      {
        foo: string;
        bar: boolean;
      }
    >
  >(true);
});

test("Fails to parse strict object with exccess fields", (t) => {
  const struct = S.object({
    foo: S.string(),
  }).strict();

  t.throws(
    () => {
      const value = struct.parseOrThrow({
        foo: "bar",
        bar: true,
      });
      expectType<
        TypeEqual<
          typeof struct,
          S.ObjectStruct<{
            foo: string;
          }>
        >
      >(true);
      expectType<
        TypeEqual<
          typeof value,
          {
            foo: string;
          }
        >
      >(true);
    },
    {
      name: "RescriptStructError",
      message: `Failed parsing at root. Reason: Encountered disallowed excess key "bar" on an object. Use Deprecated to ignore a specific field, or S.Object.strip to ignore excess keys completely`,
    }
  );
});

test("Resets object strict mode with strip method", (t) => {
  const struct = S.object({
    foo: S.string(),
  })
    .strict()
    .strip();

  const value = struct.parseOrThrow({
    foo: "bar",
    bar: true,
  });

  t.deepEqual(value, { foo: "bar" });

  expectType<
    TypeEqual<
      typeof struct,
      S.ObjectStruct<{
        foo: string;
      }>
    >
  >(true);
  expectType<
    TypeEqual<
      typeof value,
      {
        foo: string;
      }
    >
  >(true);
});

test("Successfully parses and returns result", (t) => {
  const struct = S.string();
  const value = struct.parse("123");

  t.deepEqual(value, { success: true, value: "123" });

  expectType<TypeEqual<typeof value, S.Result<string>>>(true);
  if (value.success) {
    expectType<
      TypeEqual<
        typeof value,
        {
          success: true;
          value: string;
        }
      >
    >(true);
  } else {
    expectType<
      TypeEqual<
        typeof value,
        {
          success: false;
          error: S.StructError;
        }
      >
    >(true);
  }
});

test("Successfully serializes and returns result", (t) => {
  const struct = S.string();
  const value = struct.serialize("123");

  t.deepEqual(value, { success: true, value: "123" });

  if (value.success) {
    expectType<
      TypeEqual<
        typeof value,
        {
          success: true;
          value: unknown;
        }
      >
    >(true);
  } else {
    expectType<
      TypeEqual<
        typeof value,
        {
          success: false;
          error: S.StructError;
        }
      >
    >(true);
  }
});

test("Successfully parses union", (t) => {
  const struct = S.union([S.string(), S.number()]);
  const value = struct.parse("123");

  t.deepEqual(value, { success: true, value: "123" });

  expectType<TypeEqual<typeof struct, S.Struct<string | number>>>(true);
});

test("String literal", (t) => {
  const struct = S.literal("tuna");

  t.deepEqual(struct.parseOrThrow("tuna"), "tuna");

  expectType<TypeEqual<typeof struct, S.Struct<"tuna">>>(true);
});

test("Boolean literal", (t) => {
  const struct = S.literal(true);

  t.deepEqual(struct.parseOrThrow(true), true);

  expectType<TypeEqual<typeof struct, S.Struct<true>>>(true);
});

test("Number literal", (t) => {
  const struct = S.literal(123);

  t.deepEqual(struct.parseOrThrow(123), 123);

  expectType<TypeEqual<typeof struct, S.Struct<123>>>(true);
});

test("Undefined literal", (t) => {
  const struct = S.literal(undefined);

  t.deepEqual(struct.parseOrThrow(undefined), undefined);

  expectType<TypeEqual<typeof struct, S.Struct<undefined>>>(true);
});

test("Null literal", (t) => {
  const struct = S.literal(null);

  t.deepEqual(struct.parseOrThrow(null), undefined);

  expectType<TypeEqual<typeof struct, S.Struct<undefined>>>(true);
});

test("NaN struct", (t) => {
  const struct = S.nan();

  t.deepEqual(struct.parseOrThrow(NaN), undefined);

  expectType<TypeEqual<typeof struct, S.Struct<undefined>>>(true);
});

test("Fails to create NaN literal. Use S.nan instead", (t) => {
  t.throws(
    () => {
      S.literal(NaN);
    },
    {
      name: "Error",
      message:
        "[rescript-struct] Failed to create a NaN literal struct. Use S.nan instead.",
    }
  );
});

test("Fails to create Symbol literal. It's not supported", (t) => {
  t.throws(
    () => {
      const terrificSymbol: any = Symbol("terrific");
      S.literal(terrificSymbol);
    },
    {
      name: "Error",
      message:
        "[rescript-struct] The value provided to literal struct factory is not supported.",
    }
  );
});

test("Correctly infers type", (t) => {
  const struct = S.string();
  expectType<TypeEqual<typeof struct, S.Struct<string>>>(true);
  expectType<TypeEqual<S.Infer<typeof struct>, string>>(true);
  t.pass();
});

test("Successfully parses undefined using the default value", (t) => {
  const struct = S.string()
    .optional()
    .default(() => "foo");

  const value = struct.parseOrThrow(undefined);

  t.deepEqual(value, "foo");

  expectType<TypeEqual<typeof struct, S.Struct<string>>>(true);
});

test("Creates struct with description", (t) => {
  const undocumentedStringStruct = S.string();

  expectType<TypeEqual<typeof undocumentedStringStruct, S.Struct<string>>>(
    true
  );

  const documentedStringStruct = undocumentedStringStruct.describe(
    "A useful bit of text, if you know what to do with it."
  );

  expectType<TypeEqual<typeof documentedStringStruct, S.Struct<string>>>(true);

  const descriptionResult = documentedStringStruct.description();

  expectType<TypeEqual<typeof descriptionResult, string | undefined>>(true);

  t.deepEqual(undocumentedStringStruct.description(), undefined);
  t.deepEqual(
    documentedStringStruct.description(),
    "A useful bit of text, if you know what to do with it."
  );
});

test("Empty tuple", (t) => {
  const struct = S.tuple([]);

  t.deepEqual(struct.parseOrThrow([]), undefined);

  expectType<TypeEqual<typeof struct, S.Struct<undefined>>>(true);
});

test("Tuple with single element", (t) => {
  const struct = S.tuple([S.string()]);

  t.deepEqual(struct.parseOrThrow(["foo"]), "foo");

  expectType<TypeEqual<typeof struct, S.Struct<string>>>(true);
});

test("Tuple with multiple elements", (t) => {
  const struct = S.tuple([S.string(), S.number()]);

  t.deepEqual(struct.parseOrThrow(["foo", 123]), ["foo", 123]);

  expectType<TypeEqual<typeof struct, S.Struct<[string, number]>>>(true);
});

test("Example", (t) => {
  const User = S.object({
    username: S.string(),
  });

  t.deepEqual(User.parseOrThrow({ username: "Ludwig" }), {
    username: "Ludwig",
  });

  type User = S.Infer<typeof User>;

  expectType<
    TypeEqual<
      typeof User,
      S.ObjectStruct<{
        username: string;
      }>
    >
  >(true);
  expectType<
    TypeEqual<
      User,
      {
        username: string;
      }
    >
  >(true);
});
