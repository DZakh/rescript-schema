open Ava

// TypeScript type for reference (https://www.typescriptlang.org/docs/handbook/typescript-in-5-minutes-func.html#discriminated-unions)
// type Shape =
// | { kind: "circle"; radius: number }
// | { kind: "square"; x: number }
// | { kind: "triangle"; x: number; y: number };

type shape = Circle({radius: float}) | Square({x: float}) | Triangle({x: float, y: float})
type shapeDiscriminant = [#circle | #square | #triangle]

let shapeStruct = {
  let discriminantStruct = S.record1(
    ~fields=(
      "kind",
      S.string()->S.transform(
        ~constructor=data => {
          switch Obj.magic(data) {
          | #...shapeDiscriminant as shapeDiscriminant => shapeDiscriminant->Ok
          | unknownValue =>
            Error(`The provided shape discriminant "${unknownValue->Obj.magic}" is unknown`)
          }
        },
        ~destructor=value => value->Obj.magic->Ok,
        (),
      ),
    ),
    ~constructor=kind => kind->Ok,
    ~destructor=kind => kind->Ok,
    (),
  )->S.Record.strip
  let circleStruct = S.record2(
    ~fields=(("kind", S.literal(String("circle"))), ("radius", S.float())),
    ~constructor=((_, radius)) => Circle({radius: radius})->Ok,
    ~destructor=shape =>
      switch shape {
      | Circle({radius}) => ("circle", radius)->Ok
      | _ => Error("Wrong shape")
      },
    (),
  )
  let squareStruct = S.record2(
    ~fields=(("kind", S.literal(String("square"))), ("x", S.float())),
    ~constructor=((_, x)) => Square({x: x})->Ok,
    ~destructor=shape =>
      switch shape {
      | Square({x}) => ("square", x)->Ok
      | _ => Error("Wrong shape")
      },
    (),
  )
  let triangleStruct = S.record3(
    ~fields=(("kind", S.literal(String("triangle"))), ("x", S.float()), ("y", S.float())),
    ~constructor=((_, x, y)) => Triangle({x: x, y: y})->Ok,
    ~destructor=shape =>
      switch shape {
      | Triangle({x, y}) => ("triangle", x, y)->Ok
      | _ => Error("Wrong shape")
      },
    (),
  )
  S.dynamic(
    ~constructor=unknown => {
      unknown
      ->S.parseWith(discriminantStruct)
      ->Belt.Result.map(discriminant => {
        switch discriminant {
        | #circle => circleStruct
        | #square => squareStruct
        | #triangle => triangleStruct
        }
      })
    },
    ~destructor=shape =>
      switch shape {
      | Circle(_) => circleStruct
      | Square(_) => squareStruct
      | Triangle(_) => triangleStruct
      }->Ok,
    (),
  )
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
    Error(`[ReScript Struct] Failed parsing at root. Reason: [ReScript Struct] Failed parsing at [kind]. Reason: The provided shape discriminant "oval" is unknown`),
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
