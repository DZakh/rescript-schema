(i) => {
  if (!i || i.constructor !== Object) {
    e[5](i);
  }
  let v0 = i["foo"],
    v1 = i["obj"],
    v2 = i["obj"]["foo"],
    v3 = i["tuple"],
    v4 = i["tuple"]["0"];
  if (v0 !== 1) {
    e[0](v0);
  }
  if (!v1 || v1.constructor !== Object) {
    e[1](v1);
  }
  if (v2 !== 2) {
    e[2](v2);
  }
  if (!Array.isArray(v3)) {
    e[3](v3);
  }
  if (v4 !== 3) {
    e[4](v4);
  }
  return { bar: i["obj"]["bar"], baz: i["tuple"]["1"] };
};
