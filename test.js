(i) => {
  let r0 = (i) => {
    let v5, v6, v12;
    try {
      let v0 = i["_0"],
        v4 = [];
      if (i["TAG"] !== e[0]) {
        e[1](i["TAG"]);
      }
      for (let v1 = 0; v1 < v0.length; ++v1) {
        let v3;
        try {
          v3 = r0(v0[v1]);
        } catch (v2) {
          if (v2 && v2.s === s) {
            v2.path = '["_0"]' + '["' + v1 + '"]' + v2.path;
          }
          throw v2;
        }
        v4.push(v3);
      }
      v5 = { type: e[2], nested: v4 };
      if (!v5 || v5.constructor !== Object) {
        e[3](v5);
      }
      v6 = v5;
    } catch (e0) {
      try {
        i === "B" || e[4](i);
        v6 = i;
      } catch (e1) {
        try {
          i === "C" || e[5](i);
          v6 = i;
        } catch (e2) {
          try {
            i === "D" || e[6](i);
            v6 = i;
          } catch (e3) {
            try {
              i === "E" || e[7](i);
              v6 = i;
            } catch (e4) {
              try {
                i === "F" || e[8](i);
                v6 = i;
              } catch (e5) {
                try {
                  i === "G" || e[9](i);
                  v6 = i;
                } catch (e6) {
                  try {
                    i === "H" || e[10](i);
                    v6 = i;
                  } catch (e7) {
                    try {
                      i === "I" || e[11](i);
                      v6 = i;
                    } catch (e8) {
                      try {
                        i === "J" || e[12](i);
                        v6 = i;
                      } catch (e9) {
                        try {
                          i === "K" || e[13](i);
                          v6 = i;
                        } catch (e10) {
                          try {
                            i === "L" || e[14](i);
                            v6 = i;
                          } catch (e11) {
                            try {
                              i === "M" || e[15](i);
                              v6 = i;
                            } catch (e12) {
                              try {
                                i === "N" || e[16](i);
                                v6 = i;
                              } catch (e13) {
                                try {
                                  i === "O" || e[17](i);
                                  v6 = i;
                                } catch (e14) {
                                  try {
                                    i === "P" || e[18](i);
                                    v6 = i;
                                  } catch (e15) {
                                    try {
                                      i === "Q" || e[19](i);
                                      v6 = i;
                                    } catch (e16) {
                                      try {
                                        i === "R" || e[20](i);
                                        v6 = i;
                                      } catch (e17) {
                                        try {
                                          i === "S" || e[21](i);
                                          v6 = i;
                                        } catch (e18) {
                                          try {
                                            i === "T" || e[22](i);
                                            v6 = i;
                                          } catch (e19) {
                                            try {
                                              i === "U" || e[23](i);
                                              v6 = i;
                                            } catch (e20) {
                                              try {
                                                i === "V" || e[24](i);
                                                v6 = i;
                                              } catch (e21) {
                                                try {
                                                  i === "W" || e[25](i);
                                                  v6 = i;
                                                } catch (e22) {
                                                  try {
                                                    i === "X" || e[26](i);
                                                    v6 = i;
                                                  } catch (e23) {
                                                    try {
                                                      i === "Y" || e[27](i);
                                                      v6 = i;
                                                    } catch (e24) {
                                                      try {
                                                        let v7 = i["_0"],
                                                          v11 = [];
                                                        if (
                                                          i["TAG"] !== e[28]
                                                        ) {
                                                          e[29](i["TAG"]);
                                                        }
                                                        for (
                                                          let v8 = 0;
                                                          v8 < v7.length;
                                                          ++v8
                                                        ) {
                                                          let v10;
                                                          try {
                                                            v10 = r0(v7[v8]);
                                                          } catch (v9) {
                                                            if (
                                                              v9 &&
                                                              v9.s === s
                                                            ) {
                                                              v9.path =
                                                                '["_0"]' +
                                                                '["' +
                                                                v8 +
                                                                '"]' +
                                                                v9.path;
                                                            }
                                                            throw v9;
                                                          }
                                                          v11.push(v10);
                                                        }
                                                        v12 = {
                                                          type: e[30],
                                                          nested: v11,
                                                        };
                                                        if (
                                                          !v12 ||
                                                          v12.constructor !==
                                                            Object
                                                        ) {
                                                          e[31](v12);
                                                        }
                                                        v6 = v12;
                                                      } catch (e25) {
                                                        e[32]([
                                                          e0,
                                                          e1,
                                                          e2,
                                                          e3,
                                                          e4,
                                                          e5,
                                                          e6,
                                                          e7,
                                                          e8,
                                                          e9,
                                                          e10,
                                                          e11,
                                                          e12,
                                                          e13,
                                                          e14,
                                                          e15,
                                                          e16,
                                                          e17,
                                                          e18,
                                                          e19,
                                                          e20,
                                                          e21,
                                                          e22,
                                                          e23,
                                                          e24,
                                                          e25,
                                                        ]);
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
      }
    }
    return v6;
  };
  return r0(i);
};
