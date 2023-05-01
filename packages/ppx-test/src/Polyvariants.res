@struct
type t1 = [@as(`하나`) #one | @as(`둘`) #two]

@struct
type t2 = [#one | #two]

@struct
type t3 = [#single]

// @struct
// type t4 = {"foo": [#bar]}

// TODO: Test polyvars as record fields
