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
  const struct = S.int();
  const value = struct.parse(123);

  t.deepEqual(value, 123);

  expectType<TypeEqual<typeof struct, S.Struct<number>>>(true);
  expectType<TypeEqual<typeof value, number>>(true);
});

test("Successfully parses float", (t) => {
  const struct = S.float();
  const value = struct.parse(123.4);

  t.deepEqual(value, 123.4);

  expectType<TypeEqual<typeof struct, S.Struct<number>>>(true);
  expectType<TypeEqual<typeof value, number>>(true);
});

test("Successfully parses bool", (t) => {
  const struct = S.bool();
  const value = struct.parse(true);

  t.deepEqual(value, true);

  expectType<TypeEqual<typeof struct, S.Struct<boolean>>>(true);
  expectType<TypeEqual<typeof value, boolean>>(true);
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
    bar: S.bool(),
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
