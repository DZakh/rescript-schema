// `S.env` - an environment variable value. A string format so JSON Schema
// is `{ type: "string" }`, not an instance with no document form.
// Empty string is absent unless the target keeps it with `S.minLength(0)`.
// A bare `S.string` is ambiguous.
//
// Input is `string | undefined` (index.d.ts): a var may be unset, which is what
// `process.env` is typed as. A parse checks the text and leaves that check on
// the chain; a typed input has none, so the env adds `!==void 0` there.

import { type Check, initSchema, stringTag, tagFlags, U, type Internal, type Val } from "../base";
import { B_next, B_refine, B_unsupportedDecode, failInvalidType } from "../builder";
import { string, typeofCond } from "../primitives";
import { convertTextEntry, isAbsent } from "./entries";

// Walks the chain and the scopes it was taken from: a union case scopes the
// group's narrow, whose check became the case condition.
const unchecked = (input: Val): boolean => {
  for (let val: Val | undefined = input; val; val = val.prev) {
    if (
      (val.vc && val.vc.some((check) => check.f === failInvalidType)) ||
      (val.b && !unchecked(val.b))
    ) {
      return false;
    }
  }
  return true;
};

const definedCheck: Check = { c: (inputVar) => `${inputVar}!==void 0`, f: failInvalidType };

const envDecoder = (input: Val): Val => {
  const flag = tagFlags[input.s.type]!;
  if (input.s === input.e) {
    // The env itself as a typed operation input still has to be set to be the
    // string Output. Only there: a field or item is wrapped by its loop, and a
    // conversion that follows checks on its own.
    return input.prev === U && input.b === U && input.p === U && input.e.to === U && unchecked(input)
      ? B_refine(input, input.e, [definedCheck])
      : input;
  }
  if (input.s.format === "env") {
    return input;
  }
  if (flag & 16) {
    // Omit the key. `""+undefined` is the text "undefined".
    return input;
  }
  if (flag & 1) {
    return B_refine(input, input.e, [{ c: typeofCond(stringTag), f: failInvalidType }]);
  }
  if (flag & 2) {
    return B_refine(input, input.e);
  }
  if (flag & (4 | 8 | 1024)) {
    return B_next(input, `""+${input.i}`, input.e);
  }
  return B_unsupportedDecode(input, input.s, input.e);
};

export const env: Internal = /* @__PURE__ */ initSchema(stringTag, envDecoder, (s) => {
  s.format = "env";
  s.name = "env";
  s.encoder = (input, target) =>
    convertTextEntry(
      // The env itself as the source, not a narrow a conversion produced or a
      // field a record loop wrapped (`u`). Only a text target takes an unset
      // var as it is: an absent one reads it as its absent arm, a coercion or
      // a jsonString rejects it itself.
      (input.s === s || input.s.to === target) &&
        !input.u &&
        (tagFlags[target.type]! & 2) &&
        target.format !== "json" &&
        !isAbsent(target) &&
        unchecked(input)
        ? B_refine(input, s, [definedCheck], target)
        : input,
      target,
      string,
      true,
    );
});
