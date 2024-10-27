(i) => {
  let v0 = i;
  if (!i || i.constructor !== Object) {
    e[7](i);
  } else {
    try {
      if (i["TAG"] !== "Circle") {
        e[0](i["TAG"]);
      }
      v0 = { kind: e[1], radius: i["radius"] };
    } catch (e0) {
      try {
        if (i["TAG"] !== "Square") {
          e[2](i["TAG"]);
        }
        v0 = { kind: e[3], x: i["x"] };
      } catch (e1) {
        try {
          if (i["TAG"] !== "Triangle") {
            e[4](i["TAG"]);
          }
          v0 = { kind: e[5], x: i["x"], y: i["y"] };
        } catch (e2) {
          e[6]([e0, e1, e2]);
        }
      }
    }
  }
  return v0;
};
