module.exports = {
  input: "src/S_Js.js",
  output: [
    {
      file: "dist/S.js",
      format: "cjs",
      exports: "named",
    },
    {
      file: "dist/S.mjs",
      format: "es",
      exports: "named",
    },
  ],
  plugins: [require("@rollup/plugin-commonjs")()],
};
