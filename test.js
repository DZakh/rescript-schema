(i) => {
  if (!i || i.constructor !== Object) {
    e[4](i);
  }
  let v0 = i["foo"],
    v1 = i["nested1"];
  if (typeof v0 !== "string") {
    e[0](v0);
  }
  if (!v1 || v1.constructor !== Object) {
    e[1](v1);
  }
  let v2 = v1["nested2"];
  if (!v2 || v2.constructor !== Object) {
    e[2](v2);
  }
  let v3 = v2["bar"];
  if (typeof v3 !== "string") {
    e[3](v3);
  }
  return { foo: v0, bar: v3 };
};
