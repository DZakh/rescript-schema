(i) => {
  if (!i || i.constructor !== Object) {
    e[4](i);
  }
  let r = (i) => {
    let v0 = i["Id"],
      v1 = e[1](v0),
      v2 = i["Children"],
      v8 = [],
      v9 = () => Promise.all(v8.map((t) => t()));
    if (typeof v0 !== "string") {
      e[0](v0);
    }
    if (!Array.isArray(v2)) {
      e[2](v2);
    }
    for (let v3 = 0; v3 < v2.length; ++v3) {
      let v5 = v2[v3],
        v6,
        v7;
      try {
        if (!v5 || v5.constructor !== Object) {
          e[3](v5);
        }
        v6 = r(v5);
        v7 = () => {
          try {
            return v6().catch((v4) => {
              if (v4 && v4.s === s) {
                v4.path = '["Children"]' + '["' + v3 + '"]' + v4.path;
              }
              throw v4;
            });
          } catch (v4) {
            if (v4 && v4.s === s) {
              v4.path = '["Children"]' + '["' + v3 + '"]' + v4.path;
            }
            throw v4;
          }
        };
      } catch (v4) {
        if (v4 && v4.s === s) {
          v4.path = '["Children"]' + '["' + v3 + '"]' + v4.path;
        }
        throw v4;
      }
      v8.push(v7);
    }
    return () =>
      Promise.all([v1(), v9()]).then(([v1, v9]) => ({ id: v1, children: v9 }));
  };
  return r(i);
};
