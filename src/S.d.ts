import { Json, Result, S_t } from "../RescriptSchema.gen";
export { Json, Result, S_error as Error } from "../RescriptSchema.gen";

/** The Standard Schema interface. */
export interface StandardSchemaV1<Input = unknown, Output = Input> {
  /** The Standard Schema properties. */
  readonly "~standard": StandardSchemaV1.Props<Input, Output>;
}

export declare namespace StandardSchemaV1 {
  /** The Standard Schema properties interface. */
  export interface Props<Input = unknown, Output = Input> {
    /** The version number of the standard. */
    readonly version: 1;
    /** The vendor name of the schema library. */
    readonly vendor: string;
    /** Validates unknown input values. */
    readonly validate: (
      value: unknown
    ) => Result<Output> | Promise<Result<Output>>;
    /** Inferred types associated with the schema. */
    readonly types?: Types<Input, Output> | undefined;
  }

  /** The result interface of the validate function. */
  export type Result<Output> = SuccessResult<Output> | FailureResult;

  /** The result interface if validation succeeds. */
  export interface SuccessResult<Output> {
    /** The typed output value. */
    readonly value: Output;
    /** The non-existent issues. */
    readonly issues?: undefined;
  }

  /** The result interface if validation fails. */
  export interface FailureResult {
    /** The issues of failed validation. */
    readonly issues: ReadonlyArray<Issue>;
  }

  /** The issue interface of the failure output. */
  export interface Issue {
    /** The error message of the issue. */
    readonly message: string;
    /** The path of the issue, if any. */
    readonly path?: ReadonlyArray<PropertyKey | PathSegment> | undefined;
  }

  /** The path segment interface of the issue. */
  export interface PathSegment {
    /** The key representing a path segment. */
    readonly key: PropertyKey;
  }

  /** The Standard Schema types interface. */
  export interface Types<Input = unknown, Output = Input> {
    /** The input type of the schema. */
    readonly input: Input;
    /** The output type of the schema. */
    readonly output: Output;
  }

  /** Infers the input type of a Standard Schema. */
  export type InferInput<Schema extends StandardSchemaV1> = NonNullable<
    Schema["~standard"]["types"]
  >["input"];

  /** Infers the output type of a Standard Schema. */
  export type InferOutput<Schema extends StandardSchemaV1> = NonNullable<
    Schema["~standard"]["types"]
  >["output"];
}

export type EffectCtx<Output, Input> = {
  schema: Schema<Output, Input>;
  fail: (message: string) => never;
};

export type Schema<Output, Input = Output> = S_t<Output, Input>;

export type Output<T> = T extends Schema<infer Output, unknown>
  ? Output
  : never;
export type Input<T> = T extends Schema<unknown, infer Input> ? Input : never;

type UnknownToOuput<T> = T extends Schema<unknown>
  ? Output<T>
  : T extends {
      [k in keyof T]: unknown;
    }
  ? {
      [k in keyof T]: UnknownToOuput<T[k]>;
    }
  : T;

type UnknownToInput<T> = T extends Schema<unknown>
  ? Input<T>
  : T extends {
      [k in keyof T]: unknown;
    }
  ? {
      [k in keyof T]: UnknownToInput<T[k]>;
    }
  : T;

type UnknownArrayToOutput<
  T extends unknown[],
  Length extends number = T["length"]
> = Length extends Length
  ? number extends Length
    ? T
    : _RestToOutput<T, Length, []>
  : never;
type _RestToOutput<
  T extends unknown[],
  Length extends number,
  Accumulated extends unknown[],
  Index extends number = Accumulated["length"]
> = Index extends Length
  ? Accumulated
  : _RestToOutput<T, Length, [...Accumulated, UnknownToOuput<T[Index]>]>;
type UnknownArrayToInput<
  T extends unknown[],
  Length extends number = T["length"]
> = Length extends Length
  ? number extends Length
    ? T
    : _RestToInput<T, Length, []>
  : never;
type _RestToInput<
  T extends unknown[],
  Length extends number,
  Accumulated extends unknown[],
  Index extends number = Accumulated["length"]
> = Index extends Length
  ? Accumulated
  : _RestToInput<T, Length, [...Accumulated, UnknownToInput<T[Index]>]>;

type Literal =
  | string
  | number
  | boolean
  | symbol
  | bigint
  | undefined
  | null
  | []
  | Schema<unknown>;

export function schema<T extends Literal>(
  value: T
): Schema<UnknownToOuput<T>, UnknownToInput<T>>;
export function schema<T extends Literal[]>(
  schemas: [...T]
): Schema<[...UnknownArrayToOutput<T>], [...UnknownArrayToInput<T>]>;
export function schema<T extends unknown[]>(
  schemas: [...T]
): Schema<[...UnknownArrayToOutput<T>], [...UnknownArrayToInput<T>]>;
export function schema<T>(
  value: T
): Schema<UnknownToOuput<T>, UnknownToInput<T>>;

export function union<A extends Literal, B extends Literal[]>(
  schemas: [A, ...B]
): Schema<
  UnknownToOuput<A> | UnknownArrayToOutput<B>[number],
  UnknownToInput<A> | UnknownArrayToInput<B>[number]
>;
export function union<A, B extends unknown[]>(
  schemas: [A, ...B]
): Schema<
  UnknownToOuput<A> | UnknownArrayToOutput<B>[number],
  UnknownToInput<A> | UnknownArrayToInput<B>[number]
>;

export const string: Schema<string>;
export const boolean: Schema<boolean>;
export const int32: Schema<number>;
export const number: Schema<number>;
export const bigint: Schema<bigint>;
export const never: Schema<never>;
export const unknown: Schema<unknown>;
export const undefined: Schema<undefined>;
export const json: (validate: boolean) => Schema<Json>;

export function safe<Value>(scope: () => Value): Result<Value>;
export function safeAsync<Value>(
  scope: () => Promise<Value>
): Promise<Result<Value>>;

export function reverse<Output, Input>(
  schema: Schema<Output, Input>
): Schema<Input, Output>;

export function parseOrThrow<Output, Input>(
  data: unknown,
  schema: Schema<Output, Input>
): Output;
export function parseJsonOrThrow<Output, Input>(
  json: Json,
  schema: Schema<Output, Input>
): Output;
export function parseJsonStringOrThrow<Output, Input>(
  jsonString: string,
  schema: Schema<Output, Input>
): Output;
export function parseAsyncOrThrow<Output, Input>(
  data: unknown,
  schema: Schema<Output, Input>
): Promise<Output>;

export function convertOrThrow<Output, Input>(
  data: Input,
  schema: Schema<Output, Input>
): Output;
export function convertToJsonOrThrow<Output, Input>(
  data: Input,
  schema: Schema<Output, Input>
): Json;
export function convertToJsonStringOrThrow<Output, Input>(
  data: Input,
  schema: Schema<Output, Input>
): string;

export function reverseConvertOrThrow<Output, Input>(
  value: Output,
  schema: Schema<Output, Input>
): Input;
export function reverseConvertToJsonOrThrow<Output, Input>(
  value: Output,
  schema: Schema<Output, Input>
): Json;
export function reverseConvertToJsonStringOrThrow<Output, Input>(
  value: Output,
  schema: Schema<Output, Input>
): string;

export function assertOrThrow<Output, Input>(
  data: unknown,
  schema: Schema<Output, Input>
): asserts data is Input;

export function tuple<Output, Input extends unknown[]>(
  definer: (s: {
    item: <ItemOutput>(
      inputIndex: number,
      schema: Schema<ItemOutput, unknown>
    ) => ItemOutput;
    tag: (inputIndex: number, value: unknown) => void;
  }) => Output
): Schema<Output, Input>;

export function optional<Output, Input>(
  schema: Schema<Output, Input>
): Schema<Output | undefined, Input | undefined>;
export function optional<Output, Input>(
  schema: Schema<Output, Input>,
  or: () => Output
): Schema<Output, Input | undefined>;
export function optional<Output, Input>(
  schema: Schema<Output, Input>,
  or: Output
): Schema<Output, Input | undefined>;

export const nullable: <Output, Input>(
  schema: Schema<Output, Input>
) => Schema<Output | undefined, Input | null>;

export const nullish: <Output, Input>(
  schema: Schema<Output, Input>
) => Schema<Output | undefined, Input | undefined | null>;

export const array: <Output, Input>(
  schema: Schema<Output, Input>
) => Schema<Output[], Input[]>;

export const unnest: <Output, Input extends Record<string, unknown>>(
  schema: Schema<Output, Input>
) => Schema<
  Output[],
  {
    [K in keyof Input]: Input[K][];
  }[keyof Input][]
>;

export const record: <Output, Input>(
  schema: Schema<Output, Input>
) => Schema<Record<string, Output>, Record<string, Input>>;

export const jsonString: <Output>(
  schema: Schema<Output, unknown>,
  space?: number
) => Schema<Output, string>;

type ObjectCtx<Input extends Record<string, unknown>> = {
  field: <FieldOutput>(
    name: string,
    schema: Schema<FieldOutput, unknown>
  ) => FieldOutput;
  fieldOr: <FieldOutput>(
    name: string,
    schema: Schema<FieldOutput, unknown>,
    or: FieldOutput
  ) => FieldOutput;
  tag: <TagName extends keyof Input>(
    name: TagName,
    value: Input[TagName]
  ) => void;
  flatten: <FieldOutput>(schema: Schema<FieldOutput, unknown>) => FieldOutput;
  nested: (name: string) => ObjectCtx<Record<string, unknown>>;
};

export function object<Output, Input extends Record<string, unknown>>(
  definer: (ctx: ObjectCtx<Input>) => Output
): Schema<Output, Input>;

export function strip<Output, Input extends Record<string, unknown>>(
  schema: Schema<Output, Input>
): Schema<Output, Input>;
export function deepStrip<Output, Input extends Record<string, unknown>>(
  schema: Schema<Output, Input>
): Schema<Output, Input>;
export function strict<Output, Input extends Record<string, unknown>>(
  schema: Schema<Output, Input>
): Schema<Output, Input>;
export function deepStrict<Output, Input extends Record<string, unknown>>(
  schema: Schema<Output, Input>
): Schema<Output, Input>;

export function merge<O1, O2>(
  schema1: Schema<O1, Record<string, unknown>>,
  schema2: Schema<O2, Record<string, unknown>>
): Schema<O1 & O2, Record<string, unknown>>;

export function custom<Output, Input = unknown>(
  name: string,
  parser: (data: unknown, s: EffectCtx<unknown, unknown>) => Output
): Schema<Output, Input>;
export function custom<Output, Input = unknown>(
  name: string,
  parser: (data: unknown, s: EffectCtx<unknown, unknown>) => Output | undefined,
  serializer: (value: Output, s: EffectCtx<unknown, unknown>) => Input
): Schema<Output, Input>;

export function recursive<Output, Input = Output>(
  definer: (schema: Schema<Output, Input>) => Schema<Output, Input>
): Schema<Output, Input>;

export function name(schema: Schema<unknown>): string;
export function setName<Output, Input>(
  schema: Schema<Output, Input>,
  name: string
): Schema<Output, Input>;
export function removeTypeValidation<Output, Input>(
  schema: Schema<Output, Input>
): Schema<Output, Input>;

export function asyncParserRefine<Output, Input>(
  schema: Schema<Output, Input>,
  refiner: (value: Output, s: EffectCtx<Output, Input>) => Promise<void>
): Schema<Output, Input>;
export function refine<Output, Input>(
  schema: Schema<Output, Input>,
  refiner: (value: Output, s: EffectCtx<Output, Input>) => void
): Schema<Output, Input>;

export function transform<Output, Input, Transformed>(
  schema: Schema<Output, Input>,
  parser: (value: Output, s: EffectCtx<unknown, unknown>) => Transformed
): Schema<Transformed, Input>;
export function transform<Output, Input, Transformed>(
  schema: Schema<Output, Input>,
  parser: (
    value: Output,
    s: EffectCtx<unknown, unknown>
  ) => Transformed | undefined,
  serializer: (value: Transformed, s: EffectCtx<unknown, unknown>) => Input
): Schema<Transformed, Input>;

export function describe<Output, Input>(
  schema: Schema<Output, Input>,
  description: string
): Schema<Output, Input>;
export function description<Output, Input>(
  schema: Schema<Output, Input>
): string | undefined;

export const port: <Input>(
  schema: Schema<number, Input>,
  message?: string
) => Schema<number, Input>;

export const numberMin: <Input>(
  schema: Schema<number, Input>,
  value: number,
  message?: string
) => Schema<number, Input>;
export const numberMax: <Input>(
  schema: Schema<number, Input>,
  value: number,
  message?: string
) => Schema<number, Input>;

export const arrayMinLength: <Input, ItemSchema>(
  schema: Schema<ItemSchema[], Input>,
  length: number,
  message?: string
) => Schema<ItemSchema[], Input>;
export const arrayMaxLength: <Input, ItemSchema>(
  schema: Schema<ItemSchema[], Input>,
  length: number,
  message?: string
) => Schema<ItemSchema[], Input>;
export const arrayLength: <Input, ItemSchema>(
  schema: Schema<ItemSchema[], Input>,
  length: number,
  message?: string
) => Schema<ItemSchema[], Input>;

export const stringMinLength: <Input>(
  schema: Schema<string, Input>,
  length: number,
  message?: string
) => Schema<string, Input>;
export const stringMaxLength: <Input>(
  schema: Schema<string, Input>,
  length: number,
  message?: string
) => Schema<string, Input>;
export const stringLength: <Input>(
  schema: Schema<string, Input>,
  length: number,
  message?: string
) => Schema<string, Input>;
export const email: <Input>(
  schema: Schema<string, Input>,
  message?: string
) => Schema<string, Input>;
export const uuid: <Input>(
  schema: Schema<string, Input>,
  message?: string
) => Schema<string, Input>;
export const cuid: <Input>(
  schema: Schema<string, Input>,
  message?: string
) => Schema<string, Input>;
export const url: <Input>(
  schema: Schema<string, Input>,
  message?: string
) => Schema<string, Input>;
export const pattern: <Input>(
  schema: Schema<string, Input>,
  re: RegExp,
  message?: string
) => Schema<string, Input>;
export const datetime: <Input>(
  schema: Schema<string, Input>,
  message?: string
) => Schema<Date, Input>;
export const trim: <Input>(
  schema: Schema<string, Input>
) => Schema<string, Input>;

export type UnknownKeys = "Strip" | "Strict";

export type GlobalConfigOverride = {
  defaultUnknownKeys?: UnknownKeys;
  disableNanNumberValidation?: boolean;
};

export function setGlobalConfig(
  globalConfigOverride: GlobalConfigOverride
): void;

type CompileInputMappings<Input, Output> = {
  Input: Input;
  Output: Output;
  Any: unknown;
  Json: Json;
  JsonString: string;
};

type CompileOutputMappings<Input, Output> = {
  Output: Output;
  Input: Input;
  Assert: void;
  Json: Json;
  JsonString: string;
};

export type CompileInputOption = keyof CompileInputMappings<unknown, unknown>;
export type CompileOutputOption = keyof CompileOutputMappings<unknown, unknown>;
export type CompileModeOption = "Sync" | "Async";

export function compile<
  Output,
  Input,
  InputOption extends CompileInputOption,
  OutputOption extends CompileOutputOption,
  ModeOption extends CompileModeOption
>(
  schema: Schema<Output, Input>,
  input: InputOption,
  output: OutputOption,
  mode: ModeOption,
  typeValidation?: boolean
): (
  input: CompileInputMappings<Input, Output>[InputOption]
) => ModeOption extends "Sync"
  ? CompileOutputMappings<Input, Output>[OutputOption]
  : ModeOption extends "Async"
  ? Promise<CompileOutputMappings<Input, Output>[OutputOption]>
  : never;

export function standard<Output, Input>(
  schema: Schema<Output, Input>
): {
  ["~standard"]: StandardSchemaV1.Props<Input, Output>;
};

export function shape<Output, Input, Shape>(
  schema: Schema<Output, Input>,
  shaper: (value: Output) => Shape
): Schema<Shape, Input>;

export function coerce<Output, Coerce, Input>(
  from: Schema<Coerce, Input>,
  to: Schema<Output, Coerce>
): Schema<Output, Input>;
