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
    `i=>{if(!i||i.constructor!==Object){e[11](i)}let v0=i["Id"],v1=i["Title"],v2=i["Tags"],v9=i["Rating"],v11=i["Age"];if(typeof v0!=="number"||Number.isNaN(v0)){e[0](v0)}if(typeof v1!=="string"){e[1](v1)}if(v2!==void 0&&(!Array.isArray(v2))){e[2](v2)}let v8;if(v2!==void 0){let v7=[];for(let v3=0;v3<v2.length;++v3){let v6;try{let v5=v2[v3];if(typeof v5!=="string"){e[3](v5)}v6=v5}catch(v4){if(v4&&v4.s===s){v4.path="[\\"Tags\\"]"+\'["\'+v3+\'"]\'+v4.path}throw v4}v7.push(v6)}v8=v7}let v10;try{v9==="G"||e[5](v9);v10=v9}catch(e0){try{v9==="PG"||e[6](v9);v10=v9}catch(e1){try{v9==="PG13"||e[7](v9);v10=v9}catch(e2){try{v9==="R"||e[8](v9);v10=v9}catch(e3){e[9]([e0,e1,e2,e3,])}}}}if(v11!==void 0&&(typeof v11!=="number"||v11>2147483647||v11<-2147483648||v11%1!==0)){e[10](v11)}let v12;if(v11!==void 0){v12=v11}return {"id":v0,"title":v1,"tags":v8===void 0?e[4]:v8,"rating":v10,"deprecatedAgeRestriction":v12,}}`,
  )
})

test("Compiled serialize code snapshot", t => {
  t->U.assertCompiledCode(
    ~schema=filmSchema,
    ~op=#serialize,
    `i=>{let v0=i["tags"],v1,v2=i["rating"],v3,v4=i["deprecatedAgeRestriction"],v5;if(v0!==void 0){v1=e[0](v0)}try{v2==="G"||e[1](v2);v3=v2}catch(e0){try{v2==="PG"||e[2](v2);v3=v2}catch(e1){try{v2==="PG13"||e[3](v2);v3=v2}catch(e2){try{v2==="R"||e[4](v2);v3=v2}catch(e3){e[5]([e0,e1,e2,e3,])}}}}if(v4!==void 0){v5=e[6](v4)}return {"Id":i["id"],"Title":i["title"],"Tags":v1,"Rating":v3,"Age":v5,}}`,
  )
})
