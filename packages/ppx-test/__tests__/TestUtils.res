open Ava

external magic: 'a => 'b = "%identity"

let assertEqualStructs = {
  let rec cleanUpStruct = (struct: S.t<'v>): S.t<'v> => {
    let new = Dict.make()
    struct
    ->(magic: S.t<'a> => Dict.t<unknown>)
    ->Dict.toArray
    ->Array.forEach(((key, value)) => {
      switch key {
      | "pf" | "sf" | "parseOperationFactory" => ()
      | _ =>
        if typeof(value) === #object && value !== %raw("null") {
          new->Dict.set(
            key,
            cleanUpStruct(value->(magic: unknown => S.t<'a>))->(magic: S.t<'a> => unknown),
          )
        } else {
          new->Dict.set(key, value)
        }
      }
    })
    new->(magic: Dict.t<unknown> => S.t<'a>)
  }
  (t, s1, s2, ~message=?, ()) => {
    t->Assert.deepEqual(s1->cleanUpStruct, s2->cleanUpStruct, ~message?, ())
  }
}
