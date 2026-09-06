// The operation surface: turning schemas into callables.
//
// Every operation names its outcome in its own name (`OrThrow`, `AsResult`,
// `AsPromiseOrReject`, `AsResultPromise`, `AsPromisableResult`) and takes any
// of four call forms. The Result outcomes are compiled, not wrapped: the tail
// that builds `{success, value, error}` is emitted into the operation's own
// body, which is what lets a schema that provably cannot throw skip the `try`
// entirely — a decision no `safe(() => …)` wrapper can make.
//
// Deliberately free of top-level side effects, and deliberately NOT the module
// that installs the schema prototype's interop getters (standard.ts): a bundle
// reaching a module carries its top-level statements, and an operation must not
// drag the Standard Schema machinery in with it.

import {
  type Flag,
  initSchema,
  type Internal,
  isOwnSchema,
  panic,
  panicNotSchema,
  U,
  undefinedTag,
  unknown,
  type Val
} from "./base";
import {
 __setTail,
 getOp,
 reverse,
 throwTail
} from "./parse";
import {
 B_varWithoutAllocation
} from "./builder";
import {
 literalDecoder
} from "./primitives";

// The `undefined` sentinel an assert/validate operation decodes to: the value
// runs the whole pipeline and the result is dropped.
export const assertResult: Internal = /* @__PURE__ */ initSchema(undefinedTag, literalDecoder, (s) => {
  s.const = U;
  s.noValidation = true;
});

export const assertOrThrow = (any: unknown, schema: Internal): void => {
  (getOp(0, 3, unknown, schema, assertResult) as (input: unknown) => unknown)(any);
}

// ── Result tail ──────────────────────────────────────────────────────────────

// The two Result shapes: 8 the JS `Result`, 16 ReScript's
// `result<'value, S.error>`. The Standard Schema shape (128) is emitted by
// `throwTail` instead — see the comment there.
//
// The JS pair carries the same keys in the same order — `void 0` in the slot
// the branch doesn't use — so the two branches share one hidden class and a
// consumer's `.success`/`.value` reads stay monomorphic. It is also what makes
// `const { value, error } = result` narrow on the TS side (the `?: undefined`
// sibling fields in `Result`): one decision, both halves.
const ok = (isRes: boolean, value: string): string =>
  isRes ? `{TAG:"Ok",_0:${value}}` : `{success:true,value:${value},error:void 0}`;
const err = (isRes: boolean, e: string): string =>
  isRes ? `{TAG:"Error",_0:${e}}` : `{success:false,value:void 0,error:${e}}`;

// `s` is the Sury marker symbol, the generated function's second parameter:
// anything else in flight is somebody else's exception and keeps going up.
const rethrowUnlessSury = (isRes: boolean, e: string, toPromise: boolean): string => {
  const result = err(isRes, e);
  return `if(${e}&&${e}.s===s)return ${toPromise ? `Promise.resolve(${result})` : result};throw ${e}`;
};

// The tail every operation compiles once a Result operation has been reached:
// throw mode still delegates to `throwTail`, so the throw path's generated code
// is byte-for-byte what it was.
const resultTail = (
  input: Val,
  code: string,
  out: string,
  isAsync: boolean,
  flag: Flag,
  hasDefs: boolean,
): string | undefined => {
  if (!(flag & (8 | 16))) return throwTail(input, code, out, isAsync, flag, hasDefs);
  const isRes = !!(flag & 16);
  // A promise is only produced for the async flag; the promisable mode (32)
  // asks for the value's own shape instead.
  const toPromise = !!(flag & 1) && !(flag & 32) && !hasDefs;
  const errVar = B_varWithoutAllocation(input.g);
  const valueVar = isAsync ? B_varWithoutAllocation(input.g) : "";
  const body = isAsync
    ? // Inlined into the promise chain the operation already builds, rather
      // than wrapped around it.
      `${code}return ${out}.then(${valueVar}=>(${ok(isRes, valueVar)}),${errVar}=>{${rethrowUnlessSury(isRes, errVar, false)}})`
    : `${code}return ${toPromise ? `Promise.resolve(${ok(isRes, out)})` : ok(isRes, out)}`;
  // The raise counter: when nothing merged can throw, the operation needs no
  // `try` at all — the decision a `safe(() => ...)` wrapper can never make.
  // A failure the sync phase raises has to come back in the shape the success
  // path uses, so an async operation's answer is a promise either way — the
  // consumer sees one shape whether the value died before the first await or
  // after it.
  return input.g.t
    ? `try{${body}}catch(${errVar}){${rethrowUnlessSury(isRes, errVar, isAsync || toPromise)}}`
    : body;
};

// ── Call-form dispatch ───────────────────────────────────────────────────────

// `head` is the source the compiled chain starts from — `S.unknown` for the
// operations that accept anything (`parse`), `U` where the first schema
// argument is itself the source (`decode`/`encode`). `rev` reverses that first
// argument, which is what makes an operation run the encode direction.
const compile = (
  head: Internal | undefined,
  rev: boolean,
  flag: Flag,
  // How many schema slots the dispatcher partitioned off, 1 to 3. Passed rather
  // than inferred from `s1 !== U`: a hole (`op(s, undefined, s)`) would read as
  // "two arguments" and silently drop the third.
  n: number,
  s0: unknown,
  s1?: unknown,
  s2?: unknown,
): ((data: unknown) => unknown) => {
  // A foreign Standard Schema in a schema slot is named, not silently read as
  // the data to validate; so is a hole.
  if (!isOwnSchema(s0) || (n > 1 && !isOwnSchema(s1)) || (n > 2 && !isOwnSchema(s2))) {
    panicNotSchema();
  }
  const first = rev ? reverse(s0 as Internal) : (s0 as Internal);
  return head
    ? getOp(flag, n + 1, head, first, s1 as Internal, s2 as Internal)
    : getOp(flag, n, first, s1 as Internal, s2 as Internal);
};

// The four call forms, told apart by `arguments.length` and by which arguments
// are Sury schemas:
//
//   op(s…)        → the compiled operation (curried / data-last)
//   op(s…, data)  → immediate, schema-first
//   op(data, s…)  → immediate, data-first
//
// Three schemas is the ceiling — it is ReScript's ~from/~via/~to; a longer
// chain is written with `.with(S.to, …)`.
//
// Only the argument count partitions the forms: an argument is NEVER tested
// for `undefined`, or `op(S.void, undefined)` (arity 2, a trailing non-schema,
// so a parse of `undefined`) would be misread as the compiled form of
// `op(S.void)` (arity 1).
//
// Accepted and documented: `op(s1, s2)` always reads as a chain, so parsing a
// Sury schema *as data* is only available compiled — `S.parseOrThrow(Meta)(s)`.
// No argument order makes both reachable.
const dispatch = (
  n: number,
  a: unknown,
  b: unknown,
  c: unknown,
  d: unknown,
  head: Internal | undefined,
  rev: boolean,
  flag: Flag,
): unknown => {
  switch (n) {
    case 1:
      return compile(head, rev, flag, 1, a);
    case 2:
      return isOwnSchema(a)
        ? isOwnSchema(b)
          ? compile(head, rev, flag, 2, a, b)
          : compile(head, rev, flag, 1, a)(b)
        : compile(head, rev, flag, 1, b)(a);
    case 3:
      return isOwnSchema(a)
        ? isOwnSchema(c)
          ? compile(head, rev, flag, 3, a, b, c)
          : compile(head, rev, flag, 2, a, b)(c)
        : compile(head, rev, flag, 2, b, c)(a);
    case 4:
      return isOwnSchema(a)
        ? compile(head, rev, flag, 3, a, b, c)(d)
        : compile(head, rev, flag, 3, b, c, d)(a);
    default:
      return n
        ? panic("Expected at most 3 schemas and a value. Use .with(S.to, ...) for a longer chain")
        : panicNotSchema();
  }
};

// Every Result operation goes through here, so the tail emitter is registered
// on first use. It can't be registered at this module's top level: that is a
// side effect, and a bundle that reaches this module for `parseOrThrow` would
// then carry the emitter too (parse.ts, `__setResultTail`).
const resultDispatch = (
  n: number,
  a: unknown,
  b: unknown,
  c: unknown,
  d: unknown,
  head: Internal | undefined,
  rev: boolean,
  flag: Flag,
): unknown => {
  __setTail(resultTail);
  return dispatch(n, a, b, c, d, head, rev, flag);
};

// ── Operations ───────────────────────────────────────────────────────────────
//
// NEVER annotate one of these `@__NO_SIDE_EFFECTS__`. The immediate call forms
// execute, and a validation-only call discards its result
// (`S.parseOrThrow(User, data)` used as a check) — esbuild drops an annotated
// pure call whose result is unused, which would silently delete the validation.
// tests/treeShaking_test.ts holds the matching `EFFECTFUL` entries.

export function parseOrThrow(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return dispatch(arguments.length, a, b, c, d, unknown, false, 0);
}

export function parseAsResult(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return resultDispatch(arguments.length, a, b, c, d, unknown, false, 8);
}

// The Result outcome without committing to a shape: a synchronous schema
// answers with the Result itself, an async one with a promise of it. One
// compile covers both, which is what the `~standard` bridge needs (standard.ts)
// and what a caller who doesn't know a schema's async-ness can hold.
export function parseAsPromisableResult(
  a?: unknown,
  b?: unknown,
  c?: unknown,
  d?: unknown,
): unknown {
  return resultDispatch(arguments.length, a, b, c, d, unknown, false, 1 | 8 | 32);
}
