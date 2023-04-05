// tslint:disable-next-line:max-classes-per-file
// tslint:disable-next-line:class-name
export abstract class S_t<value> {
  protected opaque!: value;
} /* simulate opaque types */

// tslint:disable-next-line:max-classes-per-file
// tslint:disable-next-line:class-name
export abstract class S_Path_t {
  protected opaque!: any;
} /* simulate opaque types */

// tslint:disable-next-line:interface-over-type-literal
export type S_Error_t = {
  readonly operation: S_Error_operation;
  readonly code: S_Error_code;
  readonly path: S_Path_t;
};

// tslint:disable-next-line:max-classes-per-file
// tslint:disable-next-line:class-name
export abstract class S_Error_code {
  protected opaque!: any;
} /* simulate opaque types */

// tslint:disable-next-line:max-classes-per-file
// tslint:disable-next-line:class-name
export abstract class S_Error_operation {
  protected opaque!: any;
} /* simulate opaque types */
