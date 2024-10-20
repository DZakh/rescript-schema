import { Json, Result, S_t } from "../RescriptSchema.gen";
export { Json, Result, S_error as Error } from "../RescriptSchema.gen";

export type EffectCtx<Output, Input> = {
  schema: Schema<Output, Input>;
  fail: (message: string) => never;
};

export type Schema<Output, Input = Output> = S_t<Output, Input>;

export type Output<T> = T extends Schema<infer Output, unknown>
  ? Output
  : never;
export type Input<T> = T extends Schema<unknown, infer Input> ? Input : never;

type UnknownSchema = Schema<unknown>;

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

type SchemaTupleOutput<
  Tuple extends UnknownSchema[],
  Length extends number = Tuple["length"]
> = Length extends Length
  ? number extends Length
    ? Tuple
    : _TupleOutput<Tuple, Length, []>
  : never;
type _TupleOutput<
  Tuple extends UnknownSchema[],
  Length extends number,
  Accumulated extends unknown[],
  Index extends number = Accumulated["length"]
> = Index extends Length
  ? Accumulated
  : _TupleOutput<Tuple, Length, [...Accumulated, Output<Tuple[Index]>]>;
type SchemaTupleInput<
  Tuple extends UnknownSchema[],
  Length extends number = Tuple["length"]
> = Length extends Length
  ? number extends Length
    ? Tuple
    : _TupleInput<Tuple, Length, []>
  : never;
type _TupleInput<
  Tuple extends UnknownSchema[],
  Length extends number,
  Accumulated extends unknown[],
  Index extends number = Accumulated["length"]
> = Index extends Length
  ? Accumulated
  : _TupleInput<Tuple, Length, [...Accumulated, Input<Tuple[Index]>]>;

type SchemaUnionTupleOutput<
  Tuple extends unknown[],
  Length extends number = Tuple["length"]
> = Length extends Length
  ? number extends Length
    ? Tuple
    : _UnionTupleOutput<Tuple, Length, []>
  : never;
type _UnionTupleOutput<
  Tuple extends unknown[],
  Length extends number,
  Accumulated extends unknown[],
  Index extends number = Accumulated["length"]
> = Index extends Length
  ? Accumulated
  : _UnionTupleOutput<
      Tuple,
      Length,
      [...Accumulated, UnknownToOuput<Tuple[Index]>]
    >;
type SchemaUnionTupleInput<
  Tuple extends unknown[],
  Length extends number = Tuple["length"]
> = Length extends Length
  ? number extends Length
    ? Tuple
    : _UnionTupleInput<Tuple, Length, []>
  : never;
type _UnionTupleInput<
  Tuple extends unknown[],
  Length extends number,
  Accumulated extends unknown[],
  Index extends number = Accumulated["length"]
> = Index extends Length
  ? Accumulated
  : _UnionTupleInput<
      Tuple,
      Length,
      [...Accumulated, UnknownToInput<Tuple[Index]>]
    >;

export const string: Schema<string>;
export const boolean: Schema<boolean>;
export const integer: Schema<number>;
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

export function parseWith<Output, Input>(
  data: unknown,
  schema: Schema<Output, Input>
): Output;
export function parseAsyncWith<Output, Input>(
  data: unknown,
  schema: Schema<Output, Input>
): Promise<Output>;

export function convertOrThrow<Output, Input>(
  data: Input,
  schema: Schema<Output, Input>
): Output;
export function convertToJsonStringOrThrow<Output, Input>(
  data: Input,
  schema: Schema<Output, Input>
): string;

export function assertOrThrow<Output, Input>(
  data: unknown,
  schema: Schema<Output, Input>
): asserts data is Input;

export function literal<Literal extends string>(
  value: Literal
): Schema<Literal>;
export function literal<Literal extends number>(
  value: Literal
): Schema<Literal>;
export function literal<Literal extends boolean>(
  value: Literal
): Schema<Literal>;
export function literal<Literal extends symbol>(
  value: Literal
): Schema<Literal>;
export function literal<Literal extends BigInt>(
  value: Literal
): Schema<Literal>;
export function literal(value: undefined): Schema<undefined>;
export function literal(value: null): Schema<null>;
export function literal<T>(value: T): Schema<T>;

// TODO: Deprecate for V9
export function tuple(schemas: []): Schema<[]>;
export function tuple<Output, Input>(
  schemas: [Schema<Output, Input>]
): Schema<[Output], [Input]>;
export function tuple<A extends UnknownSchema, B extends UnknownSchema[]>(
  schemas: [A, ...B]
): Schema<
  [Output<A>, ...SchemaTupleOutput<B>],
  [Input<A>, ...SchemaTupleInput<B>]
>;
export function tuple<Output>(
  definer: (s: {
    item: <InputIndex extends number, ItemOutput>(
      inputIndex: InputIndex,
      schema: Schema<ItemOutput, unknown>
    ) => ItemOutput;
    tag: (inputIndex: number, value: unknown) => void;
  }) => Output
): Schema<Output, unknown>;

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

export const record: <Output, Input>(
  schema: Schema<Output, Input>
) => Schema<Record<string, Output>, Record<string, Input>>;

export const jsonString: <Output>(
  schema: Schema<Output, unknown>,
  space?: number
) => Schema<Output, string>;

export const union: <A, B extends unknown[]>(
  schemas: [A, ...B]
) => Schema<
  UnknownToOuput<A> | SchemaUnionTupleOutput<B>[number],
  UnknownToInput<A> | SchemaUnionTupleInput<B>[number]
>;

export function schema<T>(
  value: T
): Schema<UnknownToOuput<T>, UnknownToInput<T>>;

export function object<Output>(
  definer: (s: {
    field: <InputFieldName extends string, FieldOutput>(
      inputFieldName: InputFieldName,
      schema: Schema<FieldOutput, unknown>
    ) => FieldOutput;
    fieldOr: <InputFieldName extends string, FieldOutput>(
      name: InputFieldName,
      schema: Schema<FieldOutput, unknown>,
      or: FieldOutput
    ) => FieldOutput;
    tag: (name: string, value: unknown) => void;
  }) => Output
): Schema<Output, unknown>;

export const Object: {
  strip: <Output, Input>(
    schema: Schema<Output, Input>
  ) => Schema<Output, Input>;
  strict: <Output, Input>(
    schema: Schema<Output, Input>
  ) => Schema<Output, Input>;
};

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

export const integerMin: <Input>(
  schema: Schema<number, Input>,
  value: number,
  message?: string
) => Schema<number, Input>;
export const integerMax: <Input>(
  schema: Schema<number, Input>,
  value: number,
  message?: string
) => Schema<number, Input>;
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
  disableNanNumberCheck?: boolean;
};

export function setGlobalConfig(
  globalConfigOverride: GlobalConfigOverride
): void;
