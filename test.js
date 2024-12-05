(i) => {
  if (!i || i.constructor !== Object) {
    e[4](i);
  }
  let v0 = i["nested"],
    v4;
  if (!v0 || v0.constructor !== Object) {
    e[0](v0);
  }
  let v1 = v0["foo"],
    v2,
    v3;
  if (v1 !== void 0 && typeof v1 !== "string") {
    e[1](v1);
  }
  if (v1 !== void 0) {
    v2 = v1;
  } else {
    v2 = null;
  }
  for (v3 in v0) {
    if (v3 !== "foo") {
      e[2](v3);
    }
  }
  for (v4 in i) {
    if (v4 !== "nested") {
      e[3](v4);
    }
  }
  return { nested: { foo: v2 } };
};
