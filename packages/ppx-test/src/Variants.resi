@struct
type t1 = One | Two

@struct
type t2 = One1 | Two1

@struct @unboxed
type t3 = One2(int)

@struct @unboxed
type t4 = One3(int)
