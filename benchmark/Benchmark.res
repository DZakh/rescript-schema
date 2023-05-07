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
  external add: (t, string, (. unit) => 'a) => t = "add"

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
      Js.log(event.target->BenchmarkResult.toString)
    })
    ->_run
  }
}

let makeTestObject = (. ()) => {
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

let makeAdvancedObjectStruct = (. ()) => {
  S.object(o =>
    {
      "number": o->S.field("number", S.float),
      "negNumber": o->S.field("negNumber", S.float),
      "maxNumber": o->S.field("maxNumber", S.float),
      "string": o->S.field("string", S.string),
      "longString": o->S.field("longString", S.string),
      "boolean": o->S.field("boolean", S.bool),
      "deeplyNested": o->S.field(
        "deeplyNested",
        S.object(o =>
          {
            "foo": o->S.field("foo", S.string),
            "num": o->S.field("num", S.float),
            "bool": o->S.field("bool", S.bool),
          }
        ),
      ),
    }
  )
}

let makeAdvancedStrictObjectStruct = (. ()) => {
  S.object(o =>
    {
      "number": o->S.field("number", S.float),
      "negNumber": o->S.field("negNumber", S.float),
      "maxNumber": o->S.field("maxNumber", S.float),
      "string": o->S.field("string", S.string),
      "longString": o->S.field("longString", S.string),
      "boolean": o->S.field("boolean", S.bool),
      "deeplyNested": o->S.field(
        "deeplyNested",
        S.object(o =>
          {
            "foo": o->S.field("foo", S.string),
            "num": o->S.field("num", S.float),
            "bool": o->S.field("bool", S.bool),
          }
        )->S.Object.strict,
      ),
    }
  )->S.Object.strict
}

Suite.make()
->Suite.addWithPrepare("Parse string", () => {
  let struct = S.string
  let data = "Hello world!"
  (. ()) => {
    data->S.parseAnyOrRaiseWith(struct)
  }
})
->Suite.addWithPrepare("Serialize string", () => {
  let struct = S.string
  let data = "Hello world!"
  (. ()) => {
    data->S.serializeOrRaiseWith(struct)
  }
})
->Suite.add("Advanced object struct factory", makeAdvancedObjectStruct)
->Suite.addWithPrepare("Parse advanced object", () => {
  let struct = makeAdvancedObjectStruct(.)
  let data = makeTestObject(.)
  (. ()) => {
    data->S.parseAnyOrRaiseWith(struct)
  }
})
->Suite.addWithPrepare("Create and parse advanced object", () => {
  let data = makeTestObject(.)
  (. ()) => {
    let struct = makeAdvancedObjectStruct(.)
    data->S.parseAnyOrRaiseWith(struct)
  }
})
->Suite.addWithPrepare("Parse advanced strict object", () => {
  let struct = makeAdvancedStrictObjectStruct(.)
  let data = makeTestObject(.)
  (. ()) => {
    data->S.parseAnyOrRaiseWith(struct)
  }
})
->Suite.addWithPrepare("Serialize advanced object", () => {
  let struct = makeAdvancedObjectStruct(.)
  let data = makeTestObject(.)
  (. ()) => {
    data->S.serializeOrRaiseWith(struct)
  }
})
->Suite.run
