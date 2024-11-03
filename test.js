(i) => {
  if (i !== 12) {
    e[4](i);
  }
  let v0 = [e[0], e[1]];
  let v1 = v0["0"],
    v2 = v0["1"];
  if (v2 !== 12) {
    e[3](v2);
  }
  if (v1 !== true) {
    e[2](v1);
  }
  return v0;
};
