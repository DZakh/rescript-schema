import { S_t, S_Error_class } from "../RescriptSchema.gen";

export class Error extends S_Error_class {
  constructor(
    code: unknown,
    operation: "Parsing" | "Serializing",
    path: string
  );
  code: unknown;
  operation: "Parsing" | "Serializing";
  path: string;
  message: string;
  reason: string;
}

export type Result<Value> =
  | {
      success: true;
      value: Value;
    }
  | { success: false; error: Error };

export type EffectCtx<Output, Input> = {
  schema: Schema<Output, Input>;
  fail: (message: string) => void;
};

export type Schema<Output, Input = Output> = S_t<Output, Input>;

export type Output<T> = T extends Schema<infer Output, unknown>
  ? Output
  : never;
export type Input<T> = T extends Schema<unknown, infer Input> ? Input : never;

export type Json =
  | string
  | boolean
  | number
  | null
  | { [key: string]: Json }
  | Json[];

type NoUndefined<T> = T extends undefined ? never : T;
type UnknownSchema = Schema<unknown, unknown>;
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

export const string: Schema<string>;
export const boolean: Schema<boolean>;
export const integer: Schema<number>;
export const number: Schema<number>;
export const never: Schema<never>;
export const unknown: Schema<unknown>;
export const undefined: Schema<undefined>;
export const json: (validate: boolean) => Schema<Json>;

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
  definer: (ctx: {
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

export const union: <A extends UnknownSchema, B extends UnknownSchema[]>(
  schemas: [A, ...B]
) => Schema<
  Output<A> | SchemaTupleOutput<B>[number],
  Input<A> | SchemaTupleInput<B>[number]
>;

export function schema<Value>(
  definer: (ctx: {
    matches: <Output>(schema: Schema<Output, unknown>) => Output;
  }) => Value
): Schema<Value, unknown>;

export function object<Output>(
  definer: (ctx: {
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
export function object<
  Shape extends {
    [k in keyof Shape]: Schema<unknown, unknown>;
  }
>(
  shape: Shape
): Schema<
  {
    [k in keyof Shape]: Output<Shape[k]>;
  },
  {
    [k in keyof Shape]: Input<Shape[k]>;
  }
>;

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

export function name(schema: Schema<unknown, unknown>): string;
export function setName<Output, Input>(
  schema: Schema<Output, Input>,
  name: string
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

export function parse<Output, Input>(
  schema: Schema<Output, Input>,
  data: unknown
): Result<Output>;
export function parseOrThrow<Output, Input>(
  schema: Schema<Output, Input>,
  data: unknown
): Output;
export function parseAsync<Output, Input>(
  schema: Schema<Output, Input>,
  data: unknown
): Promise<Result<Output>>;
export function serialize<Output, Input>(
  schema: Schema<Output, Input>,
  data: Output
): Result<Input>;
export function serializeOrThrow<Output, Input>(
  schema: Schema<Output, Input>,
  data: Output
): Input;

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
