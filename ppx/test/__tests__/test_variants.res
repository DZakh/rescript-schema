open Jest
open Expect
// open Belt

describe("variants with @struct.as", _ => {
  test(`encode 하나`, _ => {
    let variantEncoded = Variants.One->Variants.t_encode
    expect(variantEncoded) |> toEqual(JSON.Encode.string(`하나`))
  })
  test(`encode 둘`, _ => {
    let variantEncoded = Variants.Two->Variants.t_encode
    expect(variantEncoded) |> toEqual(JSON.Encode.string(`둘`))
  })
  test(`decode 하나`, _ => {
    let variantDecoded = JSON.Encode.string(`하나`)->Variants.t_decode
    expect(variantDecoded) |> toEqual(Ok(Variants.One))
  })
  test(`decode 둘`, _ => {
    let variantDecoded = JSON.Encode.string(`둘`)->Variants.t_decode
    expect(variantDecoded) |> toEqual(Ok(Variants.Two))
  })
})

describe(`variants without @struct.as`, _ => {
  test(`encode One1`, _ => {
    let variantEncoded = Variants.One1->Variants.t1_encode
    expect(variantEncoded) |> toEqual(JSON.Encode.array([JSON.Encode.string(`One1`)]))
  })
  test(`encode Two1`, _ => {
    let variantEncoded = Variants.Two1->Variants.t1_encode
    expect(variantEncoded) |> toEqual(JSON.Encode.array([JSON.Encode.string(`Two1`)]))
  })
  test(`decode ["One1"]`, _ => {
    let variantDecoded = JSON.Encode.array([JSON.Encode.string(`One1`)])->Variants.t1_decode
    expect(variantDecoded) |> toEqual(Ok(Variants.One1))
  })
  test(`decode ["Two1"]`, _ => {
    let variantDecoded = JSON.Encode.array([JSON.Encode.string(`Two1`)])->Variants.t1_decode
    expect(variantDecoded) |> toEqual(Ok(Variants.Two1))
  })
})

describe("unboxed variants with @struct.as", _ => {
  test(`encode 하나`, _ => {
    let variantEncoded = Variants.One2(0)->Variants.t2_encode
    expect(variantEncoded) |> toEqual(JSON.Encode.float(0.0))
  })
  test(`decode 하나`, _ => {
    let variantDecoded = JSON.Encode.float(0.0)->Variants.t2_decode
    expect(variantDecoded) |> toEqual(Ok(Variants.One2(0)))
  })
})

describe(`unboxed variants without @struct.as`, _ => {
  test(`encode One3(0)`, _ => {
    let variantEncoded = Variants.One3(0)->Variants.t3_encode
    expect(variantEncoded) |> toEqual(JSON.Encode.float(0.0))
  })
  test(`decode 0`, _ => {
    let variantDecoded = JSON.Encode.float(0.0)->Variants.t3_decode
    expect(variantDecoded) |> toEqual(Ok(Variants.One3(0)))
  })
})
