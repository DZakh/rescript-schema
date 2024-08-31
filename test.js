(i) => {
  if (!i || i.constructor !== Object) {
    e[3](i);
  }
  let v0 = i["nested"],
    v2 = { nested: { field: v1 } };
  if (!v0 || v0.constructor !== Object) {
    e[0](v0);
  }
  let v1 = v0["field"];
  if (typeof v1 !== "boolean") {
    e[1](v1);
  }
  return { kind: e[2], raw_field: v2["nested"]["field"] };
};
