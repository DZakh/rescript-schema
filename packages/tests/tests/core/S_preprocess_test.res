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
  let struct = S.string->preprocessNumberToString

  t->Assert.deepEqual(123->S.parseAnyWith(struct), Ok("123"), ())
  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(struct), Ok("Hello world!"), ())
})

test("Fails to parse when user raises error in parser", t => {
  let struct = S.string->S.preprocess(s => {parser: _ => s.fail("User error")})

  t->Assert.deepEqual(
    "Hello world!"->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Successfully serializes", t => {
  let struct = S.string->preprocessNumberToString

  t->Assert.deepEqual(
    "Hello world!"->S.serializeToUnknownWith(struct),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
  t->Assert.deepEqual("123"->S.serializeToUnknownWith(struct), Ok(%raw(`123`)), ())
})

test("Fails to serialize when user raises error in serializer", t => {
  let struct = S.string->S.preprocess(s => {serializer: _ => s.fail("User error")})

  t->Assert.deepEqual(
    "Hello world!"->S.serializeToUnknownWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Preprocess operations applyed in the right order when parsing", t => {
  let struct =
    S.int
    ->S.preprocess(s => {parser: _ => s.fail("First preprocess")})
    ->S.preprocess(s => {parser: _ => s.fail("Second preprocess")})

  t->Assert.deepEqual(
    123->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Second preprocess"),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Preprocess operations applyed in the right order when serializing", t => {
  let struct =
    S.int
    ->S.preprocess(s => {serializer: _ => s.fail("First preprocess")})
    ->S.preprocess(s => {serializer: _ => s.fail("Second preprocess")})

  t->Assert.deepEqual(
    123->S.serializeToUnknownWith(struct),
    Error({
      code: OperationFailed("First preprocess"),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Fails to parse async using parseAnyWith", t => {
  let struct = S.string->S.preprocess(_ => {asyncParser: value => () => Promise.resolve(value)})

  t->Assert.deepEqual(
    %raw(`"Hello world!"`)->S.parseAnyWith(struct),
    Error({
      code: UnexpectedAsync,
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
})

asyncTest("Successfully parses async using parseAsyncWith", t => {
  let struct = S.string->S.preprocess(_ => {asyncParser: value => () => Promise.resolve(value)})

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

asyncTest("Fails to parse async with user error", t => {
  let struct = S.string->S.preprocess(s => {asyncParser: _ => () => s.fail("User error")})

  %raw(`"Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(
      result,
      Error({
        S.code: OperationFailed("User error"),
        path: S.Path.empty,
        operation: Parsing,
      }),
      (),
    )
  })
})

test("Successfully parses with empty preprocess", t => {
  let struct = S.string->S.preprocess(_ => {})

  t->Assert.deepEqual(%raw(`"Hello world!"`)->S.parseAnyWith(struct), Ok("Hello world!"), ())
})

test("Successfully serializes with empty preprocess", t => {
  let struct = S.string->S.preprocess(_ => {})

  t->Assert.deepEqual(
    "Hello world!"->S.serializeToUnknownWith(struct),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})

asyncTest("Can apply other actions after async preprocess", t => {
  let struct =
    S.string
    ->S.preprocess(_ => {asyncParser: value => () => Promise.resolve(value)})
    ->S.String.trim()
    ->S.preprocess(_ => {asyncParser: value => () => Promise.resolve(value)})

  %raw(`"    Hello world!"`)
  ->S.parseAsyncWith(struct)
  ->Promise.thenResolve(result => {
    t->Assert.deepEqual(result, Ok("Hello world!"), ())
  })
})

test("Applies preproces parser for union structs separately", t => {
  let prepareEnvStruct = S.preprocess(_, s => {
    switch s.struct->S.classify {
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

  let struct =
    S.union([
      S.bool->S.variant(bool => #Bool(bool)),
      S.int->S.variant(int => #Int(int)),
    ])->prepareEnvStruct

  t->Assert.deepEqual("f"->S.parseAnyWith(struct), Ok(#Bool(false)), ())
  t->Assert.deepEqual("1"->S.parseAnyWith(struct), Ok(#Bool(true)), ())
  t->Assert.deepEqual("2"->S.parseAnyWith(struct), Ok(#Int(2)), ())
})

test("Applies preproces serializer for union structs separately", t => {
  let struct = S.union([
    S.bool->S.variant(bool => #Bool(bool)),
    S.int->S.variant(int => #Int(int)),
  ])->S.preprocess(s => {
    switch s.struct->S.classify {
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

  t->Assert.deepEqual(#Bool(false)->S.serializeToUnknownWith(struct), Ok(%raw(`"0"`)), ())
  t->Assert.deepEqual(#Bool(true)->S.serializeToUnknownWith(struct), Ok(%raw(`"1"`)), ())
  t->Assert.deepEqual(#Int(2)->S.serializeToUnknownWith(struct), Ok(%raw(`"2"`)), ())
})

test("Doesn't fail to parse with preprocess when parser isn't provided", t => {
  let struct = S.string->S.preprocess(_ => {serializer: value => value})

  t->Assert.deepEqual("Hello world!"->S.parseAnyWith(struct), Ok("Hello world!"), ())
})

test("Doesn't fail to serialize with preprocess when serializer isn't provided", t => {
  let struct = S.string->S.preprocess(_ => {parser: value => value})

  t->Assert.deepEqual(
    "Hello world!"->S.serializeToUnknownWith(struct),
    Ok(%raw(`"Hello world!"`)),
    (),
  )
})

test("Compiled parse code snapshot", t => {
  let struct = S.int->S.preprocess(_ => {
    parser: _ => 1->Int.toFloat,
    serializer: _ => 1.->Int.fromFloat,
  })

  t->TestUtils.assertCompiledCode(
    ~struct,
    ~op=#parse,
    `i=>{let v0;v0=e[0](i);if(!(typeof v0==="number"&&v0<2147483648&&v0>-2147483649&&v0%1===0)){e[1](v0)}return v0}`,
    (),
  )
})

test("Compiled async parse code snapshot", t => {
  let struct = S.int->S.preprocess(_ => {
    asyncParser: _ => () => 1->Int.toFloat->Promise.resolve,
    serializer: _ => 1.->Int.fromFloat,
  })

  t->TestUtils.assertCompiledCode(
    ~struct,
    ~op=#parse,
    `i=>{let v0,v1;v0=e[0](i);v1=()=>v0().then(t=>{if(!(typeof t==="number"&&t<2147483648&&t>-2147483649&&t%1===0)){e[1](t)}return t});return v1}`,
    (),
  )
})

test("Compiled serialize code snapshot", t => {
  let struct = S.int->S.preprocess(_ => {
    parser: _ => 1->Int.toFloat,
    serializer: _ => 1.->Int.fromFloat,
  })

  t->TestUtils.assertCompiledCode(~struct, ~op=#serialize, `i=>{return e[0](i)}`, ())
})
