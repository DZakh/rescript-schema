open Ava
open RescriptCore

test("Throws for a Union schema factory without schemas", t => {
  t->Assert.throws(
    () => {
      S.union([])
    },
    ~expectations={
      message: "[rescript-schema] S.union requires at least one item.",
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

test("Parses when both schemas misses parser", t => {
  let schema = S.union([
    S.literal(#apple)->S.transform(_ => {serializer: _ => #apple}),
    S.string->S.transform(_ => {serializer: _ => "apple"}),
  ])

  t->U.assertErrorResult(
    %raw(`null`)->S.parseAnyWith(schema),
    {
      code: InvalidUnion([
        U.error({
          code: InvalidOperation({description: "The S.transform parser is missing"}),
          operation: Parsing,
          path: S.Path.empty,
        }),
        U.error({
          code: InvalidOperation({description: "The S.transform parser is missing"}),
          operation: Parsing,
          path: S.Path.empty,
        }),
      ]),
      operation: Parsing,
      path: S.Path.empty,
    },
  )

  t->U.assertCompiledCode(~schema, ~op=#parse, `i=>{e[4]([e[1],e[3],]);return i}`)
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
          operation: Serializing,
          path: S.Path.empty,
        }),
        U.error({
          code: InvalidOperation({description: "The S.transform serializer is missing"}),
          operation: Serializing,
          path: S.Path.empty,
        }),
      ]),
      operation: Serializing,
      path: S.Path.empty,
    },
  )

  t->U.assertCompiledCode(~schema, ~op=#serialize, `i=>{e[2]([e[0],e[1],]);return i}`)
})

test("Parses when second struct misses parser", t => {
  let schema = S.union([S.literal(#apple), S.string->S.transform(_ => {serializer: _ => "apple"})])

  t->Assert.deepEqual("apple"->S.parseAnyWith(schema), Ok(#apple), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{let v0;try{i==="apple"||e[0](i);v0=i}catch(e0){e[3]([e0,e[2],])}return v0}`,
  )
})

test("Serializes when second struct misses serializer", t => {
  let schema = S.union([S.literal(#apple), S.string->S.transform(_ => {parser: _ => #apple})])

  t->Assert.deepEqual(#apple->S.serializeToUnknownWith(schema), Ok(%raw(`"apple"`)), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#serialize,
    `i=>{let v0;try{i==="apple"||e[0](i);v0=i}catch(e0){e[2]([e0,e[1],])}return v0}`,
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
            code: InvalidLiteral({
              expected: S.Literal.parse("circle"),
              received: "oval"->Obj.magic,
            }),
            operation: Parsing,
            path: S.Path.fromArray(["kind"]),
          }),
          U.error({
            code: InvalidLiteral({
              expected: S.Literal.parse("square"),
              received: "oval"->Obj.magic,
            }),
            operation: Parsing,
            path: S.Path.fromArray(["kind"]),
          }),
          U.error({
            code: InvalidLiteral({
              expected: S.Literal.parse("triangle"),
              received: "oval"->Obj.magic,
            }),
            operation: Parsing,
            path: S.Path.fromArray(["kind"]),
          }),
        ]),
        operation: Parsing,
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
            code: InvalidLiteral({
              expected: S.Literal.parse("circle"),
              received: "oval"->Obj.magic,
            }),
            operation: Parsing,
            path: S.Path.fromArray(["kind"]),
          }),
          U.error({
            code: InvalidLiteral({
              expected: S.Literal.parse("square"),
              received: "oval"->Obj.magic,
            }),
            operation: Parsing,
            path: S.Path.fromArray(["kind"]),
          }),
          U.error({
            code: InvalidLiteral({
              expected: S.Literal.parse("triangle"),
              received: "oval"->Obj.magic,
            }),
            operation: Parsing,
            path: S.Path.fromArray(["kind"]),
          }),
        ]),
        operation: Parsing,
        path: S.Path.fromArray(["field"]),
      },
    )
  })

  test("Fails to parse with invalid data type", t => {
    t->U.assertErrorResult(
      %raw(`"Hello world!"`)->S.parseAnyWith(shapeSchema),
      {
        code: InvalidUnion([
          U.error({
            code: InvalidType({
              expected: circleSchema->S.toUnknown,
              received: %raw(`"Hello world!"`),
            }),
            operation: Parsing,
            path: S.Path.empty,
          }),
          U.error({
            code: InvalidType({
              expected: squareSchema->S.toUnknown,
              received: %raw(`"Hello world!"`),
            }),
            operation: Parsing,
            path: S.Path.empty,
          }),
          U.error({
            code: InvalidType({
              expected: triangleSchema->S.toUnknown,
              received: %raw(`"Hello world!"`),
            }),
            operation: Parsing,
            path: S.Path.empty,
          }),
        ]),
        operation: Parsing,
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
            code: InvalidLiteral({
              expected: S.Literal.parse("Circle"),
              received: "Triangle"->Obj.magic,
            }),
            operation: Serializing,
            path: S.Path.fromArray(["TAG"]),
          }),
          U.error({
            code: InvalidLiteral({
              expected: S.Literal.parse("Square"),
              received: "Triangle"->Obj.magic,
            }),
            operation: Serializing,
            path: S.Path.fromArray(["TAG"]),
          }),
        ]),
        operation: Serializing,
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
      ~op=#parse,
      `i=>{let v2;try{if(!i||i.constructor!==Object){e[0](i)}let v0=i["kind"],v1=i["radius"];v0==="circle"||e[1](v0);if(typeof v1!=="number"||Number.isNaN(v1)){e[2](v1)}v2={"TAG":e[3],"radius":v1,}}catch(e0){try{if(!i||i.constructor!==Object){e[4](i)}let v3=i["kind"],v4=i["x"];v3==="square"||e[5](v3);if(typeof v4!=="number"||Number.isNaN(v4)){e[6](v4)}v2={"TAG":e[7],"x":v4,}}catch(e1){try{if(!i||i.constructor!==Object){e[8](i)}let v5=i["kind"],v6=i["x"],v7=i["y"];v5==="triangle"||e[9](v5);if(typeof v6!=="number"||Number.isNaN(v6)){e[10](v6)}if(typeof v7!=="number"||Number.isNaN(v7)){e[11](v7)}v2={"TAG":e[12],"x":v6,"y":v7,}}catch(e2){e[13]([e0,e1,e2,])}}}return v2}`,
    )
  })

  test("Compiled serialize code snapshot of shape schema", t => {
    t->U.assertCompiledCode(
      ~schema=shapeSchema,
      ~op=#serialize,
      `i=>{let v1;try{let v0={"kind":e[2],"radius":i["radius"],};if(i["TAG"]!==e[0]){e[1](i["TAG"])}if(!v0||v0.constructor!==Object){e[3](v0)}v1=v0}catch(e0){try{let v2={"kind":e[6],"x":i["x"],};if(i["TAG"]!==e[4]){e[5](i["TAG"])}if(!v2||v2.constructor!==Object){e[7](v2)}v1=v2}catch(e1){try{let v3={"kind":e[10],"x":i["x"],"y":i["y"],};if(i["TAG"]!==e[8]){e[9](i["TAG"])}if(!v3||v3.constructor!==Object){e[11](v3)}v1=v3}catch(e2){e[12]([e0,e1,e2,])}}}return v1}`,
    )
  })
}

@unboxed
type uboxedVariant = String(string) | Int(int)
test("Successfully serializes unboxed variant", t => {
  let schema = S.union([
    S.string->S.variant(s => String(s)),
    S.string
    ->S.transform(_ => {
      parser: string => string->Int.fromString->Option.getExn,
      serializer: Int.toString(_),
    })
    ->S.variant(i => Int(i)),
  ])

  t->Assert.deepEqual(String("abc")->S.serializeToUnknownWith(schema), Ok(%raw(`"abc"`)), ())
  t->Assert.deepEqual(Int(123)->S.serializeToUnknownWith(schema), Ok(%raw(`"123"`)), ())
})

test("Compiled parse code snapshot", t => {
  let schema = S.union([S.literal(0), S.literal(1)])

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{let v0;try{i===0||e[0](i);v0=i}catch(e0){try{i===1||e[1](i);v0=i}catch(e1){e[2]([e0,e1,])}}return v0}`,
  )
})

// It shouldn't compile since it throw InvalidOperation error
Failing.test("Compiled async parse code snapshot", t => {
  let schema = S.union([
    S.literal(0)->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}),
    S.literal(1),
  ])

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{let v0=e[1](i),v1;try{i===0||e[0](i);throw v0}catch(v2){if(v2&&v2.s===s||v2===v0){try{i===1||e[2](i);v1=()=>Promise.resolve(i)}catch(v3){if(v3&&v3.s===s){v1=()=>Promise.any([v2===v0?v2():Promise.reject(v2),Promise.reject(v3)]).catch(t=>{e[3](t.errors)})}else{throw v3}}}else{throw v2}}return v1}`,
  )
})

test("Compiled serialize code snapshot", t => {
  let schema = S.union([S.literal(0), S.literal(1)])

  // TODO: Improve compiled code for literals
  t->U.assertCompiledCode(
    ~schema,
    ~op=#serialize,
    `i=>{let v0;try{i===0||e[0](i);v0=i}catch(e0){try{i===1||e[1](i);v0=i}catch(e1){e[2]([e0,e1,])}}return v0}`,
  )
})

test("Compiled serialize code snapshot for unboxed variant", t => {
  let schema = S.union([
    S.string->S.variant(s => String(s)),
    S.string
    ->S.transform(_ => {
      parser: string => string->Int.fromString->Option.getExn,
      serializer: Int.toString(_),
    })
    ->S.variant(i => Int(i)),
  ])

  t->U.assertCompiledCode(
    ~schema,
    ~op=#serialize,
    `i=>{let v0;try{if(typeof i!=="string"){e[0](i)}v0=i}catch(e0){try{let v1=e[1](i);if(typeof v1!=="string"){e[2](v1)}v0=v1}catch(e1){e[3]([e0,e1,])}}return v0}`,
  )
})
