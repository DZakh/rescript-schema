(i) => {
  let v3 = i;
  if (!i || i.constructor !== Object || i["NAME"] !== "request") {
    if (!i || i.constructor !== Object || i["NAME"] !== "response") {
      e[3](i);
    } else {
      if (v0 !== "response") {
        e[1](v0);
      }
      let v2 = v1["response"];
      if (v2 !== "accepted") {
        if (v2 !== "rejected") {
          e[2](v2);
        }
      }
      v3 = {
        NAME: v0,
        VAL: { collectionName: v1["collectionName"], response: v2 },
      };
    }
  } else {
    let v0 = i["NAME"],
      v1 = i["VAL"];
    if (v0 !== "request") {
      e[0](v0);
    }
  }
  return v3;
};
