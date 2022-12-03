import test from "ava";
import { expectType, TypeEqual } from "ts-expect";

import * as S from "../src/index";

test("Successfully parses string", (t) => {
  const struct = S.string();
  const value = struct.parse("123");

  t.deepEqual(value, "123");

  expectType<TypeEqual<typeof struct, S.Struct<string>>>(true);
  expectType<TypeEqual<typeof value, string>>(true);
});

test("Successfully parses int", (t) => {
  const struct = S.integer();
  const value = struct.parse(123);

  t.deepEqual(value, 123);

  expectType<TypeEqual<typeof struct, S.Struct<number>>>(true);
  expectType<TypeEqual<typeof value, number>>(true);
});

test("Successfully parses float", (t) => {
  const struct = S.number();
  const value = struct.parse(123.4);

  t.deepEqual(value, 123.4);

  expectType<TypeEqual<typeof struct, S.Struct<number>>>(true);
  expectType<TypeEqual<typeof value, number>>(true);
});

test("Successfully parses bool", (t) => {
  const struct = S.boolean();
  const value = struct.parse(true);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof struct, S.Struct<boolean>>>(true);
  expectType<TypeEqual<typeof value, boolean>>(true);
});

test("Successfully parses unknown", (t) => {
  const struct = S.unknown();
  const value = struct.parse(true);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof struct, S.Struct<unknown>>>(true);
  expectType<TypeEqual<typeof value, unknown>>(true);
});

test("Fails to parse never", (t) => {
  const struct = S.never();

  t.throws(
    () => {
      const value = struct.parse(true);

      expectType<TypeEqual<typeof struct, S.Struct<never>>>(true);
      expectType<TypeEqual<typeof value, never>>(true);
    },
    {
      message: "Failed parsing at root. Reason: Expected Never, received Bool",
    }
  );
});

test("Successfully parses optional string when optional applied as a function", (t) => {
  const struct = S.optional(S.string());
  const value1 = struct.parse("foo");
  const value2 = struct.parse(undefined);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<TypeEqual<S.Struct<string | undefined>, typeof struct>>(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses optional string when optional applied as a method", (t) => {
  const struct = S.string().optional();
  const value1 = struct.parse("foo");
  const value2 = struct.parse(undefined);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<TypeEqual<S.Struct<string | undefined>, typeof struct>>(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses struct wrapped in optional multiple times", (t) => {
  const struct = S.string().optional().optional().optional();
  const value1 = struct.parse("foo");
  const value2 = struct.parse(undefined);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<TypeEqual<S.Struct<string | undefined>, typeof struct>>(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses nullable string when nullable applied as a function", (t) => {
  const struct = S.nullable(S.string());
  const value1 = struct.parse("foo");
  const value2 = struct.parse(null);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<TypeEqual<S.Struct<string | undefined>, typeof struct>>(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses nullable string when nullable applied as a method", (t) => {
  const struct = S.string().nullable();
  const value1 = struct.parse("foo");
  const value2 = struct.parse(null);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<TypeEqual<S.Struct<string | undefined>, typeof struct>>(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses struct wrapped in nullable multiple times", (t) => {
  const struct = S.string().nullable().nullable().nullable();
  const value1 = struct.parse("foo");
  const value2 = struct.parse(null);

  t.deepEqual(value1, "foo");
  t.deepEqual(value2, undefined);

  expectType<TypeEqual<S.Struct<string | undefined>, typeof struct>>(true);
  expectType<TypeEqual<typeof value1, string | undefined>>(true);
  expectType<TypeEqual<typeof value2, string | undefined>>(true);
});

test("Successfully parses object with shape", (t) => {
  const struct = S.object({
    foo: S.string(),
    bar: S.boolean(),
  });
  const value = struct.parse({
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
      S.Struct<{
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

test("Fails to parse with invalid data", (t) => {
  const struct = S.string();

  t.throws(
    () => {
      struct.parse(123);
    },
    {
      message:
        "Failed parsing at root. Reason: Expected String, received Float",
    }
  );
});

test("Successfully serializes with valid value", (t) => {
  const struct = S.string();
  const result = struct.serialize("123");

  t.deepEqual(result, "123");

  expectType<TypeEqual<typeof result, unknown>>(true);
});

test("Fails to serialize never", (t) => {
  const struct = S.never();

  t.throws(
    () => {
      // @ts-ignore
      struct.serialize("123");
    },
    {
      message:
        "Failed serializing at root. Reason: Expected Never, received String",
    }
  );
});

test("Successfully parses with transform to another type", (t) => {
  const struct = S.string().transform((string) => Number(string));
  const value = struct.parse("123");

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
  const result = struct.serialize(123);

  t.deepEqual(result, "123");

  expectType<TypeEqual<typeof result, unknown>>(true);
});

test("Successfully parses with refine", (t) => {
  const struct = S.string().refine((string) => {
    expectType<TypeEqual<typeof string, string>>(true);
  });
  const value = struct.parse("123");

  t.deepEqual(value, "123");

  expectType<TypeEqual<typeof value, string>>(true);
});

test("Successfully serializes with refine", (t) => {
  const struct = S.string().refine(undefined, (string) => {
    expectType<TypeEqual<typeof string, string>>(true);
  });
  const result = struct.serialize("123");

  t.deepEqual(result, "123");

  expectType<TypeEqual<typeof result, unknown>>(true);
});

test("Fails to parses with refine raising an error", (t) => {
  const struct = S.string().refine((_) => {
    S.Error.raise("User error");
  });

  t.throws(
    () => {
      struct.parse("123");
    },
    {
      message: "Failed parsing at root. Reason: User error",
    }
  );
});

test("Successfully parses async struct", async (t) => {
  const struct = S.string().asyncRefine(async (string) => {
    expectType<TypeEqual<typeof string, string>>(true);
  });
  const value = await struct.parseAsync("123");

  t.deepEqual(value, "123");

  expectType<TypeEqual<typeof value, string>>(true);
});

test("Fails to parses async struct", async (t) => {
  const struct = S.string().asyncRefine(async (_) => {
    return Promise.resolve().then(() => {
      S.Error.raise("User error");
    });
  });

  await t.throwsAsync(
    () => {
      return struct.parseAsync("123");
    },
    {
      message: "Failed parsing at root. Reason: User error",
    }
  );
});
