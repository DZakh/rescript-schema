open Jest
open Expect

describe("polymorphic variants with attribute", _ => {
  test("encode 하나", _ => {
    let polyvariantEncoded = #one->Polyvariants.t_encode
    expect(polyvariantEncoded) |> toEqual(JSON.Encode.string(`하나`))
  })
  test("encode 둘", _ => {
    let polyvariantEncoded = #two->Polyvariants.t_encode
    expect(polyvariantEncoded) |> toEqual(JSON.Encode.string(`둘`))
  })
  test("decode 하나", _ => {
    let polyvariantDecoded = JSON.Encode.string(`하나`)->Polyvariants.t_decode
    expect(polyvariantDecoded) |> toEqual(Ok(#one))
  })
  test("decode 둘", _ => {
    let polyvariantDecoded = JSON.Encode.string(`둘`)->Polyvariants.t_decode
    expect(polyvariantDecoded) |> toEqual(Ok(#two))
  })
})

describe("polymorphic variants", _ => {
  test(`encode #one`, _ => {
    let polyvariantEncoded = #one->Polyvariants.t1_encode
    expect(polyvariantEncoded) |> toEqual(JSON.Encode.array([JSON.Encode.string(`one`)]))
  })
  test(`encode #two`, _ => {
    let polyvariantEncoded = #two->Polyvariants.t1_encode
    expect(polyvariantEncoded) |> toEqual(JSON.Encode.array([JSON.Encode.string(`two`)]))
  })
  test(`decode one`, _ => {
    let polyvariantDecoded = JSON.Encode.array([JSON.Encode.string(`one`)])->Polyvariants.t1_decode
    expect(polyvariantDecoded) |> toEqual(Ok(#one))
  })
  test(`decode two`, _ => {
    let polyvariantDecoded = JSON.Encode.array([JSON.Encode.string(`two`)])->Polyvariants.t1_decode
    expect(polyvariantDecoded) |> toEqual(Ok(#two))
  })
})
