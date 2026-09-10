// `S.env` - an environment variable value. A string format so JSON Schema
// is `{ type: "string" }`, not an instance with no document form.
// Empty string is absent unless the target keeps it with `S.minLength(0)`.
// A bare `S.string` is ambiguous.

import { initSchema, stringTag, tagFlags, type Internal, type Val } from "../base";
import { B_next, B_refine, B_unsupportedDecode, failInvalidType } from "../builder";
import { string, typeofCond } from "../primitives";
import { convertTextEntry } from "./entries";

const envDecoder = (input: Val): Val => {
  const flag = tagFlags[input.s.type]!;
  if (input.s === input.e || input.s.format === "env") {
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
  s.encoder = (input, target) => convertTextEntry(input, target, string, true);
});
