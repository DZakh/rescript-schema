const packageJson = require('./package.json');

module.exports = () => ({
  files: [
    'src/**/*.bs.js'
  ],
  tests: packageJson.ava.files,
  env: {
    type: 'node',
  },
  debug: false,
  testFramework: 'ava',
})
