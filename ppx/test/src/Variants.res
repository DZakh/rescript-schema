@struct
type t = | @struct.as(`하나`) One | @struct.as(`둘`) Two

@struct
type t1 = One1 | Two1

@struct @unboxed
type t2 = | @struct.as(`하나`) One2(int)

@struct @unboxed
type t3 = One3(int)
