open Jest
open Expect
// open Belt

describe("optional field record", _ => {
  open OptionalFieldRecords

  let sample = Dict.make()
  sample->Dict.set("a", JSON.Encode.float(1.))
  sample->Dict.set("b", JSON.Encode.float(1.))
  let sampleJson = sample->JSON.Encode.object

  let sampleRecord: t0 = {
    a: 1,
    b: 1,
  }

  test(`encode`, _ => {
    let encoded = sampleRecord->t0_encode
    expect(encoded) |> toEqual(sampleJson)
  })

  test(`decode`, _ => {
    let decoded = sampleJson->t0_decode
    expect(decoded) |> toEqual(Result.Ok(sampleRecord))
  })
})

describe("optional field record: array<int>", _ => {
  open OptionalFieldRecords

  let sample = Dict.make()
  sample->Dict.set("a", JSON.Encode.float(1.))
  sample->Dict.set("bs", JSON.Encode.array([JSON.Encode.float(1.)]))
  let sampleJson = sample->JSON.Encode.object

  let sampleRecord: t1 = {
    a: 1,
    bs: [1],
  }

  test(`encode`, _ => {
    let encoded = sampleRecord->t1_encode
    expect(encoded) |> toEqual(sampleJson)
  })

  test(`decode`, _ => {
    let decoded = sampleJson->t1_decode
    expect(decoded) |> toEqual(Result.Ok(sampleRecord))
  })
})

describe("optional field record: array<variant>", _ => {
  open OptionalFieldRecords

  let sample = Dict.make()
  sample->Dict.set("a", JSON.Encode.float(1.))
  sample->Dict.set("bs", JSON.Encode.array([JSON.Encode.string("B1")]))
  let sampleJson = sample->JSON.Encode.object

  let sampleRecord: t2 = {
    a: 1,
    bs: [B1],
  }

  test(`encode`, _ => {
    let encoded = sampleRecord->t2_encode
    expect(encoded) |> toEqual(sampleJson)
  })

  test(`decode`, _ => {
    let decoded = sampleJson->t2_decode
    expect(decoded) |> toEqual(Result.Ok(sampleRecord))
  })
})

describe("optional field record: omit array<variant>", _ => {
  open OptionalFieldRecords

  let sample = Dict.make()
  sample->Dict.set("a", JSON.Encode.float(1.))

  let sampleJson = sample->JSON.Encode.object

  let sampleRecord: t2 = {
    a: 1,
  }

  test(`encode`, _ => {
    let encoded = sampleRecord->t2_encode
    expect(encoded) |> toEqual(sampleJson)
  })

  test(`decode`, _ => {
    let decoded = sampleJson->t2_decode
    expect(decoded) |> toEqual(Result.Ok(sampleRecord))
  })
})
