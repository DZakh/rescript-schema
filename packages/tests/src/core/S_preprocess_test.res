open Ava
open RescriptCore

let preprocessNumberToString = S.preprocess(_, _ => {
  parser: unknown => {
    if unknown->typeof === #number {
      unknown->Obj.magic->Float.toString
    } else {
      unknown->Obj.magic
    }
  },
  serializer: unknown => {
    if unknown->typeof === #string {
      let string: string = unknown->Obj.magic
      switch string->Float.fromString {
      | Some(float) => float->Obj.magic
      | None => string
      }
    } else {
      unknown->Obj.magic
    }
  },
})

test("Successfully parses", t => {
  let schema = S.string->preprocessNumberToString

  t->Assert.deepEqual(123->S.parseAnyWith(schema), Ok("123"), ())
  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(schema), Ok("Hello world!"), ())
})

test("Fails to parse when user raises error in parser", t => {
  let schema = S.string->S.preprocess(s => {parser: _ => s.fail("User error")})

  t->Assert.deepEqual(
    "Hello world!"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("User error"), operation: Parsing, path: S.Path.empty})),
    (),
  )
})

test("Successfully serializes", t => {
  let schema = S.string->preprocessNumberToString

  t->Assert.deepEqual(
    "Hello world!"->S.serializeToUnknownWith(schema),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
  t->Assert.deepEqual("123"->S.serializeToUnknownWith(schema), Ok(%raw(`123`)), ())
})

test("Fails to serialize when user raises error in serializer", t => {
  let schema = S.string->S.preprocess(s => {serializer: _ => s.fail("User error")})

  t->U.assertErrorResult(
    "Hello world!"->S.serializeToUnknownWith(schema),
    {code: OperationFailed("User error"), operation: Serializing, path: S.Path.empty},
  )
})

test("Preprocess operations applyed in the right order when parsing", t => {
  let schema =
    S.int
    ->S.preprocess(s => {parser: _ => s.fail("First preprocess")})
    ->S.preprocess(s => {parser: _ => s.fail("Second preprocess")})

  t->U.assertErrorResult(
    123->S.parseAnyWith(schema),
    {code: OperationFailed("Second preprocess"), operation: Parsing, path: S.Path.empty},
  )
})

test("Preprocess operations applyed in the right order when serializing", t => {
  let schema =
    S.int
    ->S.preprocess(s => {serializer: _ => s.fail("First preprocess")})
    ->S.preprocess(s => {serializer: _ => s.fail("Second preprocess")})

  t->U.assertErrorResult(
    123->S.serializeToUnknownWith(schema),
    {
      code: OperationFailed("First preprocess"),
      operation: Serializing,
      path: S.Path.empty,
    },
  )
})

test("Fails to parse async using parseAnyWith", t => {
  let schema = S.string->S.preprocess(_ => {asyncParser: value => () => Promise.resolve(value)})

  t->Assert.deepEqual(
    %raw(`"Hello world!"`)->S.parseAnyWith(schema),
    Error(U.error({code: UnexpectedAsync, operation: Parsing, path: S.Path.empty})),
    (),
  )
})

asyncTest("Successfully parses async using parseAsyncWith", t => {
  let schema = S.string->S.preprocess(_ => {asyncParser: value => () => Promise.resolve(value)})

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(schema)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

asyncTest("Fails to parse async with user error", t => {
  let schema = S.string->S.preprocess(s => {asyncParser: _ => () => s.fail("User error")})

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(schema)
  ->Promise.thenResolve(result => {
    t->U.assertErrorResult(
      result,
      {
        code: OperationFailed("User error"),
        path: S.Path.empty,
        operation: Parsing,
      },
    )
  })
})

test("Successfully parses with empty preprocess", t => {
  let schema = S.string->S.preprocess(_ => {})

  t->Assert.deepEqual(%raw(`"Hello world!"`)->S.parseAnyWith(schema), Ok("Hello world!"), ())
})

test("Successfully serializes with empty preprocess", t => {
  let schema = S.string->S.preprocess(_ => {})

  t->Assert.deepEqual(
    "Hello world!"->S.serializeToUnknownWith(schema),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})

asyncTest("Can apply other actions after async preprocess", t => {
  let schema =
    S.string
    ->S.preprocess(_ => {asyncParser: value => () => Promise.resolve(value)})
    ->S.trim
    ->S.preprocess(_ => {asyncParser: value => () => Promise.resolve(value)})

  // TODO: Can improve builder to use string schema and trim without .then in between
  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{let v5=e[0](i);return ()=>v5().then(v0=>{let v2=e[1](v0),v4=()=>v2().then(v1=>{if(typeof v1!=="string"){e[2](v1)}return v1});return (()=>v4().then(v3=>{return e[3](v3)}))()})}`,
  )

  %raw(`"    Hello world!"`)
  ->S.parseAsyncWith(schema)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

test("Applies preproces parser for union schemas separately", t => {
  let prepareEnvSchema = S.preprocess(_, s => {
    switch s.schema->S.classify {
    | Literal(Boolean(_))
    | Bool => {
        parser: unknown => {
          switch unknown->Obj.magic {
          | "true"
          | "t"
          | "1" => true
          | "false"
          | "f"
          | "0" => false
          | _ => unknown->Obj.magic
          }->Obj.magic
        },
      }
    | Int
    | Float
    | Literal(Number(_)) => {
        parser: unknown => {
          if unknown->typeof === #string {
            %raw(`+unknown`)
          } else {
            unknown
          }
        },
      }
    | _ => {}
    }
  })

  let schema =
    S.union([
      S.bool->S.variant(bool => #Bool(bool)),
      S.int->S.variant(int => #Int(int)),
    ])->prepareEnvSchema

  t->Assert.deepEqual("f"->S.parseAnyWith(schema), Ok(#Bool(false)), ())
  t->Assert.deepEqual("1"->S.parseAnyWith(schema), Ok(#Bool(true)), ())
  t->Assert.deepEqual("2"->S.parseAnyWith(schema), Ok(#Int(2)), ())
})

test("Applies preproces serializer for union schemas separately", t => {
  let schema = S.union([
    S.bool->S.variant(bool => #Bool(bool)),
    S.int->S.variant(int => #Int(int)),
  ])->S.preprocess(s => {
    switch s.schema->S.classify {
    | Bool => {
        serializer: unknown => {
          if unknown->Obj.magic === true {
            "1"->Obj.magic
          } else if unknown->Obj.magic === false {
            "0"->Obj.magic
          } else {
            unknown->Obj.magic
          }
        },
      }
    | Int => {
        serializer: unknown => {
          if unknown->typeof === #number {
            unknown->Obj.magic->Int.toString->Obj.magic
          } else {
            unknown->Obj.magic
          }
        },
      }
    | _ => {}
    }
  })

  t->Assert.deepEqual(#Bool(false)->S.serializeToUnknownWith(schema), Ok(%raw(`"0"`)), ())
  t->Assert.deepEqual(#Bool(true)->S.serializeToUnknownWith(schema), Ok(%raw(`"1"`)), ())
  t->Assert.deepEqual(#Int(2)->S.serializeToUnknownWith(schema), Ok(%raw(`"2"`)), ())
})

test("Doesn't fail to parse with preprocess when parser isn't provided", t => {
  let schema = S.string->S.preprocess(_ => {serializer: value => value})

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(schema), Ok("Hello world!"), ())
})

test("Doesn't fail to serialize with preprocess when serializer isn't provided", t => {
  let schema = S.string->S.preprocess(_ => {parser: value => value})

  t->Assert.deepEqual(
    "Hello world!"->S.serializeToUnknownWith(schema),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})

test("Compiled parse code snapshot", t => {
  let schema = S.int->S.preprocess(_ => {
    parser: _ => 1->Int.toFloat,
    serializer: _ => 1.->Int.fromFloat,
  })

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{let v0=e[0](i);if(typeof v0!=="number"||v0>2147483647||v0<-2147483648||v0%1!==0){e[1](v0)}return v0}`,
  )
})

test("Compiled async parse code snapshot", t => {
  let schema = S.int->S.preprocess(_ => {
    asyncParser: _ => () => 1->Int.toFloat->Promise.resolve,
    serializer: _ => 1.->Int.fromFloat,
  })

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{let v1=e[0](i);return ()=>v1().then(v0=>{if(typeof v0!=="number"||v0>2147483647||v0<-2147483648||v0%1!==0){e[1](v0)}return v0})}`,
  )
})

test("Compiled async parse code snapshot for object", t => {
  let schema = S.object(s =>
    {
      "foo": s.field("foo", S.string),
    }
  )->S.preprocess(_ => {
    asyncParser: _ => () => 1->Int.toFloat->Promise.resolve,
    serializer: _ => 1.->Int.fromFloat,
  })

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{let v2=e[0](i);return ()=>v2().then(v0=>{if(!v0||v0.constructor!==Object){e[1](v0)}let v1=v0["foo"];if(typeof v1!=="string"){e[2](v1)}return {"foo":v1,}})}`,
  )
})

test("Compiled serialize code snapshot", t => {
  let schema = S.int->S.preprocess(_ => {
    parser: _ => 1->Int.toFloat,
    serializer: _ => 1.->Int.fromFloat,
  })

  t->U.assertCompiledCode(~schema, ~op=#serialize, `i=>{return e[0](i)}`)
})
