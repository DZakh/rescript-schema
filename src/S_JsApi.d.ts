import { S_t } from "../RescriptStruct.gen";

export class StructError extends Error {}

export type Result<Value> =
  | {
      success: true;
      value: Value;
    }
  | { success: false; error: StructError };

export type EffectCtx<Output, Input> = {
  struct: Struct<Output, Input>;
  fail: (message: string) => void;
};

export type Struct<Output, Input = Output> = S_t<Output, Input>;

export type Output<T> = T extends Struct<infer Output, unknown>
  ? Output
  : never;
export type Input<T> = T extends Struct<unknown, infer Input> ? Input : never;

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

export const string: Struct<string>;
export const boolean: Struct<boolean>;
export const integer: Struct<number>;
export const number: Struct<number>;
export const never: Struct<never>;
export const unknown: Struct<unknown>;
export const json: Struct<Json>;

export function literal<Literal extends string>(
  value: Literal
): Struct<Literal>;
export function literal<Literal extends number>(
  value: Literal
): Struct<Literal>;
export function literal<Literal extends boolean>(
  value: Literal
): Struct<Literal>;
export function literal<Literal extends symbol>(
  value: Literal
): Struct<Literal>;
export function literal<Literal extends BigInt>(
  value: Literal
): Struct<Literal>;
export function literal(value: undefined): Struct<undefined>;
export function literal(value: null): Struct<null>;
export function tuple(structs: []): Struct<[]>;
export function tuple<Output, Input>(
  structs: [Struct<Output, Input>]
): Struct<[Output], [Input]>;
export function tuple<A extends UnknownStruct, B extends UnknownStruct[]>(
  structs: [A, ...B]
): Struct<
  [Output<A>, ...StructTupleOutput<B>],
  [Input<A>, ...StructTupleInput<B>]
>;

export function optional<Output, Input>(
  struct: Struct<Output, Input>
): Struct<Output | undefined, Input | undefined>;
export function optional<Output, Input>(
  struct: Struct<Output, Input>,
  or: () => Output
): Struct<Output, Input | undefined>;
export function optional<Output, Input>(
  struct: Struct<Output, Input>,
  or: Output
): Struct<Output, Input | undefined>;

export const nullable: <Output, Input>(
  struct: Struct<Output, Input>
) => Struct<Output | undefined, Input | null>;

export const array: <Output, Input>(
  struct: Struct<Output, Input>
) => Struct<Output[], Input[]>;

export const record: <Output, Input>(
  struct: Struct<Output, Input>
) => Struct<Record<string, Output>, Record<string, Input>>;

export const jsonString: <Output>(
  struct: Struct<Output, unknown>
) => Struct<Output, string>;

export const union: <A extends UnknownStruct, B extends UnknownStruct[]>(
  structs: [A, ...B]
) => Struct<
  Output<A> | StructTupleOutput<B>[number],
  Input<A> | StructTupleInput<B>[number]
>;

export const object: <
  Shape extends {
    [k in keyof Shape]: Struct<unknown, unknown>;
  }
>(
  shape: Shape
) => Struct<
  {
    [k in keyof Shape]: Output<Shape[k]>;
  },
  {
    [k in keyof Shape]: Input<Shape[k]>;
  }
>;

export const Object: {
  strip: <Output, Input>(
    struct: Struct<Output, Input>
  ) => Struct<Output, Input>;
  strict: <Output, Input>(
    struct: Struct<Output, Input>
  ) => Struct<Output, Input>;
};

export const String: {
  min: <Input>(
    struct: Struct<string, Input>,
    length: number,
    message?: string
  ) => Struct<string, Input>;
  max: <Input>(
    struct: Struct<string, Input>,
    length: number,
    message?: string
  ) => Struct<string, Input>;
  length: <Input>(
    struct: Struct<string, Input>,
    length: number,
    message?: string
  ) => Struct<string, Input>;
  email: <Input>(
    struct: Struct<string, Input>,
    message?: string
  ) => Struct<string, Input>;
  uuid: <Input>(
    struct: Struct<string, Input>,
    message?: string
  ) => Struct<string, Input>;
  cuid: <Input>(
    struct: Struct<string, Input>,
    message?: string
  ) => Struct<string, Input>;
  url: <Input>(
    struct: Struct<string, Input>,
    message?: string
  ) => Struct<string, Input>;
  pattern: <Input>(
    struct: Struct<string, Input>,
    re: RegExp,
    message?: string
  ) => Struct<string, Input>;
  datetime: <Input>(
    struct: Struct<string, Input>,
    message?: string
  ) => Struct<Date, Input>;
  trim: <Input>(struct: Struct<string, Input>) => Struct<string, Input>;
};

export const Number: {
  min: <Input>(
    struct: Struct<number, Input>,
    value: number,
    message?: string
  ) => Struct<number, Input>;
  max: <Input>(
    struct: Struct<number, Input>,
    value: number,
    message?: string
  ) => Struct<number, Input>;
};

export const Array: {
  min: <Input, ItemStruct>(
    struct: Struct<ItemStruct[], Input>,
    length: number,
    message?: string
  ) => Struct<ItemStruct[], Input>;
  max: <Input, ItemStruct>(
    struct: Struct<ItemStruct[], Input>,
    length: number,
    message?: string
  ) => Struct<ItemStruct[], Input>;
  length: <Input, ItemStruct>(
    struct: Struct<ItemStruct[], Input>,
    length: number,
    message?: string
  ) => Struct<ItemStruct[], Input>;
};

export function custom<Output, Input = unknown>(
  name: string,
  parser: (data: unknown, s: EffectCtx<unknown, unknown>) => Output
): Struct<Output, Input>;
export function custom<Output, Input = unknown>(
  name: string,
  parser: (data: unknown, s: EffectCtx<unknown, unknown>) => Output | undefined,
  serializer: (value: Output, s: EffectCtx<unknown, unknown>) => Input
): Struct<Output, Input>;

export function asyncParserRefine<Output, Input>(
  struct: Struct<Output, Input>,
  refiner: (value: Output, s: EffectCtx<Output, Input>) => Promise<void>
): Struct<Output, Input>;
export function refine<Output, Input>(
  struct: Struct<Output, Input>,
  refiner: (value: Output, s: EffectCtx<Output, Input>) => void
): Struct<Output, Input>;

export function transform<Output, Input, Transformed>(
  struct: Struct<Output, Input>,
  parser: (value: Output, s: EffectCtx<unknown, unknown>) => Transformed
): Struct<Transformed, Input>;
export function transform<Output, Input, Transformed>(
  struct: Struct<Output, Input>,
  parser: (
    value: Output,
    s: EffectCtx<unknown, unknown>
  ) => Transformed | undefined,
  serializer: (value: Transformed, s: EffectCtx<unknown, unknown>) => Input
): Struct<Transformed, Input>;

export function describe<Output, Input>(
  struct: Struct<Output, Input>,
  description: string
): Struct<Output, Input>;
export function description<Output, Input>(
  struct: Struct<Output, Input>
): string | undefined;

export function parse<Output, Input>(
  struct: Struct<Output, Input>,
  data: unknown
): Result<Output>;
export function parseOrThrow<Output, Input>(
  struct: Struct<Output, Input>,
  data: unknown
): Output;
export function parseAsync<Output, Input>(
  struct: Struct<Output, Input>,
  data: unknown
): Promise<Result<Output>>;
export function serialize<Output, Input>(
  struct: Struct<Output, Input>,
  data: Output
): Result<Input>;
export function serializeOrThrow<Output, Input>(
  struct: Struct<Output, Input>,
  data: Output
): Input;
