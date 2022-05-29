module Array: {
  let mapi: (array<'a>, (. 'a, int) => result<'b, 'e>) => result<array<'b>, 'e>
}

module Dict: {
  let map: (Js.Dict.t<'a>, (. 'a, string) => result<'b, 'e>) => result<Js.Dict.t<'b>, 'e>
}
