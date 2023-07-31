import fs from "fs";

const packageJson = JSON.parse(fs.readFileSync("./package.json", "utf8"));

const tests = packageJson.ava.files;

export default () => ({
  files: [
    "package.json",
    "src/**/*.mjs",
    "src/S_JsApi.js",
    "packages/tests/src/utils/TestUtils.bs.mjs",
  ],
  tests,
  env: {
    type: "node",
    params: {
      runner: "--experimental-vm-modules",
    },
  },
  testFramework: "ava",
});
