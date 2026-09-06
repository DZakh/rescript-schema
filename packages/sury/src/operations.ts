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
 B_varWithoutAllocation,
 operationArgVar
} from "./builder";
import {
 literalDecoder
} from "./primitives";
import {
 __setTail,
 getOp,
 reverse,
 type Tail,
 throwTail
} from "./parse";

// The `undefined` sentinel an assert/validate operation decodes to: the value
// runs the whole pipeline and the result is dropped.
export const assertResult: Internal = /* @__PURE__ */ initSchema(undefinedTag, literalDecoder, (s) => {
  s.const = U;
  s.noValidation = true;
});

export const assertOrThrow = (any: unknown, schema: Internal): void => {
  (getOp(0, 3, unknown, schema, assertResult) as (input: unknown) => unknown)(any);
}

// ── Operation tail ───────────────────────────────────────────────────────────
//
// The tail every operation compiles once a mode beyond "the value, or a throw"
// has been reached. Plain throw mode still delegates to `throwTail`, so the
// throw path's generated code is byte-for-byte what it always was.

// The two Result shapes: 128 the JS `Result`, 256 ReScript's
// `result<'value, S.error>`. The Standard Schema shape (1024) is emitted by
// `throwTail` instead — see the comment there. Neither bit means the value is
// its own answer, which is `is`'s `true`.
//
// The JS pair carries the same keys in the same order — `void 0` in the slot
// the branch doesn't use — so the two branches share one hidden class and a
// consumer's `.success`/`.value` reads stay monomorphic. It is also what makes
// `const { value, error } = result` narrow on the TS side (the `?: undefined`
// sibling fields in `Result`): one decision, both halves.
const okResult = (flag: Flag, value: string): string =>
  flag & 256
    ? `{TAG:"Ok",_0:${value}}`
    : flag & 128
      ? `{success:true,value:${value},error:void 0}`
      : value;
// The bare `false` is `is`'s answer; nothing else reaches this without a
// Result shape to fill.
const errResult = (flag: Flag, e: string): string =>
  flag & 256
    ? `{TAG:"Error",_0:${e}}`
    : flag & 128
      ? `{success:false,value:void 0,error:${e}}`
      : "false";

// `s` is the Sury marker symbol, the generated function's second parameter:
// anything else in flight is somebody else's exception and keeps going up.
const rethrowUnlessSury = (flag: Flag, e: string, toPromise: boolean): string => {
  const result = errResult(flag, e);
  return `if(${e}&&${e}.s===s)return ${toPromise ? `Promise.resolve(${result})` : result};throw ${e}`;
};

const operationTail: Tail = (input, code, out, isAsync, flag, hasDefs) => {
  // 2048 (`makeInput`/`makeOutput`) hands back the value it was given, and the
  // operation's parameter is not that value once the body has run: a union
  // rebinds it while dispatching, so `return i` would answer with the encoded
  // form. Bound before the body instead — except when there is no body, where
  // the parameter is still the value and the extra `let` would only make an
  // identity operation stop looking like one.
  let value = out;
  if (flag & 2048) {
    if (code === "") {
      value = operationArgVar;
    } else {
      value = B_varWithoutAllocation(input.g);
      code = `let ${value}=${operationArgVar};${code}`;
    }
  }
  // No answer of its own for a failure — the exception still is the answer, so
  // `throwTail` still decides the identity case and the promise lift.
  if (!(flag & (128 | 256 | 4096))) {
    return throwTail(
      input,
      code,
      flag & 2048 && isAsync ? `${out}.then(()=>${value})` : value,
      isAsync,
      flag,
      hasDefs,
    );
  }
  // A promise is only produced for the async flag; the promisable mode (512)
  // asks for the value's own shape instead.
  const toPromise = !!(flag & 1) && !(flag & 512) && !hasDefs;
  const errVar = B_varWithoutAllocation(input.g);
  // 4096 (`isInput`/`isOutput`) answers `true`; 2048 already picked its value.
  const valueVar = isAsync ? B_varWithoutAllocation(input.g) : value;
  const success = okResult(flag, flag & 4096 ? "true" : flag & 2048 ? value : valueVar);
  const body = isAsync
    ? // Inlined into the promise chain the operation already builds, rather
      // than wrapped around it.
      `${code}return ${out}.then(${valueVar}=>(${success}),${errVar}=>{${rethrowUnlessSury(flag, errVar, false)}})`
    : `${code}return ${toPromise ? `Promise.resolve(${success})` : success}`;
  // The raise counter: when nothing merged can throw, the operation needs no
  // `try` at all — the decision a `safe(() => ...)` wrapper can never make.
  // A failure the sync phase raises has to come back in the shape the success
  // path uses, so an async operation's answer is a promise either way: the
  // consumer sees one shape whether the value died before the first await or
  // after it.
  return input.g.t
    ? `try{${body}}catch(${errVar}){${rethrowUnlessSury(flag, errVar, isAsync || toPromise)}}`
    : body;
};

// ── Call-form dispatch ───────────────────────────────────────────────────────

// `head` is the source the compiled chain starts from — `S.unknown` for the
// operations that accept anything (`parse`, and the check/make families), `U`
// where the first schema argument is itself the source (`decode`/`encode`).
// `rev` reverses that first argument, which is what makes an operation run the
// encode direction. `tail` closes the chain: `assertResult` for the families
// that validate and discard (`is`, `assert`, `make`).
const compile = (
  head: Internal | undefined,
  tail: Internal | undefined,
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
  const first = (rev ? reverse(s0 as Internal) : s0) as Internal;
  // The chain, in order: head, the caller's schemas, tail. Written out rather
  // than assembled into an array so nothing is allocated on a cache hit.
  return head
    ? tail
      ? n > 2
        ? getOp(flag, 5, head, first, s1 as Internal, s2 as Internal, tail)
        : n > 1
          ? getOp(flag, 4, head, first, s1 as Internal, tail)
          : getOp(flag, 3, head, first, tail)
      : getOp(flag, n + 1, head, first, s1 as Internal, s2 as Internal)
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
  tail: Internal | undefined,
  rev: boolean,
  flag: Flag,
): unknown => {
  switch (n) {
    case 1:
      return compile(head, tail, rev, flag, 1, a);
    case 2:
      return isOwnSchema(a)
        ? isOwnSchema(b)
          ? compile(head, tail, rev, flag, 2, a, b)
          : compile(head, tail, rev, flag, 1, a)(b)
        : compile(head, tail, rev, flag, 1, b)(a);
    case 3:
      return isOwnSchema(a)
        ? isOwnSchema(c)
          ? compile(head, tail, rev, flag, 3, a, b, c)
          : compile(head, tail, rev, flag, 2, a, b)(c)
        : compile(head, tail, rev, flag, 2, b, c)(a);
    case 4:
      return isOwnSchema(a)
        ? compile(head, tail, rev, flag, 3, a, b, c)(d)
        : compile(head, tail, rev, flag, 3, b, c, d)(a);
    default:
      return n
        ? panic("Expected at most 3 schemas and a value. Use .with(S.to, ...) for a longer chain")
        : panicNotSchema();
  }
};

// Every operation whose tail is more than "the value, or a throw" comes through
// here, so the emitter is registered on first use. It can't be registered at
// this module's top level: that is a side effect, and a bundle that reaches
// this module for `parseOrThrow` would then carry the emitter too (parse.ts,
// `__setTail`).
const tailDispatch = (
  n: number,
  a: unknown,
  b: unknown,
  c: unknown,
  d: unknown,
  head: Internal | undefined,
  tail: Internal | undefined,
  rev: boolean,
  flag: Flag,
): unknown => {
  __setTail(operationTail);
  return dispatch(n, a, b, c, d, head, tail, rev, flag);
};

// ── Operations ───────────────────────────────────────────────────────────────
//
// NEVER annotate one of these `@__NO_SIDE_EFFECTS__`. The immediate call forms
// execute, and a validation-only call discards its result
// (`S.parseOrThrow(User, data)` used as a check) — esbuild drops an annotated
// pure call whose result is unused, which would silently delete the validation.
// tests/treeShaking_test.ts holds the matching `EFFECTFUL` entries.
//
// One declaration each, never `export const parseAsResult = makeOp(...)`: a
// factory call at the top level is a side effect that no bundler will shake.
//
// Outcome flags: 0 OrThrow · 8 AsResult · 1 AsPromiseOrReject ·
// 1|8 AsResultPromise · 1|8|32 AsPromisableResult.
// Family flags: 256 yield the operation's input · 512 answer a boolean.

export function parseOrThrow(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return dispatch(arguments.length, a, b, c, d, unknown, U, false, 0);
}

export function parseAsResult(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, U, false, 128);
}

export function parseAsPromiseOrReject(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, U, false, 1);
}

export function parseAsResultPromise(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, U, false, 1 | 128);
}

// The Result outcome without committing to a shape: a synchronous schema
// answers with the Result itself, an async one with a promise of it. One
// compile covers both, so a caller who doesn't know a schema's async-ness
// doesn't have to lift every answer into a promise to find out.
export function parseAsPromisableResult(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, U, false, 1 | 128 | 512);
}

export function decodeOrThrow(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return dispatch(arguments.length, a, b, c, d, U, U, false, 0);
}

export function decodeAsResult(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, U, U, false, 128);
}

export function decodeAsPromiseOrReject(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, U, U, false, 1);
}

export function decodeAsResultPromise(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, U, U, false, 1 | 128);
}

// Only the first schema is reversed: `S.encodeOrThrow(a, ...rest)` starts from
// a's Output and runs the rest of the chain forward, so a pipeline after the
// reversed schema is written exactly as in `decode`. Compare
// `S.decodeOrThrow(S.reverse(a), ...rest)`, which is its longhand.
export function encodeOrThrow(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return dispatch(arguments.length, a, b, c, d, U, U, true, 0);
}

export function encodeAsResult(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, U, U, true, 128);
}

export function encodeAsPromiseOrReject(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, U, U, true, 1);
}

export function encodeAsResultPromise(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, U, U, true, 1 | 128);
}

// The make family validates and hands back the value it was given (flag 256),
// rather than the decoded clone `parse` would build: the checks run, their
// result is discarded, and the value keeps its identity.
export function makeInputOrThrow(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, false, 2048);
}

export function makeInputAsResult(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, false, 128 | 2048);
}

export function makeInputAsPromiseOrReject(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, false, 1 | 2048);
}

export function makeInputAsResultPromise(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, false, 1 | 128 | 2048);
}

export function makeOutputOrThrow(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, true, 2048);
}

export function makeOutputAsResult(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, true, 128 | 2048);
}

export function makeOutputAsPromiseOrReject(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, true, 1 | 2048);
}

export function makeOutputAsResultPromise(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, true, 1 | 128 | 2048);
}

// ── Checks ───────────────────────────────────────────────────────────────────
//
// Direction is a free parameter here — there is no value to read it off — so
// it is spelled out and mandatory. `is*` answers a boolean (flag 512) and
// never throws for a failed check; `is*AsPromise` resolves to one and never
// rejects.

export function isInput(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, false, 4096);
}

export function isOutput(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, true, 4096);
}

export function isInputAsPromise(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, false, 1 | 4096);
}

export function isOutputAsPromise(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, true, 1 | 4096);
}

// `assert` keeps `OrThrow` against the rule that a suffix names the failure
// mechanism only when the return type hides it: `assert` doesn't unambiguously
// mean "throws" in JS (`console.assert` logs and continues), `S.res` already
// ships `assertOrThrow`, and the async form returns `Promise<void>` — which
// reveals nothing — so it needs `OrReject` regardless.
export function assertInputOrThrow(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return dispatch(arguments.length, a, b, c, d, unknown, assertResult, false, 0);
}

export function assertOutputOrThrow(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return dispatch(arguments.length, a, b, c, d, unknown, assertResult, true, 0);
}

export function assertInputAsPromiseOrReject(
  a?: unknown,
  b?: unknown,
  c?: unknown,
  d?: unknown,
): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, false, 1);
}

export function assertOutputAsPromiseOrReject(
  a?: unknown,
  b?: unknown,
  c?: unknown,
  d?: unknown,
): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, true, 1);
}

// ── ReScript result surface ──────────────────────────────────────────────────
//
// JS `Result` is `{success, value, error}`; ReScript's `result<'value, S.error>`
// is `{TAG, _0}`. Two shapes, one compiler (mode bit 256 instead of 128), so
// these are legitimate `$` exports: a ReScript-only result shape has no public
// JS equivalent. The ReScript tail ships only to bundles importing S.res.mjs,
// so the two shapes tree-shake independently.

export function $parseAsResult(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, U, false, 256);
}

export function $parseAsResultPromise(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, U, false, 1 | 256);
}

export function $encodeAsResult(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, U, U, true, 256);
}

export function $encodeAsResultPromise(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, U, U, true, 1 | 256);
}

export function $makeAsResult(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, true, 256 | 2048);
}

export function $makeAsResultPromise(a?: unknown, b?: unknown, c?: unknown, d?: unknown): unknown {
  return tailDispatch(arguments.length, a, b, c, d, unknown, assertResult, true, 1 | 256 | 2048);
}
