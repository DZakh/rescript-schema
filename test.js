(i) => {
  if (!Array.isArray(i) || i.length !== 3) {
    e[3](i);
  }
  let v0 = i["0"],
    v1 = i["1"],
    v2 = i["2"];
  if (v2 !== "bar") {
    e[2](v2);
  }
  if (v1 !== undefined) {
    e[1](v1);
  }
  if (typeof v0 !== "string") {
    e[0](v0);
  }
  return i;
};

(i) => {
  if (
    !Array.isArray(i) ||
    i.length !== 3 ||
    i["1"] !== undefined ||
    i["2"] !== "bar"
  ) {
    e[1](i);
  }
  let v0 = i["0"];
  if (typeof v0 !== "string") {
    e[0](v0);
  }
  return i;
};
