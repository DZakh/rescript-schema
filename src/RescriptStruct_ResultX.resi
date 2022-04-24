let mapError: (result<'ok, 'error1>, 'error1 => 'error2) => result<'ok, 'error2>

module Array: {
  let mapi: (array<'a>, ('a, int) => result<'b, 'e>) => result<array<'b>, 'e>
}

module Dict: {
  let map: (Js.Dict.t<'a>, ('a, string) => result<'b, 'e>) => result<Js.Dict.t<'b>, 'e>
}
