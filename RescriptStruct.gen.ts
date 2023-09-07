// The file hand written to support namespaces and to reuse for TS api

// tslint:disable-next-line:max-classes-per-file
// tslint:disable-next-line:class-name
export abstract class S_t<Output, Input = unknown> {
  protected opaque!: Output | Input;
} /* simulate opaque types */

// tslint:disable-next-line:max-classes-per-file
export abstract class S_Path_t {
  protected opaque!: any;
} /* simulate opaque types */

// tslint:disable-next-line:interface-over-type-literal
export type S_error = {
  readonly operation: S_operation;
  readonly code: S_errorCode;
  readonly path: S_Path_t;
};

// tslint:disable-next-line:max-classes-per-file
// tslint:disable-next-line:class-name
export abstract class S_errorCode {
  protected opaque!: any;
} /* simulate opaque types */

// tslint:disable-next-line:max-classes-per-file
// tslint:disable-next-line:class-name
export abstract class S_operation {
  protected opaque!: any;
} /* simulate opaque types */
