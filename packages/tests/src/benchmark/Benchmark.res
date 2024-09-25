open RescriptCore

module Suite = {
  module BenchmarkResult = {
    type t

    @send
    external toString: t => string = "toString"
  }

  type t
  type event = {target: BenchmarkResult.t}

  @module("benchmark") @scope("default") @new
  external make: unit => t = "Suite"

  @send
  external add: (t, string, unit => 'a) => t = "add"

  let addWithPrepare = (suite, name, fn) => {
    suite->add(name, fn())
  }

  @send
  external _onCycle: (t, @as(json`"cycle"`) _, event => unit) => t = "on"

  @send
  external _run: t => unit = "run"

  let run = suite => {
    suite
    ->_onCycle(event => {
      Console.log(event.target->BenchmarkResult.toString)
    })
    ->_run
  }
}

let makeTestObject = () => {
  %raw(`Object.freeze({
    number: 1,
    negNumber: -1,
    maxNumber: Number.MAX_VALUE,
    string: 'string',
    longString:
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Vivendum intellegat et qui, ei denique consequuntur vix. Semper aeterno percipit ut his, sea ex utinam referrentur repudiandae. No epicuri hendrerit consetetur sit, sit dicta adipiscing ex, in facete detracto deterruisset duo. Quot populo ad qui. Sit fugit nostrum et. Ad per diam dicant interesset, lorem iusto sensibus ut sed. No dicam aperiam vis. Pri posse graeco definitiones cu, id eam populo quaestio adipiscing, usu quod malorum te. Ex nam agam veri, dicunt efficiantur ad qui, ad legere adversarium sit. Commune platonem mel id, brute adipiscing duo an. Vivendum intellegat et qui, ei denique consequuntur vix. Offendit eleifend moderatius ex vix, quem odio mazim et qui, purto expetendis cotidieque quo cu, veri persius vituperata ei nec. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
    boolean: true,
    deeplyNested: {
      foo: 'bar',
      num: 1,
      bool: false,
    },
  })`)
}

let makeAdvancedObjectSchema = () => {
  S.object(s =>
    {
      "number": s.field("number", S.float),
      "negNumber": s.field("negNumber", S.float),
      "maxNumber": s.field("maxNumber", S.float),
      "string": s.field("string", S.string),
      "longString": s.field("longString", S.string),
      "boolean": s.field("boolean", S.bool),
      "deeplyNested": s.field(
        "deeplyNested",
        S.object(s =>
          {
            "foo": s.field("foo", S.string),
            "num": s.field("num", S.float),
            "bool": s.field("bool", S.bool),
          }
        ),
      ),
    }
  )
}

let makeAdvancedStrictObjectSchema = () => {
  S.object(s =>
    {
      "number": s.field("number", S.float),
      "negNumber": s.field("negNumber", S.float),
      "maxNumber": s.field("maxNumber", S.float),
      "string": s.field("string", S.string),
      "longString": s.field("longString", S.string),
      "boolean": s.field("boolean", S.bool),
      "deeplyNested": s.field(
        "deeplyNested",
        S.object(s =>
          {
            "foo": s.field("foo", S.string),
            "num": s.field("num", S.float),
            "bool": s.field("bool", S.bool),
          }
        )->S.Object.strict,
      ),
    }
  )->S.Object.strict
}

S.setGlobalConfig({
  disableNanNumberCheck: true,
})

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

  let testData1 = Z(Array.make(~length=25, Z(Array.make(~length=25, Z(Array.make(~length=25, Y))))))

  let testData2 = A(Array.make(~length=25, A(Array.make(~length=25, A(Array.make(~length=25, B))))))

  let test = () => {
    Console.time("testData1 serialize")
    let json = S.serializeOrRaiseWith(testData1, schema)
    Console.timeEnd("testData1 serialize")

    Console.time("testData1 parse")
    let _ = S.parseOrRaiseWith(json, schema)
    Console.timeEnd("testData1 parse")

    Console.time("testData2 serialize")
    let json = S.serializeOrRaiseWith(testData2, schema)
    Console.timeEnd("testData2 serialize")

    Console.time("testData2 parse")
    let _ = S.parseOrRaiseWith(json, schema)
    Console.timeEnd("testData2 parse")

    // Console.log((schema->Obj.magic)["parseOrThrow"]["toString"]())
  }
}

// Full
// testData1 serialize: 5.414s
// testData1 parse: 5.519s
// testData2 serialize: 70.864ms
// testData2 parse: 70.967ms

// Wip
// testData1 serialize: 5.843s
// testData1 parse: 5.625ms
// testData2 serialize: 64.489ms
// testData2 parse: 0.836ms

// Partial
// testData1 serialize: 1.802ms
// testData1 parse: 1.411ms
// 734 Error.make
CrazyUnion.test()

let data = makeTestObject()
Console.time("makeAdvancedObjectSchema")
let schema = makeAdvancedObjectSchema()
Console.timeEnd("makeAdvancedObjectSchema")

Console.time("parseAnyWith: 1")
data->S.parseAnyWith(schema)->ignore
Console.timeEnd("parseAnyWith: 1")
Console.time("parseAnyWith: 2")
data->S.parseAnyWith(schema)->ignore
Console.timeEnd("parseAnyWith: 2")
Console.time("parseAnyWith: 3")
data->S.parseAnyWith(schema)->ignore
Console.timeEnd("parseAnyWith: 3")

Console.time("serializeWith: 1")
data->S.serializeWith(schema)->ignore
Console.timeEnd("serializeWith: 1")
Console.time("serializeWith: 2")
data->S.serializeWith(schema)->ignore
Console.timeEnd("serializeWith: 2")
Console.time("serializeWith: 3")
data->S.serializeWith(schema)->ignore
Console.timeEnd("serializeWith: 3")

Console.time("S.Error.make")
let _ = S.Error.make(
  ~code=OperationFailed("Should be positive"),
  ~operation=Parse,
  ~path=S.Path.empty,
)
Console.timeEnd("S.Error.make")

Suite.make()
->Suite.addWithPrepare("Parse string", () => {
  let schema = S.string
  let data = "Hello world!"
  () => {
    data->S.parseAnyOrRaiseWith(schema)
  }
})
->Suite.addWithPrepare("Serialize string", () => {
  let schema = S.string
  let data = "Hello world!"
  () => {
    data->S.serializeOrRaiseWith(schema)
  }
})
->Suite.add("Advanced object schema factory", makeAdvancedObjectSchema)
->Suite.addWithPrepare("Parse advanced object", () => {
  let schema = makeAdvancedObjectSchema()
  let data = makeTestObject()
  () => {
    data->S.parseAnyOrRaiseWith(schema)
  }
})
->Suite.addWithPrepare("Assert advanced object - compile", () => {
  let schema = makeAdvancedObjectSchema()
  let data = makeTestObject()
  let assertFn = schema->S.compile(~input=Any, ~output=Assert, ~typeValidation=true)
  () => {
    assertFn(data)
  }
})
->Suite.addWithPrepare("Assert advanced object", () => {
  let schema = makeAdvancedObjectSchema()
  let data = makeTestObject()
  () => {
    data->S.assertOrRaiseWith(schema)
  }
})
->Suite.addWithPrepare("Create and parse advanced object", () => {
  let data = makeTestObject()
  () => {
    let schema = makeAdvancedObjectSchema()
    data->S.parseAnyOrRaiseWith(schema)
  }
})
->Suite.addWithPrepare("Parse advanced strict object", () => {
  let schema = makeAdvancedStrictObjectSchema()
  let data = makeTestObject()
  () => {
    data->S.parseAnyOrRaiseWith(schema)
  }
})
->Suite.addWithPrepare("Assert advanced strict object", () => {
  let schema = makeAdvancedStrictObjectSchema()
  let data = makeTestObject()
  () => {
    data->S.assertOrRaiseWith(schema)
  }
})
->Suite.addWithPrepare("Serialize advanced object", () => {
  let schema = makeAdvancedObjectSchema()
  let data = makeTestObject()
  () => {
    data->S.serializeOrRaiseWith(schema)
  }
})
->Suite.run

/*
V7.0.1
makeAdvancedObjectSchema: 0.174ms
parseAnyWith: 1: 0.465ms
parseAnyWith: 2: 0.006ms
parseAnyWith: 3: 0.004ms
serializeWith: 1: 0.208ms
serializeWith: 2: 0.004ms
serializeWith: 3: 0.003ms
S.Error.make: 0.029ms
Parse string x 607,790,506 ops/sec ±0.21% (100 runs sampled)
Serialize string x 607,895,909 ops/sec ±0.23% (99 runs sampled)
Advanced object schema factory x 789,559 ops/sec ±0.28% (99 runs sampled)
Parse advanced object x 70,550,720 ops/sec ±0.51% (98 runs sampled)
Create and parse advanced object x 54,592 ops/sec ±0.49% (93 runs sampled)
Parse advanced strict object x 26,614,621 ops/sec ±0.30% (93 runs sampled)
Serialize advanced object x 598,233,913 ops/sec ±0.19% (95 runs sampled)
 */
