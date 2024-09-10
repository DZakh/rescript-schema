(i) => {
  let v0 = i["tags"],
    v3 = i["rating"];
  if (v3 !== "G") {
    if (v3 !== "PG") {
      if (v3 !== "PG13") {
        if (v3 !== "R") {
          e[0](v3);
        }
      }
    }
  }
  return {
    Id: i["id"],
    Title: i["title"],
    Tags: v0,
    Rating: v3,
    Age: i["deprecatedAgeRestriction"],
  };
};
