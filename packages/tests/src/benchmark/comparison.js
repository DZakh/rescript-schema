import B from "benchmark";
import { z } from "zod";
import * as V from "valibot";
import * as S from "rescript-struct/src/S_JsApi.js";

new B.Suite()
  .add("rescript-struct", () => {
    return () => {
      const struct = S.object({
        email: S.String.email(S.string),
        password: S.String.min(S.string, 8),
      });
      const data = { email: "jane@example.com", password: "12345678" };
      return () => {
        return S.parseOrThrow(struct, data);
      };
    };
  })
  .add("Zod", () => {
    const schema = z.object({
      email: z.string().email(),
      password: z.string().min(8),
    });
    const data = { email: "jane@example.com", password: "12345678" };
    return () => {
      return schema.parse(data);
    };
  })
  .add("Valibot", () => {
    const schema = V.object({
      email: V.string([V.email()]),
      password: V.string([V.minLength(8)]),
    });
    const data = { email: "jane@example.com", password: "12345678" };
    return () => {
      return V.parse(schema, data);
    };
  })
  .on("cycle", (event) => {
    console.log(String(event.target));
  })
  .run();
