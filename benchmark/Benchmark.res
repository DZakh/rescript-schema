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
->Suite.run
