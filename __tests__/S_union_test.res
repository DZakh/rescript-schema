open Ava

ava->test("Throws for a Union struct factory without structs", t => {
  t->Assert.throws(() => {
    S.union([])->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message=String("A Union struct factory require at least two structs"),
    (),
  ), ())
})

ava->test("Throws for a Union struct factory with single struct", t => {
  t->Assert.throws(() => {
    S.union([S.string()])->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message=String("A Union struct factory require at least two structs"),
    (),
  ), ())
})

ava->test("Successfully creates a Union struct factory with two structs", t => {
  t->Assert.notThrows(() => {
    S.union([S.string(), S.string()])->ignore
  }, ())
})

ava->test("Successfully parses literalVariants", t => {
  let struct = S.union([
    S.literalVariant(String("apple"), #apple),
    S.literalVariant(String("orange"), #orange),
  ])

  t->Assert.deepEqual(%raw(`"apple"`)->S.parseWith(struct), Ok(#apple), ())
})

module Advanced = {
  // TypeScript type for reference (https://www.typescriptlang.org/docs/handbook/typescript-in-5-minutes-func.html#discriminated-unions)
  // type Shape =
  // | { kind: "circle"; radius: number }
  // | { kind: "square"; x: number }
  // | { kind: "triangle"; x: number; y: number };

  type shape = Circle({radius: float}) | Square({x: float}) | Triangle({x: float, y: float})

  let shapeStruct = {
    let circleStruct = S.record2(.
      ("kind", S.literalVariant(String("circle"), ())),
      ("radius", S.float()),
    )->S.transform(
      ~parser=(((), radius)) => Circle({radius: radius}),
      ~serializer=shape =>
        switch shape {
        | Circle({radius}) => ((), radius)
        | _ => S.Error.raise("Wrong shape")
        },
      (),
    )
    let squareStruct = S.record2(.
      ("kind", S.literalVariant(String("square"), ())),
      ("x", S.float()),
    )->S.transform(
      ~parser=(((), x)) => Square({x: x}),
      ~serializer=shape =>
        switch shape {
        | Square({x}) => ((), x)
        | _ => S.Error.raise("Wrong shape")
        },
      (),
    )
    let triangleStruct = S.record3(.
      ("kind", S.literalVariant(String("triangle"), ())),
      ("x", S.float()),
      ("y", S.float()),
    )->S.transform(
      ~parser=(((), x, y)) => Triangle({x, y}),
      ~serializer=shape =>
        switch shape {
        | Triangle({x, y}) => ((), x, y)
        | _ => S.Error.raise("Wrong shape")
        },
      (),
    )
    S.union([circleStruct, squareStruct, triangleStruct])
  }

  ava->test("Successfully parses Circle shape", t => {
    t->Assert.deepEqual(
      %raw(`{
      "kind": "circle",
      "radius": 1,
    }`)->S.parseWith(shapeStruct),
      Ok(Circle({radius: 1.})),
      (),
    )
  })

  ava->test("Successfully parses Square shape", t => {
    t->Assert.deepEqual(
      %raw(`{
      "kind": "square",
      "x": 2,
    }`)->S.parseWith(shapeStruct),
      Ok(Square({x: 2.})),
      (),
    )
  })

  ava->test("Successfully parses Triangle shape", t => {
    t->Assert.deepEqual(
      %raw(`{
      "kind": "triangle",
      "x": 2,
      "y": 3,
    }`)->S.parseWith(shapeStruct),
      Ok(Triangle({x: 2., y: 3.})),
      (),
    )
  })

  ava->test("Fails to parse with unknown kind", t => {
    t->Assert.deepEqual(
      %raw(`{
      "kind": "oval",
      "x": 2,
      "y": 3,
    }`)->S.parseWith(shapeStruct),
      Error({
        code: InvalidUnion([
          {
            code: UnexpectedValue({expected: `"circle"`, received: `"oval"`}),
            operation: Parsing,
            path: ["kind"],
          },
          {
            code: UnexpectedValue({expected: `"square"`, received: `"oval"`}),
            operation: Parsing,
            path: ["kind"],
          },
          {
            code: UnexpectedValue({expected: `"triangle"`, received: `"oval"`}),
            operation: Parsing,
            path: ["kind"],
          },
        ]),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  ava->test("Fails to parse with wrong data type", t => {
    t->Assert.deepEqual(
      %raw(`"Hello world!"`)->S.parseWith(shapeStruct),
      Error({
        code: InvalidUnion([
          {
            code: UnexpectedType({expected: "Record", received: "String"}),
            operation: Parsing,
            path: [],
          },
          {
            code: UnexpectedType({expected: "Record", received: "String"}),
            operation: Parsing,
            path: [],
          },
          {
            code: UnexpectedType({expected: "Record", received: "String"}),
            operation: Parsing,
            path: [],
          },
        ]),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  ava->test("Successfully serializes Circle shape", t => {
    t->Assert.deepEqual(
      Circle({radius: 1.})->S.serializeWith(shapeStruct),
      Ok(
        %raw(`{
        "kind": "circle",
        "radius": 1,
      }`),
      ),
      (),
    )
  })

  ava->test("Successfully serializes Square shape", t => {
    t->Assert.deepEqual(
      Square({x: 2.})->S.serializeWith(shapeStruct),
      Ok(
        %raw(`{
        "kind": "square",
        "x": 2,
      }`),
      ),
      (),
    )
  })

  ava->test("Successfully serializes Triangle shape", t => {
    t->Assert.deepEqual(
      Triangle({x: 2., y: 3.})->S.serializeWith(shapeStruct),
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
