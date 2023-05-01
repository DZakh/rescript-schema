@struct
type t0 = {
  a: int,
  b?: int,
}

@struct
type t1 = {
  a: int,
  bs?: array<int>,
}

@struct
type b =
  | @as("B0") B0
  | @as("B1") B1
  | @as("B2") B2

@struct
type t2 = {
  a: int,
  bs?: array<b>,
}
