(i) => {
  let v0, v1;
  try {
    v0 = JSON.parse(i);
  } catch (t) {
    e[0](t.message);
  }
  if (v0 !== null) {
    v1 = v0;
  } else {
    v1 = void 0;
  }
  return v1;
};
