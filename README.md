[![CI](https://github.com/DZakh/rescript-struct/actions/workflows/ci.yml/badge.svg)](https://github.com/DZakh/rescript-struct/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DZakh/rescript-struct/branch/main/graph/badge.svg?token=40G6YKKD6J)](https://codecov.io/gh/DZakh/rescript-struct)
[![npm](https://img.shields.io/npm/dm/rescript-struct)](https://www.npmjs.com/package/rescript-struct)

# ReScript Struct

The fastest composable parser/serializer for ReScript (and TypeScript)

> 🧠 Note that **rescript-struct** uses `eval`, which is completely safe to use as part of your application bundle, but may cause issues when included as a third-party script on a site with a [script-src](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/script-src) header.

Highlights:

- Combines validation and transformation without a performance loss
- Can transform parsed value back to the initial format (serializing)
- Works with any Js value, not only `Js.Json.t`
- Support for asynchronous transformations
- Immutable API with both result and exception-based operations
- Easy to create _recursive_ structs
- Detailed error messages
- Strict mode for object structs to prevent excessive fields and many more built-in helpers
- Works with plain JavaScript/TypeScript too! You don't need to use ReScript
- The **fastest** composable validation library in the entire JavaScript ecosystem ([benchmark](https://moltar.github.io/typescript-runtime-type-benchmarks/))
- Small and tree-shakable: [9.5kB minified + zipped](https://bundlephobia.com/package/rescript-struct)

Also, it has declarative API allowing you to use **rescript-struct** as a building block for other tools, such as:

- [rescript-envsafe](https://github.com/DZakh/rescript-envsafe) - Makes sure you don't accidentally deploy apps with missing or invalid environment variables
- [rescript-json-schema](https://github.com/DZakh/rescript-json-schema) - Typesafe JSON schema for ReScript
- Internal form library at [Carla](https://www.carla.se/)

## Documentation

- [For ReScript users](./docs/rescript-usage.md)
- [For JS/TS users](./docs/js-usage.md)
- [For library maintainers](./docs/integration-guide.md)
