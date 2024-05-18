(i) => {
  try {
    if (typeof i !== "boolean") {
      e[1](i);
    }
  } catch (v0) {
    if (v0 && v0.s === s) {
      i = e[0](i, v0);
    } else {
      throw v0;
    }
  }
  return i;
};
