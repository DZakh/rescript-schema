@struct
type t = One | Two

@struct
type t1 = One1 | Two1

@struct @unboxed
type t2 = One2(int)

@struct @unboxed
type t3 = One3(int)
