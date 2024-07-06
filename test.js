(i) => {
  if (!i || i.constructor !== Object) {
    e[1](i);
  }
  let v0 = i["foo"];
  if (typeof v0 !== "string") {
    e[0](v0);
  }
  return v0;
};
