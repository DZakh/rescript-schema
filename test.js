(i) => {
  if (!i || i.constructor !== Object) {
    e[4](i);
  }
  let v0 = i["nested"];
  if (!v0 || v0.constructor !== Object) {
    e[0](v0);
  }
  let v1 = v0["nested2"];
  if (!v1 || v1.constructor !== Object) {
    e[1](v1);
  }
  let v2 = v1["bar"],
    v3 = v1["baz"];
  if (typeof v2 !== "string") {
    e[2](v2);
  }
  if (typeof v3 !== "string") {
    e[3](v3);
  }
  return { bar: v2, baz: v3 };
};
