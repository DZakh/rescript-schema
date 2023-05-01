// open Jest
// open Expect

// describe("record with @struct.key", _ => {
//   open Records

//   let sample = Dict.make()
//   sample->Dict.set("spice-label", JSON.Encode.string("sample"))
//   sample->Dict.set("spice-value", JSON.Encode.float(1.0))
//   let sampleJson = sample->JSON.Encode.object

//   let sampleRecord: t = {
//     label: "sample",
//     value: 1,
//   }

//   test(`encode`, _ => {
//     let encoded = sampleRecord->Records.t_encode
//     expect(encoded) |> toEqual(sampleJson)
//   })

//   test(`decode`, _ => {
//     let decoded = sampleJson->Records.t_decode
//     expect(decoded) |> toEqual(Result.Ok(sampleRecord))
//   })
// })

// describe("record without @struct.key", _ => {
//   open Records

//   let sample = Dict.make()
//   sample->Dict.set("label", JSON.Encode.string("sample"))
//   sample->Dict.set("value", JSON.Encode.float(1.0))
//   let sampleJson = sample->JSON.Encode.object

//   let sampleRecord: t1 = {
//     label: "sample",
//     value: 1,
//   }

//   test(`encode`, _ => {
//     let encoded = sampleRecord->t1_encode
//     expect(encoded) |> toEqual(sampleJson)
//   })

//   test(`decode`, _ => {
//     let decoded = sampleJson->Records.t1_decode
//     expect(decoded) |> toEqual(Result.Ok(sampleRecord))
//   })
// })

// describe("record with optional field", _ => {
//   open Records

//   let sample1 = Dict.make()
//   sample1->Dict.set("label", JSON.Encode.string("sample"))
//   sample1->Dict.set("value", JSON.Encode.float(1.0))
//   let sampleJson1 = sample1->JSON.Encode.object

//   let sampleRecord1: tOp = {
//     label: Some("sample"),
//     value: 1,
//   }

//   test(`encode`, _ => {
//     let encoded = sampleRecord1->tOp_encode
//     expect(encoded) |> toEqual(sampleJson1)
//   })

//   test(`decode`, _ => {
//     let decoded = sampleJson1->Records.tOp_decode
//     expect(decoded) |> toEqual(Result.Ok(sampleRecord1))
//   })

//   let sample2 = Dict.make()
//   sample2->Dict.set("label", JSON.Encode.string("sample"))
//   let sampleJson2 = sample2->JSON.Encode.object

//   let sampleRecord2: tOp = {
//     label: Some("sample"),
//   }

//   test(`encode omit optional field`, _ => {
//     let encoded = sampleRecord2->tOp_encode
//     expect(encoded) |> toEqual(sampleJson2)
//   })

//   test(`decode omit optional field`, _ => {
//     let decoded = sampleJson2->Records.tOp_decode
//     expect(decoded) |> toEqual(Result.Ok(sampleRecord2))
//   })

//   let sample3 = Dict.make()
//   sample3->Dict.set("label", JSON.Encode.null)
//   let sampleJson3 = sample3->JSON.Encode.object

//   let sampleRecord3: tOp = {
//     label: None,
//   }

//   test(`encode omit optional field with None field`, _ => {
//     let encoded = sampleRecord3->tOp_encode
//     expect(encoded) |> toEqual(sampleJson3)
//   })

//   test(`decode omit optional field with None field`, _ => {
//     let decoded = sampleJson3->Records.tOp_decode
//     expect(decoded) |> toEqual(Result.Ok(sampleRecord3))
//   })
// })

