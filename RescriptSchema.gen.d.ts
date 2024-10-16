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

export abstract class S_t<Output, Input = unknown> {
  protected opaque: any;
} /* simulate opaque types */

export abstract class S_Path_t {
  protected opaque: any;
} /* simulate opaque types */

export class S_error {
  readonly flag: number;
  readonly code: S_errorCode;
  readonly path: S_Path_t;
  readonly message: string;
  readonly reason: string;
}

export abstract class S_errorCode {
  protected opaque: any;
} /* simulate opaque types */
