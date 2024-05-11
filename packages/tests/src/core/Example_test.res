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

let filmSchema = S.object(s => {
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
    %raw(`{"Id": 1, "Title": "My first film", "Rating": "R", "Age": 17}`)->S.parseWith(filmSchema),
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
    }->S.serializeWith(filmSchema),
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
    ~schema=filmSchema,
    ~op=#parse,
    `i=>{if(!i||i.constructor!==Object){e[11](i)}let v0,v1,v2,v7,v8,v9,v14,v15;v0=i["Id"];if(typeof v0!=="number"||Number.isNaN(v0)){e[0](v0)}v1=i["Title"];if(typeof v1!=="string"){e[1](v1)}v2=i["Tags"];if(v2!==void 0&&(!Array.isArray(v2))){e[2](v2)}if(v2!==void 0){let v6=[];for(let v3=0;v3<v2.length;++v3){let v5;try{v5=v2[v3];if(typeof v5!=="string"){e[3](v5)}}catch(v4){if(v4&&v4.s===s){v4.path="[\\"Tags\\"]"+\'["\'+v3+\'"]\'+v4.path}throw v4}v6.push(v5)}v7=v6}v8=i["Rating"];try{v8==="G"||e[5](v8);v9=v8}catch(v10){if(v10&&v10.s===s){try{v8==="PG"||e[6](v8);v9=v8}catch(v11){if(v11&&v11.s===s){try{v8==="PG13"||e[7](v8);v9=v8}catch(v12){if(v12&&v12.s===s){try{v8==="R"||e[8](v8);v9=v8}catch(v13){if(v13&&v13.s===s){e[9]([v10,v11,v12,v13])}else{throw v13}}}else{throw v12}}}else{throw v11}}}else{throw v10}}v14=i["Age"];if(v14!==void 0&&(typeof v14!=="number"||v14>2147483647||v14<-2147483648||v14%1!==0)){e[10](v14)}if(v14!==void 0){v15=v14}return {"id":v0,"title":v1,"tags":v7===void 0?e[4]:v7,"rating":v9,"deprecatedAgeRestriction":v15,}}`,
  )
})

test("Compiled serialize code snapshot", t => {
  t->U.assertCompiledCode(
    ~schema=filmSchema,
    ~op=#serialize,
    `i=>{let v0,v1,v2,v3,v8,v9;v0=i["tags"];if(v0!==void 0){v1=e[0](v0)}v2=i["rating"];try{v2==="G"||e[1](v2);v3=v2}catch(v4){if(v4&&v4.s===s){try{v2==="PG"||e[2](v2);v3=v2}catch(v5){if(v5&&v5.s===s){try{v2==="PG13"||e[3](v2);v3=v2}catch(v6){if(v6&&v6.s===s){try{v2==="R"||e[4](v2);v3=v2}catch(v7){if(v7&&v7.s===s){e[5]([v4,v5,v6,v7,])}else{throw v7}}}else{throw v6}}}else{throw v5}}}else{throw v4}}v8=i["deprecatedAgeRestriction"];if(v8!==void 0){v9=e[6](v8)}return {"Id":i["id"],"Title":i["title"],"Tags":v1,"Rating":v3,"Age":v9,}}`,
  )
})
