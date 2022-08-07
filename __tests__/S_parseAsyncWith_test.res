open Ava

let validAsyncRefine = S.asyncRefine(_, ~parser=_ => None->Js.Promise.resolve, ())
let invalidAsyncRefine = S.asyncRefine(
  _,
  ~parser=_ => Some("Async user error")->Js.Promise.resolve,
  (),
)
let invalidSyncRefine = S.refine(_, ~parser=_ => Some("Sync user error"), ())
let unresolvedPromise = Js.Promise.make((~resolve as _, ~reject as _) => ())

asyncTest("Successfully parses without asyncRefine", t => {
  let struct = S.string()

  %raw(`"Hello world!"`)->S.parseAsyncWith(struct)->Belt.Result.getExn
    |> Js.Promise.then_(result => {
      t->Assert.deepEqual(result, Ok("Hello world!"), ())
      Js.Promise.resolve()
    })
})

test("Fails to parse without asyncRefine", t => {
  let struct = S.string()

  t->Assert.deepEqual(
    %raw(`123`)->S.parseAsyncWith(struct),
    Error({
      S.Error.code: UnexpectedType({expected: "String", received: "Float"}),
      path: [],
      operation: Parsing,
    }),
    (),
  )
})

asyncTest("Successfully parses with validAsyncRefine", t => {
  let struct = S.string()->validAsyncRefine

  %raw(`"Hello world!"`)->S.parseAsyncWith(struct)->Belt.Result.getExn
    |> Js.Promise.then_(result => {
      t->Assert.deepEqual(result, Ok("Hello world!"), ())
      Js.Promise.resolve()
    })
})

asyncTest("Fails to parse with invalidAsyncRefine", t => {
  let struct = S.string()->invalidAsyncRefine

  %raw(`"Hello world!"`)->S.parseAsyncWith(struct)->Belt.Result.getExn
    |> Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: [],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    })
})

module Record = {
  asyncTest("[Record] Successfully parses", t => {
    let struct = S.record3(. ("k1", S.int()), ("k2", S.int()->validAsyncRefine), ("k3", S.int()))

    {
      "k1": 1,
      "k2": 2,
      "k3": 3,
    }
    ->S.parseAsyncWith(struct)
    ->Belt.Result.getExn
    ->Js.Promise.then_(result => {
      t->Assert.deepEqual(result, Ok(1, 2, 3), ())
      Js.Promise.resolve()
    }, _)
  })

  asyncTest("[Record] Doesn't return sync error when fails to parse sync part of async item", t => {
    let struct = S.record3(. ("k1", S.int()), ("k2", S.int()->validAsyncRefine), ("k3", S.int()))

    {
      "k1": 1,
      "k2": true,
      "k3": 3,
    }
    ->S.parseAsyncWith(struct)
    ->Belt.Result.getExn
    ->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
          path: ["k2"],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })

  test("[Record] Parses sync items first, and then starts parsing async ones", t => {
    let struct = S.record3(.
      ("k1", S.int()),
      ("k2", S.int()->invalidSyncRefine->invalidAsyncRefine),
      ("k3", S.int()->invalidSyncRefine),
    )

    t->Assert.deepEqual(
      {
        "k1": 1,
        "k2": 2,
        "k3": 3,
      }->S.parseAsyncWith(struct),
      Error({
        S.Error.code: OperationFailed("Sync user error"),
        path: ["k3"],
        operation: Parsing,
      }),
      (),
    )
  })

  asyncTest("[Record] Parses async items in parallel", t => {
    let actionCounter = ref(0)

    let struct = S.record2(.
      (
        "k1",
        S.int()->S.asyncRefine(
          _,
          ~parser=_ => {
            actionCounter.contents = actionCounter.contents + 1
            unresolvedPromise
          },
          (),
        ),
      ),
      (
        "k2",
        S.int()->S.asyncRefine(
          _,
          ~parser=_ => {
            actionCounter.contents = actionCounter.contents + 1
            unresolvedPromise
          },
          (),
        ),
      ),
    )

    {
      "k1": 1,
      "k2": 2,
    }
    ->S.parseAsyncWith(struct)
    ->ignore

    Js.Promise.resolve()
    |> Js.Promise.then_(Js.Promise.resolve)
    |> Js.Promise.then_(() => {
      t->Assert.deepEqual(actionCounter.contents, 2, ())
      Js.Promise.resolve()
    })
  })

  asyncTest("[Record] Doesn't wait for pending async items when fails to parse", t => {
    let struct = S.record2(.
      ("k1", S.int()->S.asyncRefine(_, ~parser=_ => unresolvedPromise, ())),
      ("k2", S.int()->invalidAsyncRefine),
    )

    {
      "k1": 1,
      "k2": 2,
    }
    ->S.parseAsyncWith(struct)
    ->Belt.Result.getExn
    ->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: ["k2"],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })
}

module Tuple = {
  asyncTest("[Tuple] Successfully parses", t => {
    let struct = S.tuple3(. S.int(), S.int()->validAsyncRefine, S.int())

    [1, 2, 3]->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
      t->Assert.deepEqual(result, Ok(1, 2, 3), ())
      Js.Promise.resolve()
    }, _)
  })

  asyncTest("[Tuple] Doesn't return sync error when fails to parse sync part of async item", t => {
    let struct = S.tuple3(. S.int(), S.int()->validAsyncRefine, S.int())

    %raw(`[1, true, 3]`)->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
          path: ["1"],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })

  test("[Tuple] Parses sync items first, and then starts parsing async ones", t => {
    let struct = S.tuple3(.
      S.int(),
      S.int()->invalidSyncRefine->invalidAsyncRefine,
      S.int()->invalidSyncRefine,
    )

    t->Assert.deepEqual(
      [1, 2, 3]->S.parseAsyncWith(struct),
      Error({
        S.Error.code: OperationFailed("Sync user error"),
        path: ["1"],
        operation: Parsing,
      }),
      (),
    )
  })

  asyncTest("[Tuple] Parses async items in parallel", t => {
    let actionCounter = ref(0)

    let struct = S.tuple2(.
      S.int()->S.asyncRefine(
        _,
        ~parser=_ => {
          actionCounter.contents = actionCounter.contents + 1
          unresolvedPromise
        },
        (),
      ),
      S.int()->S.asyncRefine(
        _,
        ~parser=_ => {
          actionCounter.contents = actionCounter.contents + 1
          unresolvedPromise
        },
        (),
      ),
    )

    [1, 2]->S.parseAsyncWith(struct)->ignore

    Js.Promise.resolve()
    |> Js.Promise.then_(Js.Promise.resolve)
    |> Js.Promise.then_(() => {
      t->Assert.deepEqual(actionCounter.contents, 2, ())
      Js.Promise.resolve()
    })
  })

  asyncTest("[Tuple] Doesn't wait for pending async items when fails to parse", t => {
    let struct = S.tuple2(.
      S.int()->S.asyncRefine(_, ~parser=_ => unresolvedPromise, ()),
      S.int()->invalidAsyncRefine,
    )

    [1, 2]->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: ["1"],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })
}

module Union = {
  asyncTest("[Union] Successfully parses", t => {
    let struct = S.union([
      S.literal(Int(1)),
      S.literal(Int(2))->validAsyncRefine,
      S.literal(Int(3)),
    ])

    Js.Promise.all([1->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
        t->Assert.deepEqual(result, Ok(1), ())
        Js.Promise.resolve()
      }, _), 2->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
        t->Assert.deepEqual(result, Ok(2), ())
        Js.Promise.resolve()
      }, _), 3->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
        t->Assert.deepEqual(result, Ok(3), ())
        Js.Promise.resolve()
      }, _)])->Js.Promise.then_(_ => Js.Promise.resolve(), _)
  })

  asyncTest("[Union] Doesn't return sync error when fails to parse sync part of async item", t => {
    let struct = S.union([
      S.literal(Int(1)),
      S.literal(Int(2))->validAsyncRefine,
      S.literal(Int(3)),
    ])

    // FIXME: Errors are in different order than structs
    true->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: InvalidUnion([
            {
              S.Error.code: UnexpectedType({expected: "Int Literal (1)", received: "Bool"}),
              path: [],
              operation: Parsing,
            },
            {
              S.Error.code: UnexpectedType({expected: "Int Literal (3)", received: "Bool"}),
              path: [],
              operation: Parsing,
            },
            {
              S.Error.code: UnexpectedType({expected: "Int Literal (2)", received: "Bool"}),
              path: [],
              operation: Parsing,
            },
          ]),
          path: [],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })

  asyncTest("[Union] Parses async items in parallel", t => {
    let actionCounter = ref(0)

    let struct = S.union([
      S.literal(Int(2))->S.asyncRefine(
        _,
        ~parser=_ => {
          actionCounter.contents = actionCounter.contents + 1
          unresolvedPromise
        },
        (),
      ),
      S.literal(Int(2))->S.asyncRefine(
        _,
        ~parser=_ => {
          actionCounter.contents = actionCounter.contents + 1
          unresolvedPromise
        },
        (),
      ),
    ])

    2->S.parseAsyncWith(struct)->ignore

    Js.Promise.resolve()
    |> Js.Promise.then_(Js.Promise.resolve)
    |> Js.Promise.then_(() => {
      t->Assert.deepEqual(actionCounter.contents, 2, ())
      Js.Promise.resolve()
    })
  })
}

module Array = {
  asyncTest("[Array] Successfully parses", t => {
    let struct = S.array(S.int()->validAsyncRefine)

    [1, 2, 3]->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
      t->Assert.deepEqual(result, Ok([1, 2, 3]), ())
      Js.Promise.resolve()
    }, _)
  })

  asyncTest("[Array] Doesn't return sync error when fails to parse sync part of async item", t => {
    let struct = S.array(S.int()->validAsyncRefine)

    %raw(`[1, 2, true]`)->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
          path: ["2"],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })

  asyncTest("[Array] Parses async items in parallel", t => {
    let actionCounter = ref(0)

    let struct = S.array(
      S.int()->S.asyncRefine(
        _,
        ~parser=_ => {
          actionCounter.contents = actionCounter.contents + 1
          unresolvedPromise
        },
        (),
      ),
    )

    [1, 2]->S.parseAsyncWith(struct)->ignore

    Js.Promise.resolve()
    |> Js.Promise.then_(Js.Promise.resolve)
    |> Js.Promise.then_(() => {
      t->Assert.deepEqual(actionCounter.contents, 2, ())
      Js.Promise.resolve()
    })
  })

  asyncTest("[Array] Doesn't wait for pending async items when fails to parse", t => {
    let actionCounter = ref(0)

    let struct = S.array(
      S.int()->S.asyncRefine(
        _,
        ~parser=_ => {
          actionCounter.contents = actionCounter.contents + 1
          if actionCounter.contents <= 2 {
            unresolvedPromise
          } else {
            Js.Promise.resolve(Some("Async user error"))
          }
        },
        (),
      ),
    )

    [1, 2, 3]->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: ["2"],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })
}

module Dict = {
  asyncTest("[Dict] Successfully parses", t => {
    let struct = S.dict(S.int()->validAsyncRefine)

    {"k1": 1, "k2": 2, "k3": 3}
    ->S.parseAsyncWith(struct)
    ->Belt.Result.getExn
    ->Js.Promise.then_(result => {
      t->Assert.deepEqual(result, Ok(Js.Dict.fromArray([("k1", 1), ("k2", 2), ("k3", 3)])), ())
      Js.Promise.resolve()
    }, _)
  })

  asyncTest("[Dict] Doesn't return sync error when fails to parse sync part of async item", t => {
    let struct = S.dict(S.int()->validAsyncRefine)

    {"k1": 1, "k2": 2, "k3": true}
    ->S.parseAsyncWith(struct)
    ->Belt.Result.getExn
    ->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
          path: ["k3"],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })

  asyncTest("[Dict] Parses async items in parallel", t => {
    let actionCounter = ref(0)

    let struct = S.dict(
      S.int()->S.asyncRefine(
        _,
        ~parser=_ => {
          actionCounter.contents = actionCounter.contents + 1
          unresolvedPromise
        },
        (),
      ),
    )

    {"k1": 1, "k2": 2}->S.parseAsyncWith(struct)->ignore

    Js.Promise.resolve()
    |> Js.Promise.then_(Js.Promise.resolve)
    |> Js.Promise.then_(() => {
      t->Assert.deepEqual(actionCounter.contents, 2, ())
      Js.Promise.resolve()
    })
  })

  asyncTest("[Dict] Doesn't wait for pending async items when fails to parse", t => {
    let actionCounter = ref(0)

    let struct = S.dict(
      S.int()->S.asyncRefine(
        _,
        ~parser=_ => {
          actionCounter.contents = actionCounter.contents + 1
          if actionCounter.contents <= 2 {
            unresolvedPromise
          } else {
            Js.Promise.resolve(Some("Async user error"))
          }
        },
        (),
      ),
    )

    {"k1": 1, "k2": 2, "k3": 3}
    ->S.parseAsyncWith(struct)
    ->Belt.Result.getExn
    ->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: ["k3"],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })
}

module Null = {
  asyncTest("[Null] Successfully parses", t => {
    let struct = S.null(S.int()->validAsyncRefine)

    Js.Promise.all([1->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
        t->Assert.deepEqual(result, Ok(Some(1)), ())
        Js.Promise.resolve()
      }, _), %raw(`null`)
      ->S.parseAsyncWith(struct)
      ->Belt.Result.getExn
      ->Js.Promise.then_(result => {
        t->Assert.deepEqual(result, Ok(None), ())
        Js.Promise.resolve()
      }, _)])->Js.Promise.then_(_ => Js.Promise.resolve(), _)
  })

  asyncTest("[Null] Fails to parse with invalid async refine", t => {
    let struct = S.null(S.int()->invalidAsyncRefine)

    1->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: [],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })

  asyncTest("[Null] Doesn't return sync error when fails to parse sync part of async item", t => {
    let struct = S.null(S.int()->validAsyncRefine)

    true->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
          path: [],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })
}

module Option = {
  asyncTest("[Option] Successfully parses", t => {
    let struct = S.option(S.int()->validAsyncRefine)

    Js.Promise.all([1->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
        t->Assert.deepEqual(result, Ok(Some(1)), ())
        Js.Promise.resolve()
      }, _), %raw(`undefined`)
      ->S.parseAsyncWith(struct)
      ->Belt.Result.getExn
      ->Js.Promise.then_(result => {
        t->Assert.deepEqual(result, Ok(None), ())
        Js.Promise.resolve()
      }, _)])->Js.Promise.then_(_ => Js.Promise.resolve(), _)
  })

  asyncTest("[Option] Fails to parse with invalid async refine", t => {
    let struct = S.option(S.int()->invalidAsyncRefine)

    1->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: [],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })

  asyncTest("[Option] Doesn't return sync error when fails to parse sync part of async item", t => {
    let struct = S.option(S.int()->validAsyncRefine)

    true->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
          path: [],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })
}

module Deprecated = {
  asyncTest("[Deprecated] Successfully parses", t => {
    let struct = S.deprecated(S.int()->validAsyncRefine)

    Js.Promise.all([1->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
        t->Assert.deepEqual(result, Ok(Some(1)), ())
        Js.Promise.resolve()
      }, _), %raw(`undefined`)
      ->S.parseAsyncWith(struct)
      ->Belt.Result.getExn
      ->Js.Promise.then_(result => {
        t->Assert.deepEqual(result, Ok(None), ())
        Js.Promise.resolve()
      }, _)])->Js.Promise.then_(_ => Js.Promise.resolve(), _)
  })

  asyncTest("[Deprecated] Fails to parse with invalid async refine", t => {
    let struct = S.deprecated(S.int()->invalidAsyncRefine)

    1->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: [],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })

  asyncTest(
    "[Deprecated] Doesn't return sync error when fails to parse sync part of async item",
    t => {
      let struct = S.deprecated(S.int()->validAsyncRefine)

      true->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
        t->Assert.deepEqual(
          result,
          Error({
            S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
            path: [],
            operation: Parsing,
          }),
          (),
        )
        Js.Promise.resolve()
      }, _)
    },
  )
}

module Default = {
  asyncTest("[Default] Successfully parses", t => {
    let struct = S.option(S.int()->validAsyncRefine)->S.default(10)

    Js.Promise.all([1->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
        t->Assert.deepEqual(result, Ok(1), ())
        Js.Promise.resolve()
      }, _), %raw(`undefined`)
      ->S.parseAsyncWith(struct)
      ->Belt.Result.getExn
      ->Js.Promise.then_(result => {
        t->Assert.deepEqual(result, Ok(10), ())
        Js.Promise.resolve()
      }, _)])->Js.Promise.then_(_ => Js.Promise.resolve(), _)
  })

  asyncTest("[Default] Fails to parse with invalid async refine", t => {
    let struct = S.option(S.int()->invalidAsyncRefine)->S.default(10)

    1->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: [],
          operation: Parsing,
        }),
        (),
      )
      Js.Promise.resolve()
    }, _)
  })

  asyncTest(
    "[Default] Doesn't return sync error when fails to parse sync part of async item",
    t => {
      let struct = S.option(S.int()->validAsyncRefine)->S.default(10)

      true->S.parseAsyncWith(struct)->Belt.Result.getExn->Js.Promise.then_(result => {
        t->Assert.deepEqual(
          result,
          Error({
            S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
            path: [],
            operation: Parsing,
          }),
          (),
        )
        Js.Promise.resolve()
      }, _)
    },
  )
}

module Json = {
  // FIXME:
  test("[Json] Fails to parse async item", t => {
    let struct = S.json(S.int()->validAsyncRefine)

    t->Assert.deepEqual(
      "1"->S.parseAsyncWith(struct),
      Error({
        S.Error.code: UnexpectedAsync,
        path: [],
        operation: Parsing,
      }),
      (),
    )
  })
}
