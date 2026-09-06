# Operations API rework — implementation plan

Status: planned, nothing implemented. Target: `11.0.0-rc.x`, before 11.0 final.

Every operation names its outcome, takes any of four call forms, and compiles
its Result tail instead of wearing a wrapper. `S.safe` and the `input*`/`async*`
naming go away.

Line references were verified against the tree at the time of writing; re-check
before relying on one.

## 1. Why

Three problems with the current surface, in the order they cost users:

1. **Throwing is invisible.** `S.parser(schema)(data)` throws and the call site
   never says so.
2. **The names aren't derivable.** `parser` / `assertInput` / `inputValidator` /
   `asyncInputConstructor` are four naming conventions in one namespace.
3. **The non-throwing path is a wrapper.** `S.safe(() => S.parser(s)(d))` costs a
   closure and a frame per call, and a wrapper can never skip the `try` on a
   schema that provably cannot throw. A compiled result mode can.

## 2. Naming grammar

Two connectives, one rule each:

- **`Or<X>`** — what you get *instead of* the value: `OrThrow`, `OrReject`.
  Reserved for later: `OrNull`, `OrUndefined`, `Or(fallback)`.
- **`As<X>`** — the return type, spelled as an English compound, head last:
  `AsResult`, `AsPromiseOrReject`, `AsResultPromise`, `AsPromisableResult`.
  Reserved for `packages/sury-effect`: `AsEffect`.

A suffix names the failure mechanism **only when the return type doesn't reveal
it**. `O` and `Promise<O>` reveal nothing, so they take `OrThrow` / `OrReject`.
`Result<O>` and `Promise<Result<O>>` carry failure in the type, so they take
none. `is` cannot fail, so it takes none either — that is the rule applying, not
an exception.

`assert` *does* take `OrThrow`, against that rule, for three reasons: `S.res`
already ships `assertOrThrow`; `assert` does not unambiguously mean "throws" in
JS (`console.assert` logs and continues); and the async form returns
`Promise<void>`, which reveals nothing, so it needs `OrReject` regardless — and
a bare `assertInput` beside `assertInputAsPromiseOrReject` is a worse
asymmetry than suffixing both.

| Outcome | Returns | Suffix |
| --- | --- | --- |
| value | `O` | `OrThrow` |
| result | `Result<O>` | `AsResult` |
| promise | `Promise<O>` | `AsPromiseOrReject` |
| promise of result | `Promise<Result<O>>` | `AsResultPromise` |
| promisable result | `Result<O> \| Promise<Result<O>>` | `AsPromisableResult` |

`AsPromisableOrThrow` is deliberately **not** built, in either language.

## 3. Surface

### Conversions

Verbs: `parse` (unknown → Output), `decode` (Input → Output), `encode` (Output →
Input), `makeInput` (value → Input), `makeOutput` (value → Output).

Each takes all five outcome suffixes, except that `AsPromisableResult` ships for
`parse` only in wave 1 (§8).

```
parseOrThrow  parseAsResult  parseAsPromiseOrReject  parseAsResultPromise  parseAsPromisableResult
decodeOrThrow decodeAsResult decodeAsPromiseOrReject decodeAsResultPromise
encodeOrThrow ...
makeInputOrThrow ...
makeOutputOrThrow ...
```

### Checks

Direction is a free parameter for these, so it is explicit and mandatory.

```
isInput  isOutput  isInputAsPromise  isOutputAsPromise
assertInputOrThrow  assertOutputOrThrow
assertInputAsPromiseOrReject  assertOutputAsPromiseOrReject
```

`is*AsPromise` returns `Promise<boolean>` and never rejects.

### Removed

| Removed | Replacement |
| --- | --- |
| `safe`, `safeAsync` | the `*AsResult` operations |
| `$safe`, `$safeAsync` | the `$*AsResult` operations |
| `parser`, `decoder`, `encoder` | same verbs, `*OrThrow` |
| `asyncParser`, `asyncDecoder`, `asyncEncoder` | `*AsPromiseOrReject` |
| `assertInput`, `assertOutput` | `assert*OrThrow` |
| `asyncAssertInput`, `asyncAssertOutput` | `assert*AsPromiseOrReject` |
| `inputValidator`, `outputValidator` | `isInput`, `isOutput` |
| `inputConstructor`, `outputConstructor`, `async*Constructor` | `make*` |

## 4. Call forms

Four forms on every operation, discriminated at runtime:

```
op(s)                  → compiled operation      (curried / data-last)
op(s₁ … sₙ)            → compiled chain          (n ≤ 3)
op(s₁ … sₙ, data)      → immediate, schema-first
op(data, s₁ … sₙ)      → immediate, data-first
```

Three schemas is the ceiling because that is ReScript's `~from` / `~via` / `~to`.
Deeper chains use `.with(S.to, …)`.

`arguments.length` falls out of the partition — `op(S.void)` is arity 1 and
compiles; `op(S.void, undefined)` has a trailing non-schema and parses
`undefined`. **Never** test `arg === undefined` to detect the compiled form.

### Unreachable case, accepted

`op(s₁, s₂)` with two schemas always reads as a chain, so parsing a Sury schema
*as data* is only available compiled: `S.parseOrThrow(Meta)(schemaObj)`.
Documented; no ordering makes both reachable.

## 5. Runtime

### 5.1 Dispatch predicate — ship this first, it is a live bug

`isSchemaObject` (`base.ts:560`) duck-types on `"~standard" in obj`, deliberately,
to avoid the prototype getter's allocation while building definitions. Operation
dispatch must **not** use it: with data-first, a payload carrying a `~standard`
key is read as the schema, and a schema that failed the test would be parsed as
data. Data being validated is untrusted by definition.

```ts
// Exactly two schema prototypes exist, both Object.create(null)-rooted
// (base.ts:730, base.ts:758), so a plain object or a JSON.parse result can
// never match — `JSON.parse` makes `__proto__` an own property, never a
// prototype. Adding a third schema prototype breaks every operation's
// dispatch; the invariant comment belongs on those two definitions.
const isOwnSchema = (x: unknown): boolean => {
  const p = x && Object.getPrototypeOf(x);
  return p === schemaPrototype || p === selfReversePrototype;
};
```

`isSchemaObject` stays as it is for definition parsing, where foreign Standard
Schemas are legitimate. Two predicates, two jobs.

**`assertInput`'s current `(data, schema)` sniffing has this bug today.** Fix it
as a standalone commit ahead of the rename.

A foreign Standard Schema passed as an operation argument must panic with
"expected a Sury schema" rather than silently becoming data.

### 5.2 Dispatch

Max arity 4, so named parameters — only `arguments.length` is read and the
arguments object is never materialized.

```ts
export function parseOrThrow(a, b, c, d) {
  switch (arguments.length) {
    case 1: return getDecoder1(unknown, a);
    case 2: return !isOwnSchema(a) ? getDecoder1(unknown, b)(a)
                 :  isOwnSchema(b) ? getDecoder2(unknown, a, b)
                 :                   getDecoder1(unknown, a)(b);
    // … arity 3 and 4 likewise
  }
}
```

A non-schema in the middle (`op(a, undefined, b)`) is a hole and panics. Dispatch
must not skip `undefined`, or `op(S.void, undefined)` would misread as compiled.

Each branch knows its arity statically, so it calls an arity-specialised lookup
(`getDecoder1` / `getDecoder2` / `getDecoder3`) that skips the generic
`arguments` walk in `getDecoder` (`parse.ts:351`). `findOpNode` (`parse.ts:331`)
already proves the shape for the fixed-two case. Keep them flat and
individually shakeable.

### 5.3 Tree-shaking — do not annotate

**No dual operation may carry `// @__NO_SIDE_EFFECTS__`.** Today's `parser` /
`decoder` / `encoder` are annotated correctly because they only compile. The
arity-2 form *executes*, and validation-only calls discard their result
(`S.assertInputOrThrow(User, data)`, or `S.parseOrThrow(User, data)` used as a
check) — an annotated pure call with an unused result is **dropped by esbuild**,
silently deleting validation in production.

Every new operation joins `EFFECTFUL` in `tests/treeShaking_test.ts`, which
already lists `assert`, `is`, `safe` for the same reason.

Accepted regression: `S.parser(schema)` in dead code can be dropped today and
will not be after. Unused *imports* still shake normally — only unused-result
calls are affected. Note it in the changelog.

### 5.4 Flag bits

`base.ts` documents 1 async, 2 disableNaN, 4 union-transform-context, 64 flatten.
Claim three free bits:

| Bit | Mode |
| --- | --- |
| 8 | JS result — `{success, value, error}` |
| 16 | ReScript result — `{TAG, _0}` |
| 32 | promisable |

`getDecoder` already keys its memo on the flag, so each mode compiles and caches
independently and **the throw path's generated code is unchanged**. The ReScript
tail ships only to bundles importing `S.res.mjs`, so the two result tails shake
independently.

### 5.5 Codegen tails

```js
// throw mode — byte-identical to today
(i)=>{ …checks…; return o }

// result mode
(i)=>{ try { …checks…; return {success:true,value:o,error:void 0} }
       catch(e){ if(e&&e.s===s) return {success:false,value:void 0,error:e}; throw e } }
```

Two decisions that a wrapper cannot make, and which are the point of doing this
in the compiler:

- **A schema that provably cannot throw emits no `try` at all** — just the
  literal. `noValidation` schemas, and any compile that emitted no check,
  refinement or conversion.
- **Both branches carry all three keys in the same order**, with `void 0`
  fillers, so the two results share one hidden class and a consumer's
  `.success` / `.value` reads stay monomorphic. This is the same decision as the
  `?: undefined` sibling fields in the type (§6) — the narrowing fix and the
  shape fix are one fix. Cost is a slot per result object; measure both ways
  before locking it (§9).

Async tails inline the same way: `.then(v => ({success:true, …}), e => …)`
emitted into the generated body, not wrapped around it.

## 6. Types

```ts
type Result<T> =
  | { readonly success: true;  readonly value: T; readonly error?: undefined }
  | { readonly success: false; readonly error: DataError; readonly value?: undefined }

type Promisable<T> = T | Promise<T>
```

The sibling `?: undefined` fields make `const { value, error } = result` narrow;
without them destructuring silently does not.

### Error split

```ts
type DataError   = invalid_input | unrecognized_keys | invalid_conversion  // per value
type DefectError = invalid_operation | unsupported_decode                  // per schema
```

`*AsResult` returns `DataError` and rethrows defects. A schema wired wrong fails
for every input — that is the developer's bug, not an entry in someone's form
validation. `~standard.validate` already makes this split deliberately
(`operations.ts:129`, and the comment above it); this makes the compiler enforce
it.

`invalid_conversion` is on the data side: `B_makeInvalidConversionDetails`
(`builder.ts:247`) fires when a user codec throws mid-decode, per value.
`B_unsupportedDecode` (`builder.ts:223`) fires while building, per schema.

### Overloads

Nine per operation, arity-discriminated, in this order. Chain overloads precede
`(s, data)` so `op(s, s)` never reads as parse-a-schema-as-data.

```ts
(s): (data: unknown) => O
(s1, s2): (data: unknown) => O2
(s, data: unknown): O
(data: unknown, s): O
(s1, s2, s3): (data: unknown) => O3
(s1, s2, data: unknown): O2
(data: unknown, s1, s2): O2
(s1, s2, s3, data: unknown): O3
(data: unknown, s1, s2, s3): O3
```

Fixed arities rather than variadic tuples, for two reasons: `index.d.ts:101`
already records that dedicated arity overloads "resolve far cheaper than the
rest-tuple form", and `(...schemas, data)` is inexpressible because a rest
parameter must be last.

**Known papercut:** `data` typed `any` (e.g. an untyped `req.body`) matches the
chain overload on a 2-argument call and yields a function. It fails at the
assignment, not silently. Document: type inputs `unknown`.

## 7. ReScript

Names match TS exactly, with `compile`-prefixed arity-1 forms (ReScript has no
overloads), and two deliberate divergences — both because `t<'value>` names the
**output** type (`S.res:678`):

| ReScript | JS |
| --- | --- |
| `makeOrThrow` | `makeOutputOrThrow` |
| `convertOrThrow` / `convertAsResult` / `convertAsPromiseOrReject` / `convertAsResultPromise` | `encode*` |
| `parseOrThrow` / `parseAsResult` / `parseAsPromiseOrReject` / `parseAsResultPromise` | same, `$`-prefixed for the result forms |
| `isInput` / `isOutput` | same — replaces `validate` |
| `assertInputOrThrow` / `assertOutputOrThrow` | same |
| `compileParseOrThrow(~to)` etc. | arity-1 form |

No promisable family in ReScript.

**`$`-prefixed result exports.** JS `Result` is `{success, value, error}`;
ReScript's is `{TAG, _0}`. Two shapes, one compiler (flag bits 8 and 16), so
`$parseAsResult` / `$decodeAsResult` / `$encodeAsResult` / `$makeAsResult` /
`$parseAsResultPromise` are legitimate `$` exports under CLAUDE.md — a
ReScript-only result shape has no public-JS equivalent.

**`$safe` / `$safeAsync` are deleted.** `S.res:687` (`let parse = (any, ~to) =>
safe(() => parseOrThrow(any, ~to))`) and `:696` (`convert`) become direct binds.
Two exports leave the JS surface and ReScript stops paying a closure per call.

**`encoder2` / `encoder3` survive.** An absent `~via=?` compiles to a literal
`undefined` in the middle of the argument list, which dispatch rejects as a hole.
The comment at `S.res:637` stays true (`encoder2` is declared at `:641`).

## 8. Work breakdown

Each slice ends with `pnpm spec check --write`; the printed metric summary is the
deliverable.

### Slice 0 — `isOwnSchema` dispatch fix (independent)

Ships alone, ahead of everything. Fixes a live bug in `assertInput`.

- `base.ts` — add `isOwnSchema`; invariant comment on `schemaPrototype` (`:730`)
  and `selfReversePrototype` (`:758`).
- `entry.ts` — `assertInput` / `assertOutput` / `asyncAssert*` use it.
- Specs: `assertInput(JSON.parse('{"~standard":1}'), s)`; a foreign Standard
  Schema as an operation argument panics; every construction path
  (`copySchema`, `updateOutput`, `reverse`, `recursive`) preserves a schema
  prototype.

### Slice 1 — `parseOrThrow` + `parseAsResult`

The slice that decides whether the rest is affordable.

- `base.ts` — flag bits 8/16/32 in the flag comment.
- `builder.ts` / `parse.ts` — result tail emit, the no-`try` case, arity-
  specialised lookups.
- `entry.ts` — the two operations, four call forms, no `@__NO_SIDE_EFFECTS__`.
- `index.d.ts` — `Result`, `DataError` / `DefectError`, nine overloads.
- `tests/treeShaking_test.ts` — `EFFECTFUL` entries.
- Specs: all nine shapes; `op(S.void)` vs `op(S.void, undefined)`; hole panics;
  arity-1/chain/immediate share one `OpNode`; result codegen with and without
  checks; `noValidation` emits no `try`.
- Scenarios: each of the four call shapes vs the hoisted baseline; result object
  with and without `void 0` fillers.

**Gate:** throw-mode goldens byte-identical, parse-only bundle unchanged, type
cost flat or better, and `parse-safe*` beaten by >7%.

### Slice 2 — `parseAsPromisableResult`, rewire `~standard`

- Public `Promisable<T>`.
- `operations.ts:129` — the `~standard.validate` getter drops the
  compile-sync / catch / recompile-async / `.then` dance and calls the
  promisable operation. `parse.ts:164`'s `Promise.resolve` wrapper stops firing
  for sync schemas on this path.
- Scenarios: `standard-schema-validate` and `-invalid` should both improve; that
  is the slice's proof.

### Slice 3 — `decode` / `encode` / `makeInput` / `makeOutput`

Same bits, same nine overloads. Mechanical once slice 1 lands.

### Slice 4 — `is*` / `assert*`, removals

- `isInput` / `isOutput` / `assert*OrThrow` / `*AsPromise*`.
- Delete `safe`, `safeAsync`, `inputValidator`, `outputValidator`,
  `*Constructor`, the old `parser` / `decoder` / `encoder` / `async*` names, the
  variadic operation overload and the `(data, schema)` sniffing.
- Update `docs/js-usage.md`.

### Slice 5 — ReScript

- `S.res` renames per §7, `$`-prefixed result binds, delete `$safe` /
  `$safeAsync` from `entry.ts` and `operations.ts`.
- Keep `encoder2` / `encoder3`.
- Update `docs/rescript-usage.md`.

## 9. Gates

1. Throw-mode codegen goldens **byte-identical**.
2. A parse-only bundle unchanged — the result emitter shakes completely.
3. Net type cost (`ts.instantiations`) flat or better. Nine cheap arity overloads
   replace three including the variadic `ExtractLastOutput` inference; if the
   budget still breaks, drop the arity-4 pair first, then the data-first chain
   overloads (runtime keeps working, only the typing goes).
4. `pnpm --filter=sury fuzz:union` unaffected.
5. Scenario `parse-safe` / `parse-safe-compiled` / `parse-safe-invalid`
   (committed in `181f773`) beaten by **more than 7%** — the scenario noise
   floor. A win below that is not provable and does not count.

Note for whoever runs this: `spec check --perf=skip` does **not** execute
scenarios. A deliberately broken scenario still exits 0 under it. Use the full
`check` or `--perf=only` when scenario correctness matters.

## 10. Open decisions

- **Result object fillers.** `void 0` for the absent branch buys hidden-class
  monomorphism and costs a slot. Measure both ways in slice 1 and record the
  answer here.
- **Arity-4 overloads.** First to cut if type cost breaks.
- **`AsPromisableResult` for verbs other than `parse`.** Deferred until asked.
- **Reserved, not built:** `parseOrNull`, `parseOrUndefined`, `parseOr(fallback)`
  in core; `parseAsEffect` in `packages/sury-effect`.
