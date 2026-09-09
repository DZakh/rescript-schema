// `S.env` - an environment variable value. `process.env` is a record of these,
// so `S.decodeOrThrow(process.env, S.record(S.env), S.schema({ PORT: S.port }))`
// reads the declared keys through the same text coercions a form field uses.
// Named and instance-tagged so optional fields convert the present arm.
// Empty string is a value; a missing key is absent. Nested objects, files
// and repeated keys fail as unsupported.

import {
  initSchema,
  instanceTag,
  type Internal,
  stringTag,
  tagFlags,
  type Val
} from "../base";
import {
  B_next,
  B_refine,
  B_unsupportedDecode,
  failInvalidType
} from "../builder";
import {
  typeofCond
} from "../primitives";
import {
  convertTextEntry
} from "./entries";

const envDecoder = (input: Val): Val => {
  const flag = tagFlags[input.s.type]!;
  if (input.s === input.e || ((flag & 8192) && input.s.name === "env") || (flag & 16)) {
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

export const env: Internal = /* @__PURE__ */ initSchema(instanceTag, envDecoder, (s) => {
  s.name = "env";
  s.encoder = (input, target) => convertTextEntry(input, target, s);
});
