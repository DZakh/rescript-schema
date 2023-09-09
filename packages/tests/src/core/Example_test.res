open Ava

@dead
type rating =
  | @as("G") GeneralAudiences
  | @as("PG") ParentalGuidanceSuggested
  | @as("PG13") ParentalStronglyCautioned
  | @as("R") Restricted

@dead
type film = {
  id: float,
  title: string,
  tags: array<string>,
  rating: rating,
  deprecatedAgeRestriction: option<int>,
}

let filmStruct = S.object(s => {
  id: s.field("Id", S.float),
  title: s.field("Title", S.string),
  tags: s.fieldOr("Tags", S.array(S.string), []),
  rating: s.field(
    "Rating",
    S.union([
      S.literal(GeneralAudiences),
      S.literal(ParentalGuidanceSuggested),
      S.literal(ParentalStronglyCautioned),
      S.literal(Restricted),
    ]),
  ),
  deprecatedAgeRestriction: s.field("Age", S.option(S.int)->S.deprecate("Use rating instead")),
})

test("Example", t => {
  t->Assert.deepEqual(
    %raw(`{"Id": 1, "Title": "My first film", "Rating": "R", "Age": 17}`)->S.parseWith(filmStruct),
    Ok({
      id: 1.,
      title: "My first film",
      tags: [],
      rating: Restricted,
      deprecatedAgeRestriction: Some(17),
    }),
    (),
  )
  t->Assert.deepEqual(
    {
      id: 2.,
      tags: ["Loved"],
      title: "Sad & sed",
      rating: ParentalStronglyCautioned,
      deprecatedAgeRestriction: None,
    }->S.serializeWith(filmStruct),
    Ok(
      %raw(`{
        "Id": 2,
        "Title": "Sad & sed",
        "Rating": "PG13",
        "Tags": ["Loved"],
        "Age": undefined,
      }`),
    ),
    (),
  )
})

test("Compiled parse code snapshot", t => {
  t->U.assertCompiledCode(
    ~struct=filmStruct,
    ~op=#parse,
    `i=>{let v0,v1,v2,v3,v8,v9,v14,v15;if(!i||i.constructor!==Object){e[15](i)}v0=i["Id"];if(typeof v0!=="number"||Number.isNaN(v0)){e[0](v0)}v1=i["Title"];if(typeof v1!=="string"){e[1](v1)}v2=i["Tags"];if(v2!==void 0&&(!Array.isArray(v2))){e[2](v2)}if(v2!==void 0){let v5;v5=[];for(let v4=0;v4<v2.length;++v4){let v7;try{v7=v2[v4];if(typeof v7!=="string"){e[3](v7)}}catch(v6){if(v6&&v6.s===s){v6.path="[\\"Tags\\"]"+\'["\'+v4+\'"]\'+v6.path}throw v6}v5.push(v7)}v3=v5}else{v3=void 0}v8=i["Rating"];try{v8===e[5]||e[6](v8);v9=v8}catch(v10){if(v10&&v10.s===s){try{v8===e[7]||e[8](v8);v9=v8}catch(v11){if(v11&&v11.s===s){try{v8===e[9]||e[10](v8);v9=v8}catch(v12){if(v12&&v12.s===s){try{v8===e[11]||e[12](v8);v9=v8}catch(v13){if(v13&&v13.s===s){e[13]([v10,v11,v12,v13])}else{throw v13}}}else{throw v12}}}else{throw v11}}}else{throw v10}}v14=i["Age"];if(v14!==void 0&&(typeof v14!=="number"||v14>2147483647||v14<-2147483648||v14%1!==0)){e[14](v14)}if(v14!==void 0){v15=v14}else{v15=void 0}return {"id":v0,"title":v1,"tags":v3===void 0?e[4]:v3,"rating":v9,"deprecatedAgeRestriction":v15,}}`,
  )
})

test("Compiled serialize code snapshot", t => {
  t->U.assertCompiledCode(
    ~struct=filmStruct,
    ~op=#serialize,
    `i=>{let v0,v1,v7,v8,v13,v14;v0=i["tags"];if(v0!==void 0){let v2,v4;v2=e[0](v0);v4=[];for(let v3=0;v3<v2.length;++v3){let v6;try{v6=v2[v3]}catch(v5){if(v5&&v5.s===s){v5.path="[\\"tags\\"]"+'["'+v3+'"]'+v5.path}throw v5}v4.push(v6)}v1=v4}else{v1=void 0}v7=i["rating"];try{v7===e[1]||e[2](v7);v8=v7}catch(v9){if(v9&&v9.s===s){try{v7===e[3]||e[4](v7);v8=v7}catch(v10){if(v10&&v10.s===s){try{v7===e[5]||e[6](v7);v8=v7}catch(v11){if(v11&&v11.s===s){try{v7===e[7]||e[8](v7);v8=v7}catch(v12){if(v12&&v12.s===s){e[9]([v9,v10,v11,v12,])}else{throw v12}}}else{throw v11}}}else{throw v10}}}else{throw v9}}v13=i["deprecatedAgeRestriction"];if(v13!==void 0){v14=e[10](v13)}else{v14=void 0}return {"Id":i["id"],"Title":i["title"],"Tags":v1,"Rating":v8,"Age":v14,}}`,
  )
})
