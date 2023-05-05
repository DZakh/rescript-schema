@struct
type myString = string

@struct
type myInt = int

@struct
type myFloat = float

@struct
type myBool = bool

@struct
type myUnit = unit

@struct
type myUnknown = unknown

@struct
type myNever = S.never

@struct
type myOptionOfString = option<string>

@struct
type myArrayOfString = array<string>

@struct
type myListOfString = list<string>

@struct
type myDictOfString = Js.Dict.t<string>

@struct
type myDictOfStringFromCore = Dict.t<string>

@struct
type myJson = Js.Json.t

@struct
type myJsonFromCore = JSON.t

@struct
type myTuple = (string, int)

@struct
type myBigTuple = (string, string, string, int, int, int, float, float, float, bool, bool, bool)

@struct
type myCustomString = string

@struct
type myCustomLiteralString = string

@struct
type myCustomOptionalString = option<string>

@struct
type myNullOfString = option<string>
