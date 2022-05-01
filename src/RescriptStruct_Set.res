type t<'value>

@new
external fromArray: array<'value> => t<'value> = "Set"

@send
external delete: (t<'value>, 'value) => bool = "delete"

@get
external size: t<'value> => int = "size"

@val("Array.from")
external toArray: t<'value> => array<'value> = "from"
