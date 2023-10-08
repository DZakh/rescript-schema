import { error } from "./../genType/GenType.gen";
import test from "ava";
import { expectType, TypeEqual } from "ts-expect";

import * as S from "../../../../src/S_JsApi.js";

test("Successfully parses string", (t) => {
  const struct = S.string;
  const value = S.parseOrThrow(struct, "123");

  t.deepEqual(value, "123");

  expectType<TypeEqual<typeof struct, S.Struct<string, string>>>(true);
  expectType<TypeEqual<typeof value, string>>(true);
});

test("Successfully parses string with built-in refinement", (t) => {
  const struct = S.String.length(S.string, 5);
  const result = S.parse(struct, "123");

  expectType<TypeEqual<typeof result, S.Result<string>>>(true);

  if (result.success) {
    t.fail("Should fail");
    return;
  }
  t.is(
    result.error.message,
    "Failed parsing at root. Reason: String must be exactly 5 characters long"
  );

  expectType<TypeEqual<typeof struct, S.Struct<string, string>>>(true);
  expectType<
    TypeEqual<
      typeof result,
      {
        success: false;
        error: S.Error;
      }
    >
  >(true);
});

test("Successfully parses string with built-in refinement and custom message", (t) => {
  const struct = S.String.length(S.string, 5, "Postcode must have 5 symbols");
  const result = S.parse(struct, "123");

  if (result.success) {
    t.fail("Should fail");
    return;
  }
  t.is(
    result.error.message,
    "Failed parsing at root. Reason: Postcode must have 5 symbols"
  );

  expectType<TypeEqual<typeof struct, S.Struct<string, string>>>(true);
});

test("Successfully parses string with built-in transform", (t) => {
  const struct = S.String.trim(S.string);
  const value = S.parseOrThrow(struct, "  123");

  t.deepEqual(value, "123");

  expectType<TypeEqual<typeof struct, S.Struct<string, string>>>(true);
  expectType<TypeEqual<typeof value, string>>(true);
});

test("Successfully parses string with built-in datetime transform", (t) => {
  const struct = S.String.datetime(S.string);
  const value = S.parseOrThrow(struct, "2020-01-01T00:00:00Z");

  t.deepEqual(value, new Date("2020-01-01T00:00:00Z"));

  expectType<TypeEqual<typeof struct, S.Struct<Date, string>>>(true);
  expectType<TypeEqual<typeof value, Date>>(true);
});

test("Successfully parses int", (t) => {
  const struct = S.integer;
  const value = S.parseOrThrow(struct, 123);

  t.deepEqual(value, 123);

  expectType<TypeEqual<typeof struct, S.Struct<number, number>>>(true);
  expectType<TypeEqual<typeof value, number>>(true);
});

test("Successfully parses float", (t) => {
  const struct = S.number;
  const value = S.parseOrThrow(struct, 123.4);

  t.deepEqual(value, 123.4);

  expectType<TypeEqual<typeof struct, S.Struct<number, number>>>(true);
  expectType<TypeEqual<typeof value, number>>(true);
});

test("Successfully parses bool", (t) => {
  const struct = S.boolean;
  const value = S.parseOrThrow(struct, true);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof struct, S.Struct<boolean, boolean>>>(true);
  expectType<TypeEqual<typeof value, boolean>>(true);
});

test("Successfully parses unknown", (t) => {
  const struct = S.unknown;
  const value = S.parseOrThrow(struct, true);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof struct, S.Struct<unknown, unknown>>>(true);
  expectType<TypeEqual<typeof value, unknown>>(true);
});

test("Successfully parses json", (t) => {
  const struct = S.json;
  const value = S.parseOrThrow(struct, true);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof struct, S.Struct<S.Json, S.Json>>>(true);
  expectType<TypeEqual<typeof value, S.Json>>(true);
});

test("Successfully parses undefined", (t) => {
  const struct = S.undefined;
  const value = S.parseOrThrow(struct, undefined);

  t.deepEqual(value, undefined);

  expectType<TypeEqual<typeof struct, S.Struct<undefined, undefined>>>(true);
  expectType<TypeEqual<typeof value, undefined>>(true);
});

test("Fails to parse never", (t) => {
  const struct = S.never;

  t.throws(
    () => {
      const value = S.parseOrThrow(struct, true);

      expectType<TypeEqual<typeof struct, S.Struct<never, never>>>(true);
      expectType<TypeEqual<typeof value, never>>(true);
    },
    {
      name: "RescriptStructError",
      message: "Failed parsing at root. Reason: Expected Never, received true",
    }
  );
});

test("Can get a reason from an error", (t) => {
  const struct = S.never;

  const result = S.parse(struct, true);

  if (result.success) {
    t.fail("Should fail");
    return;
  }
  t.is(result.error.reason, "Expected Never, received true");
});

test("Successfully parses array", (t) => {
  const struct = S.array(S.string);
  const value = S.parseOrThrow(struct, ["foo"]);

  t.deepEqual(value, ["foo"]);

  expectType<TypeEqual<typeof struct, S.Struct<string[], string[]>>>(true);
  expectType<TypeEqual<typeof value, string[]>>(true);
});

test("Successfully parses record", (t) => {
  const struct = S.record(S.string);
  const value = S.parseOrThrow(struct, { foo: "bar" });

  t.deepEqual(value, { foo: "bar" });

  expectType<
    TypeEqual<
      typeof struct,
      S.Struct<Record<string, string>, Record<string, string>>
    >
  >(true);
  expectType<TypeEqual<typeof value, Record<string, string>>>(true);
});

test("Successfully parses JSON string", (t) => {
  const struct = S.jsonString(S.boolean);
  const value = S.parseOrThrow(struct, `true`);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof struct, S.Struct<boolean, string>>>(true);
  expectType<TypeEqual<typeof value, boolean>>(true);
});

test("Successfully parses optional string", (t) => {
  const struct = S.optional(S.string);
  const value1 = S.parseOrThrow(struct, "foo");
  const value2 = S.parseOrThrow(struct, undefined);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<
    TypeEqual<S.Struct<string | undefined, string | undefined>, typeof struct>
  >(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses struct wrapped in optional multiple times", (t) => {
  const struct = S.optional(S.optional(S.optional(S.string)));
  const value1 = S.parseOrThrow(struct, "foo");
  const value2 = S.parseOrThrow(struct, undefined);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<
    TypeEqual<S.Struct<string | undefined, string | undefined>, typeof struct>
  >(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses nullable string", (t) => {
  const struct = S.nullable(S.string);
  const value1 = S.parseOrThrow(struct, "foo");
  const value2 = S.parseOrThrow(struct, null);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<
    TypeEqual<S.Struct<string | undefined, string | null>, typeof struct>
  >(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses struct wrapped in nullable multiple times", (t) => {
  const struct = S.nullable(S.nullable(S.nullable(S.string)));
  const value1 = S.parseOrThrow(struct, "foo");
  const value2 = S.parseOrThrow(struct, null);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<
    TypeEqual<S.Struct<string | undefined, string | null>, typeof struct>
  >(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Fails to parse with invalid data", (t) => {
  const struct = S.string;

  t.throws(
    () => {
      S.parseOrThrow(struct, 123);
    },
    {
      name: "RescriptStructError",
      message: "Failed parsing at root. Reason: Expected String, received 123",
    }
  );
});

test("Successfully serializes with valid value", (t) => {
  const struct = S.string;
  const result = S.serializeOrThrow(struct, "123");

  t.deepEqual(result, "123");

  expectType<TypeEqual<typeof result, string>>(true);
});

test("Fails to serialize never", (t) => {
  const struct = S.never;

  t.throws(
    () => {
      // @ts-ignore
      S.serializeOrThrow(struct, "123");
    },
    {
      name: "RescriptStructError",
      message: `Failed serializing at root. Reason: Expected Never, received "123"`,
    }
  );
});

test("Successfully parses with transform to another type", (t) => {
  const struct = S.transform(S.string, (string) => Number(string));
  const value = S.parseOrThrow(struct, "123");

  t.deepEqual(value, 123);

  expectType<TypeEqual<typeof value, number>>(true);
});

test("Fails to parse with transform with user error", (t) => {
  const struct = S.transform(S.string, (string, s) => {
    const number = Number(string);
    if (Number.isNaN(number)) {
      throw s.fail("Invalid number");
    }
    return number;
  });
  const value = S.parseOrThrow(struct, "123");
  t.deepEqual(value, 123);
  expectType<TypeEqual<typeof value, number>>(true);

  t.throws(
    () => {
      S.parseOrThrow(struct, "asdf");
    },
    {
      name: "RescriptStructError",
      message: "Failed parsing at root. Reason: Invalid number",
    }
  );
});

test("Successfully serializes with transform to another type", (t) => {
  const struct = S.transform(
    S.string,
    (string) => Number(string),
    (number) => {
      expectType<TypeEqual<typeof number, number>>(true);
      return number.toString();
    }
  );
  const result = S.serializeOrThrow(struct, 123);

  t.deepEqual(result, "123");

  expectType<TypeEqual<typeof result, string>>(true);
});

test("Successfully parses with refine", (t) => {
  const struct = S.refine(S.string, (string) => {
    expectType<TypeEqual<typeof string, string>>(true);
  });
  const value = S.parseOrThrow(struct, "123");

  t.deepEqual(value, "123");

  expectType<TypeEqual<typeof value, string>>(true);
});

test("Successfully serializes with refine", (t) => {
  const struct = S.refine(S.string, (string) => {
    expectType<TypeEqual<typeof string, string>>(true);
  });
  const result = S.serializeOrThrow(struct, "123");

  t.deepEqual(result, "123");

  expectType<TypeEqual<typeof result, string>>(true);
});

test("Fails to parses with refine raising an error", (t) => {
  const struct = S.refine(S.string, (_, s) => {
    s.fail("User error");
  });

  t.throws(
    () => {
      S.parseOrThrow(struct, "123");
    },
    {
      name: "RescriptStructError",
      message: "Failed parsing at root. Reason: User error",
    }
  );
});

test("Successfully parses async struct", async (t) => {
  const struct = S.asyncParserRefine(S.string, async (string) => {
    expectType<TypeEqual<typeof string, string>>(true);
  });
  const value = await S.parseAsync(struct, "123");

  t.deepEqual(value, { success: true, value: "123" });

  expectType<TypeEqual<typeof value, S.Result<string>>>(true);
});

test("Fails to parses async struct", async (t) => {
  const struct = S.asyncParserRefine(S.string, async (_, s) => {
    return Promise.resolve().then(() => {
      s.fail("User error");
    });
  });

  const result = await S.parseAsync(struct, "123");

  if (result.success) {
    t.fail("Should fail");
    return;
  }
  t.is(result.error.message, "Failed parsing at root. Reason: User error");
  t.true(result.error instanceof S.Error);
});

test("Custom string struct", (t) => {
  const struct = S.custom(
    "Postcode",
    (unknown, s) => {
      if (typeof unknown !== "string") {
        throw s.fail("Postcode should be a string");
      }
      if (unknown.length !== 5) {
        throw s.fail("Postcode should be 5 characters");
      }
      return unknown;
    },
    (value) => {
      expectType<TypeEqual<typeof value, string>>(true);
      return value;
    }
  );

  t.deepEqual(S.parseOrThrow(struct, "12345"), "12345");
  t.deepEqual(S.serializeOrThrow(struct, "12345"), "12345");
  t.throws(
    () => {
      S.parseOrThrow(struct, 123);
    },
    {
      name: "RescriptStructError",
      message: "Failed parsing at root. Reason: Postcode should be a string",
    }
  );
  t.throws(
    () => {
      S.parseOrThrow(struct, "123");
    },
    {
      name: "RescriptStructError",
      message:
        "Failed parsing at root. Reason: Postcode should be 5 characters",
    }
  );

  expectType<TypeEqual<typeof struct, S.Struct<string, string>>>(true);
});

test("Successfully parses object by provided shape", (t) => {
  const struct = S.object({
    foo: S.string,
    bar: S.boolean,
  });
  const value = S.parseOrThrow(struct, {
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
      S.Struct<
        {
          foo: string;
          bar: boolean;
        },
        {
          foo: string;
          bar: boolean;
        }
      >
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

test("Successfully parses object with field names transform", (t) => {
  const struct = S.object((s) => ({
    foo: s.field("Foo", S.string),
    bar: s.field("Bar", S.boolean),
  }));
  const value = S.parseOrThrow(struct, {
    Foo: "bar",
    Bar: true,
  });

  t.deepEqual(value, {
    foo: "bar",
    bar: true,
  });

  expectType<
    TypeEqual<
      typeof struct,
      S.Struct<
        {
          foo: string;
          bar: boolean;
        },
        unknown
      >
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

test("Successfully parses object with transformed field", (t) => {
  const struct = S.object({
    foo: S.transform(S.string, (string) => Number(string)),
    bar: S.boolean,
  });
  const value = S.parseOrThrow(struct, {
    foo: "123",
    bar: true,
  });

  t.deepEqual(value, {
    foo: 123,
    bar: true,
  });

  expectType<
    TypeEqual<
      typeof struct,
      S.Struct<
        {
          foo: number;
          bar: boolean;
        },
        {
          foo: string;
          bar: boolean;
        }
      >
    >
  >(true);
  expectType<
    TypeEqual<
      typeof value,
      {
        foo: number;
        bar: boolean;
      }
    >
  >(true);
});

test("Fails to parse strict object with exccess fields", (t) => {
  const struct = S.Object.strict(
    S.object({
      foo: S.string,
    })
  );

  t.throws(
    () => {
      const value = S.parseOrThrow(struct, {
        foo: "bar",
        bar: true,
      });
      expectType<
        TypeEqual<
          typeof struct,
          S.Struct<
            {
              foo: string;
            },
            {
              foo: string;
            }
          >
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
  const struct = S.Object.strip(
    S.Object.strict(
      S.object({
        foo: S.string,
      })
    )
  );

  const value = S.parseOrThrow(struct, {
    foo: "bar",
    bar: true,
  });

  t.deepEqual(value, { foo: "bar" });

  expectType<
    TypeEqual<
      typeof struct,
      S.Struct<
        {
          foo: string;
        },
        {
          foo: string;
        }
      >
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
  const struct = S.string;
  const value = S.parse(struct, "123");

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
          error: S.Error;
        }
      >
    >(true);
  }
});

test("Successfully serializes and returns result", (t) => {
  const struct = S.string;
  const value = S.serialize(struct, "123");

  t.deepEqual(value, { success: true, value: "123" });

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
          error: S.Error;
        }
      >
    >(true);
  }
});

test("Successfully parses union", (t) => {
  const struct = S.union([S.string, S.number]);
  const value = S.parse(struct, "123");

  t.deepEqual(value, { success: true, value: "123" });

  expectType<
    TypeEqual<typeof struct, S.Struct<string | number, string | number>>
  >(true);
});

test("Successfully parses union with transformed items", (t) => {
  const struct = S.union([
    S.transform(S.string, (string) => Number(string)),
    S.number,
  ]);
  const value = S.parse(struct, "123");

  t.deepEqual(value, { success: true, value: 123 });

  expectType<TypeEqual<typeof struct, S.Struct<number, string | number>>>(true);
});

test("String literal", (t) => {
  const struct = S.literal("tuna");

  t.deepEqual(S.parseOrThrow(struct, "tuna"), "tuna");

  expectType<TypeEqual<typeof struct, S.Struct<"tuna", "tuna">>>(true);
});

test("Boolean literal", (t) => {
  const struct = S.literal(true);

  t.deepEqual(S.parseOrThrow(struct, true), true);

  expectType<TypeEqual<typeof struct, S.Struct<true, true>>>(true);
});

test("Number literal", (t) => {
  const struct = S.literal(123);

  t.deepEqual(S.parseOrThrow(struct, 123), 123);

  expectType<TypeEqual<typeof struct, S.Struct<123, 123>>>(true);
});

test("Undefined literal", (t) => {
  const struct = S.literal(undefined);

  t.deepEqual(S.parseOrThrow(struct, undefined), undefined);

  expectType<TypeEqual<typeof struct, S.Struct<undefined, undefined>>>(true);
});

test("Null literal", (t) => {
  const struct = S.literal(null);

  t.deepEqual(S.parseOrThrow(struct, null), null);

  expectType<TypeEqual<typeof struct, S.Struct<null, null>>>(true);
});

test("Symbol literal", (t) => {
  let symbol = Symbol();
  const struct = S.literal(symbol);

  t.deepEqual(S.parseOrThrow(struct, symbol), symbol);

  expectType<TypeEqual<typeof struct, S.Struct<symbol, symbol>>>(true);
});

test("BigInt literal", (t) => {
  const struct = S.literal(123n);

  t.deepEqual(S.parseOrThrow(struct, 123n), 123n);

  expectType<TypeEqual<typeof struct, S.Struct<bigint, bigint>>>(true);
});

test("NaN literal", (t) => {
  const struct = S.literal(NaN);

  t.deepEqual(S.parseOrThrow(struct, NaN), NaN);

  expectType<TypeEqual<typeof struct, S.Struct<number, number>>>(true);
});

test("Tuple literal", (t) => {
  const cliArgsStruct = S.literal(["help", "lint"] as const);

  t.deepEqual(S.parseOrThrow(cliArgsStruct, ["help", "lint"]), [
    "help",
    "lint",
  ]);

  expectType<
    TypeEqual<
      typeof cliArgsStruct,
      S.Struct<readonly ["help", "lint"], readonly ["help", "lint"]>
    >
  >(true);
});

test("Correctly infers type", (t) => {
  const struct = S.transform(S.string, Number);
  expectType<TypeEqual<typeof struct, S.Struct<number, string>>>(true);
  expectType<TypeEqual<S.Input<typeof struct>, string>>(true);
  expectType<TypeEqual<S.Output<typeof struct>, number>>(true);
  t.pass();
});

test("Successfully parses undefined using the default value", (t) => {
  const struct = S.optional(S.string, "foo");

  const value = S.parseOrThrow(struct, undefined);

  t.deepEqual(value, "foo");

  expectType<TypeEqual<typeof struct, S.Struct<string, string | undefined>>>(
    true
  );
});

test("Successfully parses undefined using the default value from callback", (t) => {
  const struct = S.optional(S.string, () => "foo");

  const value = S.parseOrThrow(struct, undefined);

  t.deepEqual(value, "foo");

  expectType<TypeEqual<typeof struct, S.Struct<string, string | undefined>>>(
    true
  );
});

test("Creates struct with description", (t) => {
  const undocumentedStringStruct = S.string;

  expectType<
    TypeEqual<typeof undocumentedStringStruct, S.Struct<string, string>>
  >(true);

  const documentedStringStruct = S.describe(
    undocumentedStringStruct,
    "A useful bit of text, if you know what to do with it."
  );

  expectType<
    TypeEqual<typeof documentedStringStruct, S.Struct<string, string>>
  >(true);

  const descriptionResult = S.description(documentedStringStruct);

  expectType<TypeEqual<typeof descriptionResult, string | undefined>>(true);

  t.deepEqual(S.description(undocumentedStringStruct), undefined);
  t.deepEqual(
    S.description(documentedStringStruct),
    "A useful bit of text, if you know what to do with it."
  );
});

test("Empty tuple", (t) => {
  const struct = S.tuple([]);

  t.deepEqual(S.parseOrThrow(struct, []), []);

  expectType<TypeEqual<typeof struct, S.Struct<[], []>>>(true);
});

test("Tuple with single element", (t) => {
  const struct = S.tuple([S.transform(S.string, (s) => Number(s))]);

  t.deepEqual(S.parseOrThrow(struct, ["123"]), [123]);

  expectType<TypeEqual<typeof struct, S.Struct<[number], [string]>>>(true);
});

test("Tuple with multiple elements", (t) => {
  const struct = S.tuple([S.transform(S.string, (s) => Number(s)), S.number]);

  t.deepEqual(S.parseOrThrow(struct, ["123", 123]), [123, 123]);

  expectType<
    TypeEqual<typeof struct, S.Struct<[number, number], [string, number]>>
  >(true);
});

test("Tuple with transform to object", (t) => {
  let pointStruct = S.tuple((s) => {
    s.tag(0, "point");
    return {
      x: s.item(1, S.integer),
      y: s.item(2, S.integer),
    };
  });

  t.deepEqual(S.parseOrThrow(pointStruct, ["point", 1, -4]), { x: 1, y: -4 });

  expectType<
    TypeEqual<
      typeof pointStruct,
      S.Struct<
        {
          x: number;
          y: number;
        },
        unknown
      >
    >
  >(true);
});

test("Example", (t) => {
  // Create login struct with email and password
  const loginStruct = S.object({
    email: S.String.email(S.string),
    password: S.String.min(S.string, 8),
  });

  // Infer output TypeScript type of login struct
  type LoginData = S.Output<typeof loginStruct>; // { email: string; password: string }

  t.throws(
    () => {
      // Throws the S.Error(`Failed parsing at ["email"]. Reason: Invalid email address`)
      S.parseOrThrow(loginStruct, { email: "", password: "" });
    },
    { message: `Failed parsing at ["email"]. Reason: Invalid email address` }
  );

  // Returns data as { email: string; password: string }
  const result = S.parseOrThrow(loginStruct, {
    email: "jane@example.com",
    password: "12345678",
  });

  t.deepEqual(result, {
    email: "jane@example.com",
    password: "12345678",
  });

  expectType<
    TypeEqual<
      typeof loginStruct,
      S.Struct<
        { email: string; password: string },
        { email: string; password: string }
      >
    >
  >(true);
  expectType<TypeEqual<LoginData, { email: string; password: string }>>(true);
});
