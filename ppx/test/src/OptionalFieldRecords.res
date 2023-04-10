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
  | @struct.as("B0") B0
  | @struct.as("B1") B1
  | @struct.as("B2") B2

@struct
type t2 = {
  a: int,
  bs?: array<b>,
}
