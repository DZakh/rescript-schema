// @ts-ignore
import * as S_Js from "./S_Js.bs.js";

export interface Struct<Value> {
  parse(data: any): Value;
  parseAsync(data: any): Promise<Value>;
  serialize(data: Value): unknown;
  transform<Transformed>(
    parser: (value: Value) => Transformed
  ): Struct<Transformed>;
  transform<Transformed>(
    parser: (value: Value) => Transformed,
    serializer: (transformed: Transformed) => Value
  ): Struct<Transformed>;
  refine(
    parser: (value: Value) => void,
    serializer: (value: Value) => void
  ): Struct<Value>;
  asyncRefine(parser: (value: Value) => Promise<void>): Struct<Value>;
  optional(): Struct<Value | undefined>;
  nullable(): Struct<Value | undefined>;
}

export const string: () => Struct<string> = S_Js.string as any;
export const boolean: () => Struct<boolean> = S_Js.$$boolean as any;
export const integer: () => Struct<number> = S_Js.integer as any;
export const number: () => Struct<number> = S_Js.number as any;
export const never: () => Struct<never> = S_Js.never as any;
export const unknown: () => Struct<unknown> = S_Js.unknown as any;

export const optional: <Value>(
  struct: Struct<Value>
) => Struct<Value | undefined> = S_Js.optional as any;

export const nullable: <Value>(
  struct: Struct<Value>
) => Struct<Value | undefined> = S_Js.nullable as any;

export const object: <Value>(shape: {
  [k in keyof Value]: Struct<Value[k]>;
}) => Struct<{
  [k in keyof Value]: Value[k];
}> = S_Js.object as any;
