import B from "benchmark";
import { z } from "zod";
import * as V from "valibot";
import * as S from "rescript-schema/src/S.js";
import { type } from "arktype";

const data = Object.freeze({
  number: 1,
  negNumber: -1,
  maxNumber: Number.MAX_VALUE,
  string: "string",
  longString:
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Vivendum intellegat et qui, ei denique consequuntur vix. Semper aeterno percipit ut his, sea ex utinam referrentur repudiandae. No epicuri hendrerit consetetur sit, sit dicta adipiscing ex, in facete detracto deterruisset duo. Quot populo ad qui. Sit fugit nostrum et. Ad per diam dicant interesset, lorem iusto sensibus ut sed. No dicam aperiam vis. Pri posse graeco definitiones cu, id eam populo quaestio adipiscing, usu quod malorum te. Ex nam agam veri, dicunt efficiantur ad qui, ad legere adversarium sit. Commune platonem mel id, brute adipiscing duo an. Vivendum intellegat et qui, ei denique consequuntur vix. Offendit eleifend moderatius ex vix, quem odio mazim et qui, purto expetendis cotidieque quo cu, veri persius vituperata ei nec. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
  boolean: true,
  deeplyNested: {
    foo: "bar",
    num: 1,
    bool: false,
  },
});

const arkType = type({
  number: "number",
  negNumber: "number",
  maxNumber: "number",
  string: "string",
  longString: "string",
  boolean: "boolean",
  deeplyNested: {
    foo: "string",
    num: "number",
    bool: "boolean",
  },
});

const zodSchema = z.object({
  number: z.number(),
  negNumber: z.number(),
  maxNumber: z.number(),
  string: z.string(),
  longString: z.string(),
  boolean: z.boolean(),
  deeplyNested: z.object({
    foo: z.string(),
    num: z.number(),
    bool: z.boolean(),
  }),
});

const valibotSchema = V.object({
  number: V.number(),
  negNumber: V.number(),
  maxNumber: V.number(),
  string: V.string(),
  longString: V.string(),
  boolean: V.boolean(),
  deeplyNested: V.object({
    foo: V.string(),
    num: V.number(),
    bool: V.boolean(),
  }),
});

S.setGlobalConfig({
  disableNanNumberValidation: true,
});
const schema = S.schema({
  number: S.number,
  negNumber: S.number,
  maxNumber: S.number,
  string: S.string,
  longString: S.string,
  boolean: S.boolean,
  deeplyNested: {
    foo: S.string,
    num: S.number,
    bool: S.boolean,
  },
});
let parseOrThrow = S.compile(schema, "Input", "Output", "Sync", true);

new B.Suite()
  .add("rescript-schema (create)", () => {
    return S.schema({
      number: S.number,
      negNumber: S.number,
      maxNumber: S.number,
      string: S.string,
      longString: S.string,
      boolean: S.boolean,
      deeplyNested: {
        foo: S.string,
        num: S.number,
        bool: S.boolean,
      },
    });
  })
  .add("rescript-schema (parse)", () => {
    return S.parseOrThrow(data, schema);
  })
  .add("rescript-schema (precompiled parse)", () => {
    return parseOrThrow(data, schema);
  })
  .add("rescript-schema (create + parse)", () => {
    const schema = S.schema({
      number: S.number,
      negNumber: S.number,
      maxNumber: S.number,
      string: S.string,
      longString: S.string,
      boolean: S.boolean,
      deeplyNested: {
        foo: S.string,
        num: S.number,
        bool: S.boolean,
      },
    });
    return S.parseOrThrow(data, schema);
  })
  .add("Zod (create)", () => {
    return z.object({
      number: z.number(),
      negNumber: z.number(),
      maxNumber: z.number(),
      string: z.string(),
      longString: z.string(),
      boolean: z.boolean(),
      deeplyNested: z.object({
        foo: z.string(),
        num: z.number(),
        bool: z.boolean(),
      }),
    });
  })
  .add("Zod (parse)", () => {
    return zodSchema.parse(data);
  })
  .add("Zod (create + parse)", () => {
    const zodSchema = z.object({
      number: z.number(),
      negNumber: z.number(),
      maxNumber: z.number(),
      string: z.string(),
      longString: z.string(),
      boolean: z.boolean(),
      deeplyNested: z.object({
        foo: z.string(),
        num: z.number(),
        bool: z.boolean(),
      }),
    });
    return zodSchema.parse(data);
  })
  .add("Valibot (create)", () => {
    return V.object({
      number: V.number(),
      negNumber: V.number(),
      maxNumber: V.number(),
      string: V.string(),
      longString: V.string(),
      boolean: V.boolean(),
      deeplyNested: V.object({
        foo: V.string(),
        num: V.number(),
        bool: V.boolean(),
      }),
    });
  })
  .add("Valibot (parse)", () => {
    return V.parse(valibotSchema, data);
  })
  .add("Valibot (create + parse)", () => {
    const valibotSchema = V.object({
      number: V.number(),
      negNumber: V.number(),
      maxNumber: V.number(),
      string: V.string(),
      longString: V.string(),
      boolean: V.boolean(),
      deeplyNested: V.object({
        foo: V.string(),
        num: V.number(),
        bool: V.boolean(),
      }),
    });
    return V.parse(valibotSchema, data);
  })
  .add("ArkType (create)", () => {
    return type({
      number: "number",
      negNumber: "number",
      maxNumber: "number",
      string: "string",
      longString: "string",
      boolean: "boolean",
      deeplyNested: {
        foo: "string",
        num: "number",
        bool: "boolean",
      },
    });
  })
  .add("ArkType (parse)", () => {
    return arkType(data);
  })
  .add("ArkType (create + parse)", () => {
    const arkType = type({
      number: "number",
      negNumber: "number",
      maxNumber: "number",
      string: "string",
      longString: "string",
      boolean: "boolean",
      deeplyNested: {
        foo: "string",
        num: "number",
        bool: "boolean",
      },
    });
    return arkType(data);
  })
  .on("cycle", (event) => {
    console.log(String(event.target));
  })
  .run();
