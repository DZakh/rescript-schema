// The file is hand written to support namespaces and to reuse code between TS API

/* eslint-disable */
/* tslint:disable */

export abstract class S_t<Output, Input = unknown> {
  protected opaque!: Output | Input;
} /* simulate opaque types */

export abstract class S_Path_t {
  protected opaque!: any;
} /* simulate opaque types */

export type S_error = {
  readonly operation: S_operation;
  readonly code: S_errorCode;
  readonly path: S_Path_t;
};

export abstract class S_errorCode {
  protected opaque!: any;
} /* simulate opaque types */

export abstract class S_operation {
  protected opaque!: any;
} /* simulate opaque types */

export abstract class S_Error_class {
  protected opaque!: any;
} /* simulate opaque types */
