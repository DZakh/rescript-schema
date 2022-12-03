const packageJson = require("./package.json");

module.exports = () => ({
  files: ["src/**/*.ts", "src/**/*.bs.js"],
  tests: packageJson.ava.files,
  env: {
    type: "node",
  },
  testFramework: "ava",
});
