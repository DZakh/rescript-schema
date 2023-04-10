type decodeError = {
  path: string,
  message: string,
  value: JSON.t,
}

type result<'a> = Result.t<'a, decodeError>
type decoder<'a> = JSON.t => result<'a>
type encoder<'a> = 'a => JSON.t
type codec<'a> = (encoder<'a>, decoder<'a>)

let error = (~path=?, message, value) => {
  let path = switch path {
  | None => ""
  | Some(s) => s
  }
  Result.Error({path, message, value})
}

let stringToJson = s => JSON.Encode.string(s)
let stringFromJson = j =>
  switch JSON.Decode.string(j) {
  | Some(s) => Result.Ok(s)
  | None => Result.Error({path: "", message: "Not a string", value: j})
  }

let intToJson = i => i->float_of_int->JSON.Encode.float
let intFromJson = j =>
  switch JSON.Decode.float(j) {
  | Some(f) =>
    Math.floor(f) == f
      ? Ok(Math.floor(f)->Float.toInt)
      : Error({path: "", message: "Not an integer", value: j})

  | _ => Error({path: "", message: "Not a number", value: j})
  }

let int64ToJson = i => i->Int64.float_of_bits->JSON.Encode.float

let int64FromJson = j =>
  switch JSON.Decode.float(j) {
  | Some(n) => Result.Ok(Int64.bits_of_float(n))
  | None => error("Not a number", j)
  }

let int64ToJsonUnsafe = i => i->Int64.to_float->JSON.Encode.float

let int64FromJsonUnsafe = j =>
  switch JSON.Decode.float(j) {
  | Some(n) => Result.Ok(Int64.of_float(n))
  | None => error("Not a number", j)
  }

let floatToJson = v => v->JSON.Encode.float
let floatFromJson = j =>
  switch JSON.Decode.float(j) {
  | Some(f) => Result.Ok(f)
  | None => Result.Error({path: "", message: "Not a number", value: j})
  }

let boolToJson = v => v->JSON.Encode.float
let boolFromJson = j =>
  switch JSON.Decode.float(j) {
  | Some(b) => Result.Ok(b)
  | None => Result.Error({path: "", message: "Not a boolean", value: j})
  }

let unitToJson = () => JSON.Encode.float(0.0)
let unitFromJson = _ => Result.Ok()

let arrayToJson = (encoder, arr) => arr->Array.map(encoder)->JSON.Encode.array

let arrayFromJson = (decoder, json) =>
  switch JSON.Decode.array(json) {
  | Some(arr) =>
    arr->Array.reduceWithIndex(Result.Ok([]), (acc, jsonI, i) =>
      switch (acc, decoder(jsonI)) {
      | (Result.Error(_), _) => acc

      | (_, Result.Error({path} as error)) =>
        Result.Error({...error, path: "[" ++ (string_of_int(i) ++ ("]" ++ path))})

      | (Result.Ok(prev), Result.Ok(newVal)) => Result.Ok(Array.concat(prev, [newVal]))
      }
    )

  | None => Result.Error({path: "", message: "Not an array", value: json})
  }

let listToJson = (encoder, list) => list->List.toArray->arrayToJson(encoder, _)

let listFromJson = (decoder, json) => json->arrayFromJson(decoder, _)->Result.map(List.fromArray)

let optionToJson = (encoder, opt) =>
  switch opt {
  | Some(x) => encoder(x)
  | None => Js.Json.null
  }

let filterOptional = arr =>
  arr
  |> Belt.Array.keep(_, ((_, isOptional, x)) => !(isOptional && x == Js.Json.null))
  |> Belt.Array.map(_, ((k, _, v)) => (k, v))

let optionFromJson = (decoder, json) =>
  switch Js.Json.decodeNull(json) {
  | Some(_) => Belt.Result.Ok(None)
  | None => decoder(json) |> Belt.Result.map(_, v => Some(v))
  }

let resultToJson = (okEncoder, errorEncoder, result) =>
  switch result {
  | Belt.Result.Ok(v) => [Js.Json.string("Ok"), okEncoder(v)]
  | Belt.Result.Error(e) => [Js.Json.string("Error"), errorEncoder(e)]
  } |> Js.Json.array

let resultFromJson = (okDecoder, errorDecoder, json) =>
  switch Js.Json.decodeArray(json) {
  | Some([variantConstructorId, payload]) =>
    switch Js.Json.decodeString(variantConstructorId) {
    | Some("Ok") => okDecoder(payload)->Belt.Result.map(v => Belt.Result.Ok(v))

    | Some("Error") =>
      switch errorDecoder(payload) {
      | Belt.Result.Ok(v) => Belt.Result.Ok(Belt.Result.Error(v))
      | Belt.Result.Error(e) => Belt.Result.Error(e)
      }

    | Some(_) => error("Expected either \"Ok\" or \"Error\"", variantConstructorId)
    | None => error("Not a string", variantConstructorId)
    }
  | Some(_) => error("Expected exactly 2 values in array", json)
  | None => error("Not an array", json)
  }

let dictToJson = (encoder, dict) => dict->Js.Dict.map((. a) => encoder(a), _)->Js.Json.object_

let dictFromJson = (decoder, json) =>
  switch Js.Json.decodeObject(json) {
  | Some(dict) =>
    dict
    ->Js.Dict.entries
    ->Belt.Array.reduce(Ok(Js.Dict.empty()), (acc, (key, value)) =>
      switch (acc, decoder(value)) {
      | (Error(_), _) => acc

      | (_, Error({path} as error)) => Error({...error, path: "." ++ (key ++ path)})

      | (Ok(prev), Ok(newVal)) =>
        let () = prev->Js.Dict.set(key, newVal)
        Ok(prev)
      }
    )
  | None => Error({path: "", message: "Not a dict", value: json})
  }

module Codecs = {
  let string = (stringToJson, stringFromJson)
  let int = (intToJson, intFromJson)
  let int64Unsafe = (int64ToJsonUnsafe, int64FromJsonUnsafe)
  let float = (floatToJson, floatFromJson)
  let bool = (boolToJson, boolFromJson)
  let array = (arrayToJson, arrayFromJson)
  let list = (listToJson, listFromJson)
  let option = (optionToJson, optionFromJson)
  let unit = (unitToJson, unitFromJson)
}
