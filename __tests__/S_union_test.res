open Ava

test("Throws for a Union struct factory without structs", t => {
  t->Assert.throws(() => {
    S.union([])->ignore
  }, ~expectations=ThrowsException.make(
    ~message=String("[rescript-struct] A Union struct factory require at least two structs"),
    (),
  ), ())
})

test("Throws for a Union struct factory with single struct", t => {
  t->Assert.throws(() => {
    S.union([S.string()])->ignore
  }, ~expectations=ThrowsException.make(
    ~message=String("[rescript-struct] A Union struct factory require at least two structs"),
    (),
  ), ())
})

test("Successfully creates a Union struct factory with two structs", t => {
  t->Assert.notThrows(() => {
    S.union([S.string(), S.string()])->ignore
  }, ())
})

test("Successfully parses literalVariants", t => {
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

  let shapeStruct = S.union([
    S.object(o => {
      o->S.discriminant("kind", String("circle"))
      Circle({
        radius: o->S.field("radius", S.float()),
      })
    }),
    S.object(o => {
      o->S.discriminant("kind", String("square"))
      Square({
        x: o->S.field("x", S.float()),
      })
    }),
    S.object(o => {
      o->S.discriminant("kind", String("triangle"))
      Triangle({
        x: o->S.field("x", S.float()),
        y: o->S.field("y", S.float()),
      })
    }),
  ])

  test("Successfully parses Circle shape", t => {
    t->Assert.deepEqual(
      %raw(`{
      "kind": "circle",
      "radius": 1,
    }`)->S.parseWith(shapeStruct),
      Ok(Circle({radius: 1.})),
      (),
    )
  })

  test("Successfully parses Square shape", t => {
    t->Assert.deepEqual(
      %raw(`{
      "kind": "square",
      "x": 2,
    }`)->S.parseWith(shapeStruct),
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
    }`)->S.parseWith(shapeStruct),
      Ok(Triangle({x: 2., y: 3.})),
      (),
    )
  })

  test("Fails to parse with unknown kind", t => {
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

  test("Fails to parse with wrong data type", t => {
    t->Assert.deepEqual(
      %raw(`"Hello world!"`)->S.parseWith(shapeStruct),
      Error({
        code: InvalidUnion([
          {
            code: UnexpectedType({expected: "Object", received: "String"}),
            operation: Parsing,
            path: [],
          },
          {
            code: UnexpectedType({expected: "Object", received: "String"}),
            operation: Parsing,
            path: [],
          },
          {
            code: UnexpectedType({expected: "Object", received: "String"}),
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

  test("Fails to serialize incomplete struct", t => {
    let incompleteStruct = S.union([
      S.object(o => {
        o->S.discriminant("kind", String("circle"))
        Circle({
          radius: o->S.field("radius", S.float()),
        })
      }),
      S.object(o => {
        o->S.discriminant("kind", String("square"))
        Square({
          x: o->S.field("x", S.float()),
        })
      }),
    ])

    t->Assert.deepEqual(
      Triangle({x: 2., y: 3.})->S.serializeWith(incompleteStruct),
      Error({
        code: UnexpectedValue({expected: "1", received: "2"}),
        operation: Serializing,
        path: ["TAG"],
      }),
      (),
    )
  })

  test("Successfully serializes Circle shape", t => {
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

  test("Successfully serializes Square shape", t => {
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

  test("Successfully serializes Triangle shape", t => {
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
