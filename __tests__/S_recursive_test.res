open Ava

type rec node = {
  id: string,
  children: array<node>,
}

test("Successfully parses and serializes recursive object", t => {
  let nodeStruct = S.recursive(nodeStruct => {
    S.object(
      o => {
        id: o->S.field("id", S.string()),
        children: o->S.field("children", S.array(nodeStruct)),
      },
    )
  })

  t->Assert.deepEqual(
    {
      id: "1",
      children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
    }->S.parseWith(nodeStruct),
    Ok({
      id: "1",
      children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
    }),
    (),
  )
  t->Assert.deepEqual(
    {
      id: "1",
      children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
    }->S.serializeWith(nodeStruct),
    Ok(
      {
        id: "1",
        children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
      }->Obj.magic,
    ),
    (),
  )
})
