(i) => {
  var _, v0, v1;
  if (!(typeof i === "object" && i !== null && !Array.isArray(i))) {
    e[0]("", i);
  }
  v0 = {};
  if (!(typeof i["number"] === "number" && !Number.isNaN(i["number"]))) {
    e[1]("" + "[" + '"number"' + "]", i["number"]);
  }
  v0["number"] = i["number"];
  if (!(typeof i["negNumber"] === "number" && !Number.isNaN(i["negNumber"]))) {
    e[2]("" + "[" + '"negNumber"' + "]", i["negNumber"]);
  }
  v0["negNumber"] = i["negNumber"];
  if (!(typeof i["maxNumber"] === "number" && !Number.isNaN(i["maxNumber"]))) {
    e[3]("" + "[" + '"maxNumber"' + "]", i["maxNumber"]);
  }
  v0["maxNumber"] = i["maxNumber"];
  if (typeof i["string"] !== "string") {
    e[4]("" + "[" + '"string"' + "]", i["string"]);
  }
  v0["string"] = i["string"];
  if (typeof i["longString"] !== "string") {
    e[5]("" + "[" + '"longString"' + "]", i["longString"]);
  }
  v0["longString"] = i["longString"];
  if (typeof i["boolean"] !== "boolean") {
    e[6]("" + "[" + '"boolean"' + "]", i["boolean"]);
  }
  v0["boolean"] = i["boolean"];
  if (
    !(
      typeof i["deeplyNested"] === "object" &&
      i["deeplyNested"] !== null &&
      !Array.isArray(i["deeplyNested"])
    )
  ) {
    e[7]("" + "[" + '"deeplyNested"' + "]", i["deeplyNested"]);
  }
  v1 = {};
  if (typeof i["deeplyNested"]["foo"] !== "string") {
    e[8](
      "" + "[" + '"deeplyNested"' + "]" + "[" + '"foo"' + "]",
      i["deeplyNested"]["foo"]
    );
  }
  v1["foo"] = i["deeplyNested"]["foo"];
  if (
    !(
      typeof i["deeplyNested"]["num"] === "number" &&
      !Number.isNaN(i["deeplyNested"]["num"])
    )
  ) {
    e[9](
      "" + "[" + '"deeplyNested"' + "]" + "[" + '"num"' + "]",
      i["deeplyNested"]["num"]
    );
  }
  v1["num"] = i["deeplyNested"]["num"];
  if (typeof i["deeplyNested"]["bool"] !== "boolean") {
    e[10](
      "" + "[" + '"deeplyNested"' + "]" + "[" + '"bool"' + "]",
      i["deeplyNested"]["bool"]
    );
  }
  v1["bool"] = i["deeplyNested"]["bool"];
  v0["deeplyNested"] = v1;
  return v0;
};
