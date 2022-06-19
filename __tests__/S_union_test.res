open Ava

test("Throws for a Union struct factory without structs", t => {
  t->Assert.throws(() => {
    S.union([])->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message="A Union struct factory require at least two structs",
    (),
  ), ())
})

test("Throws for a Union struct factory with single struct", t => {
  t->Assert.throws(() => {
    S.union([S.string()])->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message="A Union struct factory require at least two structs",
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

  let shapeStruct = {
    let circleStruct = S.record2(
      ~fields=(("kind", S.literal(String("circle"))), ("radius", S.float())),
      ~parser=((_, radius)) => Circle({radius: radius})->Ok,
      ~serializer=shape =>
        switch shape {
        | Circle({radius}) => ("circle", radius)->Ok
        | _ => Error("Wrong shape")
        },
      (),
    )
    let squareStruct = S.record2(
      ~fields=(("kind", S.literal(String("square"))), ("x", S.float())),
      ~parser=((_, x)) => Square({x: x})->Ok,
      ~serializer=shape =>
        switch shape {
        | Square({x}) => ("square", x)->Ok
        | _ => Error("Wrong shape")
        },
      (),
    )
    let triangleStruct = S.record3(
      ~fields=(("kind", S.literal(String("triangle"))), ("x", S.float()), ("y", S.float())),
      ~parser=((_, x, y)) => Triangle({x: x, y: y})->Ok,
      ~serializer=shape =>
        switch shape {
        | Triangle({x, y}) => ("triangle", x, y)->Ok
        | _ => Error("Wrong shape")
        },
      (),
    )
    S.union([circleStruct, squareStruct, triangleStruct])
  }

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
      Error(`[ReScript Struct] Failed parsing at [kind]. Reason: Expected "triangle", got "oval"`),
      (),
    )
  })

  test("Fails to parse with wrong data type", t => {
    t->Assert.deepEqual(
      %raw(`"Hello world!"`)->S.parseWith(shapeStruct),
      Error(`[ReScript Struct] Failed parsing at root. Reason: Expected Record, got String`),
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
