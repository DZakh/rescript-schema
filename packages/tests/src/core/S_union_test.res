open Ava
open RescriptCore

test("Throws for a Union schema factory without schemas", t => {
  t->Assert.throws(
    () => {
      S.union([])
    },
    ~expectations={
      message: "[rescript-schema] S.union requires at least one item",
    },
    (),
  )
})

test("Successfully creates a Union schema factory with single schema and flattens it", t => {
  let schema = S.union([S.string])

  t->U.assertEqualSchemas(schema, S.string)
})

test("Successfully parses polymorphic variants", t => {
  let schema = S.union([S.literal(#apple), S.literal(#orange)])

  t->Assert.deepEqual(%raw(`"apple"`)->S.parseOrThrow(schema), #apple, ())
})

test("Parses when both schemas misses parser and have the same type", t => {
  let schema = S.union([
    S.string->S.transform(_ => {serializer: _ => "apple"}),
    S.string->S.transform(_ => {serializer: _ => "apple"}),
  ])

  t->U.assertRaised(
    () => %raw(`null`)->S.parseOrThrow(schema),
    {
      code: InvalidType({
        expected: schema->S.toUnknown,
        received: %raw(`null`),
      }),
      operation: Parse,
      path: S.Path.empty,
    },
  )

  t->U.assertRaised(
    () => %raw(`"foo"`)->S.parseOrThrow(schema),
    {
      code: InvalidUnion([
        U.error({
          code: InvalidOperation({description: "The S.transform parser is missing"}),
          operation: Parse,
          path: S.Path.empty,
        }),
        U.error({
          code: InvalidOperation({description: "The S.transform parser is missing"}),
          operation: Parse,
          path: S.Path.empty,
        }),
      ]),
      operation: Parse,
      path: S.Path.empty,
    },
  )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{let v0=i;if(typeof i!=="string"){e[3](i)}else{try{throw e[0]}catch(e0){try{throw e[1]}catch(e1){e[2]([e0,e1,])}}}return v0}`,
  )
})

test("Parses when both schemas misses parser and have different types", t => {
  let schema = S.union([
    S.literal(#apple)->S.transform(_ => {serializer: _ => #apple}),
    S.string->S.transform(_ => {serializer: _ => "apple"}),
  ])

  t->U.assertRaised(
    () => %raw(`null`)->S.parseOrThrow(schema),
    {
      code: InvalidType({
        expected: schema->S.toUnknown,
        received: %raw(`null`),
      }),
      operation: Parse,
      path: S.Path.empty,
    },
  )

  t->U.assertRaised(
    () => %raw(`"abc"`)->S.parseOrThrow(schema),
    {
      code: InvalidOperation({description: "The S.transform parser is missing"}),
      operation: Parse,
      path: S.Path.empty,
    },
  )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{let v0=i;if(i!=="apple"){if(typeof i!=="string"){e[2](i)}else{throw e[1]}}else{throw e[0]}return v0}`,
  )
})

test("Serializes when both schemas misses serializer", t => {
  let schema = S.union([
    S.literal(#apple)->S.transform(_ => {parser: _ => #apple}),
    S.string->S.transform(_ => {parser: _ => #apple}),
  ])

  t->U.assertRaised(
    () => %raw(`null`)->S.reverseConvertToJsonOrThrow(schema),
    {
      code: InvalidUnion([
        U.error({
          code: InvalidOperation({description: "The S.transform serializer is missing"}),
          operation: ReverseConvertToJson,
          path: S.Path.empty,
        }),
        U.error({
          code: InvalidOperation({description: "The S.transform serializer is missing"}),
          operation: ReverseConvertToJson,
          path: S.Path.empty,
        }),
      ]),
      operation: ReverseConvertToJson,
      path: S.Path.empty,
    },
  )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0=i;try{throw e[0]}catch(e0){try{throw e[1]}catch(e1){e[2]([e0,e1,])}}return v0}`,
  )
})

test("When union of json and string schemas, should parse the first one", t => {
  let schema = S.union([S.json(~validate=false)->S.to(_ => #json), S.string->S.to(_ => #str)])

  // FIXME: This is not working. Should be #json instead
  t->Assert.deepEqual(%raw(`"string"`)->S.parseOrThrow(schema), #str, ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{let v0=i;if(typeof i!=="string"){v0=e[0]}else{v0=e[1]}return v0}`,
  )
})

test("Parses when second struct misses parser", t => {
  let schema = S.union([S.literal(#apple), S.string->S.transform(_ => {serializer: _ => "apple"})])

  t->Assert.deepEqual("apple"->S.parseOrThrow(schema), #apple, ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{let v0=i;if(i!=="apple"){if(typeof i!=="string"){e[1](i)}else{throw e[0]}}return v0}`,
  )
})

test("Serializes when second struct misses serializer", t => {
  let schema = S.union([S.literal(#apple), S.string->S.transform(_ => {parser: _ => #apple})])

  t->Assert.deepEqual(#apple->S.reverseConvertOrThrow(schema), %raw(`"apple"`), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0=i;if(i!=="apple"){throw e[0]}return v0}`,
  )
})

module Advanced = {
  // TypeScript type for reference (https://www.typescriptlang.org/docs/handbook/typescript-in-5-minutes-func.html#discriminated-unions)
  // type Shape =
  // | { kind: "circle"; radius: number }
  // | { kind: "square"; x: number }
  // | { kind: "triangle"; x: number; y: number };

  type shape = Circle({radius: float}) | Square({x: float}) | Triangle({x: float, y: float})

  let circleSchema = S.object(s => {
    s.tag("kind", "circle")
    Circle({
      radius: s.field("radius", S.float),
    })
  })
  let squareSchema = S.object(s => {
    s.tag("kind", "square")
    Square({
      x: s.field("x", S.float),
    })
  })
  let triangleSchema = S.object(s => {
    s.tag("kind", "triangle")
    Triangle({
      x: s.field("x", S.float),
      y: s.field("y", S.float),
    })
  })

  let shapeSchema = S.union([circleSchema, squareSchema, triangleSchema])

  test("Successfully parses Circle shape", t => {
    t->Assert.deepEqual(
      %raw(`{
      "kind": "circle",
      "radius": 1,
    }`)->S.parseOrThrow(shapeSchema),
      Circle({radius: 1.}),
      (),
    )
  })

  test("Successfully parses Square shape", t => {
    t->Assert.deepEqual(
      %raw(`{
      "kind": "square",
      "x": 2,
    }`)->S.parseOrThrow(shapeSchema),
      Square({x: 2.}),
      (),
    )
  })

  test("Successfully parses Triangle shape", t => {
    t->Assert.deepEqual(
      %raw(`{
      "kind": "triangle",
      "x": 2,
      "y": 3,
    }`)->S.parseOrThrow(shapeSchema),
      Triangle({x: 2., y: 3.}),
      (),
    )
  })

  test("Fails to parse with unknown kind", t => {
    t->U.assertRaised(
      () =>
        %raw(`{
        "kind": "oval",
        "x": 2,
        "y": 3,
      }`)->S.parseOrThrow(shapeSchema),
      {
        code: InvalidUnion([
          U.error({
            code: InvalidType({
              expected: S.literal("circle")->S.toUnknown,
              received: "oval"->Obj.magic,
            }),
            operation: Parse,
            path: S.Path.fromArray(["kind"]),
          }),
          U.error({
            code: InvalidType({
              expected: S.literal("square")->S.toUnknown,
              received: "oval"->Obj.magic,
            }),
            operation: Parse,
            path: S.Path.fromArray(["kind"]),
          }),
          U.error({
            code: InvalidType({
              expected: S.literal("triangle")->S.toUnknown,
              received: "oval"->Obj.magic,
            }),
            operation: Parse,
            path: S.Path.fromArray(["kind"]),
          }),
        ]),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to parse with unknown kind when the union is an object field", t => {
    t->U.assertRaised(
      () =>
        %raw(`{
        "field": {
          "kind": "oval",
          "x": 2,
          "y": 3,
        }
      }`)->S.parseOrThrow(S.object(s => s.field("field", shapeSchema))),
      {
        code: InvalidUnion([
          U.error({
            code: InvalidType({
              expected: S.literal("circle")->S.toUnknown,
              received: "oval"->Obj.magic,
            }),
            operation: Parse,
            path: S.Path.fromArray(["kind"]),
          }),
          U.error({
            code: InvalidType({
              expected: S.literal("square")->S.toUnknown,
              received: "oval"->Obj.magic,
            }),
            operation: Parse,
            path: S.Path.fromArray(["kind"]),
          }),
          U.error({
            code: InvalidType({
              expected: S.literal("triangle")->S.toUnknown,
              received: "oval"->Obj.magic,
            }),
            operation: Parse,
            path: S.Path.fromArray(["kind"]),
          }),
        ]),
        operation: Parse,
        path: S.Path.fromArray(["field"]),
      },
    )
  })

  test("Fails to parse with invalid data type", t => {
    t->U.assertRaised(
      () => %raw(`"Hello world!"`)->S.parseOrThrow(shapeSchema),
      {
        code: InvalidType({
          expected: shapeSchema->S.toUnknown,
          received: %raw(`"Hello world!"`),
        }),
        operation: Parse,
        path: S.Path.empty,
      },
    )
  })

  test("Fails to serialize incomplete schema", t => {
    let incompleteSchema = S.union([
      S.object(s => {
        s.tag("kind", "circle")
        Circle({
          radius: s.field("radius", S.float),
        })
      }),
      S.object(s => {
        s.tag("kind", "square")
        Square({
          x: s.field("x", S.float),
        })
      }),
    ])

    t->U.assertRaised(
      () => Triangle({x: 2., y: 3.})->S.reverseConvertOrThrow(incompleteSchema),
      {
        code: InvalidUnion([
          U.error({
            code: InvalidType({
              expected: S.literal("Circle")->S.toUnknown,
              received: "Triangle"->Obj.magic,
            }),
            operation: ReverseConvert,
            path: S.Path.fromArray(["TAG"]),
          }),
          U.error({
            code: InvalidType({
              expected: S.literal("Square")->S.toUnknown,
              received: "Triangle"->Obj.magic,
            }),
            operation: ReverseConvert,
            path: S.Path.fromArray(["TAG"]),
          }),
        ]),
        operation: ReverseConvert,
        path: S.Path.empty,
      },
    )
  })

  test("Successfully serializes Circle shape", t => {
    t->Assert.deepEqual(
      Circle({radius: 1.})->S.reverseConvertOrThrow(shapeSchema),
      %raw(`{
          "kind": "circle",
          "radius": 1,
        }`),
      (),
    )
  })

  test("Successfully serializes Square shape", t => {
    t->Assert.deepEqual(
      Square({x: 2.})->S.reverseConvertOrThrow(shapeSchema),
      %raw(`{
        "kind": "square",
        "x": 2,
      }`),
      (),
    )
  })

  test("Successfully serializes Triangle shape", t => {
    t->Assert.deepEqual(
      Triangle({x: 2., y: 3.})->S.reverseConvertOrThrow(shapeSchema),
      %raw(`{
        "kind": "triangle",
        "x": 2,
        "y": 3,
      }`),
      (),
    )
  })

  test("Compiled parse code snapshot of shape schema", t => {
    t->U.assertCompiledCode(
      ~schema=shapeSchema,
      ~op=#Parse,
      `i=>{let v0=i;if(!i||i.constructor!==Object){e[11](i)}else{try{let v1=i["kind"],v2=i["radius"];if(v1!=="circle"){e[0](v1)}if(typeof v2!=="number"||Number.isNaN(v2)){e[1](v2)}v0={"TAG":e[2],"radius":v2,}}catch(e0){try{let v3=i["kind"],v4=i["x"];if(v3!=="square"){e[3](v3)}if(typeof v4!=="number"||Number.isNaN(v4)){e[4](v4)}v0={"TAG":e[5],"x":v4,}}catch(e1){try{let v5=i["kind"],v6=i["x"],v7=i["y"];if(v5!=="triangle"){e[6](v5)}if(typeof v6!=="number"||Number.isNaN(v6)){e[7](v6)}if(typeof v7!=="number"||Number.isNaN(v7)){e[8](v7)}v0={"TAG":e[9],"x":v6,"y":v7,}}catch(e2){e[10]([e0,e1,e2,])}}}}return v0}`,
    )
  })

  test("Compiled serialize code snapshot of shape schema", t => {
    t->U.assertCompiledCode(
      ~schema=shapeSchema,
      ~op=#ReverseConvert,
      `i=>{let v0=i;if(!i||i.constructor!==Object){e[7](i)}else{try{let v1=i["TAG"];if(v1!=="Circle"){e[0](v1)}v0={"kind":e[1],"radius":i["radius"],}}catch(e0){try{let v2=i["TAG"];if(v2!=="Square"){e[2](v2)}v0={"kind":e[3],"x":i["x"],}}catch(e1){try{let v3=i["TAG"];if(v3!=="Triangle"){e[4](v3)}v0={"kind":e[5],"x":i["x"],"y":i["y"],}}catch(e2){e[6]([e0,e1,e2,])}}}}return v0}`,
    )
  })
}

@unboxed
type uboxedVariant = String(string) | Int(int)
test("Successfully serializes unboxed variant", t => {
  let schema = S.union([
    S.string->S.to(s => String(s)),
    S.string
    ->S.transform(_ => {
      parser: string => string->Int.fromString->Option.getExn,
      serializer: Int.toString(_),
    })
    ->S.to(i => Int(i)),
  ])

  t->Assert.deepEqual(String("abc")->S.reverseConvertOrThrow(schema), %raw(`"abc"`), ())
  t->Assert.deepEqual(Int(123)->S.reverseConvertOrThrow(schema), %raw(`"123"`), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0=i;if(typeof i!=="string"){v0=e[0](i)}return v0}`,
  )
})

test("Compiled parse code snapshot", t => {
  let schema = S.union([S.literal(0), S.literal(1)])

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{let v0=i;if(i!==0){if(i!==1){e[0](i)}}return v0}`,
  )
})

test("Compiled async parse code snapshot", t => {
  let schema = S.union([
    S.literal(0)->S.transform(_ => {asyncParser: i => Promise.resolve(i)}),
    S.literal(1),
  ])

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{let v0=i;if(i!==0){if(i!==1){e[1](i)}}else{v0=e[0](i)}return Promise.resolve(v0)}`,
  )
})

test("Union with nested variant", t => {
  let schema = S.union([
    S.schema(s =>
      {
        "foo": {
          "tag": #Null(s.matches(S.null(S.string))),
        },
      }
    ),
    S.schema(s =>
      {
        "foo": {
          "tag": #Option(s.matches(S.option(S.string))),
        },
      }
    ),
  ])

  t->Assert.deepEqual(
    {
      "foo": {
        "tag": #Null(None),
      },
    }->S.reverseConvertOrThrow(schema),
    %raw(`{"foo":{"tag":{"NAME":"Null","VAL":null}}}`),
    (),
  )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0=i;if(!i||i.constructor!==Object){e[3](i)}else{try{let v1=i["foo"];let v2=v1["tag"],v3=v2["NAME"],v4=v2["VAL"],v5;if(v3!=="Null"){e[0](v3)}if(v4!==void 0){v5=v4}else{v5=null}v0={"foo":{"tag":{"NAME":v3,"VAL":v5,},},}}catch(e0){try{let v6=i["foo"];let v7=v6["tag"],v8=v7["NAME"];if(v8!=="Option"){e[1](v8)}}catch(e1){e[2]([e0,e1,])}}}return v0}`,
  )
})

test("Compiled serialize code snapshot", t => {
  let schema = S.union([S.literal(0), S.literal(1)])

  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0=i;if(i!==0){if(i!==1){e[0](i)}}return v0}`,
  )
})

test("Compiled serialize code snapshot of objects returning literal fields", t => {
  let schema = S.union([
    S.object(s => s.field("foo", S.literal(0))),
    S.object(s => s.field("bar", S.literal(1))),
  ])

  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0=i;if(i!==0){if(i!==1){e[0](i)}else{v0={"bar":i,}}}else{v0={"foo":i,}}return v0}`,
  )
})

test("Enum is a shorthand for union", t => {
  t->U.assertEqualSchemas(S.enum([0, 1]), S.union([S.literal(0), S.literal(1)]))
})

test("Reverse schema with items", t => {
  let schema = S.union([S.literal(%raw(`0`)), S.null(S.bool)])

  t->U.assertEqualSchemas(
    schema->S.reverse,
    S.union([S.literal(%raw(`0`)), S.option(S.bool)])->S.toUnknown,
  )
})

test("Succesfully uses reversed schema for parsing back to initial value", t => {
  let schema = S.union([S.literal(%raw(`0`)), S.null(S.bool)])
  t->U.assertReverseParsesBack(schema, None)
})

module CknittelBugReport = {
  module A = {
    @schema
    type payload = {a?: string}

    @schema
    type t = {payload: payload}
  }

  module B = {
    @schema
    type payload = {b?: int}

    @schema
    type t = {payload: payload}
  }

  type value = A(A.t) | B(B.t)

  test("Union serializing of objects with optional fields", t => {
    let schema = S.union([A.schema->S.to(m => A(m)), B.schema->S.to(m => B(m))])

    t->U.assertCompiledCode(
      ~schema,
      ~op=#ReverseConvert,
      `i=>{let v0=i;if(!i||i.constructor!==Object){e[3](i)}else{try{let v1=i["TAG"];if(v1!=="A"){e[0](v1)}let v2=i["_0"];let v3=v2["payload"];v0=v2}catch(e0){try{let v4=i["TAG"];if(v4!=="B"){e[1](v4)}let v5=i["_0"];let v6=v5["payload"];v0=v5}catch(e1){e[2]([e0,e1,])}}}return v0}`,
    )

    let x = {
      B.payload: {
        b: 42,
      },
    }
    t->Assert.deepEqual(B(x)->S.reverseConvertOrThrow(schema), %raw(`{"payload":{"b":42}}`), ())
  })
}

// Reported in https://gist.github.com/cknitt/4ac6813a3f3bc907187105e01a4324ca
module CrazyUnion = {
  type rec test =
    | A(array<test>)
    | B
    | C
    | D
    | E
    | F
    | G
    | H
    | I
    | J
    | K
    | L
    | M
    | N
    | O
    | P
    | Q
    | R
    | S
    | T
    | U
    | V
    | W
    | X
    | Y
    | Z(array<test>)

  let schema = S.recursive(schema =>
    S.union([
      S.object(s => {
        s.tag("type", "A")
        A(s.field("nested", S.array(schema)))
      }),
      S.literal(B),
      S.literal(C),
      S.literal(D),
      S.literal(E),
      S.literal(F),
      S.literal(G),
      S.literal(H),
      S.literal(I),
      S.literal(J),
      S.literal(K),
      S.literal(L),
      S.literal(M),
      S.literal(N),
      S.literal(O),
      S.literal(P),
      S.literal(Q),
      S.literal(R),
      S.literal(S),
      S.literal(T),
      S.literal(U),
      S.literal(V),
      S.literal(W),
      S.literal(X),
      S.literal(Y),
      S.object(s => {
        s.tag("type", "Z")
        Z(s.field("nested", S.array(schema)))
      }),
    ])
  )

  test("Compiled parse code snapshot of crazy union", t => {
    S.setGlobalConfig({})
    t->U.assertCompiledCode(
      ~schema,
      ~op=#Parse,
      `i=>{let r0=i=>{let v0=i;if(!i||i.constructor!==Object){if(i!=="B"){if(i!=="C"){if(i!=="D"){if(i!=="E"){if(i!=="F"){if(i!=="G"){if(i!=="H"){if(i!=="I"){if(i!=="J"){if(i!=="K"){if(i!=="L"){if(i!=="M"){if(i!=="N"){if(i!=="O"){if(i!=="P"){if(i!=="Q"){if(i!=="R"){if(i!=="S"){if(i!=="T"){if(i!=="U"){if(i!=="V"){if(i!=="W"){if(i!=="X"){if(i!=="Y"){e[7](i)}}}}}}}}}}}}}}}}}}}}}}}}}else{try{let v1=i["type"],v2=i["nested"],v6=[];if(v1!=="A"){e[0](v1)}if(!Array.isArray(v2)){e[1](v2)}for(let v3=0;v3<v2.length;++v3){let v5;try{v5=r0(v2[v3])}catch(v4){if(v4&&v4.s===s){v4.path="[\\"nested\\"]"+\'["\'+v3+\'"]\'+v4.path}throw v4}v6.push(v5)}v0={"TAG":e[2],"_0":v6,}}catch(e0){try{let v7=i["type"],v8=i["nested"],v12=[];if(v7!=="Z"){e[3](v7)}if(!Array.isArray(v8)){e[4](v8)}for(let v9=0;v9<v8.length;++v9){let v11;try{v11=r0(v8[v9])}catch(v10){if(v10&&v10.s===s){v10.path="[\\"nested\\"]"+\'["\'+v9+\'"]\'+v10.path}throw v10}v12.push(v11)}v0={"TAG":e[5],"_0":v12,}}catch(e1){e[6]([e0,e1,])}}}return v0};return r0(i)}`,
    )
  })

  test("Compiled serialize code snapshot of crazy union", t => {
    S.setGlobalConfig({})
    let code = `i=>{let r0=i=>{let v0=i;if(!i||i.constructor!==Object){if(i!=="B"){if(i!=="C"){if(i!=="D"){if(i!=="E"){if(i!=="F"){if(i!=="G"){if(i!=="H"){if(i!=="I"){if(i!=="J"){if(i!=="K"){if(i!=="L"){if(i!=="M"){if(i!=="N"){if(i!=="O"){if(i!=="P"){if(i!=="Q"){if(i!=="R"){if(i!=="S"){if(i!=="T"){if(i!=="U"){if(i!=="V"){if(i!=="W"){if(i!=="X"){if(i!=="Y"){e[5](i)}}}}}}}}}}}}}}}}}}}}}}}}}else{try{let v1=i["TAG"],v2=i["_0"],v6=[];if(v1!=="A"){e[0](v1)}for(let v3=0;v3<v2.length;++v3){let v5;try{v5=r0(v2[v3])}catch(v4){if(v4&&v4.s===s){v4.path="[\\"_0\\"]"+\'["\'+v3+\'"]\'+v4.path}throw v4}v6.push(v5)}v0={"type":e[1],"nested":v6,}}catch(e0){try{let v7=i["TAG"],v8=i["_0"],v12=[];if(v7!=="Z"){e[2](v7)}for(let v9=0;v9<v8.length;++v9){let v11;try{v11=r0(v8[v9])}catch(v10){if(v10&&v10.s===s){v10.path="[\\"_0\\"]"+\'["\'+v9+\'"]\'+v10.path}throw v10}v12.push(v11)}v0={"type":e[3],"nested":v12,}}catch(e1){e[4]([e0,e1,])}}}return v0};return r0(i)}`
    t->U.assertCompiledCode(~schema, ~op=#ReverseConvert, code)
    // There was an issue with reverse when it doesn't return the same code on second run
    t->U.assertCompiledCode(~schema, ~op=#ReverseConvert, code)
  })
}

test("json-rpc response", t => {
  let jsonRpcSchema = (okSchema, errorSchema) =>
    S.union([
      S.object(s => Ok(s.field("result", okSchema))),
      S.object(s => Error(s.field("error", errorSchema))),
    ])

  let getLogsResponseSchema = jsonRpcSchema(
    S.array(S.string),
    S.union([
      S.object(s => {
        s.tag("message", "NotFound")
        #LogsNotFound
      }),
      S.object(s => {
        s.tag("message", "Invalid")
        #InvalidData(s.field("data", S.string))
      }),
    ]),
  )

  t->Assert.deepEqual(
    %raw(`{
        "jsonrpc": "2.0",
        "id": 1,
        "result": ["foo", "bar"]
      }`)->S.parseOrThrow(getLogsResponseSchema),
    Ok(["foo", "bar"]),
    (),
  )

  t->Assert.deepEqual(
    %raw(`{
        "jsonrpc": "2.0",
        "id": 1,
        "error": {
          "message": "NotFound"
        }
      }`)->S.parseOrThrow(getLogsResponseSchema),
    Error(#LogsNotFound),
    (),
  )

  t->Assert.deepEqual(
    %raw(`{
        "jsonrpc": "2.0",
        "id": 1,
        "error": {
          "message": "Invalid",
          "data": "foo"
        }
      }`)->S.parseOrThrow(getLogsResponseSchema),
    Error(#InvalidData("foo")),
    (),
  )
})

test("Issue https://github.com/DZakh/rescript-schema/issues/101", t => {
  let syncRequestSchema = S.schema(s =>
    #request({
      "collectionName": s.matches(S.string),
    })
  )
  let syncResponseSchema = S.schema(s =>
    #response({
      "collectionName": s.matches(S.string),
      "response": s.matches(S.enum(["accepted", "rejected"])),
    })
  )
  let schema = S.union([syncRequestSchema, syncResponseSchema])

  t->U.assertCompiledCode(
    ~schema,
    ~op=#ReverseConvert,
    `i=>{let v0=i;if(!i||i.constructor!==Object){e[4](i)}else{try{let v1=i["NAME"];if(v1!=="request"){e[0](v1)}let v2=i["VAL"];}catch(e0){try{let v3=i["NAME"];if(v3!=="response"){e[1](v3)}let v4=i["VAL"],v5=v4["response"],v6=v5;if(v5!=="accepted"){if(v5!=="rejected"){e[2](v5)}}v0={"NAME":v3,"VAL":{"collectionName":v4["collectionName"],"response":v6,},}}catch(e1){e[3]([e0,e1,])}}}return v0}`,
  )

  t->Assert.deepEqual(
    #response({
      "collectionName": "foo",
      "response": "accepted",
    })->S.reverseConvertOrThrow(schema),
    #response({
      "collectionName": "foo",
      "response": "accepted",
    })->Obj.magic,
    (),
  )
})
