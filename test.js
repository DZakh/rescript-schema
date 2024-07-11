(i) => {
  return e[0](i).then((v0) => {
    return e[1](v0)
      .then((v1) => {
        if (typeof v1 !== "string") {
          e[2](v1);
        }
        return v1;
      })
      .then((v2) => {
        return e[3](v2);
      });
  });
};
