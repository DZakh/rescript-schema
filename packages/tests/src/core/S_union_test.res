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

  t->Assert.deepEqual(schema->S.classify, String, ())
})

test("Successfully parses polymorphic variants", t => {
  let schema = S.union([S.literal(#apple), S.literal(#orange)])

  t->Assert.deepEqual(%raw(`"apple"`)->S.parseAnyWith(schema), Ok(#apple), ())
})

test("Parses when second struct misses parser", t => {
  let schema = S.union([S.literal(#apple), S.string->S.transform(_ => {serializer: _ => "apple"})])

  t->Assert.deepEqual("apple"->S.parseAnyWith(schema), Ok(#apple), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{let v0;try{i==="apple"||e[0](i);v0=i}catch(v1){if(v1&&v1.s===s){try{throw e[2];v0=i}catch(v2){if(v2&&v2.s===s){e[3]([v1,v2])}else{throw v2}}}else{throw v1}}return v0}`,
  )
})

test("Serializes when second struct misses serializer", t => {
  let schema = S.union([S.literal(#apple), S.string->S.transform(_ => {parser: _ => #apple})])

  t->Assert.deepEqual(#apple->S.serializeToUnknownWith(schema), Ok(%raw(`"apple"`)), ())

  t->U.assertCompiledCode(
    ~schema,
    ~op=#serialize,
    `i=>{let v0;try{i==="apple"||e[0](i);v0=i}catch(v1){if(v1&&v1.s===s){try{throw e[1];if(typeof i!=="string"){e[2](i)}v0=i}catch(v2){if(v2&&v2.s===s){e[3]([v1,v2,])}else{throw v2}}}else{throw v1}}return v0}`,
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
    `i=>{let v0;try{i===0||e[0](i);v0=i}catch(v1){if(v1&&v1.s===s){try{i===1||e[1](i);v0=i}catch(v2){if(v2&&v2.s===s){e[2]([v1,v2])}else{throw v2}}}else{throw v1}}return v0}`,
  )
})

test("Compiled parse code snapshot for discriminated union", t => {
  t->U.assertCompiledCode(
    ~schema=Advanced.shapeSchema,
    ~op=#parse,
    `i=>{let v7;try{if(!i||i.constructor!==Object){e[0](i)}let v0=i["radius"],v1=i["kind"];v1==="circle"||e[3](v1);if(typeof v0!=="number"||Number.isNaN(v0)){e[2](v0)}v7={"TAG":e[1],"radius":v0,}}catch(v8){if(v8&&v8.s===s){try{if(!i||i.constructor!==Object){e[4](i)}let v2=i["x"],v3=i["kind"];v3==="square"||e[7](v3);if(typeof v2!=="number"||Number.isNaN(v2)){e[6](v2)}v7={"TAG":e[5],"x":v2,}}catch(v9){if(v9&&v9.s===s){try{if(!i||i.constructor!==Object){e[8](i)}let v4=i["x"],v5=i["y"],v6=i["kind"];v6==="triangle"||e[12](v6);if(typeof v4!=="number"||Number.isNaN(v4)){e[10](v4)}if(typeof v5!=="number"||Number.isNaN(v5)){e[11](v5)}v7={"TAG":e[9],"x":v4,"y":v5,}}catch(v10){if(v10&&v10.s===s){e[13]([v8,v9,v10])}else{throw v10}}}else{throw v9}}}else{throw v8}}return v7}`,
  )
})

test("Compiled async parse code snapshot", t => {
  let schema = S.union([
    S.literal(0)->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}),
    S.literal(1),
  ])

  t->U.assertCompiledCode(
    ~schema,
    ~op=#parse,
    `i=>{let v0,v1;try{i===0||e[0](i);v0=e[1](i);throw v0}catch(v2){if(v2&&v2.s===s||v2===v0){try{i===1||e[2](i);v1=()=>Promise.resolve(i)}catch(v3){if(v3&&v3.s===s){v1=()=>Promise.any([v2===v0?v2():Promise.reject(v2),Promise.reject(v3)]).catch(t=>{e[3](t.errors)})}else{throw v3}}}else{throw v2}}return v1}`,
  )
})

test("Compiled serialize code snapshot", t => {
  let schema = S.union([S.literal(0), S.literal(1)])

  // TODO: Improve compiled code
  t->U.assertCompiledCode(
    ~schema,
    ~op=#serialize,
    `i=>{let v0;try{i===0||e[0](i);v0=i}catch(v1){if(v1&&v1.s===s){try{i===1||e[1](i);v0=i}catch(v2){if(v2&&v2.s===s){e[2]([v1,v2,])}else{throw v2}}}else{throw v1}}return v0}`,
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
    `i=>{let v0;try{if(typeof i!=="string"){e[0](i)}v0=i}catch(v1){if(v1&&v1.s===s){try{let v3=e[1](i);if(typeof v3!=="string"){e[2](v3)}v0=v3}catch(v2){if(v2&&v2.s===s){e[3]([v1,v2,])}else{throw v2}}}else{throw v1}}return v0}`,
  )
})
