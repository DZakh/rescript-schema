(i) => {
  if (!i || i.constructor !== Object) {
    e[4](i);
  }
  let v0 = i["nested"],
    v3;
  if (!v0 || v0.constructor !== Object) {
    e[0](v0);
  }
  let v1 = v0["foo"],
    v2;
  if (typeof v1 !== "string") {
    e[1](v1);
  }
  for (v2 in v0) {
    if (v2 !== "foo") {
      e[2](v2);
    }
  }
  for (v3 in i) {
    if (v3 !== "nested") {
      e[3](v3);
    }
  }
  return i;
};
