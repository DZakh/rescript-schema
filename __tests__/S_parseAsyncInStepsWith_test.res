open Ava

let validAsyncRefine = S.advancedTransform(
  _,
  ~parser=(~struct as _) => Async(value => Promise.resolve(value)),
  (),
)
let invalidSyncRefine = S.refine(_, ~parser=_ => S.Error.raise("Sync user error"), ())
let unresolvedPromise = Promise.make((_, _) => ())
let invalidPromise = Promise.resolve()->Promise.then(() => S.Error.raise("Async user error"))
let invalidAsyncRefine = S.advancedTransform(
  _,
  ~parser=(~struct as _) => Async(_ => invalidPromise),
  (),
)

asyncTest("Successfully parses without asyncRefine", t => {
  let struct = S.string()

  (
    %raw(`"Hello world!"`)->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn
  )(.)->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

test("Fails to parse without asyncRefine", t => {
  let struct = S.string()

  t->Assert.deepEqual(
    %raw(`123`)->S.parseAsyncInStepsWith(struct),
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

  (
    %raw(`"Hello world!"`)->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn
  )(.)->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

asyncTest("Fails to parse with invalidAsyncRefine", t => {
  let struct = S.string()->invalidAsyncRefine

  (
    %raw(`"Hello world!"`)->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn
  )(.)->Promise.thenResolve(result => {
    t->Assert.deepEqual(
      result,
      Error({
        S.Error.code: OperationFailed("Async user error"),
        path: [],
        operation: Parsing,
      }),
      (),
    )
  })
})

module Object = {
  asyncTest("[Object] Successfully parses", t => {
    let struct = S.object(o =>
      {
        "k1": o->S.field("k1", S.int()),
        "k2": o->S.field("k2", S.int()->validAsyncRefine),
        "k3": o->S.field("k3", S.int()),
      }
    )

    (
      {
        "k1": 1,
        "k2": 2,
        "k3": 3,
      }
      ->S.parseAsyncInStepsWith(struct)
      ->Belt.Result.getExn
    )(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(
        result,
        Ok({
          "k1": 1,
          "k2": 2,
          "k3": 3,
        }),
        (),
      )
    })
  })

  asyncTest("[Object] Keeps fields in the correct order", t => {
    let struct = S.object(o =>
      {
        "k1": o->S.field("k1", S.int()),
        "k2": o->S.field("k2", S.int()->validAsyncRefine),
        "k3": o->S.field("k3", S.int()),
      }
    )

    (
      {
        "k1": 1,
        "k2": 2,
        "k3": 3,
      }
      ->S.parseAsyncInStepsWith(struct)
      ->Belt.Result.getExn
    )(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(
        result->Belt.Result.map(Obj.magic)->Belt.Result.map(Js.Dict.keys),
        Ok(["k1", "k2", "k3"]),
        (),
      )
    })
  })

  asyncTest("[Object] Successfully parses with valid async discriminant", t => {
    let struct = S.object(o => {
      o->S.discriminant("discriminant", S.literal(Bool(true))->validAsyncRefine)
      {
        "k1": o->S.field("k1", S.int()),
        "k2": o->S.field("k2", S.int()),
        "k3": o->S.field("k3", S.int()),
      }
    })

    (
      {
        "discriminant": true,
        "k1": 1,
        "k2": 2,
        "k3": 3,
      }
      ->S.parseAsyncInStepsWith(struct)
      ->Belt.Result.getExn
    )(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(
        result,
        Ok({
          "k1": 1,
          "k2": 2,
          "k3": 3,
        }),
        (),
      )
    })
  })

  asyncTest("[Object] Fails to parse with invalid async discriminant", t => {
    let struct = S.object(o => {
      o->S.discriminant("discriminant", S.literal(Bool(true))->invalidAsyncRefine)
      {
        "k1": o->S.field("k1", S.int()),
        "k2": o->S.field("k2", S.int()),
        "k3": o->S.field("k3", S.int()),
      }
    })

    (
      {
        "discriminant": true,
        "k1": 1,
        "k2": 2,
        "k3": 3,
      }
      ->S.parseAsyncInStepsWith(struct)
      ->Belt.Result.getExn
    )(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(
        result,
        Error({
          code: OperationFailed("Async user error"),
          operation: Parsing,
          path: ["discriminant"],
        }),
        (),
      )
    })
  })

  test("[Object] Returns sync error when fails to parse sync part of async item", t => {
    let struct = S.object(o =>
      {
        "k1": o->S.field("k1", S.int()),
        "k2": o->S.field("k2", S.int()->validAsyncRefine),
        "k3": o->S.field("k3", S.int()),
      }
    )

    t->Assert.deepEqual(
      {
        "k1": 1,
        "k2": true,
        "k3": 3,
      }->S.parseAsyncInStepsWith(struct),
      Error({
        S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
        path: ["k2"],
        operation: Parsing,
      }),
      (),
    )
  })

  test("[Object] Parses sync items first, and then starts parsing async ones", t => {
    let struct = S.object(o =>
      {
        "k1": o->S.field("k1", S.int()),
        "k2": o->S.field("k2", S.int()->invalidAsyncRefine),
        "k3": o->S.field("k3", S.int()->invalidSyncRefine),
      }
    )

    t->Assert.deepEqual(
      {
        "k1": 1,
        "k2": 2,
        "k3": 3,
      }->S.parseAsyncInStepsWith(struct),
      Error({
        S.Error.code: OperationFailed("Sync user error"),
        path: ["k3"],
        operation: Parsing,
      }),
      (),
    )
  })

  test("[Object] Parses async items in parallel", t => {
    let actionCounter = ref(0)

    let struct = S.object(o =>
      {
        "k1": o->S.field(
          "k1",
          S.int()->S.advancedTransform(
            ~parser=(~struct as _) => {
              Async(
                _ => {
                  actionCounter.contents = actionCounter.contents + 1
                  unresolvedPromise
                },
              )
            },
            (),
          ),
        ),
        "k2": o->S.field(
          "k2",
          S.int()->S.advancedTransform(
            ~parser=(~struct as _) => {
              Async(
                _ => {
                  actionCounter.contents = actionCounter.contents + 1
                  unresolvedPromise
                },
              )
            },
            (),
          ),
        ),
      }
    )

    {
      "k1": 1,
      "k2": 2,
    }
    ->S.parseAsyncWith(struct)
    ->ignore

    t->Assert.deepEqual(actionCounter.contents, 2, ())
  })

  asyncTest("[Object] Doesn't wait for pending async items when fails to parse", t => {
    let struct = S.object(o =>
      {
        "k1": o->S.field(
          "k1",
          S.int()->S.advancedTransform(
            ~parser=(~struct as _) => {
              Async(_ => unresolvedPromise)
            },
            (),
          ),
        ),
        "k2": o->S.field("k2", S.int()->invalidAsyncRefine),
      }
    )

    (
      {
        "k1": 1,
        "k2": 2,
      }
      ->S.parseAsyncInStepsWith(struct)
      ->Belt.Result.getExn
    )(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: ["k2"],
          operation: Parsing,
        }),
        (),
      )
    })
  })
}

module Tuple = {
  asyncTest("[Tuple] Successfully parses", t => {
    let struct = S.tuple3(. S.int(), S.int()->validAsyncRefine, S.int())

    (
      [1, 2, 3]->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn
    )(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(result, Ok(1, 2, 3), ())
    })
  })

  test("[Tuple] Returns sync error when fails to parse sync part of async item", t => {
    let struct = S.tuple3(. S.int(), S.int()->validAsyncRefine, S.int())

    t->Assert.deepEqual(
      %raw(`[1, true, 3]`)->S.parseAsyncInStepsWith(struct),
      Error({
        S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
        path: ["1"],
        operation: Parsing,
      }),
      (),
    )
  })

  test("[Tuple] Parses sync items first, and then starts parsing async ones", t => {
    let struct = S.tuple3(.
      S.int(),
      S.int()->invalidSyncRefine->invalidAsyncRefine,
      S.int()->invalidSyncRefine,
    )

    t->Assert.deepEqual(
      [1, 2, 3]->S.parseAsyncInStepsWith(struct),
      Error({
        S.Error.code: OperationFailed("Sync user error"),
        path: ["1"],
        operation: Parsing,
      }),
      (),
    )
  })

  test("[Tuple] Parses async items in parallel", t => {
    let actionCounter = ref(0)

    let struct = S.tuple2(. S.int()->S.advancedTransform(~parser=(~struct as _) => {
        Async(
          _ => {
            actionCounter.contents = actionCounter.contents + 1
            unresolvedPromise
          },
        )
      }, ()), S.int()->S.advancedTransform(~parser=(~struct as _) => {
        Async(
          _ => {
            actionCounter.contents = actionCounter.contents + 1
            unresolvedPromise
          },
        )
      }, ()))

    [1, 2]->S.parseAsyncWith(struct)->ignore

    t->Assert.deepEqual(actionCounter.contents, 2, ())
  })

  asyncTest("[Tuple] Doesn't wait for pending async items when fails to parse", t => {
    let struct = S.tuple2(. S.int()->S.advancedTransform(~parser=(~struct as _) => {
        Async(_ => unresolvedPromise)
      }, ()), S.int()->invalidAsyncRefine)

    (
      [1, 2]->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn
    )(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: ["1"],
          operation: Parsing,
        }),
        (),
      )
    })
  })
}

module Union = {
  asyncTest("[Union] Successfully parses", t => {
    let struct = S.union([
      S.literal(Int(1)),
      S.literal(Int(2))->validAsyncRefine,
      S.literal(Int(3)),
    ])

    Promise.all([
      (1->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn)(.)->Promise.thenResolve(result => {
        t->Assert.deepEqual(result, Ok(1), ())
      }),
      (2->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn)(.)->Promise.thenResolve(result => {
        t->Assert.deepEqual(result, Ok(2), ())
      }),
      (3->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn)(.)->Promise.thenResolve(result => {
        t->Assert.deepEqual(result, Ok(3), ())
      }),
    ])->Promise.thenResolve(_ => ())
  })

  asyncTest("[Union] Doesn't return sync error when fails to parse sync part of async item", t => {
    let struct = S.union([
      S.literal(Int(1)),
      S.literal(Int(2))->validAsyncRefine,
      S.literal(Int(3)),
    ])

    (true->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn)(.)->Promise.thenResolve(result => {
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
              S.Error.code: UnexpectedType({expected: "Int Literal (2)", received: "Bool"}),
              path: [],
              operation: Parsing,
            },
            {
              S.Error.code: UnexpectedType({expected: "Int Literal (3)", received: "Bool"}),
              path: [],
              operation: Parsing,
            },
          ]),
          path: [],
          operation: Parsing,
        }),
        (),
      )
    })
  })

  test("[Union] Parses async items in parallel", t => {
    let actionCounter = ref(0)

    let struct = S.union([S.literal(Int(2))->S.advancedTransform(~parser=(~struct as _) => {
        Async(
          _ => {
            actionCounter.contents = actionCounter.contents + 1
            unresolvedPromise
          },
        )
      }, ()), S.literal(Int(2))->S.advancedTransform(~parser=(~struct as _) => {
        Async(
          _ => {
            actionCounter.contents = actionCounter.contents + 1
            unresolvedPromise
          },
        )
      }, ())])

    2->S.parseAsyncWith(struct)->ignore

    t->Assert.deepEqual(actionCounter.contents, 2, ())
  })
}

module Array = {
  asyncTest("[Array] Successfully parses", t => {
    let struct = S.array(S.int()->validAsyncRefine)

    (
      [1, 2, 3]->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn
    )(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(result, Ok([1, 2, 3]), ())
    })
  })

  test("[Array] Returns sync error when fails to parse sync part of async item", t => {
    let struct = S.array(S.int()->validAsyncRefine)

    t->Assert.deepEqual(
      %raw(`[1, 2, true]`)->S.parseAsyncInStepsWith(struct),
      Error({
        S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
        path: ["2"],
        operation: Parsing,
      }),
      (),
    )
  })

  test("[Array] Parses async items in parallel", t => {
    let actionCounter = ref(0)

    let struct = S.array(S.int()->S.advancedTransform(~parser=(~struct as _) => {
        Async(
          _ => {
            actionCounter.contents = actionCounter.contents + 1
            unresolvedPromise
          },
        )
      }, ()))

    [1, 2]->S.parseAsyncWith(struct)->ignore

    t->Assert.deepEqual(actionCounter.contents, 2, ())
  })

  asyncTest("[Array] Doesn't wait for pending async items when fails to parse", t => {
    let actionCounter = ref(0)

    let struct = S.array(S.int()->S.advancedTransform(~parser=(~struct as _) => {
        Async(
          _ => {
            actionCounter.contents = actionCounter.contents + 1
            if actionCounter.contents <= 2 {
              unresolvedPromise
            } else {
              invalidPromise
            }
          },
        )
      }, ()))

    (
      [1, 2, 3]->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn
    )(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: ["2"],
          operation: Parsing,
        }),
        (),
      )
    })
  })
}

module Dict = {
  asyncTest("[Dict] Successfully parses", t => {
    let struct = S.dict(S.int()->validAsyncRefine)

    (
      {"k1": 1, "k2": 2, "k3": 3}->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn
    )(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(result, Ok(Js.Dict.fromArray([("k1", 1), ("k2", 2), ("k3", 3)])), ())
    })
  })

  test("[Dict] Returns sync error when fails to parse sync part of async item", t => {
    let struct = S.dict(S.int()->validAsyncRefine)

    t->Assert.deepEqual(
      {"k1": 1, "k2": 2, "k3": true}->S.parseAsyncInStepsWith(struct),
      Error({
        S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
        path: ["k3"],
        operation: Parsing,
      }),
      (),
    )
  })

  test("[Dict] Parses async items in parallel", t => {
    let actionCounter = ref(0)

    let struct = S.dict(S.int()->S.advancedTransform(~parser=(~struct as _) => {
        Async(
          _ => {
            actionCounter.contents = actionCounter.contents + 1
            unresolvedPromise
          },
        )
      }, ()))

    {"k1": 1, "k2": 2}->S.parseAsyncWith(struct)->ignore

    t->Assert.deepEqual(actionCounter.contents, 2, ())
  })

  asyncTest("[Dict] Doesn't wait for pending async items when fails to parse", t => {
    let actionCounter = ref(0)

    let struct = S.dict(S.int()->S.advancedTransform(~parser=(~struct as _) => {
        Async(
          _ => {
            actionCounter.contents = actionCounter.contents + 1
            if actionCounter.contents <= 2 {
              unresolvedPromise
            } else {
              invalidPromise
            }
          },
        )
      }, ()))

    (
      {"k1": 1, "k2": 2, "k3": 3}->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn
    )(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: ["k3"],
          operation: Parsing,
        }),
        (),
      )
    })
  })
}

module Null = {
  asyncTest("[Null] Successfully parses", t => {
    let struct = S.null(S.int()->validAsyncRefine)

    Promise.all([
      (1->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn)(.)->Promise.thenResolve(result => {
        t->Assert.deepEqual(result, Ok(Some(1)), ())
      }),
      (
        %raw(`null`)->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn
      )(.)->Promise.thenResolve(result => {
        t->Assert.deepEqual(result, Ok(None), ())
      }),
    ])->Promise.thenResolve(_ => ())
  })

  asyncTest("[Null] Fails to parse with invalid async refine", t => {
    let struct = S.null(S.int()->invalidAsyncRefine)

    (1->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn)(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: [],
          operation: Parsing,
        }),
        (),
      )
    })
  })

  test("[Null] Returns sync error when fails to parse sync part of async item", t => {
    let struct = S.null(S.int()->validAsyncRefine)

    t->Assert.deepEqual(
      true->S.parseAsyncInStepsWith(struct),
      Error({
        S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
        path: [],
        operation: Parsing,
      }),
      (),
    )
  })
}

module Option = {
  asyncTest("[Option] Successfully parses", t => {
    let struct = S.option(S.int()->validAsyncRefine)

    Promise.all([
      (1->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn)(.)->Promise.thenResolve(result => {
        t->Assert.deepEqual(result, Ok(Some(1)), ())
      }),
      (
        %raw(`undefined`)->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn
      )(.)->Promise.thenResolve(result => {
        t->Assert.deepEqual(result, Ok(None), ())
      }),
    ])->Promise.thenResolve(_ => ())
  })

  asyncTest("[Option] Fails to parse with invalid async refine", t => {
    let struct = S.option(S.int()->invalidAsyncRefine)

    (1->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn)(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: [],
          operation: Parsing,
        }),
        (),
      )
    })
  })

  test("[Option] Returns sync error when fails to parse sync part of async item", t => {
    let struct = S.option(S.int()->validAsyncRefine)

    t->Assert.deepEqual(
      true->S.parseAsyncInStepsWith(struct),
      Error({
        S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
        path: [],
        operation: Parsing,
      }),
      (),
    )
  })
}

module Defaulted = {
  asyncTest("[Defaulted] Successfully parses", t => {
    let struct = S.option(S.int()->validAsyncRefine)->validAsyncRefine->S.defaulted(10)

    Promise.all([
      (1->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn)(.)->Promise.thenResolve(result => {
        t->Assert.deepEqual(result, Ok(1), ())
      }),
      (
        %raw(`undefined`)->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn
      )(.)->Promise.thenResolve(result => {
        t->Assert.deepEqual(result, Ok(10), ())
      }),
    ])->Promise.thenResolve(_ => ())
  })

  asyncTest("[Defaulted] Fails to parse with invalid async refine", t => {
    let struct = S.option(S.int()->invalidAsyncRefine)->S.defaulted(10)

    (1->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn)(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: [],
          operation: Parsing,
        }),
        (),
      )
      ()
    })
  })

  test("[Defaulted] Returns sync error when fails to parse sync part of async item", t => {
    let struct = S.option(S.int()->validAsyncRefine)->S.defaulted(10)

    t->Assert.deepEqual(
      true->S.parseAsyncInStepsWith(struct),
      Error({
        S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
        path: [],
        operation: Parsing,
      }),
      (),
    )
  })
}

module Json = {
  asyncTest("[Json] Successfully parses", t => {
    let struct = S.json(S.int()->validAsyncRefine)

    ("1"->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn)(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(result, Ok(1), ())
    })
  })

  asyncTest("[Json] Fails to parse with invalid async refine", t => {
    let struct = S.json(S.int()->invalidAsyncRefine)

    ("1"->S.parseAsyncInStepsWith(struct)->Belt.Result.getExn)(.)->Promise.thenResolve(result => {
      t->Assert.deepEqual(
        result,
        Error({
          S.Error.code: OperationFailed("Async user error"),
          path: [],
          operation: Parsing,
        }),
        (),
      )
      ()
    })
  })

  test("[Json] Returns sync error when fails to parse sync part of async item", t => {
    let struct = S.json(S.int()->validAsyncRefine)

    t->Assert.deepEqual(
      "true"->S.parseAsyncInStepsWith(struct),
      Error({
        S.Error.code: UnexpectedType({expected: "Int", received: "Bool"}),
        path: [],
        operation: Parsing,
      }),
      (),
    )
  })
}
