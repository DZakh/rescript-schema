import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { expect, test } from "vitest";
import * as S from "sury";
import { withoutGlobalRoutes } from "./withoutGlobal";

// The value side of `S.formData`, for what the spec format can't write down: a
// golden can't hold a `FormData` (see CONTRIBUTING.md's Spec Harness
// Suggestions), so every `codec-formdata-*` encode block carries only its
// failures, and the entries an encode produces are checked here. Codegen and
// the decode direction stay in the specs.

const form = (...entries: [string, string | Blob][]): FormData => {
  const f = new FormData();
  for (const [key, value] of entries) f.append(key, value);
  return f;
};

const entries = (f: FormData): [string, string | File][] => [...f.entries()];

test("an encode appends one entry per field, in field order, as text", () => {
  const schema = S.formData.with(
    S.to,
    S.schema({
      name: S.string.with(S.nonEmpty),
      age: S.number,
      agree: S.boolean,
      kind: "signup",
      since: S.date,
      id: S.bigint,
      site: S.url,
    }),
  );
  const encoded = S.encoder(schema)({
    name: "Ann",
    age: 42,
    agree: true,
    kind: "signup",
    since: new Date("2024-01-01T00:00:00.000Z"),
    id: 7n,
    site: new URL("https://sury.dev/"),
  });
  expect(encoded).toBeInstanceOf(FormData);
  expect(entries(encoded)).toEqual([
    ["name", "Ann"],
    ["age", "42"],
    ["agree", "on"],
    ["kind", "signup"],
    ["since", "2024-01-01T00:00:00.000Z"],
    ["id", "7"],
    ["site", "https://sury.dev/"],
  ]);
  // The same schema reads the entries back, coercions included.
  expect(S.decoder(schema)(encoded)).toEqual({
    name: "Ann",
    age: 42,
    agree: true,
    kind: "signup",
    since: new Date("2024-01-01T00:00:00.000Z"),
    id: 7n,
    site: new URL("https://sury.dev/"),
  });
});

test("an absent optional is no entry, and a default fills the absent one back", () => {
  const schema = S.formData.with(
    S.to,
    S.schema({ nick: S.optional(S.string), age: S.optional(S.number, 18) }),
  );
  expect(entries(S.encoder(schema)({ age: 18 }))).toEqual([["age", "18"]]);
  expect(entries(S.encoder(schema)({ nick: "nn", age: 42 }))).toEqual([
    ["nick", "nn"],
    ["age", "42"],
  ]);
  expect(S.decoder(schema)(new FormData())).toEqual({ nick: undefined, age: 18 });
  // The empty text input is the absent one.
  expect(S.decoder(schema)(form(["nick", ""], ["age", ""]))).toEqual({ nick: undefined, age: 18 });
});

test("a boolean is a checkbox: on when set, nothing when not", () => {
  const schema = S.formData.with(S.to, S.schema({ agree: S.boolean, notify: S.optional(S.boolean) }));
  // An unchecked box sends nothing, which is all the entry list says about
  // `false` — so that is what an encode writes.
  expect(entries(S.encoder(schema)({ agree: false }))).toEqual([]);
  expect(entries(S.encoder(schema)({ agree: true, notify: false }))).toEqual([
    ["agree", "on"],
    // A tri-state is the one thing the wire cannot express, so `false` is
    // spelled out there to keep it apart from absent.
    ["notify", "false"],
  ]);
  expect(S.decoder(schema)(S.encoder(schema)({ agree: false, notify: true }))).toEqual({
    agree: false,
    notify: true,
  });
  expect(S.decoder(schema)(form(["agree", "on"]))).toEqual({ agree: true, notify: undefined });
  expect(S.decoder(schema)(new FormData())).toEqual({ agree: false, notify: undefined });
});

test("a checkbox reads the entries a form can carry, and only those", () => {
  const schema = S.formData.with(S.to, S.schema({ a: S.boolean }));
  // "on" is what a checked box submits; the rest are the hidden-input
  // spellings, matching VineJS's accepted set.
  for (const [entry, value] of [
    ["on", true],
    ["true", true],
    ["1", true],
    ["false", false],
    ["0", false],
    // A checked box whose value is "" is indistinguishable from an unchecked
    // one on this wire.
    ["", false],
  ] as const) {
    expect(S.decoder(schema)(form(["a", entry])), entry).toEqual({ a: value });
  }
  // Anything else is a checkbox with a `value` attribute, which is a string
  // the schema should name rather than a boolean the codec guesses at.
  expect(() => S.decoder(schema)(form(["a", "yes"]))).toThrow(
    'Failed at a: Expected boolean, received "yes"',
  );
});

test("a nullable field reads a blank entry as null, and omits null on the way out", () => {
  const schema = S.formData.with(
    S.to,
    S.schema({ nick: S.nullable(S.string), age: S.nullable(S.number) }),
  );
  expect(S.decoder(schema)(form(["nick", ""], ["age", ""]))).toEqual({ nick: null, age: null });
  expect(S.decoder(schema)(new FormData())).toEqual({ nick: null, age: null });
  expect(S.decoder(schema)(form(["nick", "nn"], ["age", "42"]))).toEqual({ nick: "nn", age: 42 });
  // `null` is not an entry, so it is omitted — and reads back as null.
  expect(entries(S.encoder(schema)({ nick: null, age: null }))).toEqual([]);
  expect(entries(S.encoder(schema)({ nick: "nn", age: 42 }))).toEqual([
    ["nick", "nn"],
    ["age", "42"],
  ]);
  expect(S.decoder(schema)(S.encoder(schema)({ nick: null, age: 7 }))).toEqual({
    nick: null,
    age: 7,
  });
  // The literal text "null" is a string, not the null a blank field means.
  expect(S.decoder(schema)(form(["nick", "null"]))).toEqual({ nick: "null", age: null });
});

test("a blank required string must say what it means", () => {
  const ambiguous = ["Ambiguous at f:", "S.nonEmpty", "S.minLength(0)", "S.optional", "S.nullable"];
  for (const schema of [S.string, S.string.with(S.maxLength, 100)]) {
    for (const fragment of ambiguous) {
      expect(() => S.decoder(S.formData.with(S.to, S.schema({ f: schema })))).toThrow(fragment);
    }
  }
  // Every spelling the message names, plus the ones that answer on their own.
  for (const [name, schema] of [
    ["nonEmpty", S.string.with(S.nonEmpty)],
    ["minLength(0)", S.string.with(S.minLength, 0)],
    ["optional", S.optional(S.string)],
    ["nullable", S.nullable(S.string)],
    ["a format", S.email],
    ["a literal", S.schema("x")],
    ["a pattern rejecting blank", S.string.with(S.pattern, /^\d+$/)],
    ["a conversion", S.string.with(S.to, S.date)],
  ] as const) {
    expect(() => S.decoder(S.formData.with(S.to, S.schema({ f: schema }))), name).not.toThrow();
  }
  // A pattern that matches "" says nothing about it, so it stays ambiguous.
  expect(() =>
    S.decoder(S.formData.with(S.to, S.schema({ f: S.string.with(S.pattern, /^\d*$/) }))),
  ).toThrow("Ambiguous at f:");
  // Encoding never reads a blank entry, so it has nothing to be ambiguous about.
  expect(() => S.encoder(S.formData.with(S.to, S.schema({ f: S.string })))).not.toThrow();
});

test("an array is a repeated key, and an empty array is no entry", () => {
  const schema = S.formData.with(S.to, S.schema({ tags: S.array(S.string), ids: S.array(S.number) }));
  expect(entries(S.encoder(schema)({ tags: ["a", "b"], ids: [1, 2] }))).toEqual([
    ["tags", "a"],
    ["tags", "b"],
    ["ids", "1"],
    ["ids", "2"],
  ]);
  expect(entries(S.encoder(schema)({ tags: [], ids: [] }))).toEqual([]);
  expect(S.decoder(schema)(form(["ids", "1"], ["tags", "x"], ["ids", "2"]))).toEqual({
    tags: ["x"],
    ids: [1, 2],
  });
});

test("a file travels as itself, name included, and a blob becomes a file", async () => {
  const schema = S.formData.with(
    S.to,
    S.schema({ avatar: S.file, cover: S.optional(S.file), raw: S.blob }),
  );
  const avatar = new File(["a"], "a.png", { type: "image/png" });
  const encoded = S.encoder(schema)({ avatar, raw: new Blob(["r"]) });
  const sent = entries(encoded) as [string, File][];
  const sentAvatar = sent[0]![1];
  const sentRaw = sent[1]![1];
  expect(sentAvatar.name).toBe("a.png");
  expect(sentAvatar.type).toBe("image/png");
  expect(await sentAvatar.text()).toBe("a");
  // `append` wraps a bare blob in a File, which is what `S.blob` still accepts.
  expect(sentRaw).toBeInstanceOf(File);
  expect(await sentRaw.text()).toBe("r");
  const decoded = S.decoder(schema)(encoded);
  expect(decoded.avatar).toBe(sentAvatar);
  expect(decoded.cover).toBe(undefined);
  expect(decoded.raw).toBe(sentRaw);
});

test("a multi-file input is an array of entries, both ways", () => {
  const schema = S.formData.with(S.to, S.schema({ files: S.array(S.file) }));
  const a = new File(["a"], "a.png");
  const b = new File(["b"], "b.png");
  expect(entries(S.encoder(schema)({ files: [a, b] }))).toEqual([
    ["files", a],
    ["files", b],
  ]);
  expect(S.decoder(schema)(form(["files", a], ["files", b]))).toEqual({ files: [a, b] });
  expect(S.decoder(schema)(new FormData())).toEqual({ files: [] });
  expect(() => S.decoder(schema)(form(["files", "x"]))).toThrow(
    "Failed at files[0]: Expected File, received \"x\"",
  );
});

test("an array of optional items encodes without leaking a declaration", () => {
  // The item's own `let` used to land after the loop body that reads it, so
  // the compiled encoder threw `ReferenceError` on its first item.
  const schema = S.formData.with(S.to, S.schema({ m: S.array(S.optional(S.string)) }));
  expect(entries(S.encoder(schema)({ m: ["a", undefined, "b"] }))).toEqual([
    ["m", "a"],
    ["m", "b"],
  ]);
  const nested = S.formData.with(S.to, S.schema({ n: S.array(S.array(S.string)) }));
  expect(entries(S.encoder(nested)({ n: [["a", "b"], ["c"]] }))).toEqual([
    ["n", "a"],
    ["n", "b"],
    ["n", "c"],
  ]);
});

test("a checkbox round-trips however the field is wrapped", () => {
  for (const [name, schema] of [
    ["required", S.boolean],
    ["optional", S.optional(S.boolean)],
    ["defaulted false", S.optional(S.boolean, false)],
  ] as const) {
    const s = S.formData.with(S.to, S.schema({ a: schema }));
    for (const value of [true, false]) {
      expect(S.decoder(s)(S.encoder(s)({ a: value })), `${name} ${value}`).toEqual({ a: value });
    }
    // What a browser actually submits for a checked and an unchecked box.
    expect(S.decoder(s)(form(["a", "on"])), name).toEqual({ a: true });
    expect(S.decoder(s)(new FormData()), name).toEqual({ a: name === "optional" ? undefined : false });
  }
});

test("a boolean literal is the must-be-checked box", () => {
  // The terms-and-conditions checkbox, which submits "on" like any other and
  // reports the box rather than the entry when it is missing.
  const schema = S.formData.with(S.to, S.schema({ terms: S.schema(true) }));
  expect(S.decoder(schema)(form(["terms", "on"]))).toEqual({ terms: true });
  expect(entries(S.encoder(schema)({ terms: true }))).toEqual([["terms", "on"]]);
  for (const fd of [new FormData(), form(["terms", "false"]), form(["terms", "0"])]) {
    expect(() => S.decoder(schema)(fd)).toThrow("Failed at terms: Expected true, received false");
  }
  // And its mirror, for a box that must stay clear.
  const clear = S.formData.with(S.to, S.schema({ spam: S.schema(false) }));
  expect(S.decoder(clear)(new FormData())).toEqual({ spam: false });
  expect(entries(S.encoder(clear)({ spam: false }))).toEqual([]);
  expect(() => S.decoder(clear)(form(["spam", "on"]))).toThrow(
    "Failed at spam: Expected false, received true",
  );
});

test("a repeated key is a list, so a boolean list is positional", () => {
  // Not a checkbox group: dropping the false entries the way a browser does
  // would lose the indices the decoder reads back. A checkbox *group* submits
  // the values of the checked boxes, which is S.array(S.string).
  const schema = S.formData.with(S.to, S.schema({ flags: S.array(S.boolean) }));
  const encoded = S.encoder(schema)({ flags: [true, false, true] });
  expect(entries(encoded)).toEqual([
    ["flags", "true"],
    ["flags", "false"],
    ["flags", "true"],
  ]);
  expect(S.decoder(schema)(encoded)).toEqual({ flags: [true, false, true] });
});

test("a nullable checkbox reads an absent box as null", () => {
  // Without it the `null` arm would be unreachable: nothing a form submits
  // reads as null, so absence is the only thing left to carry it.
  const schema = S.formData.with(S.to, S.schema({ a: S.nullable(S.boolean) }));
  expect(S.decoder(schema)(new FormData())).toEqual({ a: null });
  expect(S.decoder(schema)(form(["a", "on"]))).toEqual({ a: true });
  expect(S.decoder(schema)(form(["a", "false"]))).toEqual({ a: false });
  expect(entries(S.encoder(schema)({ a: null }))).toEqual([]);
  expect(entries(S.encoder(schema)({ a: false }))).toEqual([]);
});

test("a checkbox defaulting to true cannot round-trip, because the wire disagrees", () => {
  // An absent checkbox entry means unchecked, so a default of `true` states
  // something the wire never says. The encode omits `false` like a browser
  // does, and the decode then applies that default. Documented rather than
  // worked around: the schema is what contradicts the medium.
  const schema = S.formData.with(S.to, S.schema({ a: S.optional(S.boolean, true) }));
  expect(entries(S.encoder(schema)({ a: false }))).toEqual([]);
  expect(S.decoder(schema)(S.encoder(schema)({ a: false }))).toEqual({ a: true });
});

test("FIXME: a refinement inside S.optional is not checked on encode", () => {
  // Not this codec's doing — the union encode path trusts its typed input, and
  // a plain object target has the same hole. Pinned so the fix shows up here.
  const schema = S.formData.with(
    S.to,
    S.schema({ nick: S.optional(S.string.with(S.maxLength, 3)) }),
  );
  const encoded = S.encoder(schema)({ nick: "long" });
  expect(entries(encoded)).toEqual([["nick", "long"]]);
  expect(() => S.decoder(schema)(encoded)).toThrow(
    'Failed at nick: Expected string.length <= 3, received "long"',
  );
  expect(() => S.encoder(S.schema({ nick: S.optional(S.string.with(S.maxLength, 3)) }))({ nick: "long" }))
    .not.toThrow();
});

test("a scalar field takes the first entry of a repeated key", () => {
  // Parameter pollution: a client can send a key twice for a field the schema
  // declared once. `get` is what the platform answers with, and it is the
  // first entry — not the last, and not a silent array.
  const schema = S.formData.with(S.to, S.schema({ name: S.string.with(S.nonEmpty) }));
  expect(S.decoder(schema)(form(["name", "first"], ["name", "second"]))).toEqual({
    name: "first",
  });
});

test("a file entry in a text field is reported as the file it is", () => {
  const schema = S.formData.with(S.to, S.schema({ name: S.string.with(S.nonEmpty) }));
  expect(() => S.decoder(schema)(form(["name", new File(["x"], "a.txt")]))).toThrow(
    "Failed at name: Expected string.length >= 1, received File",
  );
});

test("what a text input reaching S.number is read as", () => {
  // A form has no number type, so every one of these is a string a user can
  // type into a field the schema calls a number. `+text` is the reading, which
  // is broader than most people expect at both ends.
  const schema = S.formData.with(S.to, S.schema({ n: S.number }));
  for (const [text, value] of [
    ["42", 42],
    ["  42  ", 42],
    ["42.00", 42],
    ["+42", 42],
    [".5", 0.5],
    ["1e5", 100000],
    ["0x10", 16],
    ["Infinity", Infinity],
  ] as const) {
    expect(S.decoder(schema)(form(["n", text])), text).toEqual({ n: value });
  }
  for (const text of ["42abc", "1_000", "NaN", "", " "]) {
    expect(() => S.decoder(schema)(form(["n", text])), text).toThrow("Expected number");
  }
});

test("a nested document is a JSON text field, both ways", () => {
  const schema = S.formData.with(
    S.to,
    S.schema({ prefs: S.jsonString.with(S.to, S.schema({ theme: S.string, size: S.number })) }),
  );
  const encoded = S.encoder(schema)({ prefs: { theme: "dark", size: 2 } });
  expect(entries(encoded)).toEqual([["prefs", `{"theme":"dark","size":2}`]]);
  expect(S.decoder(schema)(encoded)).toEqual({ prefs: { theme: "dark", size: 2 } });
});

test("the reverse is spelled the same as jsonString's", () => {
  const user = S.schema({ name: S.string.with(S.nonEmpty), age: S.number });
  const value = { name: "Ann", age: 42 };
  expect(entries(S.encoder(user, S.formData)(value))).toEqual([
    ["name", "Ann"],
    ["age", "42"],
  ]);
  expect(S.decoder(S.formData, user)(S.encoder(user, S.formData)(value))).toEqual(value);
  expect(entries(S.parser(user.with(S.to, S.formData))(value))).toEqual([
    ["name", "Ann"],
    ["age", "42"],
  ]);
});

test("a runtime without FormData says so on every route into the schema", () => {
  const message = "[Sury] S.formData is not supported in this runtime";
  expect(
    withoutGlobalRoutes("FormData", [
      `S.parser(S.formData)`,
      `S.inputExpression(S.formData)`,
      `S.encoder(S.schema({ a: S.string }), S.formData)`,
      `S.decoder(S.formData, S.schema({ a: S.string }))`,
      // And the sibling the runtime does have is untouched.
      `typeof S.parser(S.file)`,
    ]),
  ).toEqual([message, message, message, message, "ok:function"]);
});
