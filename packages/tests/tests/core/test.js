(i) => {
  let v0, v1, v2, v3;
  if (!i || i.constructor !== Object) {
    e[0](i);
  }
  v3 = i["tag"];
  v3 === e[5] || e[6](v3);
  v1 = i["FOO"];
  if (typeof v1 !== "string") {
    e[2](v1);
  }
  v2 = i["BAR"];
  if (typeof v2 !== "boolean") {
    e[3](v2);
  }
  for (v0 in i) {
    if (v0 !== "tag" && v0 !== "FOO" && v0 !== "BAR") {
      e[1](v0);
    }
  }
  return { foo: v1, bar: v2, zoo: e[4] };
};
