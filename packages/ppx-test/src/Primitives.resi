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
// FIXME: The incompatible parts: option<string> vs myNullOfString (defined as Js.null<string>)
// @struct
// type myNullOfString = null<string>
@struct
type myArrayOfString = array<string>
@struct
type myListOfString = list<string>
@struct
type myDictOfString1 = Dict.t<string>
@struct
type myDictOfString2 = Js.Dict.t<string>
@struct
type myJsonable1 = Js.Json.t
@struct
type myJsonable2 = JSON.t
@struct
type myResult = result<int, string>
@struct
type myTuple = (string, int)
@struct
type myBigTuple = (string, string, string, int, int, int, float, float, float, bool, bool, bool)
@struct
type myCustomString = @struct.custom(S.string()->S.String.email()) string
