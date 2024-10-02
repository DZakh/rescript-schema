// The file is hand written to support namespaces and to reuse code between TS API

/* eslint-disable */
/* tslint:disable */

export type Result<Value> =
  | {
      success: true;
      value: Value;
    }
  | { success: false; error: S_error };

export type Json =
  | string
  | boolean
  | number
  | null
  | { [key: string]: Json }
  | Json[];

export type S_t<Output, Input = unknown> = {
  parse(data: unknown): Result<Output>;
  parseAsync(data: unknown): Promise<Result<Output>>;
  parseOrThrow(data: unknown): Output;
  serialize(value: Output): Result<Input>;
  /**
   * @deprecated It'll be removed in v9. Use S.convertWith(data, S.reverse(schema)) instead
   */
  serializeOrThrow(value: Output): Input;
  /**
   * @deprecated It'll be removed in v9. Create an issue if you use it, there're currently no alternatives
   */
  serializeToJsonOrThrow(value: Output): Json;
  /**
   * @deprecated It'll be removed in v9. Use S.assertWith(data, schema) instead
   */
  assert(data: unknown): asserts data is Input;
};

export abstract class S_Path_t {
  protected opaque: any;
} /* simulate opaque types */

export class S_error {
  readonly operation: S_operation;
  readonly code: S_errorCode;
  readonly path: S_Path_t;
  readonly message: string;
  readonly reason: string;
}

export abstract class S_errorCode {
  protected opaque: any;
} /* simulate opaque types */

export type S_operation =
  | "Parse"
  | "ParseAsync"
  | "SerializeToJson"
  | "SerializeToUnknown";
