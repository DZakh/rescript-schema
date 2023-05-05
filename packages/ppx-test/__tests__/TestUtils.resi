external magic: 'a => 'b = "%identity"

let assertEqualStructs: (
  Ava.ExecutionContext.t<'a>,
  S.t<'v>,
  S.t<'v>,
  ~message: string=?,
  unit,
) => unit
