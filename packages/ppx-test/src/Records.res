@struct
type t = {
  @struct.key("spice-label") label: string,
  @struct.key("spice-value") value: int,
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
