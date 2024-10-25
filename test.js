(i) => {
  let v0 = i;
  try {
    if (i["TAG"] !== "A") {
      e[0](i["TAG"]);
    }
    v0 = { payload: { a: i["_0"]["payload"]["a"] } };
  } catch (e0) {
    try {
      if (i["TAG"] !== "B") {
        e[1](i["TAG"]);
      }
      v0 = { payload: { b: i["_0"]["payload"]["b"] } };
    } catch (e1) {
      e[2]([e0, e1]);
    }
  }
  return v0;
};

(i) => {
  let v3 = i;
  try {
    let v0 = i["_0"],
      v1 = v0["payload"],
      v2 = { payload: { a: v1["a"] } };
    if (i["TAG"] !== "A") {
      e[0](i["TAG"]);
    }
    if (!v2 || v2.constructor !== Object) {
      e[1](v2);
    }
    v3 = v2;
  } catch (e0) {
    try {
      let v4 = i["_0"],
        v5 = v4["payload"],
        v6 = { payload: { b: v5["b"] } };
      if (i["TAG"] !== "B") {
        e[2](i["TAG"]);
      }
      if (!v6 || v6.constructor !== Object) {
        e[3](v6);
      }
      v3 = v6;
    } catch (e1) {
      e[4]([e0, e1]);
    }
  }
  return v3;
};
