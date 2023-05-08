open Ava

type rec node = {
  id: string,
  children: array<node>,
}

test("Successfully parses recursive object", t => {
  let nodeStruct = S.recursive(nodeStruct => {
    S.object(
      o => {
        id: o.field("Id", S.string),
        children: o.field("Children", S.array(nodeStruct)),
      },
    )
  })

  t->Assert.deepEqual(
    {
      "Id": "1",
      "Children": [
        {"Id": "2", "Children": []},
        {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
      ],
    }->S.parseAnyWith(nodeStruct),
    Ok({
      id: "1",
      children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
    }),
    (),
  )
})

asyncTest("Successfully parses recursive object using S.parseAsyncWith", t => {
  let nodeStruct = S.recursive(nodeStruct => {
    S.object(
      o => {
        id: o.field("Id", S.string),
        children: o.field("Children", S.array(nodeStruct)),
      },
    )
  })

  %raw(`{
    "Id": "1",
    "Children": [
      {"Id": "2", "Children": []},
      {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
    ],
  }`)
  ->S.parseAsyncWith(nodeStruct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(
      result,
      Ok({
        id: "1",
        children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
      }),
      (),
    )
  })
})

test("Successfully serializes recursive object", t => {
  let nodeStruct = S.recursive(nodeStruct => {
    S.object(
      o => {
        id: o.field("Id", S.string),
        children: o.field("Children", S.array(nodeStruct)),
      },
    )
  })

  t->Assert.deepEqual(
    {
      id: "1",
      children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
    }->S.serializeToUnknownWith(nodeStruct),
    Ok(
      %raw(`{
        "Id": "1",
        "Children": [
          {"Id": "2", "Children": []},
          {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
        ],
      }`),
    ),
    (),
  )
})

test("Fails to parse nested recursive object", t => {
  let nodeStruct = S.recursive(nodeStruct => {
    S.object(
      o => {
        id: o.field(
          "Id",
          S.string->S.refine(
            ~parser=id => {
              if id === "4" {
                S.fail("Invalid id")
              }
            },
            (),
          ),
        ),
        children: o.field("Children", S.array(nodeStruct)),
      },
    )
  })

  t->Assert.deepEqual(
    {
      "Id": "1",
      "Children": [
        {"Id": "2", "Children": []},
        {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
      ],
    }->S.parseAnyWith(nodeStruct),
    Error({
      code: OperationFailed("Invalid id"),
      operation: Parsing,
      path: S.Path.fromArray(["Children", "1", "Children", "0", "Id"]),
    }),
    (),
  )
})

test("Fails to serialise nested recursive object", t => {
  let nodeStruct = S.recursive(nodeStruct => {
    S.object(
      o => {
        id: o.field(
          "Id",
          S.string->S.refine(
            ~serializer=id => {
              if id === "4" {
                S.fail("Invalid id")
              }
            },
            (),
          ),
        ),
        children: o.field("Children", S.array(nodeStruct)),
      },
    )
  })

  t->Assert.deepEqual(
    {
      id: "1",
      children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
    }->S.serializeToUnknownWith(nodeStruct),
    Error({
      code: OperationFailed("Invalid id"),
      operation: Serializing,
      path: S.Path.fromArray(["children", "1", "children", "0", "id"]),
    }),
    (),
  )
})

test(
  "Recursively transforms all objects when added transform to the recursive's function returned struct",
  t => {
    let nodeStruct = S.recursive(nodeStruct => {
      S.object(
        o => {
          id: o.field("Id", S.string),
          children: o.field("Children", S.array(nodeStruct)),
        },
      )->S.transform(
        ~parser=node => {...node, id: `node_${node.id}`},
        ~serializer=node => {...node, id: node.id->Js.String2.sliceToEnd(~from=5)},
        (),
      )
    })

    t->Assert.deepEqual(
      {
        "Id": "1",
        "Children": [
          {"Id": "2", "Children": []},
          {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
        ],
      }->S.parseAnyWith(nodeStruct),
      Ok({
        id: "node_1",
        children: [
          {id: "node_2", children: []},
          {id: "node_3", children: [{id: "node_4", children: []}]},
        ],
      }),
      (),
    )
    t->Assert.deepEqual(
      {
        id: "node_1",
        children: [
          {id: "node_2", children: []},
          {id: "node_3", children: [{id: "node_4", children: []}]},
        ],
      }->S.serializeToUnknownWith(nodeStruct),
      Ok(
        {
          "Id": "1",
          "Children": [
            {"Id": "2", "Children": []},
            {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
          ],
        }->Obj.magic,
      ),
      (),
    )
  },
)

test("Recursively transforms nested objects when added transform to the placeholder struct", t => {
  let nodeStruct = S.recursive(nodeStruct => {
    S.object(
      o => {
        id: o.field("Id", S.string),
        children: o.field(
          "Children",
          S.array(
            nodeStruct->S.transform(
              ~parser=node => {...node, id: `child_${node.id}`},
              ~serializer=node => {...node, id: node.id->Js.String2.sliceToEnd(~from=6)},
              (),
            ),
          ),
        ),
      },
    )
  })

  t->Assert.deepEqual(
    {
      "Id": "1",
      "Children": [
        {"Id": "2", "Children": []},
        {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
      ],
    }->S.parseAnyWith(nodeStruct),
    Ok({
      id: "1",
      children: [
        {id: "child_2", children: []},
        {id: "child_3", children: [{id: "child_4", children: []}]},
      ],
    }),
    (),
  )
  t->Assert.deepEqual(
    {
      id: "1",
      children: [
        {id: "child_2", children: []},
        {id: "child_3", children: [{id: "child_4", children: []}]},
      ],
    }->S.serializeToUnknownWith(nodeStruct),
    Ok(
      {
        "Id": "1",
        "Children": [
          {"Id": "2", "Children": []},
          {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
        ],
      }->Obj.magic,
    ),
    (),
  )
})

test("Shallowly transforms object when added transform to the S.recursive result", t => {
  let nodeStruct = S.recursive(nodeStruct => {
    S.object(
      o => {
        id: o.field("Id", S.string),
        children: o.field("Children", S.array(nodeStruct)),
      },
    )
  })->S.transform(
    ~parser=node => {...node, id: `parent_${node.id}`},
    ~serializer=node => {...node, id: node.id->Js.String2.sliceToEnd(~from=7)},
    (),
  )

  t->Assert.deepEqual(
    {
      "Id": "1",
      "Children": [
        {"Id": "2", "Children": []},
        {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
      ],
    }->S.parseAnyWith(nodeStruct),
    Ok({
      id: "parent_1",
      children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
    }),
    (),
  )
  t->Assert.deepEqual(
    {
      id: "parent_1",
      children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
    }->S.serializeToUnknownWith(nodeStruct),
    Ok(
      {
        "Id": "1",
        "Children": [
          {"Id": "2", "Children": []},
          {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
        ],
      }->Obj.magic,
    ),
    (),
  )
})

test("Fails to create struct with async parse function using S.recursive", t => {
  t->Assert.throws(
    () => {
      S.recursive(
        nodeStruct => {
          S.object(
            o => {
              id: o.field("Id", S.string->S.refine(~asyncParser=_ => Promise.resolve(), ())),
              children: o.field("Children", S.array(nodeStruct)),
            },
          )
        },
      )->ignore
    },
    ~expectations={
      message: "[rescript-struct] The \"Object\" struct in the S.recursive has an async parser. To make it work, use S.asyncRecursive instead.",
    },
    (),
  )
})

test("Creates struct without async parse function using S.asyncRecursive", t => {
  t->Assert.notThrows(() => {
    S.recursive(
      nodeStruct => {
        S.object(
          o => {
            id: o.field("Id", S.string),
            children: o.field("Children", S.array(nodeStruct)),
          },
        )
      },
    )->ignore
  }, ())
})

test("Creates struct with async parse function using S.asyncRecursive", t => {
  t->Assert.notThrows(() => {
    S.asyncRecursive(
      nodeStruct => {
        S.object(
          o => {
            id: o.field("Id", S.string->S.refine(~asyncParser=_ => Promise.resolve(), ())),
            children: o.field("Children", S.array(nodeStruct)),
          },
        )
      },
    )->ignore
  }, ())
})

asyncTest("Successfully parses recursive object with async parse function", t => {
  let nodeStruct = S.asyncRecursive(nodeStruct => {
    S.object(
      o => {
        id: o.field("Id", S.string->S.refine(~asyncParser=_ => Promise.resolve(), ())),
        children: o.field("Children", S.array(nodeStruct)),
      },
    )
  })

  %raw(`{
    "Id": "1",
    "Children": [
      {"Id": "2", "Children": []},
      {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
    ],
  }`)
  ->S.parseAsyncWith(nodeStruct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(
      result,
      Ok({
        id: "1",
        children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
      }),
      (),
    )
  })
})

test("Parses recursive object with async fields in parallel", t => {
  let unresolvedPromise = Promise.make((_, _) => ())
  let actionCounter = ref(0)

  let nodeStruct = S.asyncRecursive(nodeStruct => {
    S.object(
      o => {
        id: o.field(
          "Id",
          S.string->S.refine(
            ~asyncParser=_ => {
              actionCounter.contents = actionCounter.contents + 1
              unresolvedPromise
            },
            (),
          ),
        ),
        children: o.field("Children", S.array(nodeStruct)),
      },
    )
  })

  %raw(`{
    "Id": "1",
    "Children": [
      {"Id": "2", "Children": []},
      {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
    ],
  }`)
  ->S.parseAsyncWith(nodeStruct)
  ->ignore

  t->Assert.deepEqual(actionCounter.contents, 4, ())
})
