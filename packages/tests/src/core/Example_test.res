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
    `i=>{let v0,v1,v2,v3,v7,v8,v13,v14;if(!i||i.constructor!==Object){e[0](i)}v0=i["Id"];if(typeof v0!=="number"||Number.isNaN(v0)){e[1](v0)}v1=i["Title"];if(typeof v1!=="string"){e[2](v1)}v2=i["Tags"];if(v2!==void 0){let v5;if(!Array.isArray(v2)){e[3](v2)}v5=[];for(let v4=0;v4<v2.length;++v4){let v6;v6=v2[v4];try{if(typeof v6!=="string"){e[4](v6)}}catch(t){if(t&&t.s===s){t.path="[\\"Tags\\"]"+\'["\'+v4+\'"]\'+t.path}throw t}v5.push(v6)}v3=v5}else{v3=void 0}v7=i["Rating"];try{v7===e[6]||e[7](v7);v8=v7}catch(v9){if(v9&&v9.s===s){try{v7===e[8]||e[9](v7);v8=v7}catch(v10){if(v10&&v10.s===s){try{v7===e[10]||e[11](v7);v8=v7}catch(v11){if(v11&&v11.s===s){try{v7===e[12]||e[13](v7);v8=v7}catch(v12){if(v12&&v12.s===s){e[14]([v9,v10,v11,v12])}else{throw v12}}}else{throw v11}}}else{throw v10}}}else{throw v9}}v13=i["Age"];if(v13!==void 0){if(!(typeof v13==="number"&&v13<2147483648&&v13>-2147483649&&v13%1===0)){e[15](v13)}v14=v13}else{v14=void 0}return {"id":v0,"title":v1,"tags":v3===void 0?e[5]:v3,"rating":v8,"deprecatedAgeRestriction":v14,}}`,
    (),
  )
})

test("Compiled serialize code snapshot", t => {
  t->U.assertCompiledCode(
    ~struct=filmStruct,
    ~op=#serialize,
    `i=>{let v0,v1,v5,v6,v11,v12;v0=i["tags"];if(v0!==void 0){let v3;v3=[];for(let v2=0;v2<e[0](v0).length;++v2){let v4;v4=e[0](v0)[v2];try{}catch(t){if(t&&t.s===s){t.path="[\\"tags\\"]"+\'["\'+v2+\'"]\'+t.path}throw t}v3.push(v4)}v1=v3}else{v1=void 0}v5=i["rating"];try{v5===e[1]||e[2](v5);v6=v5}catch(v7){if(v7&&v7.s===s){try{v5===e[3]||e[4](v5);v6=v5}catch(v8){if(v8&&v8.s===s){try{v5===e[5]||e[6](v5);v6=v5}catch(v9){if(v9&&v9.s===s){try{v5===e[7]||e[8](v5);v6=v5}catch(v10){if(v10&&v10.s===s){e[9]([v7,v8,v9,v10,])}else{throw v10}}}else{throw v9}}}else{throw v8}}}else{throw v7}}v11=i["deprecatedAgeRestriction"];if(v11!==void 0){v12=e[10](v11)}else{v12=void 0}return {"Id":i["id"],"Title":i["title"],"Tags":v1,"Rating":v6,"Age":v12,}}`,
    (),
  )
})
