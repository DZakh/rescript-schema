import { expect, test } from "vitest";
import * as S from "sury";

// The operation surface itself: which call form an argument list resolves to,
// and the Result tail the compiler emits. Neither is expressible as a spec —
// a spec pins one schema's codegen per direction, and these are properties of
// the call, not of the schema (see CONTRIBUTING.md's Spec Harness
// Suggestions).

const user = S.schema({ id: S.string });

// ── Call forms ───────────────────────────────────────────────────────────────

test("all four call forms resolve, on every arity", () => {
  const trimmed = S.string.with(S.trim);
  const toNumber = S.string.with(S.to, S.number, { decode: Number, encode: String });

  // op(s…) — compiled
  expect(S.parseOrThrow(trimmed)(" a ")).toBe("a");
  expect(S.parseOrThrow(S.unknown, toNumber)("1")).toBe(1);
  expect(S.parseOrThrow(S.unknown, S.string, toNumber)("2")).toBe(2);

  // op(s…, data) — immediate, schema-first
  expect(S.parseOrThrow(trimmed, " a ")).toBe("a");
  expect(S.parseOrThrow(S.unknown, toNumber, "1")).toBe(1);
  expect(S.parseOrThrow(S.unknown, S.string, toNumber, "2")).toBe(2);

  // op(data, s…) — immediate, data-first
  expect(S.parseOrThrow(" a ", trimmed)).toBe("a");
  expect(S.parseOrThrow("1", S.unknown, toNumber)).toBe(1);
  expect(S.parseOrThrow("2", S.unknown, S.string, toNumber)).toBe(2);
});

test("the compiled form is told from the immediate one by argument count alone", () => {
  // `undefined` is a perfectly good value to parse, so a schema slot is never
  // probed for it: only `arguments.length` separates these two.
  expect(typeof S.parseOrThrow(S.void)).toBe("function");
  expect(S.parseOrThrow(S.void, undefined)).toBe(undefined);
  expect(S.parseAsResult(S.void, undefined)).toEqual({
    success: true,
    value: undefined,
    error: undefined,
  });
});

test("every call form shares one compiled operation", () => {
  const schema = S.schema({ id: S.string });
  const compiled = S.parseOrThrow(schema);
  expect(S.parseOrThrow(schema)).toBe(compiled);
  // The immediate forms go through the same memo, so nothing recompiles.
  S.parseOrThrow(schema, { id: "a" });
  S.parseOrThrow({ id: "a" }, schema);
  expect(S.parseOrThrow(schema)).toBe(compiled);
  // A different return mode is a different operation, keyed by its own flag.
  expect(S.parseAsResult(schema)).not.toBe(compiled);
});

test("a Sury schema reaching a data slot parses as data", () => {
  // `op(s1, s2)` always reads as a chain, so a schema is only parsed AS DATA
  // through the compiled form. Documented; no argument order makes both
  // reachable.
  const meta = S.schema({ seq: S.number });
  expect(S.parseOrThrow(meta)(S.string as unknown)).toEqual({ seq: (S.string as any).seq });
});

test("a hole and a foreign Standard Schema are named, not read as data", () => {
  const foreign = {
    "~standard": { version: 1, vendor: "other", validate: (v: unknown) => ({ value: v }) },
  } as unknown as S.Schema<string, string>;
  expect(() => S.parseOrThrow(user, undefined as any, user)).toThrow("Expected a Sury schema");
  expect(() => S.parseOrThrow(foreign, "x")).toThrow("Expected a Sury schema");
  expect(() => (S.parseOrThrow as (...a: unknown[]) => unknown)()).toThrow(
    "Expected a Sury schema",
  );
  expect(() =>
    (S.parseOrThrow as (...a: unknown[]) => unknown)(user, user, user, user, "x"),
  ).toThrow("Expected at most 3 schemas");
});

// ── Result tail ──────────────────────────────────────────────────────────────

test("the Result tail is compiled into the operation, not wrapped around it", () => {
  expect(S.parseAsResult(S.string).toString()).toMatchInlineSnapshot(
    `"i=>{try{typeof i==="string"||e[0](i);return {success:true,value:i,error:void 0}}catch(v0){if(v0&&v0.s===s)return {success:false,value:void 0,error:v0};throw v0}}"`,
  );
});

test("an operation that provably cannot throw emits no try", () => {
  // The raise counter says nothing in the body can fail, so there is no `try`
  // to pay for — the decision a `safe(() => ...)` wrapper can never make.
  expect(S.parseAsResult(S.unknown).toString()).toMatchInlineSnapshot(
    `"i=>{return {success:true,value:i,error:void 0}}"`,
  );
  // Transformation code, and still no `try`: what the body does can't fail.
  expect(
    S.parseAsResult(S.schema({ id: S.unknown }).with(S.noValidation, true)).toString(),
  ).toMatchInlineSnapshot(
    `"i=>{return {success:true,value:{id:i["id"]},error:void 0}}"`,
  );
});

test("the throw tail is untouched by the Result modes existing", () => {
  expect(S.parseOrThrow(S.string).toString()).toMatchInlineSnapshot(
    `"i=>{typeof i==="string"||e[0](i);return i}"`,
  );
  expect(S.parseOrThrow(S.unknown)).toBe(S.parseOrThrow(S.number.with(S.noValidation, true)));
});

test("both Result branches carry the same keys in the same order", () => {
  // One hidden class for the two branches, so a consumer's `.success`/`.value`
  // reads stay monomorphic.
  const parse = S.parseAsResult(user);
  expect(Object.keys(parse({ id: "a" }))).toEqual(["success", "value", "error"]);
  expect(Object.keys(parse({ id: 1 }))).toEqual(["success", "value", "error"]);
});

test("a Result destructures and narrows", () => {
  const { value, error } = S.parseAsResult(user, { id: "a" });
  expect(error).toBe(undefined);
  expect(value).toEqual({ id: "a" });
  const failure = S.parseAsResult(user, { id: 1 });
  expect(failure.success).toBe(false);
  expect(failure.error).toBeInstanceOf(S.Error);
  expect(failure.error?.code).toBe("invalid_input");
  expect(failure.error?.path).toEqual(["id"]);
});

test("a foreign exception from user code is rethrown, not returned", () => {
  const boom = new TypeError("boom");
  const schema = S.string.with(S.to, S.number, {
    decode: () => {
      throw boom;
    },
    encode: String,
  });
  // Sury wraps a coder failure as `invalid_conversion` — a failure of THIS
  // value — and keeps the original as the cause.
  const result = S.parseAsResult(schema, "1");
  expect(result.error?.code).toBe("invalid_conversion");
  expect((result.error as { cause?: unknown } | undefined)?.cause).toBe(boom);

  // Nothing else is caught: a refinement that throws outright escapes.
  const throwing = S.string.with(S.refine, () => {
    throw boom;
  });
  expect(() => S.parseAsResult(throwing, "1")).toThrow(boom);
});

test("a defect throws instead of becoming a Result", () => {
  // A schema wired wrong fails for every input, so it is the developer's bug,
  // not an entry in someone's form validation. It is raised where the
  // operation is created — which for an immediate call form is that same call.
  const undecodable = S.boolean.with(S.to, S.number, { decode: "never", encode: "never" });
  expect(() => S.parseAsResult(undecodable, true)).toThrow(S.Error);
  expect(() => S.parseAsResult(undecodable)).toThrow(S.Error);
});
