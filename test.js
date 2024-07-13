(i) => {
  let r0 = (i) => {
    let v6 = i;
    if (!i || i.constructor !== Object) {
      if (i !== "B") {
        if (i !== "C") {
          if (i !== "D") {
            if (i !== "E") {
              if (i !== "F") {
                if (i !== "G") {
                  if (i !== "H") {
                    if (i !== "I") {
                      if (i !== "J") {
                        if (i !== "K") {
                          if (i !== "L") {
                            if (i !== "M") {
                              if (i !== "N") {
                                if (i !== "O") {
                                  if (i !== "P") {
                                    if (i !== "Q") {
                                      if (i !== "R") {
                                        if (i !== "S") {
                                          if (i !== "T") {
                                            if (i !== "U") {
                                              if (i !== "V") {
                                                if (i !== "W") {
                                                  if (i !== "X") {
                                                    if (i !== "Y") {
                                                      e[6](i);
                                                    }
                                                  }
                                                }
                                              }
                                            }
                                          }
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    } else {
      try {
        let v0 = i["type"],
          v1 = i["nested"],
          v5 = [];
        if (v0 !== "A") {
          e[0](v0);
        }
        if (!Array.isArray(v1)) {
          e[1](v1);
        }
        for (let v2 = 0; v2 < v1.length; ++v2) {
          let v4;
          try {
            v4 = r0(v1[v2]);
          } catch (v3) {
            if (v3 && v3.s === s) {
              v3.path = '["nested"]' + '["' + v2 + '"]' + v3.path;
            }
            throw v3;
          }
          v5.push(v4);
        }
        v6 = { TAG: e[2], _0: v5 };
      } catch (e0) {
        try {
          let v7 = i["type"],
            v8 = i["nested"],
            v12 = [];
          if (v7 !== "Z") {
            e[3](v7);
          }
          if (!Array.isArray(v8)) {
            e[4](v8);
          }
          for (let v9 = 0; v9 < v8.length; ++v9) {
            let v11;
            try {
              v11 = r0(v8[v9]);
            } catch (v10) {
              if (v10 && v10.s === s) {
                v10.path = '["nested"]' + '["' + v9 + '"]' + v10.path;
              }
              throw v10;
            }
            v12.push(v11);
          }
          v6 = { TAG: e[5], _0: v12 };
        } catch (e1) {
          e[7]([e0, e1]);
        }
      }
    }
    return v6;
  };
  return r0(i);
};
