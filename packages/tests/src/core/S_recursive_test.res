open Ava
open RescriptCore

type rec node = {
  id: string,
  children: array<node>,
}

test("Successfully parses recursive object", t => {
  let nodeSchema = S.recursive(nodeSchema => {
    S.object(
      s => {
        id: s.field("Id", S.string),
        children: s.field("Children", S.array(nodeSchema)),
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
    }->S.parseAnyWith(nodeSchema),
    Ok({
      id: "1",
      children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
    }),
    (),
  )
})

asyncTest("Successfully parses recursive object using S.parseAsyncWith", t => {
  let nodeSchema = S.recursive(nodeSchema => {
    S.object(
      s => {
        id: s.field("Id", S.string),
        children: s.field("Children", S.array(nodeSchema)),
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
  ->S.parseAsyncWith(nodeSchema)
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
  let nodeSchema = S.recursive(nodeSchema => {
    S.object(
      s => {
        id: s.field("Id", S.string),
        children: s.field("Children", S.array(nodeSchema)),
      },
    )
  })

  t->Assert.deepEqual(
    {
      id: "1",
      children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
    }->S.serializeToUnknownWith(nodeSchema),
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
  let nodeSchema = S.recursive(nodeSchema => {
    S.object(
      s => {
        id: s.field(
          "Id",
          S.string->S.refine(
            s => id => {
              if id === "4" {
                s.fail("Invalid id")
              }
            },
          ),
        ),
        children: s.field("Children", S.array(nodeSchema)),
      },
    )
  })

  t->U.assertErrorResult(
    {
      "Id": "1",
      "Children": [
        {"Id": "2", "Children": []},
        {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
      ],
    }->S.parseAnyWith(nodeSchema),
    {
      code: OperationFailed("Invalid id"),
      operation: Parsing,
      path: S.Path.fromArray(["Children", "1", "Children", "0", "Id"]),
    },
  )
})

test("Fails to parse nested recursive object inside of another object", t => {
  let schema = S.object(s =>
    s.field(
      "recursive",
      S.recursive(
        nodeSchema => {
          S.object(
            s => {
              id: s.field(
                "Id",
                S.string->S.refine(
                  s => id => {
                    if id === "4" {
                      s.fail("Invalid id")
                    }
                  },
                ),
              ),
              children: s.field("Children", S.array(nodeSchema)),
            },
          )
        },
      ),
    )
  )

  t->U.assertErrorResult(
    {
      "recursive": {
        "Id": "1",
        "Children": [
          {"Id": "2", "Children": []},
          {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
        ],
      },
    }->S.parseAnyWith(schema),
    {
      code: OperationFailed("Invalid id"),
      operation: Parsing,
      path: S.Path.fromArray(["recursive", "Children", "1", "Children", "0", "Id"]),
    },
  )
})

test("Fails to serialise nested recursive object", t => {
  let nodeSchema = S.recursive(nodeSchema => {
    S.object(
      s => {
        id: s.field(
          "Id",
          S.string->S.refine(
            s => id => {
              if id === "4" {
                s.fail("Invalid id")
              }
            },
          ),
        ),
        children: s.field("Children", S.array(nodeSchema)),
      },
    )
  })

  t->U.assertErrorResult(
    {
      id: "1",
      children: [{id: "2", children: []}, {id: "3", children: [{id: "4", children: []}]}],
    }->S.serializeToUnknownWith(nodeSchema),
    {
      code: OperationFailed("Invalid id"),
      operation: Serializing,
      path: S.Path.fromArray(["children", "1", "children", "0", "id"]),
    },
  )
})

test(
  "Recursively transforms all objects when added transform to the recursive's function returned schema",
  t => {
    let nodeSchema = S.recursive(nodeSchema => {
      S.object(
        s => {
          id: s.field("Id", S.string),
          children: s.field("Children", S.array(nodeSchema)),
        },
      )->S.transform(
        _ => {
          parser: node => {...node, id: `node_${node.id}`},
          serializer: node => {...node, id: node.id->String.sliceToEnd(~start=5)},
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
      }->S.parseAnyWith(nodeSchema),
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
      }->S.serializeToUnknownWith(nodeSchema),
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

test("Recursively transforms nested objects when added transform to the placeholder schema", t => {
  let nodeSchema = S.recursive(nodeSchema => {
    S.object(
      s => {
        id: s.field("Id", S.string),
        children: s.field(
          "Children",
          S.array(
            nodeSchema->S.transform(
              _ => {
                parser: node => {...node, id: `child_${node.id}`},
                serializer: node => {...node, id: node.id->String.sliceToEnd(~start=6)},
              },
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
    }->S.parseAnyWith(nodeSchema),
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
    }->S.serializeToUnknownWith(nodeSchema),
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
  let nodeSchema = S.recursive(nodeSchema => {
    S.object(
      s => {
        id: s.field("Id", S.string),
        children: s.field("Children", S.array(nodeSchema)),
      },
    )
  })->S.transform(_ => {
    parser: node => {...node, id: `parent_${node.id}`},
    serializer: node => {...node, id: node.id->String.sliceToEnd(~start=7)},
  })

  t->Assert.deepEqual(
    {
      "Id": "1",
      "Children": [
        {"Id": "2", "Children": []},
        {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
      ],
    }->S.parseAnyWith(nodeSchema),
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
    }->S.serializeToUnknownWith(nodeSchema),
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

test("Creates schema without async parse function using S.recursive", t => {
  t->Assert.notThrows(() => {
    S.recursive(
      nodeSchema => {
        S.object(
          s => {
            id: s.field("Id", S.string),
            children: s.field("Children", S.array(nodeSchema)),
          },
        )
      },
    )->ignore
  }, ())
})

test("Creates schema with async parse function using S.recursive", t => {
  t->Assert.notThrows(() => {
    S.recursive(
      nodeSchema => {
        S.object(
          s => {
            id: s.field(
              "Id",
              S.string->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}),
            ),
            children: s.field("Children", S.array(nodeSchema)),
          },
        )
      },
    )->ignore
  }, ())
})

asyncTest("Successfully parses recursive object with async parse function", t => {
  let nodeSchema = S.recursive(nodeSchema => {
    S.object(
      s => {
        id: s.field("Id", S.string->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)})),
        children: s.field("Children", S.array(nodeSchema)),
      },
    )
  })

  %raw(`{
    "Id":"1",
    "Children": [
      {"Id": "2", "Children": []},
      {"Id": "3", "Children": [{"Id": "4", "Children": []}]},
    ],
  }`)
  ->S.parseAsyncWith(nodeSchema)
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

  let nodeSchema = S.recursive(nodeSchema => {
    S.object(
      s => {
        id: s.field(
          "Id",
          S.string->S.transform(
            _ => {
              asyncParser: _ => () => {
                actionCounter.contents = actionCounter.contents + 1
                unresolvedPromise
              },
            },
          ),
        ),
        children: s.field("Children", S.array(nodeSchema)),
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
  ->S.parseAsyncWith(nodeSchema)
  ->ignore

  t->Assert.deepEqual(actionCounter.contents, 4, ())
})
