const packageJson = require("./package.json");

module.exports = () => ({
  files: ["src/**/*.js"],
  tests: packageJson.ava.files,
  env: {
    type: "node",
  },
  testFramework: "ava",
});
