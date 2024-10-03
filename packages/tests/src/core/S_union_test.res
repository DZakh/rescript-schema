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

  t->Assert.deepEqual(%raw(`"apple"`)->S.parseAnyWith(schema), Ok(#apple), ())
})

test("Parses when both schemas misses parser and have the same type", t => {
  let schema = S.union([
    S.string->S.transform(_ => {serializer: _ => "apple"}),
    S.string->S.transform(_ => {serializer: _ => "apple"}),
  ])

  t->U.assertErrorResult(
    %raw(`null`)->S.parseAnyWith(schema),
    {
      code: InvalidType({
        expected: schema->S.toUnknown,
        received: %raw(`null`),
      }),
      operation: Parse,
      path: S.Path.empty,
    },
  )

  t->U.assertErrorResult(
    %raw(`"foo"`)->S.parseAnyWith(schema),
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
    `i=>{if(typeof i!=="string"){e[3](i)}else{try{throw e[0]}catch(e0){try{throw e[1]}catch(e1){e[2]([e0,e1,])}}}return i}`,
  )
})

test("Parses when both schemas misses parser and have different types", t => {
  let schema = S.union([
    S.literal(#apple)->S.transform(_ => {serializer: _ => #apple}),
    S.string->S.transform(_ => {serializer: _ => "apple"}),
  ])

  t->U.assertErrorResult(
    %raw(`null`)->S.parseAnyWith(schema),
    {
      code: InvalidType({
        expected: schema->S.toUnknown,
        received: %raw(`null`),
      }),
      operation: Parse,
      path: S.Path.empty,
    },
  )

  t->U.assertErrorResult(
    %raw(`"abc"`)->S.parseAnyWith(schema),
    {
      code: InvalidOperation({description: "The S.transform parser is missing"}),
      operation: Parse,
      path: S.Path.empty,
    },
  )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(i!=="apple"){if(typeof i!=="string"){e[2](i)}else{throw e[1]}}else{throw e[0]}return i}`,
  )
})

test("Serializes when both schemas misses serializer", t => {
  let schema = S.union([
    S.literal(#apple)->S.transform(_ => {parser: _ => #apple}),
    S.string->S.transform(_ => {parser: _ => #apple}),
  ])

  t->U.assertErrorResult(
    %raw(`null`)->S.serializeWith(schema),
    {
      code: InvalidUnion([
        U.error({
          code: InvalidOperation({description: "The S.transform serializer is missing"}),
          operation: SerializeToJson,
          path: S.Path.empty,
        }),
        U.error({
          code: InvalidOperation({description: "The S.transform serializer is missing"}),
          operation: SerializeToJson,
          path: S.Path.empty,
        }),
      ]),
      operation: SerializeToJson,
      path: S.Path.empty,
    },
  )

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Serialize,
    `i=>{try{throw e[0]}catch(e0){try{throw e[1]}catch(e1){e[2]([e0,e1,])}}return i}`,
  )
})

test("When union of json and string schemas, should parse the first one", t => {
  let schema = S.union([S.json(~validate=false)->S.to(_ => #json), S.string->S.to(_ => #str)])

  // FIXME: This is not working. Should be #json instead
  t->Assert.deepEqual(%raw(`"string"`)->S.parseAnyWith(schema), Ok(#str), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{let v0=i;if(typeof i!=="string"){v0=e[0]}else{v0=e[1]}return v0}`,
  )
})

test("Parses when second struct misses parser", t => {
  let schema = S.union([S.literal(#apple), S.string->S.transform(_ => {serializer: _ => "apple"})])

  t->Assert.deepEqual("apple"->S.parseAnyWith(schema), Ok(#apple), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{if(i!=="apple"){if(typeof i!=="string"){e[1](i)}else{throw e[0]}}return i}`,
  )
})

test("Serializes when second struct misses serializer", t => {
  let schema = S.union([S.literal(#apple), S.string->S.transform(_ => {parser: _ => #apple})])

  t->Assert.deepEqual(#apple->S.serializeToUnknownWith(schema), Ok(%raw(`"apple"`)), ())

  t->U.assertCompiledCode(~schema, ~op=#Serialize, `i=>{if(i!=="apple"){throw e[0]}return i}`)
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
    }`)->S.parseAnyWith(shapeSchema),
      Ok(Circle({radius: 1.})),
      (),
    )
  })

  test("Successfully parses Square shape", t => {
    t->Assert.deepEqual(
      %raw(`{
      "kind": "square",
      "x": 2,
    }`)->S.parseAnyWith(shapeSchema),
      Ok(Square({x: 2.})),
      (),
    )
  })

  test("Successfully parses Triangle shape", t => {
    t->Assert.deepEqual(
      %raw(`{
      "kind": "triangle",
      "x": 2,
      "y": 3,
    }`)->S.parseAnyWith(shapeSchema),
      Ok(Triangle({x: 2., y: 3.})),
      (),
    )
  })

  test("Fails to parse with unknown kind", t => {
    t->U.assertErrorResult(
      %raw(`{
        "kind": "oval",
        "x": 2,
        "y": 3,
      }`)->S.parseAnyWith(shapeSchema),
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
    t->U.assertErrorResult(
      %raw(`{
        "field": {
          "kind": "oval",
          "x": 2,
          "y": 3,
        }
      }`)->S.parseAnyWith(S.object(s => s.field("field", shapeSchema))),
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
    t->U.assertErrorResult(
      %raw(`"Hello world!"`)->S.parseAnyWith(shapeSchema),
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

    t->U.assertErrorResult(
      Triangle({x: 2., y: 3.})->S.serializeToUnknownWith(incompleteSchema),
      {
        code: InvalidUnion([
          U.error({
            code: InvalidType({
              expected: S.literal("Circle")->S.toUnknown,
              received: "Triangle"->Obj.magic,
            }),
            operation: SerializeToUnknown,
            path: S.Path.fromArray(["TAG"]),
          }),
          U.error({
            code: InvalidType({
              expected: S.literal("Square")->S.toUnknown,
              received: "Triangle"->Obj.magic,
            }),
            operation: SerializeToUnknown,
            path: S.Path.fromArray(["TAG"]),
          }),
        ]),
        operation: SerializeToUnknown,
        path: S.Path.empty,
      },
    )
  })

  test("Successfully serializes Circle shape", t => {
    t->Assert.deepEqual(
      Circle({radius: 1.})->S.serializeToUnknownWith(shapeSchema),
      Ok(
        %raw(`{
          "kind": "circle",
          "radius": 1,
        }`),
      ),
      (),
    )
  })

  test("Successfully serializes Square shape", t => {
    t->Assert.deepEqual(
      Square({x: 2.})->S.serializeToUnknownWith(shapeSchema),
      Ok(
        %raw(`{
        "kind": "square",
        "x": 2,
      }`),
      ),
      (),
    )
  })

  test("Successfully serializes Triangle shape", t => {
    t->Assert.deepEqual(
      Triangle({x: 2., y: 3.})->S.serializeToUnknownWith(shapeSchema),
      Ok(
        %raw(`{
        "kind": "triangle",
        "x": 2,
        "y": 3,
      }`),
      ),
      (),
    )
  })

  test("Compiled parse code snapshot of shape schema", t => {
    t->U.assertCompiledCode(
      ~schema=shapeSchema,
      ~op=#Parse,
      `i=>{let v2=i;if(!i||i.constructor!==Object){e[11](i)}else{try{let v0=i["kind"],v1=i["radius"];if(v0!=="circle"){e[0](v0)}if(typeof v1!=="number"||Number.isNaN(v1)){e[1](v1)}v2={"TAG":e[2],"radius":v1}}catch(e0){try{let v3=i["kind"],v4=i["x"];if(v3!=="square"){e[3](v3)}if(typeof v4!=="number"||Number.isNaN(v4)){e[4](v4)}v2={"TAG":e[5],"x":v4}}catch(e1){try{let v5=i["kind"],v6=i["x"],v7=i["y"];if(v5!=="triangle"){e[6](v5)}if(typeof v6!=="number"||Number.isNaN(v6)){e[7](v6)}if(typeof v7!=="number"||Number.isNaN(v7)){e[8](v7)}v2={"TAG":e[9],"x":v6,"y":v7}}catch(e2){e[10]([e0,e1,e2,])}}}}return v2}`,
    )
  })

  test("Compiled serialize code snapshot of shape schema", t => {
    t->U.assertCompiledCode(
      ~schema=shapeSchema,
      ~op=#Serialize,
      `i=>{let v0=i;try{if(i["TAG"]!=="Circle"){e[0](i["TAG"])}v0={"kind":e[1],"radius":i["radius"]}}catch(e0){try{if(i["TAG"]!=="Square"){e[2](i["TAG"])}v0={"kind":e[3],"x":i["x"]}}catch(e1){try{if(i["TAG"]!=="Triangle"){e[4](i["TAG"])}v0={"kind":e[5],"x":i["x"],"y":i["y"]}}catch(e2){e[6]([e0,e1,e2,])}}}return v0}`,
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

  t->Assert.deepEqual(String("abc")->S.serializeToUnknownWith(schema), Ok(%raw(`"abc"`)), ())
  t->Assert.deepEqual(Int(123)->S.serializeToUnknownWith(schema), Ok(%raw(`"123"`)), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Serialize,
    `i=>{let v1=i;try{if(typeof i!=="string"){e[0](i)}}catch(e0){try{let v0=e[1](i);if(typeof v0!=="string"){e[2](v0)}v1=v0}catch(e1){e[3]([e0,e1,])}}return v1}`,
  )
})

test("Compiled parse code snapshot", t => {
  let schema = S.union([S.literal(0), S.literal(1)])

  t->U.assertCompiledCode(~schema, ~op=#Parse, `i=>{if(i!==0){if(i!==1){e[0](i)}}return i}`)
})

test("Compiled async parse code snapshot", t => {
  let schema = S.union([
    S.literal(0)->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}),
    S.literal(1),
  ])

  t->U.assertCompiledCode(
    ~schema,
    ~op=#Parse,
    `i=>{let v0=i;if(i!==0){if(i!==1){e[1](i)}}else{v0=e[0](i)}return Promise.resolve(v0)}`,
  )
})

test("Compiled serialize code snapshot", t => {
  let schema = S.union([S.literal(0), S.literal(1)])

  t->U.assertCompiledCode(~schema, ~op=#Serialize, `i=>{if(i!==0){if(i!==1){e[0](i)}}return i}`)
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
      ~op=#Serialize,
      `i=>{let v0=i;try{if(i["TAG"]!=="A"){e[0](i["TAG"])}v0={"payload":{"a":i["_0"]["payload"]["a"]}}}catch(e0){try{if(i["TAG"]!=="B"){e[1](i["TAG"])}v0={"payload":{"b":i["_0"]["payload"]["b"]}}}catch(e1){e[2]([e0,e1,])}}return v0}`,
    )

    let x = {
      B.payload: {
        b: 42,
      },
    }
    t->Assert.deepEqual(
      B(x)->S.serializeToUnknownWith(schema),
      Ok(%raw(`{"payload":{"b":42}}`)),
      (),
    )
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
      `i=>{let r0=i=>{let v6=i;if(!i||i.constructor!==Object){if(i!=="B"){if(i!=="C"){if(i!=="D"){if(i!=="E"){if(i!=="F"){if(i!=="G"){if(i!=="H"){if(i!=="I"){if(i!=="J"){if(i!=="K"){if(i!=="L"){if(i!=="M"){if(i!=="N"){if(i!=="O"){if(i!=="P"){if(i!=="Q"){if(i!=="R"){if(i!=="S"){if(i!=="T"){if(i!=="U"){if(i!=="V"){if(i!=="W"){if(i!=="X"){if(i!=="Y"){e[7](i)}}}}}}}}}}}}}}}}}}}}}}}}}else{try{let v0=i["type"],v1=i["nested"],v5=[];if(v0!=="A"){e[0](v0)}if(!Array.isArray(v1)){e[1](v1)}for(let v2=0;v2<v1.length;++v2){let v4;try{v4=r0(v1[v2])}catch(v3){if(v3&&v3.s===s){v3.path="[\\"nested\\"]"+\'["\'+v2+\'"]\'+v3.path}throw v3}v5.push(v4)}v6={"TAG":e[2],"_0":v5}}catch(e0){try{let v7=i["type"],v8=i["nested"],v12=[];if(v7!=="Z"){e[3](v7)}if(!Array.isArray(v8)){e[4](v8)}for(let v9=0;v9<v8.length;++v9){let v11;try{v11=r0(v8[v9])}catch(v10){if(v10&&v10.s===s){v10.path="[\\"nested\\"]"+\'["\'+v9+\'"]\'+v10.path}throw v10}v12.push(v11)}v6={"TAG":e[5],"_0":v12}}catch(e1){e[6]([e0,e1,])}}}return v6};return r0(i)}`,
    )
  })

  test("Compiled serialize code snapshot of crazy union", t => {
    S.setGlobalConfig({})
    t->U.assertCompiledCode(
      ~schema,
      ~op=#Serialize,
      `i=>{let r0=i=>{let v5=i;if(i!=="B"){if(i!=="C"){if(i!=="D"){if(i!=="E"){if(i!=="F"){if(i!=="G"){if(i!=="H"){if(i!=="I"){if(i!=="J"){if(i!=="K"){if(i!=="L"){if(i!=="M"){if(i!=="N"){if(i!=="O"){if(i!=="P"){if(i!=="Q"){if(i!=="R"){if(i!=="S"){if(i!=="T"){if(i!=="U"){if(i!=="V"){if(i!=="W"){if(i!=="X"){if(i!=="Y"){try{let v0=i["_0"],v4=[];if(i["TAG"]!=="A"){e[0](i["TAG"])}for(let v1=0;v1<v0.length;++v1){let v3;try{v3=r0(v0[v1])}catch(v2){if(v2&&v2.s===s){v2.path="[\\"_0\\"]"+\'["\'+v1+\'"]\'+v2.path}throw v2}v4.push(v3)}v5={"type":e[1],"nested":v4}}catch(e0){try{let v6=i["_0"],v10=[];if(i["TAG"]!=="Z"){e[2](i["TAG"])}for(let v7=0;v7<v6.length;++v7){let v9;try{v9=r0(v6[v7])}catch(v8){if(v8&&v8.s===s){v8.path="[\\"_0\\"]"+\'["\'+v7+\'"]\'+v8.path}throw v8}v10.push(v9)}v5={"type":e[3],"nested":v10}}catch(e1){e[4]([e0,e1,])}}}}}}}}}}}}}}}}}}}}}}}}}}return v5};return r0(i)}`,
    )
    // There was an issue with reverse when it doesn't return the same code on second run
    t->U.assertCompiledCode(
      ~schema,
      ~op=#Serialize,
      `i=>{let r0=i=>{let v5=i;if(i!=="B"){if(i!=="C"){if(i!=="D"){if(i!=="E"){if(i!=="F"){if(i!=="G"){if(i!=="H"){if(i!=="I"){if(i!=="J"){if(i!=="K"){if(i!=="L"){if(i!=="M"){if(i!=="N"){if(i!=="O"){if(i!=="P"){if(i!=="Q"){if(i!=="R"){if(i!=="S"){if(i!=="T"){if(i!=="U"){if(i!=="V"){if(i!=="W"){if(i!=="X"){if(i!=="Y"){try{let v0=i["_0"],v4=[];if(i["TAG"]!=="A"){e[0](i["TAG"])}for(let v1=0;v1<v0.length;++v1){let v3;try{v3=r0(v0[v1])}catch(v2){if(v2&&v2.s===s){v2.path="[\\"_0\\"]"+\'["\'+v1+\'"]\'+v2.path}throw v2}v4.push(v3)}v5={"type":e[1],"nested":v4}}catch(e0){try{let v6=i["_0"],v10=[];if(i["TAG"]!=="Z"){e[2](i["TAG"])}for(let v7=0;v7<v6.length;++v7){let v9;try{v9=r0(v6[v7])}catch(v8){if(v8&&v8.s===s){v8.path="[\\"_0\\"]"+\'["\'+v7+\'"]\'+v8.path}throw v8}v10.push(v9)}v5={"type":e[3],"nested":v10}}catch(e1){e[4]([e0,e1,])}}}}}}}}}}}}}}}}}}}}}}}}}}return v5};return r0(i)}`,
    )
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
      }`)
    ->S.parseWith(getLogsResponseSchema)
    ->S.unwrap,
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
      }`)
    ->S.parseWith(getLogsResponseSchema)
    ->S.unwrap,
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
      }`)
    ->S.parseWith(getLogsResponseSchema)
    ->S.unwrap,
    Error(#InvalidData("foo")),
    (),
  )
})
