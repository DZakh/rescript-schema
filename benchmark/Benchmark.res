module Suite = {
  module Benchmark = {
    type t

    @send
    external toString: t => string = "toString"
  }

  type t
  type event = {target: Benchmark.t}

  @module("benchmark") @new
  external make: unit => t = "Suite"

  @send
  external add: (t, string, unit => 'a) => t = "add"

  @send
  external _onCycle: (t, @as(json`"cycle"`) _, event => unit) => t = "on"

  @send
  external _run: t => unit = "run"

  let run = suite => {
    suite
    ->_onCycle(event => {
      Js.log(event.target->Benchmark.toString)
    })
    ->_run
  }
}

Suite.make()
->Suite.add("String struct factory", () => {
  S.string()
})
->Suite.add("Advanced object struct factory", () => {
  S.object7(.
    ("number", S.float()),
    ("negNumber", S.float()),
    ("maxNumber", S.float()),
    ("string", S.string()),
    ("longString", S.string()),
    ("boolean", S.bool()),
    ("deeplyNested", S.object3(. ("foo", S.string()), ("num", S.float()), ("bool", S.bool()))),
  )->S.transform(
    ~parser=((number, negNumber, maxNumber, string, longString, boolean, (foo, num, bool))) => {
      {
        "number": number,
        "negNumber": negNumber,
        "maxNumber": maxNumber,
        "string": string,
        "longString": longString,
        "boolean": boolean,
        "deeplyNested": {
          "foo": foo,
          "num": num,
          "bool": bool,
        },
      }
    },
    (),
  )
})
->Suite.run
