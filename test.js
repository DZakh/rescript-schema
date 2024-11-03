(i) => {
  if (typeof i !== "boolean") {
    e[2](i);
  }
  let v0 = [e[0], i];
  let v1 = v0["0"];
  if (v1 !== true) {
    e[1](v1);
  }
  return v0;
};
