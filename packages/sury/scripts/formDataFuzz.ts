// `S.formData` codec fuzzer.
//
//   pnpm --filter=sury fuzz:formdata
//   pnpm --filter=sury fuzz:formdata --show-known
//
// The union fuzzer differs against a reference implementation. This one has
// none — a form submission is whatever a browser sends, and nothing here can
// re-derive that — so it checks the three properties the codec claims for
// itself, over every wrapper crossed with every leaf:
//
//   symmetry     a field works in both directions or is rejected in both, with
//                a Sury error. A `TypeError` out of the compiler is always a
//                finding, and so is a field that only encodes: nothing tells
//                the author, and the data is unreadable by the time anyone
//                notices.
//   no mutation  encoding does not write into the value it was handed.
//   round-trip   `decode(encode(value))` is `value`.
//
// Each has a list of the cases known not to hold, keyed by what the run prints,
// with the reason written out — a blank entry and an absent one are the same
// submission, so some pairs genuinely cannot survive the wire. The run fails on
// anything not listed, and on anything listed that has started to hold. A key
// may name `*` for the wrapper or for the leaf.
//
// The cross is exhaustive rather than sampled: it is a few hundred cases, so a
// seed would only re-find them more slowly. Add a leaf or a wrapper and the
// cross grows on its own.

import * as S from "../index.mjs";

type Leaf = { schema: unknown; values: unknown[] };

const file = (name: string, body: string): File => new File([body], name);

// One leaf per reading the codec has: text, each coercion, the entry taken as
// it is, and the unions whose arms disagree about what an entry means.
const LEAVES: Record<string, Leaf> = {
  string: { schema: S.string.with(S.nonEmpty), values: ["x", "on", "0", " "] },
  "string-blank-ok": { schema: S.string.with(S.minLength, 0), values: ["", "x"] },
  literal: { schema: S.schema("x"), values: ["x"] },
  number: { schema: S.number, values: [0, 42, -1.5, 1e21, Infinity] },
  int32: { schema: S.int32, values: [0, -7] },
  bigint: { schema: S.bigint, values: [0n, 10n ** 30n] },
  boolean: { schema: S.boolean, values: [true, false] },
  "literal-true": { schema: S.schema(true), values: [true] },
  date: { schema: S.date, values: [new Date(0), new Date("2026-09-06T00:00:00.000Z")] },
  file: { schema: S.file, values: [file("a.txt", "hi"), file("empty.bin", "")] },
  blob: { schema: S.blob, values: [new Blob(["hi"])] },
  enum: { schema: S.union(["yes", "no"]), values: ["yes", "no"] },
  "json-string": {
    schema: S.jsonString.with(S.to, S.schema({ a: S.number })),
    values: [{ a: 1 }],
  },
  "to-date": { schema: S.string.with(S.to, S.date), values: [new Date(0)] },
  "union-text": { schema: S.union([S.string, S.number]), values: ["x", 1] },
  "union-checkbox": { schema: S.union([S.boolean, S.number]), values: [true, false, 0, 1, 2] },
  "union-entry": { schema: S.union([S.string, S.file]), values: ["x", file("a.txt", "hi")] },
  unknown: { schema: S.unknown, values: ["x"] },
  null: { schema: S.schema(null), values: [null] },
  void: { schema: S.void, values: [undefined] },
};

// Every way a field can wrap one of them.
const WRAPPERS: Record<string, (leaf: Leaf) => Leaf> = {
  bare: (leaf) => leaf,
  optional: (leaf) => ({
    schema: S.optional(leaf.schema as never),
    values: [...leaf.values, undefined],
  }),
  defaulted: (leaf) => ({
    schema: S.optional(leaf.schema as never, leaf.values[0] as never),
    values: leaf.values,
  }),
  nullable: (leaf) => ({
    schema: S.nullable(leaf.schema as never),
    values: [...leaf.values, null],
  }),
  nullish: (leaf) => ({
    schema: S.nullish(leaf.schema as never),
    values: [...leaf.values, null, undefined],
  }),
  array: (leaf) => ({
    schema: S.array(leaf.schema as never),
    values: [[], leaf.values, [leaf.values[0]]],
  }),
  "optional-array": (leaf) => ({
    schema: S.optional(S.array(leaf.schema as never)),
    values: [leaf.values, undefined],
  }),
  tuple: (leaf) => ({
    schema: S.schema([leaf.schema, leaf.schema] as never),
    values: [[leaf.values[0], leaf.values[leaf.values.length - 1]]],
  }),
};

// Fields the codec reads but cannot write, which the author hears about when
// the encoder is compiled and not before.
const ONE_WAY: Record<string, string> = {
  "*/union-text":
    "the union rules reject `string -> string | number` on the way out, where the codec is not consulted at all",
  "*/union-entry": "the same, for `string | File`",
};

// Values the wire cannot carry back, and why.
const KNOWN: Record<string, string> = {
  "*/union-checkbox <- 0":
    '"0" is both an unchecked box and zero, and the boolean arm is tried first',
  "*/union-checkbox <- 1": '"1" is both a checked box and one, and the boolean arm is tried first',
  "array/union-checkbox <- [true,false,0,1,2]": "the same, per item",
  "optional-array/union-checkbox <- [true,false,0,1,2]": "the same, per item",
  "nullish/* <- null":
    "a form has one way to say nothing, so a field declaring both sentinels reads it as the weaker one",
  "optional/null <- null": "the same, from the other side",
  "defaulted/boolean <- false":
    "an unchecked box sends nothing, so a default of `true` states what the wire never says and reads back as itself",
  "nullable/void <- null": "the same, from the other side",
};

// Where an encode writes into the value it was handed.
const MUTATES: Record<string, string> = {
  "tuple/union-checkbox":
    "a union dispatch assigns its result back into the slot it read, and a tuple slot is an index into the caller's array. Not this codec's doing — `S.schema([union]).with(S.to, S.schema([S.string]))` does it with no form in sight (see IDEAS)",
};

// A key matches its own entry, or one naming `*` for the wrapper or the leaf.
const reasonFor = (
  list: Record<string, string>,
  wrapper: string,
  leaf: string,
  value?: string,
): string | undefined => {
  const tail = value === undefined ? "" : ` <- ${value}`;
  return list[`${wrapper}/${leaf}${tail}`] ?? list[`*/${leaf}${tail}`] ?? list[`${wrapper}/*${tail}`];
};

// Blob identity is not object identity: `append` renames a bare Blob to "blob"
// and reads it back as a File, so bytes — and a File's name — are what must
// survive.
const same = (a: unknown, b: unknown): boolean => {
  if (a instanceof Blob && b instanceof Blob) {
    return a.size === b.size && (a instanceof File && b instanceof File ? a.name === b.name : true);
  }
  if (a instanceof Date && b instanceof Date) return Object.is(+a, +b);
  if (Array.isArray(a) && Array.isArray(b)) {
    return a.length === b.length && a.every((item, index) => same(item, b[index]));
  }
  if (typeof a === "object" && a !== null && typeof b === "object" && b !== null) {
    const keys = Object.keys(a);
    return (
      keys.length === Object.keys(b).length &&
      keys.every((key) => same((a as never)[key], (b as never)[key]))
    );
  }
  return Object.is(a, b) || (typeof a === "number" && isNaN(a) && isNaN(b as number));
};

// Blobs and Dates are handed over as they are: neither has an index an encode
// could write into, and one that mutated a Blob would be a different finding.
const copy = (value: unknown): unknown => {
  if (Array.isArray(value)) return value.map(copy);
  if (
    value !== null &&
    typeof value === "object" &&
    !(value instanceof Blob) &&
    !(value instanceof Date)
  ) {
    return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, copy(item)]));
  }
  return value;
};

const show = (value: unknown): string => {
  if (value instanceof File) return `File(${value.name})`;
  if (value instanceof Blob) return `Blob(${value.size})`;
  if (value instanceof Date) return `Date(${value.toJSON() ?? "invalid"})`;
  if (typeof value === "bigint") return `${value}n`;
  if (Array.isArray(value)) return `[${value.map(show).join(",")}]`;
  if (value && typeof value === "object") {
    return `{${Object.entries(value)
      .map(([key, item]) => `${key}:${show(item)}`)
      .join(",")}}`;
  }
  return typeof value === "string" ? `'${value}'` : String(value);
};

// A Sury rejection is an answer; anything else is the compiler falling over.
const compile = (build: () => unknown): { fn?: unknown; rejected?: string; crash?: string } => {
  try {
    return { fn: build() };
  } catch (error) {
    const err = error as Error;
    return err instanceof S.Error
      ? { rejected: err.message.split("\n")[0] }
      : { crash: `${err.constructor.name}: ${err.message}` };
  }
};

const findings: string[] = [];
const used = new Set<string>();
let checked = 0;
let rejected = 0;

// Listed with a reason, which is what keeps a pass from being silent.
const excused = (
  list: Record<string, string>,
  wrapper: string,
  leaf: string,
  value?: string,
): boolean => {
  const reason = reasonFor(list, wrapper, leaf, value);
  if (reason === undefined) {
    return false;
  }
  used.add(reason);
  return true;
};

for (const [wrapperName, wrap] of Object.entries(WRAPPERS)) {
  for (const [leafName, leaf] of Object.entries(LEAVES)) {
    const id = `${wrapperName}/${leafName}`;
    let field: Leaf;
    try {
      field = wrap(leaf);
    } catch {
      // A wrapper the public API refuses to build is not this codec's business.
      continue;
    }
    const schema = S.formData.with(S.to, S.schema({ a: field.schema as never }) as never);
    const decode = compile(() => S.decoder(schema));
    const encode = compile(() => S.encoder(schema));

    for (const [direction, result] of [
      ["decode", decode],
      ["encode", encode],
    ] as const) {
      if (result.crash) {
        findings.push(`${id}: ${direction} compile crashed — ${result.crash}`);
      }
    }
    if (!decode.rejected !== !encode.rejected) {
      const shape = decode.rejected ? "encodes but does not decode" : "decodes but does not encode";
      if (!excused(ONE_WAY, wrapperName, leafName)) {
        findings.push(`${id}: ${shape} — ${decode.rejected ?? encode.rejected}`);
      }
    } else if (reasonFor(ONE_WAY, wrapperName, leafName) !== undefined) {
      findings.push(`${id}: listed in ONE_WAY but works in both directions — delete the entry`);
    }
    if (decode.rejected || encode.rejected || decode.crash || encode.crash) {
      rejected += 1;
      continue;
    }

    let mutated = false;
    for (const value of field.values) {
      const printed = show(value);
      const key = `${id} <- ${printed}`;
      checked += 1;
      const before = copy(value);
      let back: unknown;
      try {
        back = (decode.fn as (form: FormData) => { a: unknown })(
          (encode.fn as (value: unknown) => FormData)({ a: value }),
        ).a;
      } catch (error) {
        if (!excused(KNOWN, wrapperName, leafName, printed)) {
          findings.push(`${key}: round-trip threw — ${(error as Error).message.split("\n")[0]}`);
        }
        continue;
      }
      if (!same(before, value)) {
        mutated = true;
        if (!excused(MUTATES, wrapperName, leafName)) {
          findings.push(`${key}: the encode wrote into its input, leaving ${show(value)}`);
        }
      }
      if (same(before, back)) {
        if (reasonFor(KNOWN, wrapperName, leafName, printed) !== undefined) {
          findings.push(`${key}: listed in KNOWN but round-trips — delete the entry`);
        }
      } else if (!excused(KNOWN, wrapperName, leafName, printed)) {
        findings.push(`${key}: read back as ${show(back)}`);
      }
    }
    if (!mutated && reasonFor(MUTATES, wrapperName, leafName) !== undefined) {
      findings.push(`${id}: listed in MUTATES but leaves its input alone — delete the entry`);
    }
  }
}

for (const [name, list] of [
  ["ONE_WAY", ONE_WAY],
  ["KNOWN", KNOWN],
  ["MUTATES", MUTATES],
] as const) {
  for (const [key, reason] of Object.entries(list)) {
    if (!used.has(reason)) {
      findings.push(`${key}: listed in ${name} but no such case ran — the catalog moved under it`);
    }
  }
}

if (process.argv.includes("--show-known")) {
  for (const [name, list] of [
    ["one-way fields", ONE_WAY],
    ["pairs the wire cannot tell apart", KNOWN],
    ["encodes that write into their input", MUTATES],
  ] as const) {
    console.log(`\n${name}:`);
    for (const [key, reason] of Object.entries(list)) {
      console.log(`  ${key}\n    ${reason}`);
    }
  }
  console.log("");
}

console.log(
  `${checked} round-trips over ${Object.keys(WRAPPERS).length}x${Object.keys(LEAVES).length} fields, ${rejected} rejected in both directions`,
);
if (findings.length) {
  console.log(`\n${findings.length} finding(s):`);
  for (const finding of findings) {
    console.log(`  ${finding}`);
  }
  process.exitCode = 1;
} else {
  console.log("No findings.");
}
