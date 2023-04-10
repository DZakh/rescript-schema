@struct
type t = {
  label: string,
  value: int,
}

@struct
type t1 = {
  label: string,
  value: int,
}

@struct
type tOp = {
  label: option<string>,
  value?: int,
}
