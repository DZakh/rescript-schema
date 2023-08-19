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

// TODO: Research how to do it properly
export abstract class Struct<Input, Output> {
  protected opaque: Output;
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

export const string: Struct<string, string>;
export const boolean: Struct<boolean, boolean>;
export const integer: Struct<number, number>;
export const number: Struct<number, number>;
export const never: Struct<never, never>;
export const unknown: Struct<unknown, unknown>;
export const json: Struct<Json, Json>;

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
export function literal(value: undefined): Struct<undefined, undefined>;
export function literal(value: null): Struct<null, null>;
export function tuple(structs: []): Struct<[], []>;
export function tuple<Input, Output>(
  structs: [Struct<Input, Output>]
): Struct<[Input], [Output]>;
export function tuple<A extends UnknownStruct, B extends UnknownStruct[]>(
  structs: [A, ...B]
): Struct<
  [Input<A>, ...StructTupleInput<B>],
  [Output<A>, ...StructTupleOutput<B>]
>;

export function optional<Input, Output>(
  struct: Struct<Input, Output>
): Struct<Input | undefined, Output | undefined>;
export function optional<Input, Output>(
  struct: Struct<Input, Output>,
  or: () => Output
): Struct<Input | undefined, Output>;
export function optional<Input, Output>(
  struct: Struct<Input, Output>,
  or: Output
): Struct<Input | undefined, Output>;

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
) => Struct<
  {
    [k in keyof Shape]: Input<Shape[k]>;
  },
  {
    [k in keyof Shape]: Output<Shape[k]>;
  }
>;

export const Object: {
  strip: <Input, Output>(
    struct: Struct<Input, Output>
  ) => Struct<Input, Output>;
  strict: <Input, Output>(
    struct: Struct<Input, Output>
  ) => Struct<Input, Output>;
};

export function custom<Input, Output>(
  name: string,
  parser: (data: unknown, s: EffectCtx<unknown, unknown>) => Output
): Struct<Input, Output>;
export function custom<Input, Output>(
  name: string,
  parser: (data: unknown, s: EffectCtx<unknown, unknown>) => Output | undefined,
  serializer: (value: Output, s: EffectCtx<unknown, unknown>) => Input
): Struct<Input, Output>;

export function asyncParserRefine<Input, Output>(
  struct: Struct<Input, Output>,
  refiner: (value: Output, s: EffectCtx<Input, Output>) => Promise<void>
): Struct<Input, Output>;
export function refine<Input, Output>(
  struct: Struct<Input, Output>,
  refiner: (value: Output, s: EffectCtx<Input, Output>) => void
): Struct<Input, Output>;

export function transform<Input, Output, Transformed>(
  struct: Struct<Input, Output>,
  parser: (value: Output, s: EffectCtx<unknown, unknown>) => Transformed
): Struct<Input, Transformed>;
export function transform<Input, Output, Transformed>(
  struct: Struct<Input, Output>,
  parser: (
    value: Output,
    s: EffectCtx<unknown, unknown>
  ) => Transformed | undefined,
  serializer: (value: Transformed, s: EffectCtx<unknown, unknown>) => Input
): Struct<Input, Transformed>;

export function describe<Input, Output>(
  struct: Struct<Input, Output>,
  description: string
): Struct<Input, Output>;
export function description<Input, Output>(
  struct: Struct<Input, Output>
): string | undefined;

export function parse<Input, Output>(
  struct: Struct<Input, Output>,
  data: unknown
): Result<Output>;
export function parseOrThrow<Input, Output>(
  struct: Struct<Input, Output>,
  data: unknown
): Output;
export function parseAsync<Input, Output>(
  struct: Struct<Input, Output>,
  data: unknown
): Promise<Result<Output>>;
export function serialize<Input, Output>(
  struct: Struct<Input, Output>,
  data: Output
): Result<Input>;
export function serializeOrThrow<Input, Output>(
  struct: Struct<Input, Output>,
  data: Output
): Input;
