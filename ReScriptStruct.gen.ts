// tslint:disable-next-line:max-classes-per-file
// tslint:disable-next-line:class-name
export abstract class S_t<value> {
  protected opaque!: value;
} /* simulate opaque types */

// tslint:disable-next-line:interface-over-type-literal
export type S_Error_t = {
  readonly operation: S_Error_operation;
  readonly code: S_Error_code;
  readonly path: string[];
};

// tslint:disable-next-line:interface-over-type-literal
export type S_Error_code =
  | "MissingParser"
  | "MissingSerializer"
  | "UnexpectedAsync"
  | { tag: "OperationFailed"; value: string }
  | {
      tag: "UnexpectedType";
      value: { readonly expected: string; readonly received: string };
    }
  | {
      tag: "UnexpectedValue";
      value: { readonly expected: string; readonly received: string };
    }
  | {
      tag: "TupleSize";
      value: { readonly expected: number; readonly received: number };
    }
  | { tag: "ExcessField"; value: string }
  | { tag: "InvalidUnion"; value: S_Error_t[] };

// tslint:disable-next-line:interface-over-type-literal
export type S_Error_operation = "Serializing" | "Parsing";
