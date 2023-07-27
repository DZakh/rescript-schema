export class StructError extends Error {}

export type Result<Value> =
  | {
      success: true;
      value: Value;
    }
  | { success: false; error: StructError };

export type EffectCtx<Input, Output> = {
  struct: Struct<Input, Output>;
  fail: (message: string) => void;
};

export interface Struct<Input, Output> {
  parse(data: unknown): Result<Output>;
  parseOrThrow(data: unknown): Output;
  parseAsync(data: unknown): Promise<Result<Output>>;
  serialize(data: Output): Result<Input>;
  serializeOrThrow(data: Output): Input;
  transform<Transformed>(
    parser: (value: Output) => Transformed
  ): Struct<Input, Transformed>;
  transform<Transformed>(
    parser: ((value: Output) => Transformed) | undefined,
    serializer: (transformed: Transformed) => Output
  ): Struct<Input, Transformed>;
  refine(
    refiner: (ctx: EffectCtx<Input, Output>) => (value: Output) => void
  ): Struct<Input, Output>;
  asyncParserRefine(
    refiner: (ctx: EffectCtx<Input, Output>) => (value: Output) => Promise<void>
  ): Struct<Input, Output>;
  optional(): Struct<Input | undefined, Output | undefined>;
  nullable(): Struct<Input | null, Output | undefined>;
  describe(description: string): Struct<Input, Output>;
  description(): string | undefined;
  default(def: () => Output): Struct<Input | undefined, Output>;
}

export type Output<T> = T extends Struct<unknown, infer Output>
  ? Output
  : never;
export type Input<T> = T extends Struct<infer Input, unknown> ? Input : never;

export type Json =
  | string
  | boolean
  | number
  | null
  | { [key: string]: Json }
  | Json[];

type NoUndefined<T> = T extends undefined ? never : T;
type UnknownStruct = Struct<unknown, unknown>;
type StructTupleOutput<
  Tuple extends UnknownStruct[],
  Length extends number = Tuple["length"]
> = Length extends Length
  ? number extends Length
    ? Tuple
    : _TupleOutput<Tuple, Length, []>
  : never;
type _TupleOutput<
  Tuple extends UnknownStruct[],
  Length extends number,
  Accumulated extends unknown[],
  Index extends number = Accumulated["length"]
> = Index extends Length
  ? Accumulated
  : _TupleOutput<Tuple, Length, [...Accumulated, Output<Tuple[Index]>]>;
type StructTupleInput<
  Tuple extends UnknownStruct[],
  Length extends number = Tuple["length"]
> = Length extends Length
  ? number extends Length
    ? Tuple
    : _TupleInput<Tuple, Length, []>
  : never;
type _TupleInput<
  Tuple extends UnknownStruct[],
  Length extends number,
  Accumulated extends unknown[],
  Index extends number = Accumulated["length"]
> = Index extends Length
  ? Accumulated
  : _TupleInput<Tuple, Length, [...Accumulated, Input<Tuple[Index]>]>;

export interface ObjectStruct<Input, Output> extends Struct<Input, Output> {
  strip(): ObjectStruct<Input, Output>;
  strict(): ObjectStruct<Input, Output>;
}

export const string: Struct<string, string>;
export const boolean: Struct<boolean, boolean>;
export const integer: Struct<number, number>;
export const number: Struct<number, number>;
export const never: Struct<never, never>;
export const unknown: Struct<unknown, unknown>;
export const json: Struct<Json, Json>;
export const nan: Struct<number, undefined>;

export function literal<Literal extends string>(
  value: Literal
): Struct<Literal, Literal>;
export function literal<Literal extends number>(
  value: Literal
): Struct<Literal, Literal>;
export function literal<Literal extends boolean>(
  value: Literal
): Struct<Literal, Literal>;
export function literal<Literal extends symbol>(
  value: Literal
): Struct<Literal, Literal>;
export function literal<Literal extends BigInt>(
  value: Literal
): Struct<Literal, Literal>;
// TODO: add complete types
export function literal(value: undefined): Struct<undefined, undefined>;
export function literal(value: null): Struct<null, null>;
export function tuple(structs: []): Struct<[], undefined>;
export function tuple<Input, Output>(
  structs: [Struct<Input, Output>]
): Struct<[Input], Output>;
export function tuple<A extends UnknownStruct, B extends UnknownStruct[]>(
  structs: [A, ...B]
): Struct<
  [Input<A>, ...StructTupleInput<B>],
  [Output<A>, ...StructTupleOutput<B>]
>;

export const optional: <Input, Output>(
  struct: Struct<Input, Output>
) => Struct<Input | undefined, Output | undefined>;

export const nullable: <Input, Output>(
  struct: Struct<Input, Output>
) => Struct<Input | null, Output | undefined>;

export const array: <Input, Output>(
  struct: Struct<Input, Output>
) => Struct<Input[], Output[]>;

export const record: <Input, Output>(
  struct: Struct<Input, Output>
) => Struct<Record<string, Input>, Record<string, Output>>;

export const jsonString: <Output>(
  struct: Struct<unknown, Output>
) => Struct<string, Output>;

export const union: <A extends UnknownStruct, B extends UnknownStruct[]>(
  structs: [A, ...B]
) => Struct<
  Input<A> | StructTupleInput<B>[number],
  Output<A> | StructTupleOutput<B>[number]
>;

export const object: <
  Shape extends {
    [k in keyof Shape]: Struct<unknown, unknown>;
  }
>(
  shape: Shape
) => ObjectStruct<
  {
    [k in keyof Shape]: Input<Shape[k]>;
  },
  {
    [k in keyof Shape]: Output<Shape[k]>;
  }
>;

export const custom: <Input, Output>(
  name: string,
  parser?: (data: unknown) => Output,
  serializer?: (value: Output) => Input
) => Struct<Input, Output>;

export const fail: (reason: string) => void;
