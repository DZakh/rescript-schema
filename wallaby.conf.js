import fs from 'fs'

const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'))

export default () => ({
  files: [
    'src/**/*.bs.js',
    'package.json'
  ],
  tests: packageJson.ava.files,
  env: {
    type: 'node',
    params: {
      runner: '--experimental-vm-modules' 
    }
  },
  testFramework: 'ava',
  debug: true
});
