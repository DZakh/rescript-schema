// @ts-ignore
import * as S_Js from "./S_Js.bs.js";
// @ts-ignore
import * as S from "./S.bs.js";

export class Error extends S_Js.ReScriptStructError {}

export interface Struct<Value> {
  parse(data: any): Value | Error;
  parseOrThrow(data: any): Value;
  parseAsync(data: any): Promise<Value | Error>;
  serialize(data: Value): unknown | Error;
  serializeOrThrow(data: Value): unknown;
  transform<Transformed>(
    parser: (value: Value) => Transformed
  ): Struct<Transformed>;
  transform<Transformed>(
    parser: (value: Value) => Transformed,
    serializer: (transformed: Transformed) => Value
  ): Struct<Transformed>;
  refine(parser: (value: Value) => void): Struct<Value>;
  refine(
    parser: ((value: Value) => void) | undefined,
    serializer: (value: Value) => void
  ): Struct<Value>;
  asyncRefine(parser: (value: Value) => Promise<void>): Struct<Value>;
  optional(): Struct<Value | undefined>;
  nullable(): Struct<Value | undefined>;
}
export interface ObjectStruct<Value> extends Struct<Value> {
  strip(): ObjectStruct<Value>;
  strict(): ObjectStruct<Value>;
}

export const string: () => Struct<string> = S_Js.string;
export const boolean: () => Struct<boolean> = S_Js.$$boolean;
export const integer: () => Struct<number> = S_Js.integer;
export const number: () => Struct<number> = S_Js.number;
export const never: () => Struct<never> = S_Js.never;
export const unknown: () => Struct<unknown> = S_Js.unknown;

export const optional: <Value>(
  struct: Struct<Value>
) => Struct<Value | undefined> = S_Js.optional;

export const nullable: <Value>(
  struct: Struct<Value>
) => Struct<Value | undefined> = S_Js.nullable;

export const array: <Value>(struct: Struct<Value>) => Struct<[Value]> =
  S_Js.array;

export const record: <Value>(
  struct: Struct<Value>
) => Struct<Record<string, Value>> = S_Js.record;

export const json: <Value>(struct: Struct<Value>) => Struct<Value> = S_Js.json;

export const object: <Value>(shape: {
  [k in keyof Value]: Struct<Value[k]>;
}) => ObjectStruct<{
  [k in keyof Value]: Value[k];
}> = S_Js.$$Object.factory;

export const custom: <Value>(
  name: string,
  parser?: (data: unknown) => Value,
  serializer?: (value: Value) => any
) => Struct<Value> = S_Js.custom;

export const raiseError: (reason: string) => void = S.$$Error.raise;
