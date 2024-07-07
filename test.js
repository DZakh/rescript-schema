(i) => {
  if (!i || i.constructor !== Object) {
    e[10](i);
  }
  let v0 = i["number"],
    v1 = i["negNumber"],
    v2 = i["maxNumber"],
    v3 = i["string"],
    v4 = i["longString"],
    v5 = i["boolean"],
    v6 = i["deeplyNested"];
  if (typeof v0 !== "number" || Number.isNaN(v0)) {
    e[0](v0);
  }
  if (typeof v1 !== "number" || Number.isNaN(v1)) {
    e[1](v1);
  }
  if (typeof v2 !== "number" || Number.isNaN(v2)) {
    e[2](v2);
  }
  if (typeof v3 !== "string") {
    e[3](v3);
  }
  if (typeof v4 !== "string") {
    e[4](v4);
  }
  if (typeof v5 !== "boolean") {
    e[5](v5);
  }
  if (!v6 || v6.constructor !== Object) {
    e[6](v6);
  }
  let v7 = v6["foo"],
    v8 = v6["num"],
    v9 = v6["bool"];
  if (typeof v7 !== "string") {
    e[7](v7);
  }
  if (typeof v8 !== "number" || Number.isNaN(v8)) {
    e[8](v8);
  }
  if (typeof v9 !== "boolean") {
    e[9](v9);
  }
  return void 0;
};
