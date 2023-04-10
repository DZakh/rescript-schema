let falseableEncode = (encoder, opt) =>
  switch opt {
  | None => JSON.Encode.bool(false)
  | Some(v) => encoder(v)
  }
let falseableDecode = (decoder, json) =>
  switch JSON.Decode.bool(json) {
  | Some(false) => Result.Ok(None)
  | _ => decoder(json) |> Result.map(_, v => Some(v))
  }
let falseable = (falseableEncode, falseableDecode)

let magicDecode = j => Result.Ok(Obj.magic(j))
let magic = (Obj.magic, magicDecode)
