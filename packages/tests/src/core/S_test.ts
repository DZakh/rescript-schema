import test from "ava";
import { expectType, TypeEqual } from "ts-expect";

import * as S from "../../../../src/S.js";
import { stringSchema } from "../genType/GenType.gen.js";

// Can use genType schema
expectType<TypeEqual<typeof stringSchema, S.Schema<string, unknown>>>(true);

test("Successfully parses string", (t) => {
  const schema = S.string;
  const value = S.parseOrThrow("123", schema);

  t.deepEqual(value, "123");

  expectType<TypeEqual<typeof schema, S.Schema<string, string>>>(true);
  expectType<TypeEqual<typeof value, string>>(true);
});

test("Successfully parses string with built-in refinement", (t) => {
  const schema = S.stringLength(S.string, 5);
  const result = S.safe(() => S.parseOrThrow("123", schema));

  expectType<TypeEqual<typeof result, S.Result<string>>>(true);

  if (result.success) {
    t.fail("Should fail");
    return;
  }
  t.is(
    result.error.message,
    "Failed parsing at root. Reason: String must be exactly 5 characters long"
  );

  expectType<TypeEqual<typeof schema, S.Schema<string, string>>>(true);
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
  const schema = S.stringLength(S.string, 5, "Postcode must have 5 symbols");
  const result = S.safe(() => S.parseOrThrow("123", schema));

  if (result.success) {
    t.fail("Should fail");
    return;
  }
  t.is(
    result.error.message,
    "Failed parsing at root. Reason: Postcode must have 5 symbols"
  );

  expectType<TypeEqual<typeof schema, S.Schema<string, string>>>(true);
});

test("Successfully parses string with built-in transform", (t) => {
  const schema = S.trim(S.string);
  const value = S.parseOrThrow("  123", schema);

  t.deepEqual(value, "123");

  expectType<TypeEqual<typeof schema, S.Schema<string, string>>>(true);
  expectType<TypeEqual<typeof value, string>>(true);
});

test("Successfully parses string with built-in datetime transform", (t) => {
  const schema = S.datetime(S.string);
  const value = S.parseOrThrow("2020-01-01T00:00:00Z", schema);

  t.deepEqual(value, new Date("2020-01-01T00:00:00Z"));

  expectType<TypeEqual<typeof schema, S.Schema<Date, string>>>(true);
  expectType<TypeEqual<typeof value, Date>>(true);
});

test("Successfully parses int", (t) => {
  const schema = S.int32;
  const value = S.parseOrThrow(123, schema);

  t.deepEqual(value, 123);

  expectType<TypeEqual<typeof schema, S.Schema<number, number>>>(true);
  expectType<TypeEqual<typeof value, number>>(true);
});

test("Successfully parses float", (t) => {
  const schema = S.number;
  const value = S.parseOrThrow(123.4, schema);

  t.deepEqual(value, 123.4);

  expectType<TypeEqual<typeof schema, S.Schema<number, number>>>(true);
  expectType<TypeEqual<typeof value, number>>(true);
});

test("Successfully parses BigInt", (t) => {
  const schema = S.bigint;
  const value = S.parseOrThrow(123n, schema);

  t.deepEqual(value, 123n);

  expectType<TypeEqual<typeof schema, S.Schema<bigint, bigint>>>(true);
  expectType<TypeEqual<typeof value, bigint>>(true);
});

test("Fails to parse float when NaN is provided", (t) => {
  const schema = S.number;

  t.throws(
    () => {
      const value = S.parseOrThrow(NaN, schema);

      expectType<TypeEqual<typeof schema, S.Schema<number, number>>>(true);
      expectType<TypeEqual<typeof value, number>>(true);
    },
    {
      name: "RescriptSchemaError",
      message: "Failed parsing at root. Reason: Expected Float, received NaN",
    }
  );
});

test("Successfully parses float when NaN is provided and NaN check disabled in global config", (t) => {
  S.setGlobalConfig({
    disableNanNumberCheck: true,
  });
  const schema = S.number;
  const value = S.parseOrThrow(NaN, schema);
  S.setGlobalConfig({});

  t.deepEqual(value, NaN);

  expectType<TypeEqual<typeof schema, S.Schema<number, number>>>(true);
  expectType<TypeEqual<typeof value, number>>(true);
});

test("Successfully parses bool", (t) => {
  const schema = S.boolean;
  const value = S.parseOrThrow(true, schema);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof schema, S.Schema<boolean, boolean>>>(true);
  expectType<TypeEqual<typeof value, boolean>>(true);
});

test("Successfully parses unknown", (t) => {
  const schema = S.unknown;
  const value = S.parseOrThrow(true, schema);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof schema, S.Schema<unknown, unknown>>>(true);
  expectType<TypeEqual<typeof value, unknown>>(true);
});

test("Successfully parses json", (t) => {
  const schema = S.json(true);
  const value = S.parseOrThrow(true, schema);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof schema, S.Schema<S.Json, S.Json>>>(true);
  expectType<TypeEqual<typeof value, S.Json>>(true);
});

test("Successfully parses invalid json without validation", (t) => {
  const schema = S.json(false);
  const value = S.parseOrThrow(undefined, schema);

  t.deepEqual(value, undefined); // This is broken but it's intentional

  expectType<TypeEqual<typeof schema, S.Schema<S.Json, S.Json>>>(true);
  expectType<TypeEqual<typeof value, S.Json>>(true);
});

test("Successfully parses undefined", (t) => {
  const schema = S.undefined;
  const value = S.parseOrThrow(undefined, schema);

  t.deepEqual(value, undefined);

  expectType<TypeEqual<typeof schema, S.Schema<undefined, undefined>>>(true);
  expectType<TypeEqual<typeof value, undefined>>(true);
});

test("Fails to parse never", (t) => {
  const schema = S.never;

  t.throws(
    () => {
      const value = S.parseOrThrow(true, schema);

      expectType<TypeEqual<typeof schema, S.Schema<never, never>>>(true);
      expectType<TypeEqual<typeof value, never>>(true);
    },
    {
      name: "RescriptSchemaError",
      message: "Failed parsing at root. Reason: Expected Never, received true",
    }
  );
});

test("Can get a reason from an error", (t) => {
  const schema = S.never;

  const result = S.safe(() => S.parseOrThrow(true, schema));

  if (result.success) {
    t.fail("Should fail");
    return;
  }
  t.is(result.error.reason, "Expected Never, received true");
});

test("Successfully parses array", (t) => {
  const schema = S.array(S.string);
  const value = S.parseOrThrow(["foo"], schema);

  t.deepEqual(value, ["foo"]);

  expectType<TypeEqual<typeof schema, S.Schema<string[], string[]>>>(true);
  expectType<TypeEqual<typeof value, string[]>>(true);
});

test("Successfully parses record", (t) => {
  const schema = S.record(S.string);
  const value = S.parseOrThrow({ foo: "bar" }, schema);

  t.deepEqual(value, { foo: "bar" });

  expectType<
    TypeEqual<
      typeof schema,
      S.Schema<Record<string, string>, Record<string, string>>
    >
  >(true);
  expectType<TypeEqual<typeof value, Record<string, string>>>(true);
});

test("Successfully parses JSON string", (t) => {
  const schema = S.jsonString(S.boolean);
  const value = S.parseOrThrow(`true`, schema);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof schema, S.Schema<boolean, string>>>(true);
  expectType<TypeEqual<typeof value, boolean>>(true);
});

test("Successfully serialized JSON object", (t) => {
  const objectSchema = S.schema({ foo: [1, S.number] });
  const schema = S.jsonString(objectSchema);
  const schemaWithSpace = S.jsonString(objectSchema, 2);

  const value = S.convertOrThrow({ foo: [1, 2] }, S.reverse(schema));
  t.deepEqual(value, '{"foo":[1,2]}');

  const valueWithSpace = S.convertOrThrow(
    { foo: [1, 2] },
    S.reverse(schemaWithSpace)
  );
  t.deepEqual(valueWithSpace, '{\n  "foo": [\n    1,\n    2\n  ]\n}');

  expectType<
    TypeEqual<
      typeof schema,
      S.Schema<
        {
          foo: number[];
        },
        string
      >
    >
  >(true);
  expectType<TypeEqual<typeof schema, typeof schemaWithSpace>>(true);
  expectType<TypeEqual<typeof value, string>>(true);
});

test("Successfully parses optional string", (t) => {
  const schema = S.optional(S.string);
  const value1 = S.parseOrThrow("foo", schema);
  const value2 = S.parseOrThrow(undefined, schema);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<
    TypeEqual<S.Schema<string | undefined, string | undefined>, typeof schema>
  >(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses schema wrapped in optional multiple times", (t) => {
  const schema = S.optional(S.optional(S.optional(S.string)));
  const value1 = S.parseOrThrow("foo", schema);
  const value2 = S.parseOrThrow(undefined, schema);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<
    TypeEqual<S.Schema<string | undefined, string | undefined>, typeof schema>
  >(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses nullable string", (t) => {
  const schema = S.nullable(S.string);
  const value1 = S.parseOrThrow("foo", schema);
  const value2 = S.parseOrThrow(null, schema);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<
    TypeEqual<S.Schema<string | undefined, string | null>, typeof schema>
  >(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
});

test("Successfully parses nullish string", (t) => {
  const schema = S.nullish(S.string);
  const value1 = S.parseOrThrow("foo", schema);
  const value2 = S.parseOrThrow(undefined, schema);
  const value3 = S.parseOrThrow(null, schema);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);
  t.deepEqual(value3, undefined);

  expectType<
    TypeEqual<
      S.Schema<string | undefined, string | undefined | null>,
      typeof schema
    >
  >(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
});

test("Successfully parses schema wrapped in nullable multiple times", (t) => {
  const schema = S.nullable(S.nullable(S.nullable(S.string)));
  const value1 = S.parseOrThrow("foo", schema);
  const value2 = S.parseOrThrow(null, schema);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<
    TypeEqual<S.Schema<string | undefined, string | null>, typeof schema>
  >(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Fails to parse with invalid data", (t) => {
  const schema = S.string;

  t.throws(
    () => {
      S.parseOrThrow(123, schema);
    },
    {
      name: "RescriptSchemaError",
      message: "Failed parsing at root. Reason: Expected String, received 123",
    }
  );
});

test("Successfully serializes with valid value", (t) => {
  const schema = S.string;
  const result = S.convertOrThrow("123", S.reverse(schema));

  t.deepEqual(result, "123");

  expectType<TypeEqual<typeof result, string>>(true);
});

test("Fails to serialize never", (t) => {
  const schema = S.never;

  t.throws(
    () => {
      // @ts-ignore
      S.convertOrThrow("123", S.reverse(schema));
    },
    {
      name: "RescriptSchemaError",
      message: `Failed converting at root. Reason: Expected Never, received "123"`,
    }
  );
});

test("Successfully parses with transform to another type", (t) => {
  const schema = S.transform(S.string, (string) => Number(string));
  const value = S.parseOrThrow("123", schema);

  t.deepEqual(value, 123);

  expectType<TypeEqual<typeof value, number>>(true);
});

test("Fails to parse with transform with user error", (t) => {
  const schema = S.transform(S.string, (string, s) => {
    const number = Number(string);
    if (Number.isNaN(number)) {
      s.fail("Invalid number");
    }
    return number;
  });
  const value = S.parseOrThrow("123", schema);
  t.deepEqual(value, 123);
  expectType<TypeEqual<typeof value, number>>(true);

  t.throws(
    () => {
      S.parseOrThrow("asdf", schema);
    },
    {
      name: "RescriptSchemaError",
      message: "Failed parsing at root. Reason: Invalid number",
    }
  );
});

test("Successfully serializes with transform to another type", (t) => {
  const schema = S.transform(
    S.string,
    (string) => Number(string),
    (number) => {
      expectType<TypeEqual<typeof number, number>>(true);
      return number.toString();
    }
  );
  const result = S.convertOrThrow(123, S.reverse(schema));

  t.deepEqual(result, "123");

  expectType<TypeEqual<typeof result, string>>(true);
});

test("Successfully converts reversed schema with transform to another type", (t) => {
  const schema = S.transform(
    S.string,
    (string) => Number(string),
    (number) => {
      expectType<TypeEqual<typeof number, number>>(true);
      return number.toString();
    }
  );
  const result = S.convertOrThrow(123, S.reverse(schema));

  t.deepEqual(result, "123");

  expectType<TypeEqual<typeof result, string>>(true);
});

test("Successfully parses with refine", (t) => {
  const schema = S.refine(S.string, (string) => {
    expectType<TypeEqual<typeof string, string>>(true);
  });
  const value = S.parseOrThrow("123", schema);

  t.deepEqual(value, "123");

  expectType<TypeEqual<typeof value, string>>(true);
});

test("Successfully serializes with refine", (t) => {
  const schema = S.refine(S.string, (string) => {
    expectType<TypeEqual<typeof string, string>>(true);
  });
  const result = S.convertOrThrow("123", S.reverse(schema));

  t.deepEqual(result, "123");

  expectType<TypeEqual<typeof result, string>>(true);
});

test("Fails to parses with refine raising an error", (t) => {
  const schema = S.refine(S.string, (_, s) => {
    s.fail("User error");
  });

  t.throws(
    () => {
      S.parseOrThrow("123", schema);
    },
    {
      name: "RescriptSchemaError",
      message: "Failed parsing at root. Reason: User error",
    }
  );
});

test("Successfully parses async schema", async (t) => {
  const schema = S.asyncParserRefine(S.string, async (string) => {
    expectType<TypeEqual<typeof string, string>>(true);
  });
  const value = await S.safeAsync(() => S.parseAsyncOrThrow("123", schema));

  t.deepEqual(value, { success: true, value: "123" });

  expectType<TypeEqual<typeof value, S.Result<string>>>(true);
});

test("Fails to parses async schema", async (t) => {
  const schema = S.asyncParserRefine(S.string, async (_, s) => {
    return Promise.resolve().then(() => {
      s.fail("User error");
    });
  });

  const result = await S.safeAsync(() => S.parseAsyncOrThrow("123", schema));

  if (result.success) {
    t.fail("Should fail");
    return;
  }
  t.is(
    result.error.message,
    "Failed parsing async at root. Reason: User error"
  );
  t.true(result.error instanceof S.Error);
});

test("Custom string schema", (t) => {
  const schema = S.custom(
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

  t.deepEqual(S.parseOrThrow("12345", schema), "12345");
  t.deepEqual(S.convertOrThrow("12345", S.reverse(schema)), "12345");
  t.throws(
    () => {
      S.parseOrThrow(123, schema);
    },
    {
      name: "RescriptSchemaError",
      message: "Failed parsing at root. Reason: Postcode should be a string",
    }
  );
  t.throws(
    () => {
      S.parseOrThrow("123", schema);
    },
    {
      name: "RescriptSchemaError",
      message:
        "Failed parsing at root. Reason: Postcode should be 5 characters",
    }
  );

  expectType<TypeEqual<typeof schema, S.Schema<string, string>>>(true);
});

test("Successfully parses object by provided shape", (t) => {
  const schema = S.schema({
    foo: S.string,
    bar: S.boolean,
  });
  const value = S.parseOrThrow(
    {
      foo: "bar",
      bar: true,
    },
    schema
  );

  t.deepEqual(value, {
    foo: "bar",
    bar: true,
  });

  expectType<
    TypeEqual<
      typeof schema,
      S.Schema<
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

test("Successfully parses tagged object", (t) => {
  const schema = S.schema({
    tag: "block" as const,
    bar: S.boolean,
  });
  const value = S.parseOrThrow(
    {
      tag: "block",
      bar: true,
    },
    schema
  );

  t.deepEqual(value, {
    tag: "block",
    bar: true,
  });

  expectType<
    TypeEqual<
      typeof schema,
      S.Schema<
        {
          tag: "block";
          bar: boolean;
        },
        {
          tag: "block";
          bar: boolean;
        }
      >
    >
  >(true);
  expectType<
    TypeEqual<
      typeof value,
      {
        tag: "block";
        bar: boolean;
      }
    >
  >(true);
});

test("Successfully parses and reverse convert object with optional field", (t) => {
  const schema = S.schema({
    bar: S.optional(S.boolean),
  });
  const value = S.parseOrThrow({}, schema);
  t.deepEqual(value, { bar: undefined });

  const reversed = S.convertOrThrow(value, S.reverse(schema));
  t.deepEqual(reversed, { bar: undefined });

  expectType<
    TypeEqual<
      typeof schema,
      S.Schema<{
        bar: boolean | undefined;
      }>
    >
  >(true);
  expectType<
    TypeEqual<
      typeof value,
      {
        bar: boolean | undefined;
      }
    >
  >(true);
});

test("Successfully parses object with field names transform", (t) => {
  const schema = S.object((s) => ({
    foo: s.field("Foo", S.string),
    bar: s.field("Bar", S.boolean),
  }));
  const value = S.parseOrThrow(
    {
      Foo: "bar",
      Bar: true,
    },
    schema
  );

  t.deepEqual(value, {
    foo: "bar",
    bar: true,
  });

  expectType<
    TypeEqual<
      typeof schema,
      S.Schema<
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
  const schema = S.schema({
    foo: S.transform(S.string, (string) => Number(string)),
    bar: S.boolean,
  });
  const value = S.parseOrThrow(
    {
      foo: "123",
      bar: true,
    },
    schema
  );

  t.deepEqual(value, {
    foo: 123,
    bar: true,
  });

  expectType<
    TypeEqual<
      typeof schema,
      S.Schema<
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
  const schema = S.Object.strict(
    S.schema({
      foo: S.string,
    })
  );

  t.throws(
    () => {
      const value = S.parseOrThrow(
        {
          foo: "bar",
          bar: true,
        },
        schema
      );
      expectType<
        TypeEqual<
          typeof schema,
          S.Schema<
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
      name: "RescriptSchemaError",
      message: `Failed parsing at root. Reason: Encountered disallowed excess key "bar" on an object`,
    }
  );
});

test("Fails to parse strict object with exccess fields which created using global config override", (t) => {
  S.setGlobalConfig({
    defaultUnknownKeys: "Strict",
  });
  const schema = S.schema({
    foo: S.string,
  });
  // Reset global config back
  S.setGlobalConfig({});

  t.throws(
    () => {
      const value = S.parseOrThrow(
        {
          foo: "bar",
          bar: true,
        },
        schema
      );
      expectType<
        TypeEqual<
          typeof schema,
          S.Schema<
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
      name: "RescriptSchemaError",
      message: `Failed parsing at root. Reason: Encountered disallowed excess key "bar" on an object`,
    }
  );
});

test("Resets object strict mode with strip method", (t) => {
  const schema = S.Object.strip(
    S.Object.strict(
      S.schema({
        foo: S.string,
      })
    )
  );

  const value = S.parseOrThrow(
    {
      foo: "bar",
      bar: true,
    },
    schema
  );

  t.deepEqual(value, { foo: "bar" });

  expectType<
    TypeEqual<
      typeof schema,
      S.Schema<
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

test("Successfully parses intersected objects", (t) => {
  const schema = S.merge(
    S.schema({
      foo: S.string,
      bar: S.boolean,
    }),
    S.schema({
      baz: S.string,
    })
  );

  expectType<
    TypeEqual<
      typeof schema,
      S.Schema<
        {
          foo: string;
          bar: boolean;
        } & {
          baz: string;
        },
        Record<string, unknown>
      >
    >
  >(true);

  const result = S.safe(() =>
    S.parseOrThrow(
      {
        foo: "bar",
        bar: true,
      },
      schema
    )
  );
  if (result.success) {
    t.fail("Should fail");
    return;
  }
  t.is(
    result.error.message,
    `Failed parsing at ["baz"]. Reason: Expected String, received undefined`
  );

  const value = S.parseOrThrow(
    {
      foo: "bar",
      baz: "baz",
      bar: true,
    },
    schema
  );
  t.deepEqual(value, {
    foo: "bar",
    baz: "baz",
    bar: true,
  });
});

test("Successfully parses intersected objects with transform", (t) => {
  const schema = S.merge(
    S.transform(
      S.schema({
        foo: S.string,
        bar: S.boolean,
      }),
      (obj) => ({
        abc: obj.foo,
      })
    ),
    S.schema({
      baz: S.string,
    })
  );

  expectType<
    TypeEqual<
      typeof schema,
      S.Schema<
        {
          abc: string;
        } & {
          baz: string;
        },
        Record<string, unknown>
      >
    >
  >(true);

  const result = S.safe(() =>
    S.parseOrThrow(
      {
        foo: "bar",
        bar: true,
      },
      schema
    )
  );
  if (result.success) {
    t.fail("Should fail");
    return;
  }
  t.is(
    result.error.message,
    `Failed parsing at ["baz"]. Reason: Expected String, received undefined`
  );

  const value = S.parseOrThrow(
    {
      foo: "bar",
      baz: "baz",
      bar: true,
    },
    schema
  );
  t.deepEqual(value, {
    abc: "bar",
    baz: "baz",
  });
});

test("Fails to serialize merge. Not supported yet", (t) => {
  const schema = S.merge(
    S.schema({
      foo: S.string,
      bar: S.boolean,
    }),
    S.schema({
      baz: S.string,
    })
  );

  const result = S.safe(() =>
    S.convertOrThrow(
      {
        foo: "bar",
        bar: true,
        baz: "string",
      },
      S.reverse(schema)
    )
  );
  if (result.success) {
    t.fail("Should fail");
    return;
  }
  t.is(
    result.error.message,
    `Failed converting at root. Reason: The S.merge serializing is not supported yet`
  );
});

test("Name of merge schema", (t) => {
  const schema = S.merge(
    S.schema({
      foo: S.string,
      bar: S.boolean,
    }),
    S.schema({
      baz: S.string,
    })
  );

  t.is(
    S.name(schema),
    `Object({"foo": String, "bar": Bool}) & Object({"baz": String})`
  );
});

test("Successfully parses object using S.schema", (t) => {
  const schema = S.schema({
    foo: S.string,
    bar: S.boolean,
  });
  const value = S.parseOrThrow(
    {
      foo: "bar",
      bar: true,
    },
    schema
  );

  t.deepEqual(value, {
    foo: "bar",
    bar: true,
  });

  expectType<
    TypeEqual<
      typeof schema,
      S.Schema<{
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

test("Successfully parses tuple using S.schema", (t) => {
  const schema = S.schema([S.string, S.boolean] as const);
  const value = S.parseOrThrow(["bar", true], schema);

  t.deepEqual(value, ["bar", true]);

  expectType<TypeEqual<typeof schema, S.Schema<readonly [string, boolean]>>>(
    true
  );
  expectType<TypeEqual<typeof value, readonly [string, boolean]>>(true);
});

test("Successfully parses primitive schema passed to S.schema", (t) => {
  const schema = S.schema(S.string);
  const value = S.parseOrThrow("bar", schema);

  t.deepEqual(value, "bar");

  expectType<TypeEqual<typeof schema, S.Schema<string>>>(true);
  expectType<TypeEqual<typeof value, string>>(true);
});

test("Successfully parses literal using S.schema", (t) => {
  const schema = S.schema("foo" as const);

  const value = S.parseOrThrow("foo", schema);

  t.deepEqual(value, "foo");

  expectType<TypeEqual<typeof schema, S.Schema<"foo">>>(true);
  expectType<TypeEqual<typeof value, "foo">>(true);
});

test("Successfully parses nested object using S.schema", (t) => {
  const schema = S.schema({
    foo: {
      bar: S.number,
    },
  });
  const value = S.parseOrThrow(
    {
      foo: { bar: 123 },
    },
    schema
  );

  t.deepEqual(value, {
    foo: { bar: 123 },
  });

  expectType<
    TypeEqual<
      typeof schema,
      S.Schema<{
        foo: { bar: number };
      }>
    >
  >(true);
  expectType<
    TypeEqual<
      typeof value,
      {
        foo: { bar: number };
      }
    >
  >(true);
});

test("S.schema example", (t) => {
  type Shape =
    | { kind: "circle"; radius: number }
    | { kind: "square"; x: number };

  let circleSchema: S.Schema<Shape> = S.schema({
    kind: "circle",
    radius: S.number,
  });

  const value = S.parseOrThrow(
    {
      kind: "circle",
      radius: 123,
    },
    circleSchema
  );

  t.deepEqual(value, {
    kind: "circle",
    radius: 123,
  });

  expectType<TypeEqual<typeof circleSchema, S.Schema<Shape>>>(true);
  expectType<TypeEqual<typeof value, Shape>>(true);
});

test("setName", (t) => {
  t.is(S.name(S.setName(S.unknown, "BlaBla")), `BlaBla`);
});

test("Successfully parses and returns result", (t) => {
  const schema = S.string;
  const value = S.safe(() => S.parseOrThrow("123", schema));

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
  const schema = S.string;
  const value = S.safe(() => S.convertOrThrow("123", S.reverse(schema)));

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
  const schema = S.union([S.string, S.number]);
  const value = S.safe(() => S.parseOrThrow("123", schema));

  t.deepEqual(value, { success: true, value: "123" });

  expectType<
    TypeEqual<typeof schema, S.Schema<string | number, string | number>>
  >(true);
});

test("Shape union", (t) => {
  const shapeSchema = S.union([
    {
      kind: "circle" as const,
      radius: S.number,
    },
    {
      kind: "square" as const,
      x: S.number,
    },
    {
      kind: "triangle" as const,
      x: S.number,
      y: S.number,
    },
  ]);
  const value = S.parseOrThrow(
    {
      kind: "circle",
      radius: 123,
    },
    shapeSchema
  );

  t.deepEqual(value, {
    kind: "circle",
    radius: 123,
  });

  expectType<
    TypeEqual<
      typeof shapeSchema,
      S.Schema<
        | {
            kind: "circle";
            radius: number;
          }
        | {
            kind: "square";
            x: number;
          }
        | {
            kind: "triangle";
            x: number;
            y: number;
          }
      >
    >
  >(true);
});

test("Successfully parses union with transformed items", (t) => {
  const schema = S.union([
    S.transform(S.string, (string) => Number(string)),
    S.number,
  ]);
  const value = S.safe(() => S.parseOrThrow("123", schema));

  t.deepEqual(value, { success: true, value: 123 });

  expectType<TypeEqual<typeof schema, S.Schema<number, string | number>>>(true);
});

test("String literal", (t) => {
  const schema = S.literal("tuna");

  t.deepEqual(S.parseOrThrow("tuna", schema), "tuna");

  expectType<TypeEqual<typeof schema, S.Schema<"tuna", "tuna">>>(true);
});

test("Boolean literal", (t) => {
  const schema = S.literal(true);

  t.deepEqual(S.parseOrThrow(true, schema), true);

  expectType<TypeEqual<typeof schema, S.Schema<true, true>>>(true);
});

test("Number literal", (t) => {
  const schema = S.literal(123);

  t.deepEqual(S.parseOrThrow(123, schema), 123);

  expectType<TypeEqual<typeof schema, S.Schema<123, 123>>>(true);
});

test("Undefined literal", (t) => {
  const schema = S.literal(undefined);

  t.deepEqual(S.parseOrThrow(undefined, schema), undefined);

  expectType<TypeEqual<typeof schema, S.Schema<undefined, undefined>>>(true);
});

test("Null literal", (t) => {
  const schema = S.literal(null);

  t.deepEqual(S.parseOrThrow(null, schema), null);

  expectType<TypeEqual<typeof schema, S.Schema<null, null>>>(true);
});

test("Symbol literal", (t) => {
  let symbol = Symbol();
  const schema = S.literal(symbol);

  t.deepEqual(S.parseOrThrow(symbol, schema), symbol);

  expectType<TypeEqual<typeof schema, S.Schema<symbol, symbol>>>(true);
});

test("BigInt literal", (t) => {
  const schema = S.literal(123n);

  t.deepEqual(S.parseOrThrow(123n, schema), 123n);

  expectType<TypeEqual<typeof schema, S.Schema<bigint, bigint>>>(true);
});

test("NaN literal", (t) => {
  const schema = S.literal(NaN);

  t.deepEqual(S.parseOrThrow(NaN, schema), NaN);

  expectType<TypeEqual<typeof schema, S.Schema<number, number>>>(true);
});

test("Tuple literal", (t) => {
  const cliArgsSchema = S.literal(["help", "lint"] as const);

  t.deepEqual(S.parseOrThrow(["help", "lint"], cliArgsSchema), [
    "help",
    "lint",
  ]);

  expectType<
    TypeEqual<
      typeof cliArgsSchema,
      S.Schema<readonly ["help", "lint"], readonly ["help", "lint"]>
    >
  >(true);
});

test("Correctly infers type", (t) => {
  const schema = S.transform(S.string, Number);
  expectType<TypeEqual<typeof schema, S.Schema<number, string>>>(true);
  expectType<TypeEqual<S.Input<typeof schema>, string>>(true);
  expectType<TypeEqual<S.Output<typeof schema>, number>>(true);
  t.pass();
});

test("Successfully parses undefined using the default value", (t) => {
  const schema = S.optional(S.string, "foo");

  const value = S.parseOrThrow(undefined, schema);

  t.deepEqual(value, "foo");

  expectType<TypeEqual<typeof schema, S.Schema<string, string | undefined>>>(
    true
  );
});

test("Successfully parses undefined using the default value from callback", (t) => {
  const schema = S.optional(S.string, () => "foo");

  const value = S.parseOrThrow(undefined, schema);

  t.deepEqual(value, "foo");

  expectType<TypeEqual<typeof schema, S.Schema<string, string | undefined>>>(
    true
  );
});

test("Creates schema with description", (t) => {
  const undocumentedStringSchema = S.string;

  expectType<
    TypeEqual<typeof undocumentedStringSchema, S.Schema<string, string>>
  >(true);

  const documentedStringSchema = S.describe(
    undocumentedStringSchema,
    "A useful bit of text, if you know what to do with it."
  );

  expectType<
    TypeEqual<typeof documentedStringSchema, S.Schema<string, string>>
  >(true);

  const descriptionResult = S.description(documentedStringSchema);

  expectType<TypeEqual<typeof descriptionResult, string | undefined>>(true);

  t.deepEqual(S.description(undocumentedStringSchema), undefined);
  t.deepEqual(
    S.description(documentedStringSchema),
    "A useful bit of text, if you know what to do with it."
  );
});

test("Empty tuple", (t) => {
  const schema = S.tuple([]);

  t.deepEqual(S.parseOrThrow([], schema), []);

  expectType<TypeEqual<typeof schema, S.Schema<[], []>>>(true);
});

test("Tuple with single element", (t) => {
  const schema = S.tuple([S.transform(S.string, (s) => Number(s))]);

  t.deepEqual(S.parseOrThrow(["123"], schema), [123]);

  expectType<TypeEqual<typeof schema, S.Schema<[number], [string]>>>(true);
});

test("Tuple with multiple elements", (t) => {
  const schema = S.tuple([S.transform(S.string, (s) => Number(s)), S.number]);

  t.deepEqual(S.parseOrThrow(["123", 123], schema), [123, 123]);

  expectType<
    TypeEqual<typeof schema, S.Schema<[number, number], [string, number]>>
  >(true);
});

test("Tuple with transform to object", (t) => {
  let pointSchema = S.tuple((s) => {
    s.tag(0, "point");
    return {
      x: s.item(1, S.int32),
      y: s.item(2, S.int32),
    };
  });

  t.deepEqual(S.parseOrThrow(["point", 1, -4], pointSchema), { x: 1, y: -4 });

  expectType<
    TypeEqual<
      typeof pointSchema,
      S.Schema<
        {
          x: number;
          y: number;
        },
        unknown
      >
    >
  >(true);
});

test("Assert throws with invalid data", (t) => {
  const schema: S.Schema<string> = S.string;

  t.throws(
    () => {
      S.assertOrThrow(123, schema);
    },
    {
      name: "RescriptSchemaError",
      message:
        "Failed asserting at root. Reason: Expected String, received 123",
    }
  );
});

test("Assert passes with valid data", (t) => {
  const schema: S.Schema<string> = S.string;

  const data: unknown = "abc";
  expectType<TypeEqual<typeof data, unknown>>(true);
  S.assertOrThrow(data, schema);
  expectType<TypeEqual<typeof data, string>>(true);
  t.pass();
});

test("Successfully parses recursive object", (t) => {
  type Node = {
    id: string;
    children: Node[];
  };

  let nodeSchema = S.recursive<Node>((nodeSchema) =>
    S.schema({
      id: S.string,
      children: S.array(nodeSchema),
    })
  );

  expectType<TypeEqual<typeof nodeSchema, S.Schema<Node, Node>>>(true);

  t.deepEqual(
    S.parseOrThrow(
      {
        id: "1",
        children: [
          { id: "2", children: [] },
          { id: "3", children: [{ id: "4", children: [] }] },
        ],
      },
      nodeSchema
    ),
    {
      id: "1",
      children: [
        { id: "2", children: [] },
        { id: "3", children: [{ id: "4", children: [] }] },
      ],
    }
  );
});

test("Example", (t) => {
  // Create login schema with email and password
  const loginSchema = S.schema({
    email: S.email(S.string),
    password: S.stringMinLength(S.string, 8),
  });

  // Infer output TypeScript type of login schema
  type LoginData = S.Output<typeof loginSchema>; // { email: string; password: string }

  t.throws(
    () => {
      // Throws the S.Error(`Failed parsing at ["email"]. Reason: Invalid email address`)
      S.parseOrThrow({ email: "", password: "" }, loginSchema);
    },
    { message: `Failed parsing at ["email"]. Reason: Invalid email address` }
  );

  // Returns data as { email: string; password: string }
  const result = S.parseOrThrow(
    {
      email: "jane@example.com",
      password: "12345678",
    },
    loginSchema
  );

  t.deepEqual(result, {
    email: "jane@example.com",
    password: "12345678",
  });

  expectType<
    TypeEqual<
      typeof loginSchema,
      S.Schema<
        { email: string; password: string },
        { email: string; password: string }
      >
    >
  >(true);
  expectType<TypeEqual<LoginData, { email: string; password: string }>>(true);
});
