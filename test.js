(i) => {
  let v0 = i["tags"],
    v3 = i["rating"],
    v4 = i["deprecatedAgeRestriction"],
    v5;
  if (v3 !== "G") {
    if (v3 !== "PG") {
      if (v3 !== "PG13") {
        if (v3 !== "R") {
          e[0](v3);
        }
      }
    }
  }
  if (v4 !== void 0) {
    v5 = e[1](v4);
  }
  return { Id: i["id"], Title: i["title"], Tags: v0, Rating: v3, Age: v5 };
};
