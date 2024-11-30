(i) => {
  let v0 = i;
  if (!i || i.constructor !== Object) {
    e[3](i);
  } else {
    try {
      let v1 = i["foo"];
      let v2 = v1["tag"],
        v3 = v2["NAME"],
        v4 = v2["VAL"],
        v5;
      if (v3 !== "Null") {
        e[0](v3);
      }
      if (v4 !== void 0) {
        v5 = v4;
      } else {
        v5 = null;
      }
      v0 = { foo: { tag: { NAME: v3, VAL: v5 } } };
    } catch (e0) {
      try {
        let v6 = i["foo"];
        let v7 = v6["tag"],
          v8 = v7["NAME"];
        if (v8 !== "Option") {
          e[1](v8);
        }
      } catch (e1) {
        e[2]([e0, e1]);
      }
    }
  }
  return v0;
};
