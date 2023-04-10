open Jest
open Expect
// open Belt

describe("encode only", _ => {
  open EncodeDecode

  let sample = Dict.make()
  sample->Dict.set("name", JSON.Encode.string("Alice"))
  sample->Dict.set("nickname", JSON.Encode.string("Ecila"))
  let sampleJson = sample->JSON.Encode.object

  let sampleRecord: te = {
    name: "Alice",
    nickname: "Ecila",
  }

  test(`encode`, _ => {
    let encoded = sampleRecord->te_encode
    expect(encoded) |> toEqual(sampleJson)
  })
})

describe("decode only", _ => {
  open EncodeDecode

  let sample = Dict.make()
  sample->Dict.set("name", JSON.Encode.string("Alice"))
  sample->Dict.set("nickname", JSON.Encode.string("Ecila"))
  let sampleJson = sample->JSON.Encode.object

  let sampleRecord: td = {
    name: "Alice",
    nickname: "Ecila",
  }

  test(`decode`, _ => {
    let decoded = sampleJson->td_decode
    expect(decoded) |> toEqual(Result.Ok(sampleRecord))
  })
})
