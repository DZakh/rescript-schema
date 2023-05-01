@struct
type t1 = | @as(`하나`) One | @as(`둘`) Two

@struct
type t2 = One1 | Two1

@struct @unboxed
type t3 = | @as(`하나`) One2(int)

@struct @unboxed
type t4 = One3(int)
